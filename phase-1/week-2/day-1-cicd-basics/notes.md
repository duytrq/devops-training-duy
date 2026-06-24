## 1. Phân biệt CI / CD / Continuous Deployment

| Khái niệm | Định nghĩa & Đặc điểm | Mục tiêu chính |
| :--- | :--- | :--- |
| **CI (Continuous Integration)**<br>| Tự động hóa quá trình **xây dựng (build)** và **kiểm thử (test)** mã nguồn mỗi khi lập trình viên commit code mới lên repository. | Phát hiện lỗi sớm, tránh xung đột code ("merge hell"), và đảm bảo chất lượng của nhánh chính luôn ổn định. |
| **CD (Continuous Delivery)**<br> | Tiếp nối sau CI. Tự động đóng gói sản phẩm (artifacts) và triển khai chúng lên môi trường kiểm thử (Staging, UAT) hoặc chuẩn bị sẵn sàng cho môi trường chạy thực tế (Production). Tuy nhiên, bước triển khai lên Production **cần sự phê duyệt thủ công (manual approval)** từ con người. | Đảm bảo phần mềm luôn ở trạng thái sẵn sàng phát hành (release-ready) bất kỳ lúc nào chỉ bằng một nút bấm. |
| **Continuous Deployment**<br> | Là mức độ tự động hóa cao nhất. Mọi thay đổi vượt qua được tất cả các vòng kiểm thử tự động của pipeline sẽ **tự động triển khai trực tiếp lên Production** mà không cần bất kỳ sự can thiệp hay phê duyệt thủ công nào từ con người. | Rút ngắn tối đa thời gian đưa tính năng hoặc bản vá lỗi tới tay người dùng cuối (time-to-market). |

---

## 2. DORA 4 Key Metrics & Ý nghĩa

DORA (DevOps Research and Assessment) đã xác định 4 chỉ số cốt lõi giúp đo lường hiệu suất làm việc của đội ngũ kỹ thuật và mức độ trưởng thành của quy trình DevOps, được chia thành 2 nhóm: **Tốc độ (Speed)** và **Độ tin cậy (Reliability)**.

### Nhóm Tốc độ (Speed)
*   **Deployment Frequency (DF) - Tần suất triển khai:**
    *   *Định nghĩa:* Đo lường mức độ thường xuyên mà đội ngũ triển khai code thành công lên môi trường Production (ví dụ: nhiều lần trong ngày, hàng ngày, hàng tuần, hàng tháng).
    *   *Ý nghĩa:* Thể hiện sự linh hoạt và khả năng phân phối giá trị/tính năng mới một cách nhanh chóng tới người dùng.
*   **Lead Time for Changes (LT) - Thời gian thực hiện thay đổi:**
    *   *Định nghĩa:* Khoảng thời gian từ khi code bắt đầu được commit (hoặc merge) cho tới khi nó được triển khai thành công lên Production.
    *   *Ý nghĩa:* Đo lường tốc độ phản hồi của quy trình phát triển. Lead Time ngắn chứng tỏ quy trình CI/CD hoạt động mượt mà và ít nút thắt cổ chai.

### Nhóm Độ tin cậy (Reliability)
*   **Change Failure Rate (CFR) - Tỷ lệ thay đổi thất bại:**
    *   *Định nghĩa:* Tỷ lệ phần trăm các lần deploy lên Production gặp lỗi dẫn đến việc gián đoạn dịch vụ và yêu cầu xử lý ngay lập tức (phải rollback, hotfix, hoặc patch).
    *   *Ý nghĩa:* Đo lường chất lượng của các bản phát hành. CFR thấp chứng tỏ hệ thống kiểm thử tự động hoạt động tốt và quy trình release có độ an toàn cao.
*   **Failed Deployment Recovery Time / Time to Restore Service (MTTR) - Thời gian khôi phục dịch vụ:**
    *   *Định nghĩa:* Thời gian trung bình cần thiết để khắc phục sự cố và đưa dịch vụ trở lại trạng thái hoạt động bình thường sau khi xảy ra lỗi trên Production.
    *   *Ý nghĩa:* Đo lường khả năng phục hồi và tính ổn định của hệ thống cũng như năng lực xử lý sự cố nhanh chóng của đội ngũ vận hành.

---

## 3. Ưu điểm của Pipeline as Code so với cấu hình UI

Cấu hình quy trình CI/CD bằng mã nguồn (Pipeline as Code - ví dụ: YAML trong GitHub Actions/GitLab CI, Jenkinsfile) mang lại nhiều ưu điểm vượt trội so với việc thiết lập trực tiếp trên giao diện đồ họa (UI):

