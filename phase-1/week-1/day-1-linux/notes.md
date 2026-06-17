## ls

- Mô tả: Liệt kê danh sách các file và thư mục trong thư mục hiện tại hoặc một thư mục chỉ định.
- Ví dụ: `ls -la`

## cd

- Mô tả: Thay đổi thư mục làm việc hiện tại sang một thư mục khác.
- Ví dụ: `cd /home/user`

## pwd

- Mô tả: Hiển thị đường dẫn tuyệt đối của thư mục làm việc hiện tại.
- Ví dụ: `pwd`

## mkdir

- Mô tả: Tạo một hoặc nhiều thư mục mới.
- Ví dụ: `mkdir -p project/src`

## rm

- Mô tả: Xóa file hoặc thư mục khỏi hệ thống.
- Ví dụ: `rm -rf temp_dir`

## cp

- Mô tả: Sao chép file hoặc thư mục từ nguồn đến đích.
- Ví dụ: `cp -r folder1 folder2`

## mv

- Mô tả: Di chuyển hoặc đổi tên file, thư mục.
- Ví dụ: `mv old_name.txt new_name.txt`

## touch

- Mô tả: Tạo một file trống mới hoặc cập nhật mốc thời gian truy cập/chỉnh sửa của file sẵn có.
- Ví dụ: `touch newfile.txt`

## cat

- Mô tả: Đọc và hiển thị nội dung của file ra màn hình hoặc gộp nội dung các file.
- Ví dụ: `cat file.txt`

## less

- Mô tả: Đọc nội dung file theo từng trang màn hình và hỗ trợ cuộn lên xuống.
- Ví dụ: `less large_logfile.log`

## head

- Mô tả: Hiển thị các dòng đầu tiên (mặc định là 10 dòng) của một file.
- Ví dụ: `head -n 20 file.txt`

## tail

- Mô tả: Hiển thị các dòng cuối cùng của một file và hỗ trợ theo dõi thời gian thực.
- Ví dụ: `tail -f error.log`

## grep

- Mô tả: Tìm kiếm các dòng văn bản khớp với chuỗi ký tự hoặc mẫu (pattern) trong file.
- Ví dụ: `grep -i "error" app.log`

## find

- Mô tả: Tìm kiếm file hoặc thư mục trên hệ thống dựa theo tên, kích thước, thời gian hoặc quyền truy cập.
- Ví dụ: `find /var/log -name "*.log"`

## xargs

- Mô tả: Xây dựng và thực thi các lệnh từ luồng dữ liệu đầu vào tiêu chuẩn (stdin).
- Ví dụ: `find . -name "*.tmp" | xargs rm`

## awk

- Mô tả: Ngôn ngữ xử lý văn bản, trích xuất dữ liệu và báo cáo dựa trên các cột/trường.
- Ví dụ: `awk '{print $1, $3}' data.txt`

## sed

- Mô tả: Trình chỉnh sửa luồng văn bản (Stream Editor) dùng để tìm kiếm, thay thế, xóa hoặc chèn chuỗi.
- Ví dụ: `sed -i 's/localhost/127.0.0.1/g' config.conf`

## sort

- Mô tả: Sắp xếp các dòng văn bản theo thứ tự chữ cái hoặc chữ số.
- Ví dụ: `sort -n numbers.txt`

## uniq

- Mô tả: Lọc bỏ hoặc đếm các dòng trùng lặp liên tiếp trong dữ liệu đã được sắp xếp.
- Ví dụ: `sort names.txt | uniq -c`

## wc

- Mô tả: Đếm số dòng, số từ, số ký tự hoặc dung lượng byte của một file.
- Ví dụ: `wc -l access.log`

## tee

- Mô tả: Đọc từ stdin rồi ghi đồng thời ra màn hình và ra một hoặc nhiều file.
- Ví dụ: `command | tee output.txt`

## ps

- Mô tả: Xem thông tin và trạng thái các tiến trình (process) đang chạy trên hệ thống.
- Ví dụ: `ps aux | grep nginx`

## top

- Mô tả: Hiển thị và cập nhật liên tục thông tin sử dụng CPU, RAM và danh sách tiến trình thời gian thực.
- Ví dụ: `top`

## htop

- Mô tả: Giao diện trực quan tương tác dòng lệnh để giám sát tài nguyên hệ thống và quản lý tiến trình.
- Ví dụ: `htop`

## kill

- Mô tả: Gửi tín hiệu (signal) để dừng hoặc thay đổi hành vi của một tiến trình dựa trên PID.
- Ví dụ: `kill -9 1234`

## nice

- Mô tả: Thiết lập độ ưu tiên điều phối CPU (nice value) cho một tiến trình khi khởi chạy.
- Ví dụ: `nice -n 10 backup.sh`

## df

- Mô tả: Hiển thị thông tin dung lượng đĩa cứng trống và đã sử dụng của các phân vùng hệ thống.
- Ví dụ: `df -h`

## du

- Mô tả: Ước tính dung lượng đĩa cứng đã sử dụng của các file và thư mục cụ thể.
- Ví dụ: `du -sh /var/www`

## free

- Mô tả: Xem dung lượng bộ nhớ vật lý (RAM) và bộ nhớ ảo (Swap) còn trống và đã dùng.
- Ví dụ: `free -m`

