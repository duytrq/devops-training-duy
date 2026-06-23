## 1. Retry nhanh khi Fail ở step `push` (Không Build lại)
*   **Cách 1: Tận dụng Docker Layer Cache (`gha` hoặc `inline`)**
    Dùng bộ nhớ cache để Docker bỏ qua các bước build cũ khi rerun job.

*   **Cách 2: Tách biệt Job Build và Job Push**
    *   **Job 1:** `docker build` -> `docker save -o image.tar` -> Upload Artifact.
    *   **Job 2:** Download Artifact -> `docker load` -> `docker push`. (Nếu lỗi mạng, chỉ cần rerun Job 2).

---

## 2. Debug Job chỉ bị Fail trên Runner
*   **SSH trực tiếp vào Runner:** tìm cách truy cập thẳng vào môi trường của runner rồi thực hiện debug
*   **Dump thông tin:** Chèn lệnh `env`, `df -h` (kiểm tra ổ đĩa), `whoami` (kiểm tra quyền) để soát sự khác biệt môi trường.
*   **Giả lập tại Local:** Dùng công cụ **`act`** để chạy thử pipeline trong container local mô phỏng cấu hình của GitHub Runner.

---

## 3. Phân biệt: `needs` vs `if` vs `concurrency`

| Từ khóa | Mục đích | Phạm vi | Ví dụ |
| :--- | :--- | :--- | :--- |
| **`needs`** | **Thứ tự chạy** (Phụ thuộc) | Giữa các Job | Job `deploy` chỉ chạy khi job `test` đã SUCCESS. |
| **`if`** | **Điều kiện chạy** (Bộ lọc) | Job hoặc Step | Chỉ chạy job deploy nếu là branch `main`. |
| **`concurrency`** | **Giới hạn đồng thời** (Xung đột) | Job hoặc Workflow | Có commit mới -> Hủy deploy của commit cũ (`cancel-in-progress`). |

---

## 4. Tại sao nên chọn OIDC thay vì Static Access Key (AWS)?
*   **An toàn tuyệt đối (No Long-lived Secrets):** Không lưu key cố định trên CI. Hệ thống dùng cơ chế bắt tay sinh Token tạm thời (Short-lived, hết hạn sau ~1h). Lỡ lộ tài khoản CI cũng không mất quyền AWS vĩnh viễn.
*   **Không tốn công bảo trì:** Không cần setup cơ chế đổi key định kỳ (Key Rotation).
*   **Phân quyền mạnh:** Cấu hình AWS IAM giới hạn chính xác: *Chỉ Repo X, đúng Branch Y mới có quyền tác động vào Resource Z*.

---