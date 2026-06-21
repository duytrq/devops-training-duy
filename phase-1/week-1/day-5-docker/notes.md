## 1. Image gồm những lớp gì? Vì sao layer được cache?

- **Các layers trong Docker Image**:
  - Docker Image được xây dựng dựa trên kiến trúc **Union File System (UnionFS)** dưới dạng các lớp xếp chồng lên nhau (read-only layers).
  - Khi build một image từ `Dockerfile`, mỗi câu lệnh (như `FROM`, `RUN`, `COPY`, `ADD`) tạo ra một read-only layer mới đại diện cho những thay đổi của file system tại bước đó.
  - Khi chạy một container từ image, Docker sẽ thêm một lớp mỏng có thể ghi được (read-write layer / container layer) lên trên cùng. Mọi thay đổi khi container chạy (ghi file mới, sửa file cũ) đều được thực hiện trên lớp này.
- **Vì sao layer được cache?**:
  - **Tiết kiệm thời gian build**: Nếu các câu lệnh trong `Dockerfile` và các file nguồn không thay đổi, Docker sẽ reuse các layer đã build trước đó thay vì chạy lại câu lệnh, giúp tăng tốc độ build đáng kể.
  - **Tiết kiệm băng thông và tài nguyên**: Khi push/pull image lên/từ Registry (như Docker Hub), Docker chỉ cần truyền tải các layer bị thay đổi hoặc chưa có ở môi trường đích.

## 2. Sự khác nhau giữa COPY và ADD

Cả hai lệnh đều dùng để sao chép file từ máy host vào trong container, nhưng có những khác biệt quan trọng:

- **`COPY`**:
  - Chỉ hỗ trợ sao chép các file/thư mục cục bộ (local) từ máy host vào container.
  - Hoạt động đơn giản, tường minh, an toàn và dễ đoán.
- **`ADD`**:
  - Hỗ trợ thêm 2 tính năng nâng cao:
    1. **Tải file từ URL**: Cho phép tải file trực tiếp từ một đường dẫn internet (tuy nhiên không khuyến khích vì không xóa được file tạm trong cùng một layer, làm tăng dung lượng image; thay vào đó nên dùng `RUN curl` hoặc `RUN wget`).
    2. **Tự động giải nén (Auto-extraction)**: Nếu file nguồn cục bộ là một định dạng nén được hỗ trợ (tar, gzip, bzip2, xz,...), `ADD` sẽ tự động giải nén file đó vào thư mục đích trong container.

## 3. CMD vs ENTRYPOINT — khi nào dùng cái nào?

Cả hai đều định nghĩa lệnh sẽ chạy khi container khởi động, nhưng hoạt động khác nhau khi nhận tham số từ dòng lệnh (command line argument khi chạy `docker run`):

- **`ENTRYPOINT`**:
  - Thiết lập lệnh chạy chính của container. Lệnh này rất khó bị ghi đè (phải dùng tham số `--entrypoint` khi run).
  - Thường dùng khi container được thiết kế giống như một công cụ dòng lệnh (CLI tool) hoặc một dịch vụ cố định (ví dụ: `nginx`, `node`, `python`).
- **`CMD`**:
  - Đóng vai trò là các tham số mặc định (default arguments) cho `ENTRYPOINT`, hoặc lệnh chạy mặc định nếu không khai báo `ENTRYPOINT`.
  - Dễ dàng bị ghi đè hoàn toàn bằng cách truyền lệnh mới ở cuối câu lệnh `docker run`.
- **Best Practice**:
  - Dùng `ENTRYPOINT` để khai báo chương trình chính cần chạy (ví dụ: `ENTRYPOINT ["npm", "start"]` hoặc `ENTRYPOINT ["python", "app.py"]`).
  - Dùng `CMD` để khai báo các tham số mặc định có thể thay đổi (ví dụ: `CMD ["--port", "8080"]`).
- **Dạng khai báo (Exec vs Shell form)**:
  - Nên dùng dạng **Exec form** (ví dụ: `["executable", "param1", "param2"]`) để container có thể nhận tín hiệu hệ thống (như SIGTERM để dừng container một cách graceful). Tránh dùng **Shell form** (ví dụ: `node app.js`) vì nó chạy dưới dạng tiến trình con của `/bin/sh -c`, khiến tín hiệu dừng không truyền được tới ứng dụng.

## 4. Tại sao nên có `.dockerignore`?

File `.dockerignore` hoạt động tương tự `.gitignore`, giúp chỉ định các file và thư mục không được gửi từ máy host lên Docker daemon khi build image (gọi là build context).
Lý do cần có `.dockerignore`:

- **Tăng tốc độ build**: Giảm dung lượng build context truyền tới Docker daemon (đặc biệt là thư mục nặng như `node_modules`, `.git`, v.v.).
- **Giảm dung lượng Image**: Tránh vô tình sao chép các file không cần thiết vào image qua câu lệnh `COPY . .`.
- **Bảo mật**: Ngăn chặn việc lộ các file chứa thông tin nhạy cảm (như `.env`, API keys, private keys, tài liệu nội bộ, build logs) vào trong image công khai.

## 5. EXPOSE thực sự làm gì? Có tự mở port không?

- **EXPOSE thực sự làm gì?**:
  - Lệnh `EXPOSE` chỉ mang tính chất **tài liệu hóa (documentation/metadata)**. Nó khai báo cho người vận hành biết container này lắng nghe ở port nào khi chạy.
  - Nó **KHÔNG** tự động mở port hay mapping port từ container ra ngoài máy host.
- **Có tự mở port không?**:
  - **Không**. Để bên ngoài (hoặc máy host) truy cập được vào port của container, bạn bắt buộc phải map port bằng cờ `-p` hoặc `-P` khi chạy container (ví dụ: `docker run -p 8080:80 my-image`).
  - Điểm đặc biệt: Nếu bạn dùng cờ `-P` (in hoa), Docker sẽ tự động lấy các port được liệt kê trong `EXPOSE` và map chúng với các port ngẫu nhiên trên máy host.

## 6. Tại sao không nên chạy container dưới quyền root?

Mặc định, nếu không chỉ định user, các tiến trình trong container sẽ chạy dưới quyền `root` (UID 0). Điều này tiềm ẩn các nguy cơ bảo mật nghiêm trọng:

- **Container Escape**: Nếu kẻ tấn công khai thác được lỗ hổng bảo mật trong ứng dụng hoặc trong Docker runtime, họ có thể thoát ra khỏi container và chiếm quyền điều khiển toàn bộ máy host dưới quyền root (vì root trong container mặc định ánh xạ với root trên máy host trong nhiều cấu hình).
- **Principle of Least Privilege**: Một ứng dụng web thông thường (như Node.js, Python, Java) không cần quyền quản trị hệ thống để chạy. Việc giới hạn quyền giúp giảm thiểu thiệt hại nếu hệ thống bị xâm nhập.
- **Khắc phục**:
  - Nên tạo một group và user không có quyền admin (non-root user) trong `Dockerfile` và chuyển sang user đó bằng câu lệnh `USER`.
  - Ví dụ:
    ```dockerfile
    RUN groupadd -r myuser && useradd -r -g myuser myuser
    USER myuser
    ```