## uptime

- Mô tả: Xem thời gian hệ thống hoạt động liên tục, số lượng người dùng kết nối và chỉ số tải (load average).
- Ví dụ: `uptime`

## uname

- Mô tả: Hiển thị thông tin chi tiết về hệ điều hành, cấu trúc phần cứng và phiên bản nhân Linux (kernel).
- Ví dụ: `uname -a`

## who

- Mô tả: Hiển thị thông tin những người dùng hiện đang đăng nhập vào hệ thống.
- Ví dụ: `who`

## chmod

- Mô tả: Thay đổi quyền truy cập đọc, ghi, thực thi (read, write, execute) của file hoặc thư mục.
- Ví dụ: `chmod 755 script.sh`

## chown

- Mô tả: Thay đổi quyền chủ sở hữu (owner) và nhóm sở hữu (group) của file hoặc thư mục.
- Ví dụ: `chown -R user:group /var/www`

## umask

- Mô tả: Thiết lập hoặc hiển thị mặt nạ quyền mặc định áp dụng khi tạo mới file và thư mục.
- Ví dụ: `umask 022`

## tar

- Mô tả: Đóng gói nhiều file/thư mục thành 1 file duy nhất (tarball) hoặc giải nén file đóng gói.
- Ví dụ: `tar -czvf archive.tar.gz folder`

## gzip

- Mô tả: Nén hoặc giải nén file bằng thuật toán Lempel-Ziv (.gz).
- Ví dụ: `gzip largefile.txt`

## zip

- Mô tả: Đóng gói và nén các file hoặc thư mục thành định dạng .zip.
- Ví dụ: `zip -r project.zip project_dir`

## unzip

- Mô tả: Giải nén các file lưu trữ định dạng .zip.
- Ví dụ: `unzip archive.zip -d /target/dir`

## ssh

- Mô tả: Kết nối và điều khiển một máy chủ từ xa an toàn qua giao thức SSH.
- Ví dụ: `ssh user@192.168.1.10 -p 22`

## scp

- Mô tả: Sao chép dữ liệu bảo mật giữa các máy tính trong mạng qua giao thức SSH.
- Ví dụ: `scp localfile.txt user@192.168.1.10:/remote/path/`

## rsync

- Mô tả: Đồng bộ hóa file và thư mục giữa các thư mục cục bộ hoặc qua mạng (chỉ truyền phần thay đổi).
- Ví dụ: `rsync -avz /local/dir/ user@192.168.1.10:/remote/dir/`

## ln

- Mô tả: Tạo liên kết cứng (hard link) trỏ đến cùng vùng dữ liệu (inode) của file gốc.
- Ví dụ: `ln target.txt hardlink.txt`

## ln -s

- Mô tả: Tạo liên kết mềm/biểu tượng (symbolic link) trỏ đến đường dẫn của file hoặc thư mục gốc.
- Ví dụ: `ln -s /var/log/nginx/access.log nginx_log`

## env

- Mô tả: Liệt kê các biến môi trường hiện tại hoặc chạy một lệnh với môi trường được tùy biến.
- Ví dụ: `env`

## export

- Mô tả: Khởi tạo hoặc chuyển biến shell thành biến môi trường có hiệu lực cho toàn hệ thống.
- Ví dụ: `export DB_PORT=27017`

## source

- Mô tả: Đọc và thực thi nội dung của một file cấu hình trực tiếp trên phiên shell hiện tại.
- Ví dụ: `source ~/.bashrc`

## curl

- Mô tả: Truyền tải dữ liệu đi hoặc đến máy chủ thông qua các giao thức mạng (HTTP, HTTPS, FTP, v.v.).
- Ví dụ: `curl -I https://google.com`

## wget

- Mô tả: Tải xuống các tệp tin từ Internet bằng giao thức HTTP, HTTPS hoặc FTP.
- Ví dụ: `wget https://example.com/file.tar.gz`

## which

- Mô tả: Tìm đường dẫn đầy đủ của file thực thi tương ứng với một lệnh nằm trong biến môi trường PATH.
- Ví dụ: `which python3`

## whereis

- Mô tả: Tìm kiếm vị trí các file nhị phân, file mã nguồn và tài liệu hướng dẫn (man page) của lệnh.
- Ví dụ: `whereis ls`

## type

- Mô tả: Cho biết cách shell diễn dịch một lệnh cụ thể (builtin, alias, file nhị phân ngoài, v.v.).
- Ví dụ: `type cd`

## history

- Mô tả: Hiển thị danh sách các lệnh đã được thực thi trước đó trong phiên làm việc của terminal.
- Ví dụ: `history 10`

## alias

- Mô tả: Tạo bí danh (tên viết tắt) thay thế cho một hoặc một nhóm lệnh dài phức tạp.
- Ví dụ: `alias ll="ls -la"`

## echo

- Mô tả: In văn bản hoặc giá trị của biến ra màn hình terminal (tự động xuống dòng).
- Ví dụ: `echo "Hello World"`

## printf

- Mô tả: Định dạng và hiển thị văn bản ra màn hình (không tự động xuống dòng).
- Ví dụ: `printf "Name: %s\n" "Duy"`
