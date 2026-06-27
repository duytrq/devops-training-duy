# Observability: Log, Metric, Trace và các khái niệm liên quan

## 1. Log vs Metric vs Trace

| Loại dữ liệu | Trả lời câu hỏi | Đặc điểm | Ví dụ |
|---|---|---|---|
| **Log** | Chuyện gì đã xảy ra? | Bản ghi sự kiện tại một thời điểm, thường chứa timestamp và thông tin chi tiết | `2026-06-27T10:15:02Z ERROR payment failed order_id=123 reason=timeout` |
| **Metric** | Hệ thống đang hoạt động như thế nào? | Số liệu tổng hợp theo thời gian; phù hợp cho dashboard, alert và phân tích xu hướng | `http_requests_total{service="checkout",status="500"} 42` |
| **Trace** | Một request đã đi qua hệ thống như thế nào? | Theo dõi toàn bộ hành trình của một request qua nhiều service; mỗi công đoạn là một **span** | Request đi qua `API Gateway -> Checkout -> Payment -> Database`, trong đó span Payment mất 2,1 giây |

### Ví dụ cụ thể

Người dùng thanh toán đơn hàng nhưng nhận HTTP 500:

- **Metric** phát hiện tỷ lệ lỗi của `checkout` tăng từ 0,2% lên 8% và kích hoạt alert.
- **Trace** chỉ ra phần lớn thời gian của request nằm ở span gọi `payment-service`.
- **Log** của `payment-service` cho biết request thất bại do timeout khi kết nối ngân hàng.

Ba loại dữ liệu bổ trợ nhau: metric giúp **phát hiện**, trace giúp **khoanh vùng**, log giúp xem **chi tiết nguyên nhân**.

## 2. Pull-based vs Push-based

### Pull-based — ví dụ: Prometheus

Prometheus chủ động gửi HTTP request định kỳ tới endpoint `/metrics` của từng target để lấy dữ liệu:

```text
Prometheus --scrape /metrics--> Application
```

**Ưu điểm:**

- Prometheus kiểm soát tập trung chu kỳ scrape, timeout và danh sách target.
- Dễ kiểm tra target còn sống hay không: scrape thất bại tạo ra metric `up = 0`.
- Application không cần biết địa chỉ của hệ thống giám sát.
- Dễ debug bằng cách mở trực tiếp endpoint `/metrics`.
- Prometheus có thể áp dụng service discovery để tự tìm target.

**Nhược điểm:**

- Prometheus phải kết nối được tới mọi target; khó hơn khi target nằm sau firewall, NAT hoặc ở nhiều network.
- Có thể bỏ lỡ dữ liệu từ job sống rất ngắn nếu job kết thúc trước lần scrape tiếp theo.
- Mỗi target phải cung cấp endpoint mà Prometheus có thể scrape.

> Với batch job ngắn hạn, Prometheus có **Pushgateway**, nhưng đây là giải pháp cho trường hợp đặc biệt, không thay đổi mô hình pull chính của Prometheus.

### Push-based — ví dụ: StatsD và OpenTelemetry Collector

Ứng dụng hoặc agent chủ động gửi dữ liệu tới một điểm thu thập:

```text
Application --push--> StatsD / OpenTelemetry Collector
```

- Với **StatsD**, ứng dụng thường gửi metric qua UDP tới StatsD server.
- Với **OpenTelemetry**, SDK/agent thường xuất telemetry qua OTLP tới Collector; Collector xử lý rồi gửi tiếp tới backend. Collector cũng có thể scrape Prometheus, nên nó không chỉ hỗ trợ push.

**Ưu điểm:**

- Phù hợp với batch job, serverless function và workload sống ngắn.
- Application chỉ cần kết nối ra collector; hữu ích khi không thể mở kết nối từ monitoring system vào application.
- Collector có thể buffer, batch, retry, lọc và chuyển đổi dữ liệu trước khi gửi tới backend.
- Có thể đặt collector gần application để giảm số kết nối trực tiếp tới backend.

**Nhược điểm:**

