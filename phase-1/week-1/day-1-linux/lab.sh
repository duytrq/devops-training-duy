#!/usr/bin/env bash

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
