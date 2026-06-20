# tcpdump Lab

## 1. Thứ tự các packet trong file capture

Quá trình giao tiếp diễn ra giữa Client (`2001:ee0:8205:d5a8:80fa:5feb:4130:b18`) và Server (`2606:4700:10::ac42:93f3.http`):

1. **Packet 1 (22:53:15.954245)**: `Client -> Server` | **SYN**
   - Cờ: `[S]` (SYN). Bắt đầu thiết lập kết nối TCP.
2. **Packet 2 (22:53:16.013018)**: `Server -> Client` | **SYN-ACK**
   - Cờ: `[S.]` (SYN-ACK). Server chấp nhận kết nối và gửi lại yêu cầu đồng bộ.
3. **Packet 3 (22:53:16.013231)**: `Client -> Server` | **ACK**
   - Cờ: `[.]` (ACK). Hoàn tất quá trình bắt tay 3 bước (3-way handshake).
4. **Packet 4 (22:53:16.013708)**: `Client -> Server` | **HTTP GET (Request)**
   - Cờ: `[P.]` (PUSH-ACK), chứa payload HTTP Request: `GET / HTTP/1.1`.
5. **Packet 5 (22:53:16.071767)**: `Server -> Client` | **ACK**
   - Cờ: `[.]` (ACK). Server xác nhận đã nhận yêu cầu HTTP GET từ Client.
6. **Packet 6 (22:53:16.081578)**: `Server -> Client` | **HTTP 200 OK (Response Header + Body Part 1)**
   - Cờ: `[P.]` (PUSH-ACK), chứa payload HTTP Response và phần lớn nội dung HTML của `example.com`.
7. **Packet 7 (22:53:16.081579)**: `Server -> Client` | **HTTP Response (Remaining Chunked Data)**
   - Cờ: `[P.]` (PUSH-ACK), chứa dữ liệu cuối cùng (`0` biểu thị kết thúc chunked response).
8. **Packet 8 (22:53:16.081624)**: `Client -> Server` | **ACK**
   - Cờ: `[.]` (ACK). Client xác nhận đã nhận gói dữ liệu Response đến byte thứ 868.
9. **Packet 9 (22:53:16.081630)**: `Client -> Server` | **ACK**
   - Cờ: `[.]` (ACK). Client xác nhận nhận gói cuối cùng đến byte thứ 873.
10. **Packet 10 (22:53:16.082069)**: `Client -> Server` | **FIN-ACK**
    - Cờ: `[F.]` (FIN-ACK). Client chủ động gửi yêu cầu đóng kết nối TCP.
11. **Packet 11 (22:53:16.144853)**: `Server -> Client` | **FIN-ACK**
    - Cờ: `[F.]` (FIN-ACK). Server chấp nhận đóng kết nối và cũng gửi yêu cầu đóng kết nối của mình.
12. **Packet 12 (22:53:16.144885)**: `Client -> Server` | **ACK**
    - Cờ: `[.]` (ACK). Client gửi gói ACK cuối cùng để hoàn tất việc giải phóng kết nối TCP (TCP Connection Teardown).

### A. Đã bắt được request đầy đủ chưa?
**Đầy đủ.**
Chúng ta đã bắt được toàn bộ vòng đời của một phiên kết nối HTTP qua TCP:
- Quá trình bắt tay thiết lập kết nối (TCP 3-way handshake - Packets 1-3).
- Toàn bộ nội dung yêu cầu HTTP (HTTP Request GET - Packet 4).
- Toàn bộ nội dung phản hồi HTTP bao gồm Header và HTML Body (HTTP Response 200 OK - Packets 6-7).
- Quá trình ngắt kết nối an toàn (TCP Connection Teardown - Packets 10-12).

### B. Vì sao HTTPS không bắt được payload?
Đối với kết nối HTTPS (HTTP over TLS), `tcpdump` chỉ có thể bắt được các gói tin TCP thô chứ **không thể xem được nội dung payload (HTTP Request/Response)** vì các lý do sau:
1. **Quá trình mã hóa TLS**: Ngay sau bước bắt tay TCP 3-way handshake, Client và Server sẽ tiến hành bắt tay TLS (TLS handshake) để thỏa thuận các thuật toán mật mã và sinh ra khóa đối xứng tạm thời (Symmetric Session Keys).
2. **Bảo vệ Payload**: Tất cả dữ liệu ứng dụng (HTTP headers, URL, Method, Request Body, Response Body) sau đó đều được mã hóa bằng khóa đối xứng này trước khi truyền qua mạng.
3. **Môi trường bắt gói (Sniffing)**: Do `tcpdump` là công cụ bắt gói tin ở tầng mạng/liên kết dữ liệu (Network/Data Link layer) và không có khóa giải mã (Session Keys hoặc Private Key của Server), nên payload thu được chỉ là chuỗi byte nhị phân đã mã hóa (Ciphertext), trông giống như các ký tự rác ngẫu nhiên và không thể đọc được dưới dạng Plaintext.