1.  **Version Control:**
    *   Pipeline được lưu trữ trực tiếp cùng mã nguồn dự án trong Git. Điều này giúp bạn dễ dàng theo dõi lịch sử thay đổi (ai sửa gì, khi nào), thực hiện Code Review/Pull Request trước khi áp dụng cấu hình mới, và rollback nhanh chóng về phiên bản cũ nếu pipeline lỗi.
2.  **Reusability & Scalability:**
    *   Dễ dàng nhân bản pipeline cho nhiều dự án tương tự bằng cách sao chép file cấu hình hoặc sử dụng các template dùng chung. Với UI, bạn phải bấm click thủ công từng bước cho mỗi dự án mới, rất tốn thời gian và dễ sai sót.
3.  **Hạn chế lỗi cấu hình do con người:**
    *   Tránh việc cấu hình sai lệch do bấm nhầm nút trên giao diện. Quá trình kiểm soát thay đổi chặt chẽ hơn giúp đảm bảo tính nhất quán (Consistency) giữa các lần chạy.
4.  **Tự động hóa toàn diện & Khả năng lập trình:**
    *   Cho phép sử dụng các cấu trúc điều kiện (if/else), vòng lặp, biến môi trường linh hoạt tùy thuộc vào sự kiện (trigger) hoặc nhánh (branch) đang thực thi.
5.  **Self-documenting:**
    *   File code mô tả pipeline đóng vai trò như một tài liệu đặc tả quy trình build/deploy trực quan nhất của dự án mà bất kỳ thành viên nào trong nhóm cũng có thể đọc hiểu dễ dàng.

---

## 4. Khi nào dùng runs-on: self-hosted vs ubuntu-latest trong GitHub Actions?

| Tiêu chí | `runs-on: ubuntu-latest` (GitHub-Hosted) | `runs-on: self-hosted` (Self-Hosted Runner) |
| :--- | :--- | :--- |
| **Quản lý & Bảo trì** | Do GitHub quản lý hoàn toàn. Tự động cập nhật OS, công cụ phát triển, và vá lỗi bảo mật. | Tự cài đặt và quản lý trên máy chủ riêng (VM, On-premise, AWS, GCP, v.v.). |
| **Tài nguyên chạy** | Môi trường ảo hóa (VM) sạch sẽ, bị hủy hoàn toàn sau khi pipeline kết thúc. | Máy chủ có tính kế thừa dữ liệu (stateful). Dữ liệu build cũ có thể lưu lại trừ khi được cấu hình dọn dẹp. |

### Khi nào chọn `ubuntu-latest` (GitHub-Hosted)?
*   **Dự án tiêu chuẩn:** Các dự án phổ thông không yêu cầu phần cứng quá mạnh hay truy cập mạng nội bộ.
*   **Tiện lợi và Nhanh chóng:** Bạn muốn pipeline hoạt động ngay lập tức mà không muốn tốn công sức thiết lập, duy trì và bảo mật cho hạ tầng máy chủ runner.
*   **Tiết kiệm ngân sách:** Đối với các dự án mã nguồn mở hoặc các dự án nhỏ nằm trong gói miễn phí của GitHub (Free tier).

### Khi nào chọn `self-hosted`?
*   **Yêu cầu về Bảo mật & Mạng riêng:** Khi pipeline cần triển khai trực tiếp vào các tài nguyên nằm trong mạng nội bộ (VPN, VPC riêng, database nội bộ) mà bạn không muốn mở cổng ra internet công cộng cho GitHub truy cập.
*   **Tối ưu hóa hiệu năng & Phần cứng đặc thù:** Cần cấu hình CPU/RAM cực cao, ổ đĩa SSD dung lượng lớn hoặc GPU chuyên dụng (như để train AI model) mà GitHub-Hosted không hỗ trợ hoặc chi phí quá đắt đỏ.
*   **Tận dụng bộ nhớ đệm (Caching local):** Cho phép lưu Docker images, thư mục `node_modules`, package cache trực tiếp trên đĩa cứng local để tái sử dụng giữa các lần build, giúp rút ngắn thời gian chạy pipeline đáng kể.
*   **Yêu cầu về Hệ điều hành / Môi trường tùy chỉnh:** Cần chạy pipeline trên một phiên bản hệ điều hành cụ thể hoặc kiến trúc CPU đặc thù (như ARM) mà GitHub không cung cấp sẵn.
*   **Tối ưu hóa chi phí dài hạn:** Với các doanh nghiệp lớn chạy pipeline liên tục 24/7, việc thuê/mua máy chủ riêng và tự vận hành runner sẽ rẻ hơn đáng kể so với việc trả phí theo từng phút chạy của GitHub.

---
