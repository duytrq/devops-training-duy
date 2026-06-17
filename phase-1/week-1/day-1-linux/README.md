# Part A

Đã tổng hợp chi tiết mô tả và ví dụ sử dụng cho lệnh Linux cơ bản trong file [notes.md](./notes.md).

# Part B

```shell
echo "1. Top 5 process tốn RAM nhất"
ps -eo pid,comm,%mem --sort=-%mem | head -n 6

echo ""
echo "2. Số file .log trong /var/log"
find /var/log -maxdepth 2 -name "*.log" 2>/dev/null | wc -l

echo ""
echo "3. 10 IP xuất hiện nhiều nhất trong /var/log/auth.log"

if [ -r /var/log/auth.log ]; then
    grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' /var/log/auth.log | sort | uniq -c | sort -nr | head -n 10
else
    echo "File /var/log/auth.log không tồn tại hoặc không có quyền đọc (Cần chạy với quyền sudo)."
fi

echo ""
echo "4. Lấy hostname + kernel version + uptime"

printf "host=%s\nkernel=%s\nuptime=%s\n" "$(hostname)" "$(uname -r)" "$(uptime -p)" | tee system-info.txt
echo "Đã lưu thông tin vào file system-info.txt"
```

### Cách chạy

```bash
chmod +x ./lab.sh
./lab.sh
```

![Lab Execution](./screenshots/lab.png)

---

# Part C

Kịch bản Shell Script tự động sao lưu một thư mục chỉ định dưới định dạng nén `.tar.gz` lưu trữ tại thư mục `~/backups/`.

```shell
#!/usr/bin/env bash
set -euo pipefail

show_help() {
    echo "Usage: $(basename "$0") <directory_to_backup>"
    echo "Backup a directory as a .tar.gz archive stored in ~/backups/"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
}


perform_backup() {
    local target_dir="$1"

    if [ ! -d "$target_dir" ]; then
        echo "Error: Directory '$target_dir' does not exist." >&2
        exit 1
    fi

    local target_abs_path
    target_abs_path=$(realpath "$target_dir")

    local backup_dir="$HOME/backups"
    mkdir -p "$backup_dir"

    local dir_basename
    dir_basename=$(basename "$target_abs_path")
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)

    local backup_file="${dir_basename}-${timestamp}.tar.gz"
    local backup_path="${backup_dir}/${backup_file}"

    echo "Backing up directory '$target_abs_path'..."

    tar -czf "$backup_path" -C "$(dirname "$target_abs_path")" "$dir_basename"

    local file_count
    file_count=$(tar -tzf "$backup_path" | grep -v '/$' | wc -l)

    local backup_size
    backup_size=$(du -sh "$backup_path" | cut -f1)

    echo "----------------------------------------"
    echo "Backup completed successfully!"
    echo "Archive path: $backup_path"
    echo "Files backed up: $file_count"
    echo "Backup size: $backup_size"
    echo "----------------------------------------"
}

if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        input_dir="${1%/}"
        perform_backup "$input_dir"
        ;;
esac

```

### Chạy script

```bash
chmod +x ./backup.sh
./backup.sh <directory_to_backup>
```

![Backup Execution](./screenshots/backup.png)

### Ở folder ~/backups

![Backup Result](./screenshots/result.png)
