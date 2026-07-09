# Task: Week 4 — Ansible: Role nginx

- **Intern**: Trương Quang Duy
- **Phase/Week/Day**: phase-2/week-4/
- **Branch**: phase-2/week-4/
- **Submitted at**: 2026-07-09
- **Time spent**: 6h

# 1. Mục Tiêu

Demo được 2 container Ubuntu chạy SSH, map port SSH/HTTP/HTTPS và script bootstrap SSH key cho Ansible.

Tạo Ansible project với inventory, ansible.cfg, site.yml và role nginx cài Nginx/OpenSSL, tạo self-signed cert, render config từ template.

Thêm handler reload nginx, template phục vụ HTTP/HTTPS theo inventory_hostname.

# 2. Triển khai

**P1. Chuẩn bị SSH key**

File: [scripts/bootstrap-ssh-key.sh](/home/lozshi/devops-training-duy/phase-2/week-4/ansible/scripts/bootstrap-ssh-key.sh)

Chạy:

```bash
./scripts/bootstrap-ssh-key.sh
```

Script này tạo:

```text
.ssh/lab_key
.ssh/lab_key.pub
```

Private key `.ssh/lab_key` dùng bởi Ansible để SSH vào container. Public key `.ssh/lab_key.pub` sẽ được mount vào container để user `ansible` có thể login. Hai file key đã được ignore trong [.gitignore](/home/lozshi/devops-training-duy/phase-2/week-4/ansible/.gitignore), nên không bị commit nhầm.

**P2. Khởi động 2 container SSH**

File chính:

- [Dockerfile](/home/lozshi/devops-training-duy/phase-2/week-4/ansible/Dockerfile)
- [docker-compose.yml](/home/lozshi/devops-training-duy/phase-2/week-4/ansible/docker-compose.yml)
- [docker-entrypoint.sh](/home/lozshi/devops-training-duy/phase-2/week-4/ansible/docker-entrypoint.sh)

Chạy:

```bash
docker compose up -d --build
```

Docker build image Ubuntu 24.04 có:

```text
openssh-server
python3
sudo
user ansible
```

Compose tạo 2 container:

```text
nginx-host-1
nginx-host-2
```

Port mapping:

```text
nginx-host-1 SSH   -> 127.0.0.1:2222
nginx-host-2 SSH   -> 127.0.0.1:2223

nginx-host-1 HTTP  -> 127.0.0.1:8081
nginx-host-2 HTTP  -> 127.0.0.1:8082

nginx-host-1 HTTPS -> 127.0.0.1:8441
nginx-host-2 HTTPS -> 127.0.0.1:8442
```

Entrypoint lấy `.ssh/lab_key.pub` từ host, copy vào:

```text
/home/ansible/.ssh/authorized_keys
```

Sau đó start SSH daemon. Vì vậy Ansible có thể SSH vào container bằng private key.

**P3. Inventory định nghĩa 2 host**

File: [inventory](/home/lozshi/devops-training-duy/phase-2/week-4/ansible/inventory)

Nội dung chính:

```ini
[web]
nginx-host-1 ansible_host=127.0.0.1 ansible_port=2222
nginx-host-2 ansible_host=127.0.0.1 ansible_port=2223

[web:vars]
ansible_user=ansible
ansible_ssh_private_key_file=.ssh/lab_key
ansible_python_interpreter=/usr/bin/python3
```

Ý nghĩa:

- Group `web` có 2 managed hosts.
- Cả 2 đều thật ra là localhost, nhưng khác SSH port.
- Ansible login bằng user `ansible`.
- Ansible dùng private key `.ssh/lab_key`.
- Python interpreter là `/usr/bin/python3`, cần cho module Ansible chạy trên host.

Kiểm tra kết nối:

```bash
ansible -i inventory web -m ping
```

Nếu OK, cả 2 host trả về `pong`.

**P4. Playbook gọi role nginx**

File: [site.yml](/home/lozshi/devops-training-duy/phase-2/week-4/ansible/site.yml)

```yaml
- name: Configure nginx web servers
  hosts: web
  become: true
  roles:
    - nginx
```

Flow ở đây:

- Target là group `web`, tức 2 container.
- `become: true` để chạy task bằng quyền root qua sudo.
- Gọi role `nginx`.

Chạy:

```bash
ansible-playbook -i inventory site.yml
```

**P5. Role nginx chạy các task**

File task chính: [roles/nginx/tasks/main.yml](/home/lozshi/devops-training-duy/phase-2/week-4/ansible/roles/nginx/tasks/main.yml)

Role chạy theo thứ tự:

1. Cài package:

```yaml
nginx
openssl
```

Dùng `apt`, nên phù hợp Ubuntu/Debian container.

2. Tạo thư mục SSL:

```text
/etc/nginx/ssl
```

3. Kiểm tra cert và key đã tồn tại chưa:

```text
/etc/nginx/ssl/nginx-selfsigned.crt
/etc/nginx/ssl/nginx-selfsigned.key
```

4. Nếu chỉ thiếu một trong hai file cert/key, xóa pair chưa hoàn chỉnh.

Điều này tránh trạng thái lỗi kiểu có cert nhưng mất key, hoặc có key nhưng mất cert.

5. Tạo self-signed certificate bằng `openssl`.

Task có:

```yaml
creates: '{{ nginx_ssl_cert_path }}'
```

Nghĩa là nếu cert đã tồn tại thì Ansible không chạy lại command. Đây là điểm quan trọng cho idempotency.

6. Set permission:

```text
cert: 0644
key:  0600
```

7. Render Nginx config từ template.

Template: [roles/nginx/templates/nginx.conf.j2](/home/lozshi/devops-training-duy/phase-2/week-4/ansible/roles/nginx/templates/nginx.conf.j2)

Destination:

```text
/etc/nginx/nginx.conf
```

Có validate:

```text
nginx -t -c %s
```

Ansible sẽ render ra file tạm, chạy `nginx -t` với file đó trước. Nếu config sai syntax, Ansible không ghi đè config thật.

8. Start và enable service nginx.

**P6. Handler reload nginx**

File: [roles/nginx/handlers/main.yml](/home/lozshi/devops-training-duy/phase-2/week-4/ansible/roles/nginx/handlers/main.yml)

```yaml
- name: reload nginx
  service:
    name: nginx
    state: reloaded
```

Handler chỉ chạy khi có task notify, ví dụ:

- cert mới được tạo
- nginx config thay đổi

Nếu không có thay đổi, handler không chạy. Đây cũng là một phần của idempotency.

**P7. Nginx response**

Template tạo 2 server blocks:

HTTP port 80:

```text
Hello from nginx-host-1
Hello from nginx-host-2
```

HTTPS port 443:

```text
Hello securely from nginx-host-1
Hello securely from nginx-host-2
```

Test:

```bash
curl http://127.0.0.1:8081
curl http://127.0.0.1:8082
curl -k https://127.0.0.1:8441
curl -k https://127.0.0.1:8442
```

Dùng `-k` vì certificate là self-signed.

**P8. Vì sao check mode idempotent**

Flow đúng để test:

```bash
ansible-playbook -i inventory site.yml
ansible-playbook -i inventory site.yml --check
```

Lần đầu chạy thật sẽ:

- cài package
- tạo cert
- ghi config
- start nginx

Sau đó chạy `--check` thì Ansible chỉ kiểm tra xem có gì sẽ thay đổi không. Vì trạng thái đã đúng rồi nên kỳ vọng:

```text
changed=0
```
