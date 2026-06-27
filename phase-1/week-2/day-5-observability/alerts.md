## 1. High latency

**Mục đích:** phát hiện người dùng phải chờ quá lâu dù request cuối cùng vẫn có thể thành công.

**Điều kiện đề xuất:** p95 latency lớn hơn 500 ms liên tục trong 10 phút.

```promql
histogram_quantile(
  0.95,
  sum by (le, service) (
    rate(http_request_duration_seconds_bucket{job="web-app"}[5m])
  )
) > 0.5
```

- `severity`: warning; có thể nâng thành critical nếu p95 vượt 1 giây.
- `for`: `10m` để không alert vì một spike ngắn.
- Loại bỏ health check và endpoint nội bộ khỏi phép tính nếu chúng không đại diện cho trải nghiệm người dùng.
- Khi alert xảy ra: kiểm tra trace của request chậm, dependency latency, database query và resource saturation.

## 2. High error rate

**Mục đích:** phát hiện tỷ lệ request lỗi phía server tăng cao.

**Điều kiện đề xuất:** tỷ lệ HTTP 5xx lớn hơn 5% trong 5 phút và lưu lượng lớn hơn 1 request/giây.

```promql
(
  sum by (service) (
    rate(http_requests_total{job="web-app",status=~"5.."}[5m])
  )
  /
  sum by (service) (
    rate(http_requests_total{job="web-app"}[5m])
  )
) > 0.05
and on (service)
sum by (service) (
  rate(http_requests_total{job="web-app"}[5m])
) > 1
```

- `severity`: critical.
- `for`: `5m`.
- Điều kiện lưu lượng tối thiểu tránh trường hợp 1 request lỗi trên tổng số 1 request tạo ra alert 100% nhưng tác động rất nhỏ.
- Khi alert xảy ra: kiểm tra deployment gần nhất, log HTTP 5xx, dependency failure và trace lỗi.

## 3. Host CPU saturation

**Mục đích:** phát hiện host gần hết năng lực CPU, có thể làm tăng latency và timeout của web app.

**Điều kiện đề xuất:** CPU usage trung bình lớn hơn 85% liên tục trong 15 phút.

```promql
100 * (
  1 - avg by (instance) (
    rate(node_cpu_seconds_total{
      job="node-exporter",
      mode="idle"
    }[5m])
  )
) > 85
```

- `severity`: warning; có thể dùng ngưỡng trên 95% trong 5 phút cho critical.
- `for`: `15m` để bỏ qua workload burst ngắn.
- Khi alert xảy ra: kiểm tra process/container dùng CPU, traffic, autoscaling, CPU throttling và deployment gần nhất.
- CPU chỉ là một loại saturation. Tùy bottleneck thực tế, nên bổ sung hoặc thay thế bằng memory pressure, connection-pool usage, request queue, disk I/O hoặc container CPU throttling.

## Alert noise và actionable alert

### Alert noise

Alert là **noise** khi nó tạo thông báo nhưng người trực không cần hoặc không thể thực hiện hành động hữu ích ngay lúc đó.

Ví dụ:

- CPU vượt 85% trong vài giây rồi tự giảm.
- Một request lỗi trong lúc gần như không có traffic làm error rate thành 100%.
- Cùng một sự cố tạo hàng chục alert từ application, pod, node và dependency.
- Alert tự phục hồi trước khi người trực kịp kiểm tra.
- Alert không có owner, dashboard, runbook hoặc thông tin xác định service bị ảnh hưởng.
- Alert dựa trên nguyên nhân kỹ thuật nhưng không ảnh hưởng người dùng hoặc SLO.

Noise kéo dài gây **alert fatigue**: người trực bắt đầu bỏ qua hoặc phản ứng chậm với cả alert nghiêm trọng.

### Actionable alert

Alert là **actionable** khi nó chỉ ra một vấn đề cần phản ứng, được gửi đúng người và cung cấp đủ ngữ cảnh để họ quyết định bước tiếp theo.

Một actionable alert nên có:

- Tác động rõ ràng tới người dùng hoặc nguy cơ vi phạm SLO.
- Ngưỡng và khoảng `for` đủ để loại bỏ biến động tạm thời.
- Owner chịu trách nhiệm và severity phù hợp.
- Tên service, môi trường, instance/region bị ảnh hưởng và giá trị hiện tại.
- Link tới dashboard, log, trace và runbook.
- Hành động cụ thể như rollback deployment, scale service, kiểm tra dependency hoặc chuyển traffic.
- Cơ chế grouping/inhibition để một incident không tạo ra nhiều notification trùng lặp.