- Backend/collector dễ bị quá tải nếu nhiều client cùng push hoặc gửi quá nhanh; cần rate limit, queue và backpressure.
- Khó phân biệt “không có dữ liệu vì hệ thống bình thường” với “client đã chết hoặc mất kết nối” nếu không có heartbeat.
- Client cần biết địa chỉ collector hoặc phải có cơ chế discovery/cấu hình.
- UDP của StatsD không bảo đảm giao nhận; packet có thể bị mất mà client không biết.
- Buffer và retry làm hệ thống vận hành phức tạp hơn, đồng thời có nguy cơ mất dữ liệu khi queue đầy.

### So sánh nhanh

| Tiêu chí | Pull | Push |
|---|---|---|
| Bên khởi tạo kết nối | Monitoring system | Application/agent |
| Workload sống ngắn | Dễ bỏ lỡ | Phù hợp hơn |
| Phát hiện target chết | Tự nhiên qua scrape failure | Cần heartbeat hoặc kiểm tra riêng |
| Kiểm soát tần suất thu thập | Tập trung tại server | Phụ thuộc client/collector |
| Rủi ro quá tải receiver | Dễ kiểm soát hơn bằng scrape interval | Có thể xảy ra burst từ nhiều client |

## 3. SLI, SLO và SLA

- **SLI (Service Level Indicator):** chỉ số đo chất lượng thực tế của dịch vụ, ví dụ availability, latency hoặc error rate.
- **SLO (Service Level Objective):** mục tiêu nội bộ đặt cho SLI trong một khoảng thời gian.
- **SLA (Service Level Agreement):** cam kết chính thức với khách hàng, thường nêu hậu quả nếu không đạt, chẳng hạn hoàn tiền hoặc service credit.

### Ví dụ: API thanh toán

- **SLI:** tỷ lệ request thành công trong 30 ngày:

  ```text
  SLI = số request HTTP 2xx / tổng số request hợp lệ × 100%
  ```

- **SLO:** ít nhất **99,95%** request thành công trong mỗi cửa sổ 30 ngày.
- **SLA:** cam kết với khách hàng đạt **99,9%** mỗi tháng; nếu thấp hơn, khách hàng được nhận service credit.

SLO thường nghiêm ngặt hơn SLA để đội vận hành có khoảng an toàn trước khi vi phạm hợp đồng.

## 4. Cardinality explosion

**Cardinality** là số lượng tổ hợp label duy nhất của một metric. Mỗi tổ hợp label tạo thành một time series riêng.

Ví dụ metric:

```text
http_requests_total{
  method="GET",
  status="200",
  user_id="u-123456",
  path="/orders/987654"
}
```

Nếu có:

- 5 giá trị `method`
- 10 giá trị `status`
- 1.000.000 giá trị `user_id`
- 1.000.000 đường dẫn chứa ID khác nhau

thì số tổ hợp tiềm năng có thể cực lớn. Việc thêm label có giá trị gần như không giới hạn như `user_id`, `request_id`, `order_id`, timestamp, UUID hoặc URL chưa chuẩn hóa được gọi là **cardinality explosion**.

### Hậu quả

- Tăng mạnh RAM và dung lượng lưu trữ của hệ thống metrics.
- Query và dashboard chậm, timeout hoặc tiêu tốn nhiều CPU.
- Chi phí monitoring tăng cao.
- Quá trình scrape/ingest có thể bị chậm hoặc từ chối dữ liệu.
- Prometheus có thể bị OOM và restart, dẫn đến mất khả năng quan sát đúng lúc có sự cố.
- Alert chậm hoặc không được đánh giá đúng hạn.

### Cách hạn chế

- Chỉ dùng label có tập giá trị hữu hạn và nhỏ, như `method`, `status_code`, `region`, `service`.
- Không đưa `user_id`, `request_id`, `order_id`, UUID hoặc nội dung lỗi tự do vào label; đặt chúng trong log hoặc trace.
- Chuẩn hóa route: dùng `/orders/:id` thay cho `/orders/987654`.
- Giới hạn/drop label tại application, collector hoặc Prometheus relabeling.
- Theo dõi số lượng active series và đặt cảnh báo cho tốc độ tăng series.
