# 2-aws - Provision EC2 public web server trên AWS

Thư mục này chứa Terraform code để tạo một hạ tầng AWS đơn giản:

- 1 VPC riêng với CIDR `10.20.0.0/16`.
- 2 public subnet nằm ở 2 Availability Zone khác nhau.
- 1 Internet Gateway để VPC có đường ra/vào Internet.
- 1 public route table trỏ default route `0.0.0.0/0` ra Internet Gateway.
- 1 security group cho phép:
  - SSH port `22` từ public IP của bạn.
  - HTTP port `80` từ mọi nơi.
- 1 EC2 instance `t3.micro` chạy Amazon Linux 2023.
- 1 Elastic IP gắn vào EC2.
- User data cài `nginx` và hiển thị nội dung `hello from <hostname>`.

## Files

| File           | Vai trò                                                                                     |
| -------------- | ------------------------------------------------------------------------------------------- |
| `versions.tf`  | Khai báo Terraform version, AWS provider và region.                                         |
| `variables.tf` | Khai báo các biến đầu vào như region, tên project, owner, IP được phép SSH và key pair.     |
| `main.tf`      | Định nghĩa toàn bộ AWS resources: VPC, subnet, IGW, route table, security group, EC2, EIP.  |
| `outputs.tf`   | In ra các giá trị quan trọng sau khi apply, như VPC ID, instance ID, Elastic IP và web URL. |

## Provider Và Region

Trong `versions.tf`, Terraform yêu cầu:

- Terraform CLI version `>= 1.6`.
- AWS provider `hashicorp/aws` version `~> 5.0`.

Provider AWS dùng biến:

```hcl
provider "aws" {
  region = var.aws_region
}
```

Mặc định `aws_region = "ap-southeast-1"`, tức Singapore region. Nếu muốn deploy sang region khác, truyền biến `aws_region` khi chạy plan hoặc apply.

## Data Sources

### Availability Zones

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}
```

Data source này lấy danh sách Availability Zone đang available trong region hiện tại. Code dùng 2 AZ đầu tiên:

```hcl
data.aws_availability_zones.available.names[count.index]
```

Mục đích là đảm bảo 2 public subnet nằm ở 2 AZ khác nhau, đúng yêu cầu và tốt hơn việc đặt tất cả subnet trong cùng một AZ.

### Amazon Linux 2023 AMI

```hcl
data "aws_ami" "amazon_linux_2023" {
    most_recent = true
    owners      = ["amazon"]

    filter {
      name   = "name"
      values = ["al2023-ami-2023.*-kernel-*-x86_64"]
    }

    filter {
      name   = "architecture"
      values = ["x86_64"]
    }

    filter {
      name   = "virtualization-type"
      values = ["hvm"]
    }

    filter {
      name   = "root-device-type"
      values = ["ebs"]
    }
}
```

AWS ami này trả về AMI ID mới nhất của Amazon Linux 2023 cho từng region. Cách này tốt hơn hard-code AMI ID vì AMI ID thay đổi theo region và theo thời gian.

EC2 dùng giá trị này:

```hcl
ami                         = data.aws_ami.amazon_linux_2023
```

## Locals Và Tags

```hcl
locals {
  public_subnet_cidrs = [
    cidrsubnet(aws_vpc.main.cidr_block, 8, 1),
    cidrsubnet(aws_vpc.main.cidr_block, 8, 2),
  ]

  common_tags = {
    Project = var.project_name
    Owner   = var.project_owner
  }
}
```

`public_subnet_cidrs` tạo 2 subnet CIDR từ VPC CIDR `10.20.0.0/16`.

Hàm:

```hcl
cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
cidrsubnet(aws_vpc.main.cidr_block, 8, 2)
```

có nghĩa là lấy CIDR của VPC và thêm 8 bit cho subnet mask. Từ `/16`, subnet sẽ thành `/24`.

Kết quả:

- Public subnet 1: `10.20.1.0/24`
- Public subnet 2: `10.20.2.0/24`

`common_tags` được gắn vào resources để dễ nhận diện trên AWS Console:

- `Project = var.project_name`
- `Owner = var.project_owner`

Mặc định hiện tại:

- `project_name = "devops-training"`
- `project_owner = "duy"`

## VPC

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```

VPC là mạng riêng trên AWS. CIDR `10.20.0.0/16` cho phép tạo nhiều subnet bên trong dải IP `10.20.x.x`.

Hai option DNS được bật:

- `enable_dns_support = true`: cho phép VPC dùng DNS resolver của AWS.
- `enable_dns_hostnames = true`: instance trong public subnet có thể có public DNS hostname nếu có public IP.

## Public Subnets

```hcl
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}
```

Resource này tạo 2 subnet bằng `count = 2`.

Mỗi subnet:

- Nằm trong VPC `aws_vpc.main`.
- Có CIDR riêng từ `local.public_subnet_cidrs`.
- Nằm ở AZ khác nhau do lấy AZ theo `count.index`.
- Bật `map_public_ip_on_launch = true`, nên instance tạo trong subnet sẽ tự động có public IP nếu không gắn EIP riêng.

Trong cấu hình này EC2 vẫn được gắn Elastic IP riêng. `map_public_ip_on_launch` giúp subnet đúng nghĩa là public subnet và hữu ích nếu sau này tạo thêm instance khác.

## Internet Gateway

```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```

Internet Gateway là cổng kết nối giữa VPC và Internet. VPC muốn có public subnet thì cần Internet Gateway và route table trỏ traffic ra gateway này.

## Public Route Table

