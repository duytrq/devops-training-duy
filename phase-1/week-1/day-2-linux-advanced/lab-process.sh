echo "1. Chạy tiến trình 'sleep 300' trong background..."
sleep 300 &
# Lấy PID của tiến trình vừa chạy trong background
PID=$!

# 2. Hiển thị PPID/PID của nó
# PPID của sleep 300 chính là PID của chính script shell đang chạy ($$)
MY_PID=$$
echo "2. Thông tin tiến trình:"
echo "    - PID của 'sleep 300': $PID"
echo "    - PPID của 'sleep 300': $MY_PID"

# Hiển thị trạng thái tiến trình bằng ps để kiểm tra
echo "    - Trạng thái tiến trình từ lệnh ps:"
ps -p $PID -o pid,ppid,stat,cmd

# Chờ 1 giây để tiến trình sleep thực sự khởi chạy ổn định
sleep 1

# 3. Gửi SIGTERM, kiểm tra exit code
echo "3. Đang gửi tín hiệu SIGTERM đến tiến trình $PID..."
kill -15 $PID

# Chờ tiến trình kết thúc và lấy exit code
wait $PID
EXIT_CODE=$?

echo "4.  Kết quả kiểm tra:"
echo "    - Exit code của tiến trình sau khi nhận SIGTERM: $EXIT_CODE"

