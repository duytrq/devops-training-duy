# AWS IAM Notes

## 1. Phân biệt user, group, role, policy

- **User**: danh tính đại diện cho một người dùng hoặc một ứng dụng cần đăng nhập/gọi AWS trực tiếp. User có thể có password để vào AWS Console và/hoặc access key để gọi API/CLI.
- **Group**: tập hợp nhiều IAM user. Group giúp gắn policy cho nhiều user cùng lúc. Group không đăng nhập được và không thể lồng group trong group.
- **Role**: danh tính IAM được một principal khác tạm thời assume để nhận credential ngắn hạn. Role thường dùng cho EC2, Lambda, ECS, CI/CD, cross-account access, hoặc federated users.
- **Policy**: tài liệu JSON mô tả quyền được allow hoặc deny. Policy quy định ai được làm hành động nào, trên tài nguyên nào, và trong điều kiện nào.

## 2. Trust policy vs identity policy vs resource policy

- **Trust policy**: gắn vào IAM role, quy định principal nào được assume role đó. Nó trả lời câu hỏi: "Ai được nhập vai role này?"
- **Identity policy**: gắn vào identity như user, group, hoặc role. Nó quy định identity đó được/không được làm gì trên AWS resources. Nó trả lời câu hỏi: "Identity này có quyền làm hành động nào?"
- **Resource policy**: gắn trực tiếp vào resource, ví dụ S3 bucket policy, SQS queue policy, KMS key policy. Nó quy định principal nào được truy cập resource đó. Nó trả lời câu hỏi: "Resource này cho ai truy cập?"

Ví dụ:

- EC2 assume một IAM role: role cần **trust policy** cho phép service `ec2.amazonaws.com` assume role.
- Role đọc object trong S3: role cần **identity policy** cho phép `s3:GetObject`.
- Bucket cho phép account khác đọc object: bucket có thể cần **resource policy** cho phép principal từ account đó.

## 3. Tại sao IAM role tốt hơn IAM user key cho EC2/CI/CD?

IAM role tốt hơn IAM user access key vì:

- **Credential ngắn hạn**: role cấp temporary credentials, tự động expire. IAM user key thường là long-lived key, nếu lộ sẽ nguy hiểm hơn.
- **Không cần hard-code secret**: EC2/CI/CD có thể lấy credential từ metadata service hoặc OIDC/assume role flow, không cần lưu access key trong file, biến môi trường, hay secret store nếu không cần thiết.
- **Tự động rotate**: AWS tự động rotate temporary credentials của role. IAM user key phải rotate thủ công hoặc tự xây quy trình rotate.
- **Giảm blast radius**: role có thể gắn quyền tối thiểu cho từng workload, từng pipeline, từng environment.
- **Phù hợp best practice**: workload trên AWS và CI/CD hiện đại nên dùng role/OIDC thay vì access key dài hạn.

## 4. Đọc policy JSON và giải thích từng trường

Policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": { "IpAddress": { "aws:SourceIp": "203.0.113.0/24" } }
    }
  ]
}
```

Giải thích:

- **Version**: phiên bản ngôn ngữ policy của AWS IAM. `2012-10-17` là version hiện hành và thường được dùng.
- **Statement**: danh sách các rule trong policy. Mỗi statement mô tả một tập quyền allow/deny.
- **Effect**: kết quả của statement. `Allow` nghĩa là cho phép nếu request khớp với các trường `Action`, `Resource`, và `Condition`.
- **Action**: hành động AWS được áp dụng. `s3:GetObject` là quyền đọc/tải object trong S3.
- **Resource**: tài nguyên AWS mà action áp dụng lên. `arn:aws:s3:::my-bucket/*` nghĩa là tất cả object nằm trong bucket `my-bucket`, không phải chính bucket.
- **Condition**: điều kiện bổ sung để statement có hiệu lực. Ở đây request chỉ được allow nếu IP nguồn nằm trong dải `203.0.113.0/24`.
- **IpAddress**: condition operator kiểm tra địa chỉ IP.
- **aws:SourceIp**: condition key đại diện cho IP nguồn của request.

Kết luận: policy này cho phép đọc object trong `my-bucket` bằng `s3:GetObject`, nhưng chỉ khi request đến từ dải IP `203.0.113.0/24`.

## 5. User nằm trong group có Allow, nhưng policy gắn trực tiếp user có Deny

Kết quả là **Deny**.

Trong IAM, **explicit Deny luôn ưu tiên hơn Allow**. Nếu một user nhận được `Allow` từ group, nhưng có policy gắn trực tiếp vào user với `Deny` cho cùng hành động/tài nguyên, thì request bị từ chối.

Thứ tự đánh giá có thể hiểu ngắn gọn:

1. Mặc định là deny nếu không có Allow.
2. Nếu có Allow phù hợp, request có thể được cho phép.
3. Nếu có bất kỳ explicit Deny nào phù hợp, request bị deny bất kể Allow đến từ đâu.

# AWS VPC Topology Notes

## Mô hình yêu cầu

- 1 VPC.
- 2 public subnet ở 2 Availability Zone khác nhau.
- 2 private subnet ở 2 Availability Zone khác nhau.
- 1 Internet Gateway gắn vào VPC.
- NAT Gateway đặt trong public subnet.
- Public route table cho public subnet.
- Private route table cho private subnet.
- 1 Application Load Balancer ở public subnet.
- 2 EC2 backend ở private subnet.

## ASCII diagram

```text
Internet
   |
   v
+-------------------+
| Internet Gateway  |
+-------------------+
   |
   v
+-----------------------------------------------------------------------+
| VPC: 10.0.0.0/16                                                      |
|                                                                       |
|  Availability Zone A                       Availability Zone B        |
|  -------------------                       -------------------        |
|                                                                       |
|  Public Subnet A                           Public Subnet B            |
|  10.0.1.0/24                               10.0.2.0/24                |
|  +----------------------+                  +----------------------+   |
|  | ALB node             |<---------------->| ALB node             |   |
|  | NAT Gateway          |                  |                      |   |
|  +----------------------+                  +----------------------+   |
|          |                                               |            |
|          | Public Route Table                            |            |
|          | 10.0.0.0/16 -> local                          |            |
|          | 0.0.0.0/0  -> Internet Gateway                |            |
|          v                                               v            |
|                                                                       |
|  Private Subnet A                          Private Subnet B           |
|  10.0.11.0/24                              10.0.12.0/24               |
|  +----------------------+                  +----------------------+   |
|  | EC2 backend 1        |                  | EC2 backend 2        |   |
|  +----------------------+                  +----------------------+   |
|          |                                               |            |
|          | Private Route Table                           |            |
|          | 10.0.0.0/16 -> local                          |            |
|          | 0.0.0.0/0  -> NAT Gateway                     |            |
|          v                                               v            |
|                                                                       |
+-----------------------------------------------------------------------+
```

Luồng inbound:

```text
User trên Internet
  -> Internet Gateway
  -> Public ALB
  -> Target Group
  -> EC2 backend trong private subnet
```

Luồng outbound từ backend:

```text
EC2 backend trong private subnet
  -> Private Route Table
  -> NAT Gateway trong public subnet
  -> Internet Gateway
  -> Internet
```

## Giải thích từng thành phần

### VPC

VPC là mạng riêng trong AWS account. Ví dụ dùng CIDR `10.0.0.0/16`, bên trong chia ra các subnet nhỏ hơn. Tất cả subnet, route table, Internet Gateway, NAT Gateway, ALB và EC2 đều nằm trong hoặc gắn với VPC này.

### Public subnet

Public subnet là subnet có route ra Internet Gateway:

```text
0.0.0.0/0 -> Internet Gateway
```

Một resource trong public subnet có thể nhận traffic từ internet nếu:

- Subnet có route ra Internet Gateway.
- Resource có public IP hoặc ALB có public interface.
- Security group và network ACL cho phép traffic cần thiết.

Trong mô hình này, ALB đặt ở public subnet vì user từ internet cần truy cập ALB.

### Private subnet

Private subnet không có route trực tiếp ra Internet Gateway. Route mặc định của private subnet đi qua NAT Gateway:

```text
0.0.0.0/0 -> NAT Gateway
```

EC2 backend đặt trong private subnet để không bị truy cập trực tiếp từ internet.

### Internet Gateway

Internet Gateway cho phép traffic giữa VPC và internet. Public subnet dùng Internet Gateway để:

- Nhận inbound traffic từ internet vào ALB.
- Gửi outbound traffic từ NAT Gateway ra internet.

### NAT Gateway

NAT Gateway nằm trong public subnet và có Elastic IP. Nó cho phép EC2 trong private subnet đi ra internet để:

- Update package.
- Pull Docker image.
- Gọi external API.
- Tải dependency.

NAT Gateway chỉ hỗ trợ outbound từ private subnet ra internet. Nó không cho internet chủ động mở kết nối inbound vào EC2 private.

### Route table

Public route table:

```text
10.0.0.0/16 -> local
0.0.0.0/0  -> Internet Gateway
```

Private route table:

```text
10.0.0.0/16 -> local
0.0.0.0/0  -> NAT Gateway
```

Route `local` giúp các resource trong cùng VPC nói chuyện với nhau, ví dụ ALB gửi traffic đến EC2 backend.

### Application Load Balancer

ALB đặt trong public subnet của ít nhất 2 AZ để có high availability. User truy cập ALB qua DNS name của ALB. ALB nhận HTTP/HTTPS request rồi forward đến target group chứa EC2 backend trong private subnet.

### EC2 backend

EC2 backend nằm trong private subnet. Security group của EC2 nên chỉ cho phép inbound từ security group của ALB, không mở trực tiếp từ `0.0.0.0/0`.

Ví dụ:

- ALB security group: allow inbound `80/443` từ `0.0.0.0/0`.
- EC2 security group: allow inbound app port, ví dụ `80` hoặc `8080`, chỉ từ ALB security group.

## Tại sao backend phải ở private subnet?

Backend nên ở private subnet vì:

- **Giảm bề mặt tấn công**: EC2 không có public IP và không nhận traffic trực tiếp từ internet.
- **Ép traffic đi qua ALB**: user chỉ truy cập được qua ALB, giúp tập trung TLS, routing, health check, WAF, logging và rate limiting.
- **Dễ kiểm soát security group**: backend chỉ cần allow inbound từ ALB security group.
- **Bảo vệ service nội bộ**: database connection, internal API, admin port hoặc metrics endpoint không bị expose public.
- **Phù hợp mô hình production**: public layer chỉ nên là ALB/bastion/API Gateway/NAT, còn application server và database nên ở private subnet.

Nếu backend đặt ở public subnet và có public IP, chỉ cần security group cấu hình sai là service có thể bị expose trực tiếp ra internet.

## Outbound internet của backend đi qua đâu?

Backend trong private subnet đi ra internet qua NAT Gateway:

```text
EC2 private
  -> route table private
  -> NAT Gateway trong public subnet
  -> route table public
  -> Internet Gateway
  -> Internet
```

Điểm quan trọng:

- EC2 private không cần public IP.
- Response từ internet quay lại theo connection do EC2 khởi tạo.
- Internet không thể chủ động kết nối trực tiếp vào EC2 private thông qua NAT Gateway.
- NAT Gateway phải nằm trong public subnet và public subnet đó phải có route `0.0.0.0/0 -> Internet Gateway`.