```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
```

Route `0.0.0.0/0` nghĩa là tất cả traffic IPv4 không nằm trong route nội bộ VPC sẽ đi ra Internet Gateway.

Đây là thành phần làm subnet trở thành public subnet. Nếu chỉ có subnet mà không có route ra IGW thì instance không thể nhận traffic từ Internet đúng cách.

## Route Table Association

```hcl
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

Do có 2 public subnet, Terraform tạo 2 association để gắn cả 2 subnet vào public route table. Nếu thiếu association, subnet sẽ dùng main route table mặc định của VPC và có thể không có đường ra Internet.

## Security Group

```hcl
resource "aws_security_group" "web" {
  name   = "${var.project_name}-web-sg"
  vpc_id = aws_vpc.main.id
}
```

Security group này đóng vai trò firewall gắn vào EC2.

### Inbound SSH

```hcl
ingress {
  description = "SSH from your public IP"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = [var.ssh_allowed_cidr]
}
```

Chỉ cho phép SSH từ CIDR bạn truyền vào `ssh_allowed_cidr`, ví dụ:

```text
203.0.113.10/32
```

Dùng `/32` nghĩa là chỉ một IP duy nhất được phép SSH. Không nên dùng `0.0.0.0/0` cho SSH vì sẽ mở port 22 ra toàn Internet.

### Inbound HTTP

```hcl
ingress {
  description = "HTTP from anywhere"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

Cho phép mọi người truy cập web server qua HTTP port `80`.

### Outbound

```hcl
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

Cho phép EC2 tạo kết nối ra ngoài. Điều này cần để instance cài package bằng `dnf install -y nginx` trong user data.

## EC2 Instance

```hcl
resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
}
```

EC2 này:

- Dùng Amazon Linux 2023 AMI mới nhất từ SSM Parameter Store.
- Dùng instance type `t3.micro`.
- Nằm trong public subnet đầu tiên: `aws_subnet.public[0]`.
- Gắn security group `aws_security_group.web`.
- Có public IP.
- Có thể gắn EC2 key pair nếu bạn truyền `key_name`.

`key_name` có default `null`, nghĩa là nếu không truyền key pair thì EC2 vẫn tạo được, nhưng bạn sẽ không SSH bằng private key theo cách thông thường. Để SSH, cần tạo sẵn EC2 Key Pair trên AWS và truyền tên key pair vào Terraform.

## User Data

```bash
#!/bin/bash
set -eux
dnf install -y nginx
echo "hello from $(hostname)" > /usr/share/nginx/html/index.html
systemctl enable --now nginx
```

User data chạy lúc EC2 boot lần đầu.

Ý nghĩa từng dòng:

- `#!/bin/bash`: chạy script bằng Bash.
- `set -eux`: dừng script khi có lỗi, in command đang chạy, và báo lỗi nếu dùng biến chưa khai báo.
- `dnf install -y nginx`: cài nginx trên Amazon Linux 2023.
- `echo "hello from $(hostname)" > /usr/share/nginx/html/index.html`: ghi trang HTML mặc định. `$(hostname)` được xử lý trên EC2, nên nội dung sẽ là hostname thật của instance.
- `systemctl enable --now nginx`: bật nginx tự động khởi động cùng máy và start nginx ngay lập tức.

Sau khi apply thành công, truy cập output `web_url` sẽ thấy nội dung dạng như:

```text
hello from ip-10-20-1-xxx.ap-southeast-1.compute.internal
```

## Elastic IP

```hcl
resource "aws_eip" "web" {
  domain   = "vpc"
  instance = aws_instance.web.id

  depends_on = [aws_internet_gateway.main]
}
```

Elastic IP là public IPv4 tĩnh gắn vào EC2. Nếu instance stop/start, public IP thông thường có thể thay đổi, nhưng Elastic IP giữ nguyên cho đến khi bạn release hoặc destroy resource.

`depends_on = [aws_internet_gateway.main]` đảm bảo Internet Gateway được tạo trước khi gắn EIP.

Lưu ý chi phí: AWS có thể tính phí Elastic IP nếu EIP không được gắn vào resource đang chạy, hoặc tùy theo chính sách giá hiện tại của AWS. Sau khi học xong nên chạy `terraform destroy`.

## Biến Đầu Vào

| Variable           | Default           | Bắt buộc? | Ý nghĩa                                                   |
| ------------------ | ----------------- | --------- | --------------------------------------------------------- |
| `aws_region`       | `ap-southeast-1`  | Không     | Region AWS để tạo resource.                               |
| `project_name`     | `devops-training` | Không     | Prefix đặt tên và tag `Project`.                          |
| `project_owner`    | `duy`             | Không     | Giá trị tag `Owner`.                                      |
| `ssh_allowed_cidr` | Không có          | Có        | Public IP/CIDR được phép SSH vào EC2. Nên dùng `/32`.     |
| `key_name`         | `null`            | Không     | Tên EC2 Key Pair đã tồn tại trên AWS để SSH vào instance. |

## Outputs

Sau khi `terraform apply`, Terraform in ra:

| Output              | Ý nghĩa                            |
| ------------------- | ---------------------------------- |
| `vpc_id`            | ID của VPC vừa tạo.                |
| `public_subnet_ids` | Danh sách ID của 2 public subnet.  |
| `security_group_id` | ID của security group gắn vào EC2. |
| `instance_id`       | ID của EC2 instance.               |
| `elastic_ip`        | Public Elastic IP của EC2.         |
| `web_url`           | URL HTTP để truy cập nginx.        |
