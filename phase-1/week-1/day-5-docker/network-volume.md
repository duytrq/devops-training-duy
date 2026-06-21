## 1. Docker Bridge Network (demo-net) & Container Communication

### Bước 1: Tạo một bridge network riêng có tên là `demo-net`

**Command:**

```bash
docker network create demo-net
```

**Output:**

```
59192e08ed9cd7343a72e331cd7bf0c0ed2e5b16e601d4accc4a7ce50bd0728c
```

---

### Bước 2: Chạy 2 container `app1` và `app2` từ image `demo-app` cùng tham gia vào `demo-net`

**Command chạy `app2`:**

```bash
docker run -d --name app2 --network demo-net -e NAME=app2 demo-app
```

**Output:**

```
af0841faa39a5402bbdb2921f5f9f76375222ef3bd353f3bc58ef28a914cd4ad
```

**Command chạy `app1`:**

```bash
docker run -d --name app1 --network demo-net -e NAME=app1 demo-app
```

**Output:**

```
376a8e38dc9cf393c2a851296da77421f5f574619ab908fa90bedf68ce384457
```

---

### Bước 3: Kiểm tra giao tiếp giữa các container qua DNS (từ `app1` gọi tới `app2`)

Cài đặt `curl` vào container `app1` (do base image alpine không có sẵn `curl` và ứng dụng đang chạy dưới user non-root `node`, ta thực thi dưới quyền `root` để cài đặt):
**Command:**

```bash
docker exec -u root app1 apk add --no-cache curl
```

**Output:**

```
(1/9) Installing brotli-libs (1.2.0-r0)
(2/9) Installing c-ares (1.34.6-r0)
(3/9) Installing libunistring (1.4.1-r0)
(4/9) Installing libidn2 (2.3.8-r0)
(5/9) Installing nghttp2-libs (1.69.0-r0)
(6/9) Installing libpsl (0.21.5-r3)
(7/9) Installing zstd-libs (1.5.7-r2)
(8/9) Installing libcurl (8.19.0-r0)
(9/9) Installing curl (8.19.0-r0)
Executing busybox-1.37.0-r30.trigger
OK: 15.9 MiB in 27 packages
```

Thực hiện lệnh `curl` từ container `app1` đến `http://app2:3000`:
**Command:**

```bash
docker exec app1 curl -s http://app2:3000
```

**Output:**

```json
{ "msg": "hello from app2", "ts": 1781991213431 }
```

---

## 2. Docker Volume Persistence (PostgreSQL)

### Bước 1: Khởi chạy container PostgreSQL 16 với volume `pgdata`

Khởi tạo volume có tên là `pgdata` và mount vào thư mục lưu trữ dữ liệu của Postgres `/var/lib/postgresql/data`.
**Command:**

```bash
docker run -d --name pg-db -e POSTGRES_PASSWORD=mysecretpassword -v pgdata:/var/lib/postgresql/data postgres:16-alpine
```

**Output:**

```
d80d24f769a918ec6e2fda9859db1cb8cd1bf622f18576326345313a9e3c07a0
```

---

### Bước 2: Tạo dữ liệu thử nghiệm trong database

Kết nối vào cơ sở dữ liệu để tạo một bảng `test` và insert 1 dòng dữ liệu.
**Command:**

```bash
docker exec -i pg-db psql -U postgres -c "CREATE TABLE test (id SERIAL PRIMARY KEY, name VARCHAR(50)); INSERT INTO test (name) VALUES ('docker demo'); SELECT * FROM test;"
```

**Output:**

```
CREATE TABLE
INSERT 0 1
 id |    name
----+-------------
  1 | docker demo
(1 row)
```

---

### Bước 3: Khởi động lại container PostgreSQL và xác thực dữ liệu

Chúng ta tiến hành khởi động lại container `pg-db`.
**Command:**

```bash
docker restart pg-db
```

**Output:**

```
pg-db
```

Kiểm tra lại xem dữ liệu đã ghi có còn tồn tại hay không.
**Command:**

```bash
docker exec -i pg-db psql -U postgres -c "SELECT * FROM test;"
```

**Output:**

```
 id |    name
----+-------------
  1 | docker demo
(1 row)
```

---

## 3. Bind Mount

### Bước 1: Tạo thư mục chứa mã nguồn tĩnh trên host và file `index.html` ban đầu

**Command:**

```bash
mkdir -p site && echo "<h1>Hello from Nginx Bind Mount</h1>" > site/index.html
```

---

### Bước 2: Chạy container Nginx sử dụng Bind Mount tới thư mục vừa tạo

Mount thư mục cục bộ `site` trên host vào `/usr/share/nginx/html` của Nginx container.
**Command:**

```bash
docker run -d --name web-nginx -p 8080:80 -v /home/lozshi/devops-training-duy/phase-1/week-1/day-5-docker/site:/usr/share/nginx/html nginx:alpine
```

**Output:**

```
2a556466e143820adc51b4e6495663e2817176e83e36bf9ddb0ca07d41fe94c8
```

---

### Bước 3: Kiểm tra nội dung ban đầu từ bên ngoài host

**Command:**

```bash
curl http://localhost:8080
```

**Output:**

```html
<h1>Hello from Nginx Bind Mount</h1>
```

---

### Bước 4: Sửa đổi file tĩnh trên máy host, reload Nginx và kiểm tra thay đổi

Tiến hành cập nhật nội dung file `site/index.html` (vì là file tĩnh nên không cần reload nginx)
**Command:**

```bash
echo "<h1>Hello updated</h1>" > site/index.html && curl http://localhost:8080
```

**Output:**

```
<h1>Hello updated</h1>
```
