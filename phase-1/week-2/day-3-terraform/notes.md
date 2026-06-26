## State file là gì? Vì sao không được commit lên Git?

Terraform state file, thường là `terraform.tfstate`, là file Terraform dùng để ghi nhớ trạng thái hiện tại của infrastructure mà nó quản lý.

State file lưu các thông tin như:

- Resource nào đã được tạo.
- ID thật của resource trên cloud, ví dụ EC2 instance ID, VPC ID, Security Group ID.
- Mapping giữa code Terraform và resource thật.
- Metadata và dependency giữa các resource.
- Một số giá trị output hoặc attribute nhạy cảm.

Không nên commit state file lên Git vì:

- Có thể chứa secret hoặc thông tin nhạy cảm, ví dụ password, token, private IP, database endpoint.
- State thay đổi thường xuyên, dễ gây conflict khi nhiều người cùng làm việc.
- Git không có locking, nên nhiều người có thể apply cùng lúc và làm hỏng state.
- State là dữ liệu runtime của môi trường, không phải source code.
- Nếu state bị public, người khác có thể biết cấu trúc infrastructure của mình.

Nên đưa các file state local vào `.gitignore`, ví dụ:

```gitignore
*.tfstate
*.tfstate.*
.terraform/
```

## So sánh `terraform plan`, `terraform apply` và `terraform refresh`

### `terraform plan`

`terraform plan` dùng để xem Terraform sẽ thay đổi gì trước khi thực hiện.

Lệnh này:

- Đọc file `.tf`.
- Đọc state hiện tại.
- So sánh state với infrastructure thật.
- So sánh với desired configuration trong code.
- In ra danh sách resource sẽ được tạo, sửa hoặc xóa.

`plan` không thay đổi infrastructure.

Dùng khi muốn review trước khi deploy.

### `terraform apply`

`terraform apply` dùng để thực hiện thay đổi lên infrastructure.

Lệnh này:

- Tạo plan.
- Hỏi xác nhận, trừ khi dùng `-auto-approve`.
- Gọi API của provider, ví dụ AWS API.
- Tạo, sửa hoặc xóa resource.
- Cập nhật state file sau khi thay đổi thành công.

`apply` có thay đổi infrastructure thật.

Dùng khi muốn deploy thay đổi.

### `terraform refresh`

`terraform refresh` dùng để cập nhật state dựa trên infrastructure thật hiện tại.

Lệnh này:

- Đọc resource trong state.
- Gọi provider API để lấy trạng thái thật.
- Cập nhật state nếu infrastructure thật đã thay đổi bên ngoài Terraform.

`terraform refresh` không sửa infrastructure, chỉ sửa state.

Lưu ý: Trong các phiên bản Terraform mới, `terraform refresh` ít được dùng trực tiếp hơn. Thường dùng:

```bash
terraform plan -refresh-only
terraform apply -refresh-only
```

Bảng so sánh nhanh:

| Lệnh | Thay đổi infrastructure? | Thay đổi state? | Mục đích |
| --- | --- | --- | --- |
| `terraform plan` | Không | Có thể refresh state trong quá trình plan, tùy cấu hình | Xem trước thay đổi |
| `terraform apply` | Có | Có | Deploy thay đổi |
| `terraform refresh` | Không | Có | Đồng bộ state với infrastructure thật |

## Tại sao nên dùng remote backend S3 + DynamoDB lock?

Remote backend giúp lưu state ở một nơi chung thay vì nằm trên máy local của từng người.

Với AWS, một setup phổ biến là:

- S3: lưu file Terraform state.
- DynamoDB: dùng để lock state khi có người đang chạy Terraform.

Lợi ích:

- Nhiều người trong team cùng dùng chung một state.
- State không bị mất khi máy local hỏng hoặc bị xóa.
- S3 có versioning, có thể rollback state khi cần.
- Có thể bật encryption để bảo vệ state.
- DynamoDB lock ngăn việc hai người cùng `apply` cùng lúc.
- Dễ tích hợp với CI/CD.
- Phân quyền truy cập bằng IAM tốt hơn so với share file thủ công.

Nếu không có lock, hai người chạy `terraform apply` cùng lúc có thể làm state bị sai hoặc resource bị tạo/xóa ngoài ý muốn.

## So sánh module local và module registry

### Module local

Module local là module nằm trong chính repository hoặc filesystem của mình.

Ví dụ:

```hcl
module "vpc" {
  source = "./modules/vpc"
}
```

Ưu điểm:

- Dễ chỉnh sửa.
- Phù hợp với logic riêng của project.
- Không phụ thuộc vào internet hoặc registry bên ngoài.
- Dễ review cùng codebase.

Nhược điểm:

- Khó tái sử dụng giữa nhiều repo nếu không tách riêng.
- Team phải tự maintain.
- Có thể bị duplicate logic giữa các project.

### Module registry

Module registry là module lấy từ Terraform Registry hoặc private registry.

Ví dụ:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
}
```

Ưu điểm:

- Tái sử dụng nhanh.
- Thường đã có sẵn best practice.
- Có version rõ ràng.
- Giảm công viết module từ đầu.

Nhược điểm:

- Cần đọc kỹ input, output và behavior.
- Có thể phức tạp hơn nhu cầu thật.
- Phụ thuộc vào module bên ngoài.
- Nếu không pin version, update có thể gây lỗi.

Nên dùng module local khi logic gắn với project hoặc cần tùy biến nhiều.

Nên dùng module registry khi bài toán phổ biến, ví dụ VPC, EKS, RDS, ALB, và module đó được maintain tốt.

## `count` vs `for_each` - khi nào dùng cái nào?

Cả `count` và `for_each` đều dùng để tạo nhiều instance của cùng một resource hoặc module.

### `count`

`count` phù hợp khi:

- Chỉ cần tạo N resource giống nhau.
- Resource được quản lý bằng index số: `0`, `1`, `2`.
- Danh sách ít thay đổi thứ tự.

Ví dụ:

```hcl
resource "aws_instance" "web" {
  count = 3

  ami           = var.ami_id
  instance_type = "t3.micro"
}
```

Truy cập:

```hcl
aws_instance.web[0].id
```

Nhược điểm của `count`:

- Nếu xóa một phần tử ở giữa list, index thay đổi.
- Terraform có thể hiểu nhầm là cần destroy/recreate nhiều resource.

### `for_each`

`for_each` phù hợp khi:

- Mỗi resource có tên/key riêng.
- Cần tạo resource từ map hoặc set.
- Muốn identity của resource ổn định theo key.
- Danh sách có thể thêm/xóa item thường xuyên.

Ví dụ:

```hcl
resource "aws_iam_user" "user" {
  for_each = toset(["alice", "bob", "charlie"])

  name = each.key
}
```

Truy cập:

```hcl
aws_iam_user.user["alice"].name
```

Nên dùng:

- `count` khi các object giống nhau và chỉ quan tâm số lượng.
- `for_each` khi mỗi object có định danh riêng và cần tránh thay đổi do index.

Trong thực tế, `for_each` thường an toàn hơn cho resource có tên hoặc cấu hình riêng.

## Drift là gì? Cách phát hiện và xử lý

Drift là tình trạng infrastructure thật khác với Terraform state hoặc khác với Terraform code.

Ví dụ:

- Terraform tạo EC2 instance type `t3.micro`.
- Ai đó vào AWS Console đổi thành `t3.small`.
- Code vẫn ghi `t3.micro`, nhưng resource thật đã bị thay đổi.

Đó là drift.

Nguyên nhân thường gặp:

- Sửa resource thủ công trên AWS Console.
- Script hoặc tool khác thay đổi infrastructure.
- Auto Scaling hoặc service tự động thay đổi một số attribute.
- Terraform state bị cũ hoặc bị sai.
- Nhiều workspace/team quản lý trùng một resource.

Cách phát hiện drift:

- Chạy `terraform plan`.
- Chạy `terraform plan -refresh-only` để xem thay đổi giữa state và infrastructure thật.
- Dùng CI/CD chạy drift detection định kỳ.
- Dùng Terraform Cloud/Enterprise drift detection nếu có.
- Kiểm tra log thay đổi trên cloud, ví dụ AWS CloudTrail.

Cách xử lý drift:

- Nếu thay đổi bên ngoài là đúng: cập nhật code Terraform cho khớp, sau đó `terraform plan` và `terraform apply`.
- Nếu thay đổi bên ngoài là sai: chạy `terraform apply` để đưa infrastructure về đúng với code.
- Nếu resource đã tồn tại nhưng chưa có trong state: dùng `terraform import`.
- Nếu state sai: dùng các lệnh state như `terraform state mv`, `terraform state rm` cẩn thận.
- Hạn chế sửa tay trên cloud console; nên thay đổi qua Terraform.

Nguyên tắc quan trọng: Terraform code nên là source of truth cho infrastructure.
