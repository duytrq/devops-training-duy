| Tiêu chí | Trunk-based Development | GitFlow | GitHub Flow |
| :--- | :--- | :--- | :--- |
| **Số nhánh sống dài hạn** | 1 (`main` / `trunk`) | Tối thiểu 2 (`main`, `develop`) | 1 (`main`) |
| **Thời gian sống của nhánh feature** | Cực ngắn (vài giờ đến tối đa 1-2 ngày) | Dài (vài tuần hoặc cả sprint phát triển) | Ngắn (vài ngày, cho đến khi hoàn thành task) |
| **Mức độ tự động hóa (CI/CD)** | Rất cao (Bắt buộc phải có test suite và deploy tự động) | Thấp đến trung bình (Thường có bước QA thủ công trước release) | Trung bình (Yêu cầu test tự động tốt trên các PR) |
| **Sử dụng Feature Flags** | Bắt buộc (Để ẩn tính năng chưa hoàn thiện khi đẩy trực tiếp lên `main`) | Không bắt buộc (Tính năng được giữ riêng trên nhánh feature) | Khuyến khích (Giúp gộp PR nhanh hơn mà không lo hỏng production) |
| **Cách xử lý Hotfix** | Fix trực tiếp trên `trunk` rồi roll forward (hoặc cherry-pick sang nhánh release nếu có) | Tạo nhánh `hotfix/` từ `main`, sau đó merge vào cả `main` và `develop` | Tạo nhánh fix từ `main`, mở PR review rồi merge trực tiếp lại vào `main` |
| **Tần suất Release** | Hàng ngày / Hàng giờ (Deploy liên tục) | Theo chu kỳ tuần/tháng/quý (Scheduled) | Bất cứ khi nào merge PR (Continuous Delivery) |
| **Kịch bản phù hợp** | Dự án SaaS tốc độ cao, đội ngũ giàu kinh nghiệm, DevOps mạnh | Sản phẩm đóng gói phiên bản, hệ thống nhúng, mobile app có chu kỳ kiểm thử dài | Dự án web vừa và nhỏ, microservices, chu kỳ release linh hoạt |
| **Khó khăn áp dụng** | Kỷ luật viết code cao, quản lý feature flags phức tạp, test suite phải nhanh | Quản lý nhánh phức tạp, dễ gặp xung đột lớn khi merge (Merge Hell) | Nhánh `main` dễ bị mất ổn định nếu thiếu kiểm thử tự động vững chắc |

---
