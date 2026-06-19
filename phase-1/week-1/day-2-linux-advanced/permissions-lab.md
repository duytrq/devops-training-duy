## Các bước chuẩn bị hệ thống

Trước khi thực hiện lab, cần đảm bảo hệ thống đã cài đặt gói `acl` và chuẩn bị đầy đủ group, user để thử nghiệm.

### 1. Cài đặt gói `acl`

Trên các hệ điều hành Ubuntu/Debian, cài đặt bằng lệnh:

```bash
sudo apt-get update
sudo apt-get install -y acl
```

### 2. Tạo Group và User thử nghiệm

Tạo group `devops` và user `testuser` (nếu chưa tồn tại) để kiểm chứng việc phân quyền:

```bash
# Tạo group devops
sudo groupadd devops

# Thêm user hiện tại vào group devops
sudo usermod -aG devops $USER

# Tạo user testuser để kiểm tra ACL
sudo useradd -m -s /bin/bash testuser
```

_(Lưu ý: Sau khi thêm user hiện tại vào group `devops`, cần login lại hoặc chạy lệnh `newgrp devops` để cập nhật nhóm mới cho session hiện tại)._

---

## Reproduce Steps

### Bước 1: Tạo thư mục lab và cấu hình SetGID

Tạo thư mục `/tmp/shared-lab`, chuyển sở hữu nhóm về `devops` và bật bit SetGID.

```bash
# 1. Tạo thư mục
mkdir -p /tmp/shared-lab

# 2. Chuyển quyền sở hữu nhóm (Group Ownership) về devops
sudo chown :devops /tmp/shared-lab

# 3. Phân quyền cơ bản: Owner (rwx), Group devops (rwx), Others (không có quyền)
# Đồng thời gán bit SetGID (số 2 đứng đầu hoặc sử dụng g+s)
sudo chmod 2770 /tmp/shared-lab
```

_Giải thích quyền `2770`:_

- `2`: Đại diện cho **SetGID bit**. Khi đặt bit này trên thư mục, bất kỳ file hoặc thư mục con nào được tạo ra bên trong `/tmp/shared-lab` sẽ tự động có nhóm sở hữu là `devops` (giống thư mục cha), thay vì nhóm mặc định của user tạo ra file đó.
- `7`: Quyền của Owner (`rwx` - đọc, ghi, truy cập).
- `7`: Quyền của Group (`rwx` - đọc, ghi, truy cập).
- `0`: Quyền của Others (`---` - không có bất cứ quyền gì).

---

### Bước 2: Kiểm chứng tính năng kế thừa Group (SetGID)

Tạo một file mới bên trong thư mục bằng tài khoản của bạn để kiểm tra tính năng kế thừa:

```bash
touch /tmp/shared-lab/test_inherit.txt
ls -l /tmp/shared-lab/test_inherit.txt
```

_Kết quả mong đợi:_ Nhóm sở hữu của file `test_inherit.txt` tự động là `devops`.

---

### Bước 3: Tạo file secret.txt chỉ chủ sở hữu được đọc

Tạo file `secret.txt` và phân quyền giới hạn nghiêm ngặt chỉ cho phép chủ sở hữu (owner) đọc (hoặc đọc/ghi):

```bash
# 1. Tạo file secret.txt
touch /tmp/shared-lab/secret.txt

# 2. Phân quyền chỉ owner đọc được (và ghi được nếu cần), chặn toàn bộ group và others
chmod 600 /tmp/shared-lab/secret.txt
```

_Kiểm tra lại:_

```bash
ls -l /tmp/shared-lab/secret.txt
# Kết quả mong đợi: -rw------- 1 ...
```

---

### Bước 4: Thiết lập ACL cho `testuser` chỉ được đọc trên file chỉ định

Sử dụng ACL để cấp quyền tùy biến cho `testuser` (người không thuộc nhóm `devops` và không phải là owner của file).

Tạo một file thông tin công khai `public.txt`:

```bash
touch /tmp/shared-lab/public.txt
chmod 660 /tmp/shared-lab/public.txt
```

Bây giờ thiết lập ACL cho `testuser`:

```bash
# 1. Cho phép testuser có quyền truy cập (rx) vào thư mục cha /tmp/shared-lab
# (Bắt buộc phải có quyền thực thi 'x' trên thư mục thì user mới truy cập được file bên trong)
sudo setfacl -m u:testuser:rx /tmp/shared-lab

# 2. Cấp quyền chỉ đọc (r) cho testuser trên file public.txt
sudo setfacl -m u:testuser:r /tmp/shared-lab/public.txt
```

_Kiểm tra danh sách ACL đã được cấu hình:_

```bash
getfacl /tmp/shared-lab/public.txt
```

_(Ký tự `+` xuất hiện khi gõ lệnh `ls -l /tmp/shared-lab/public.txt`, ký tự này biểu thị file đang được áp dụng ACL)._

---

## Các bước kiểm tra

Để chắc chắn mọi thiết lập hoạt động hoàn hảo, hãy đóng vai trò là `testuser` để thực hiện các thao tác kiểm tra sau:

```bash
# Chuyển sang shell của testuser
sudo -i -u testuser

# 1. Kiểm tra quyền truy cập thư mục
cd /tmp/shared-lab             # Thành công (nhờ ACL rx trên thư mục)

# 2. Kiểm tra đọc file public.txt
cat public.txt                 # Thành công (nhờ ACL r trên file)

# 3. Kiểm tra ghi file public.txt (Phải thất bại)
echo "hacker" >> public.txt    # Kết quả: Permission denied

# 4. Kiểm tra đọc file secret.txt (Phải thất bại)
cat secret.txt                 # Kết quả: Permission denied

# 5. Kiểm tra tạo file mới trong thư mục (Phải thất bại)
touch new_file.txt             # Kết quả: Permission denied

```
