#!/bin/bash

# Thiết lập tệp tin log
LOG_FILE="$HOME/monitor.log"
high_cpu_count=0

# Hàm dọn dẹp khi nhận tín hiệu SIGINT
cleanup() {
    echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] Nhận tín hiệu dừng (SIGINT). Đang thoát chương trình giám sát..."
    exit 0
}

# Đăng ký trap bắt tín hiệu SIGINT
trap cleanup SIGINT

echo "=== Khởi động script giám sát hệ thống (monitor.sh) ==="
echo "Log file cảnh báo lưu tại: $LOG_FILE"
echo "Nhấn Ctrl+C để thoát."
echo "------------------------------------------------------"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # 1. Tính toán CPU% và MEM%
    # CPU% = 100 - %Idle
    CPU_USAGE=$(top -bn1 | grep "%Cpu(s)" | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - $1}')
    # MEM% = Used / Total * 100
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100}')

    # 2. In thông tin ra màn hình
    echo "[$TIMESTAMP] CPU: ${CPU_USAGE}%, MEM: ${MEM_USAGE}%"
    echo "Top 3 tiến trình tiêu thụ CPU nhiều nhất:"
    ps -eo pid,%cpu,%mem,comm --sort=-%cpu | head -n 4 | sed 's/^/  /'
    echo "------------------------------------------------------"

    # 3. Kiểm tra điều kiện CPU > 80% trong 3 mẫu liên tiếp
    IS_HIGH=$(awk -v cpu="$CPU_USAGE" 'BEGIN {print (cpu > 80.0) ? 1 : 0}')
    if [ "$IS_HIGH" -eq 1 ]; then
        high_cpu_count=$((high_cpu_count + 1))
        # Nếu CPU vượt ngưỡng 3 lần liên tiếp, ghi log cảnh báo
        if [ "$high_cpu_count" -ge 3 ]; then
            echo "[$TIMESTAMP] WARNING: High CPU usage ($CPU_USAGE%) detected for 3 consecutive samples!" >> "$LOG_FILE"
        fi
    else
        # Reset bộ đếm nếu CPU quay về dưới ngưỡng
        high_cpu_count=0
    fi

    # Đợi 10 giây cho lần lấy mẫu tiếp theo
    sleep 10 &
    wait $!
done
