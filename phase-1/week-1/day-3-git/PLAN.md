### Part A — Rebase + Cherry-pick + Conflict

#### Bước 1: Tạo branch `feature-a` và commit 3 lần

1. Tạo và di chuyển sang branch `feature-a`.
2. Tạo 3 commit khác nhau trên 3 file khác nhau:

   ```bash
   git checkout -b feature-a

   # Commit 1
   echo "Feature A - Step 1" > file1.txt
   git add file1.txt
   git commit -m "feat(a): add file1.txt"

   # Commit 2
   echo "Feature A - Step 2" > file2.txt
   git add file2.txt
   git commit -m "feat(a): add file2.txt"

   # Commit 3
   echo "Feature A - Step 3" > file3.txt
   git add file3.txt
   git commit -m "feat(a): add file3.txt"
   ```

3. Lưu vết log: `git log --oneline --graph --all` ghi vào `history.md`.

#### Bước 2: Tạo branch `feature-b` từ `main` và commit 2 lần gây xung đột

1. Quay về `main`, tạo và di chuyển sang branch `feature-b`.
2. Tạo 2 commit chỉnh sửa đè lên cùng các file đã tạo ở `feature-a` (`file1.txt`, `file2.txt`):

   ```bash
   git checkout main
   git checkout -b feature-b

   # Commit 1 (gây xung đột với file1.txt)
   echo "Feature B - Step 1 conflicting change" > file1.txt
   git add file1.txt
   git commit -m "feat(b): add file1.txt with conflicting content"

   # Commit 2 (gây xung đột với file2.txt)
   echo "Feature B - Step 2 conflicting change" > file2.txt
   git add file2.txt
   git commit -m "feat(b): add file2.txt with conflicting content"
   ```

3. Lưu vết log ghi vào `history.md`.

#### Bước 3: Rebase `feature-b` lên `feature-a` và giải quyết conflict

1. Thực hiện lệnh rebase:
   ```bash
   git checkout feature-b
   git rebase feature-a
   ```
2. Xử lý xung đột lần lượt:
   - Xung đột đầu tiên xuất hiện ở `file1.txt`. Mở file và giải quyết thủ công (giữ cả nội dung của cả hai hoặc điều chỉnh hợp lý, không lạm dụng `--ours` hay `--theirs`).
   - Đánh dấu đã giải quyết và tiếp tục:
     ```bash
     git add file1.txt
     git rebase --continue
     ```
   - Xung đột tiếp theo xuất hiện ở `file2.txt`. Thực hiện tương tự:
     ```bash
     git add file2.txt
     git rebase --continue
     ```
3. Lưu vết log sau khi rebase hoàn tất thành công vào `history.md`.

#### Bước 4 & 5: Tạo branch `hotfix` và cherry-pick

1. Quay về `main`, tạo branch `hotfix`.
2. Commit 1 lỗi khẩn cấp:
   ```bash
   git checkout main
   git checkout -b hotfix
   echo "Emergency patch" > bugfix.txt
   git add bugfix.txt
   git commit -m "fix(hotfix): critical bugfix applied"
   ```
3. Lấy mã SHA của commit hotfix này (`git log -n 1 --oneline`).
4. Cherry-pick sang `main` và `feature-a`:

   ```bash
   # Cherry-pick sang main
   git checkout main
   git cherry-pick <SHA-commit-hotfix>

   # Cherry-pick sang feature-a
   git checkout feature-a
   git cherry-pick <SHA-commit-hotfix>
   ```

5. Lưu vết log ghi vào `history.md`.

#### Bước 6: Squash 3 commit của `feature-a` thành 1 bằng `rebase -i`

1. Đứng tại branch `feature-a`, hiện tại lịch sử bao gồm:
   - Commit của `main`
   - 3 commit phát triển của `feature-a` (file1, file2, file3)
   - 1 commit cherry-pick hotfix nằm ở trên cùng.
2. Thực hiện lệnh:
   ```bash
   git rebase -i HEAD~4
   ```
3. Trong giao diện trình soạn thảo tương tác:
   - Giữ nguyên `pick` cho commit đầu tiên của `feature-a`.
   - Đổi `pick` thành `squash` (hoặc `s`) cho commit thứ 2 và thứ 3 của `feature-a`.
   - Giữ nguyên `pick` cho commit cherry-pick.
     _Ví dụ cấu hình:_
   ```text
   pick <SHA_1> feat(a): add file1.txt
   squash <SHA_2> feat(a): add file2.txt
   squash <SHA_3> feat(a): add file3.txt
   pick <SHA_4> fix(hotfix): critical bugfix applied
   ```
4. Lưu và đóng trình soạn thảo. Nhập thông điệp commit mới khi được yêu cầu (ví dụ: `feat(a): implement feature-a suite containing files 1, 2, and 3`).
5. Lưu vết log sau cùng vào `history.md`.

---

### Part B — Tìm lại commit bị "mất"

#### Các bước thực hiện:

1. Tạo 1 commit mới chứa file tạm:
   ```bash
   git checkout main
   echo "Secret contents" > lost-file.txt
   git add lost-file.txt
   git commit -m "feat: commit destined to be lost"
   ```
2. Thực hiện reset cứng để xóa bỏ lịch sử commit vừa tạo:
   ```bash
   git reset --hard HEAD~1
   ```
   _(File `lost-file.txt` biến mất khỏi thư mục làm việc và commit không còn xuất hiện trong `git log` thông thường)._
3. Sử dụng `git reflog` để quét lịch sử hành vi của con trỏ HEAD:
   ```bash
   git reflog
   ```
4. Xác định dòng log dạng `HEAD@{0}: commit: feat: commit destined to be lost` và copy mã SHA tương ứng.
5. Khôi phục commit này bằng cách check out ra một nhánh mới từ mã SHA đó:
   ```bash
   git checkout -b recovered <SHA-commit-bi-mat>
   ```
6. Kiểm tra lại sự tồn tại của `lost-file.txt`.
7. Ghi nhận các bước thực hiện chi tiết cùng nhật ký shell trực quan vào file `reflog-lab.md`.

---

### Part C — git bisect

#### Bước 1: Viết script tự động hóa để tạo lịch sử 20 commit

**Nội dung logic của file `app.py`:**

- Trạng thái chuẩn: `print("SYSTEM STATUS: OK")`
- Trạng thái lỗi (bắt đầu từ commit 13): `print("SYSTEM STATUS: ERROR")`

**Script tự động dựng lịch sử (`build_bisect_history.sh`):**

```bash
git checkout main
git checkout -b bug-hunt

for i in {1..20}
do
  if [ $i -eq 13 ]; then
    echo -e "def check():\n    print(\"SYSTEM STATUS: ERROR\")\n\ncheck()" > app.py
  elif [ $i -eq 1 ]; then
    echo -e "def check():\n    print(\"SYSTEM STATUS: OK\")\n\ncheck()" > app.py
  else
    echo "# Commit $i - benign change" >> app.py
  fi
  git add app.py
  git commit -m "feat: commit index $i"
done
```

#### Bước 2: Thực hiện quy trình tìm lỗi `git bisect`

1. Khởi động bisect:
   ```bash
   git bisect start
   ```
2. Đánh dấu trạng thái hiện tại (commit 20) là lỗi:
   ```bash
   git bisect bad
   ```
3. Quay lại commit đầu tiên (commit 1 hoặc `main`) đánh dấu là sạch:
   ```bash
   git bisect good <SHA-commit-index-1>
   ```
4. Git sẽ tự động chuyển đổi sang commit ở giữa (binary search).
5. Thực thi chương trình `python3 app.py` và kiểm tra kết quả:
   - Nếu output in ra `ERROR` -> gõ `git bisect bad`.
   - Nếu output in ra `OK` -> gõ `git bisect good`.
6. Thực hiện lặp lại cho đến khi Git xác định chính xác commit đầu tiên bị lỗi (Commit index 13).
7. Kết thúc quá trình tìm lỗi và phục hồi trạng thái đầu đọc:
   ```bash
   git bisect reset
   ```
8. Chuyển toàn bộ output log của shell trong quá trình bisect vào file `bisect.log`.

---

### Part D — Pre-commit hook

#### Các bước cấu hình:

1. Cài đặt thư viện `pre-commit` (nếu môi trường chưa cài, sử dụng `pip install pre-commit` hoặc qua trình quản lý gói của hệ thống).
2. Tạo file cấu hình cấu hình `.pre-commit-config.yaml` tại thư mục gốc của repo `git-lab` với các hook:
   - `trailing-whitespace`
   - `end-of-file-fixer`
   - `check-yaml`
   - `check-added-large-files`
   - `gitleaks` (Kiểm tra rò rỉ secret)
3. Cài đặt các Git hook script:
   ```bash
   pre-commit install
   ```
4. **Kịch bản kiểm thử (Test case):**
   - Tạo file `test_hook.txt` chứa một số khoảng trắng dư thừa ở cuối dòng:
     ```text
     Hello World
     ```
   - Tiến hành add và commit file này:
     ```bash
     git add test_hook.txt
     git commit -m "test: commit containing trailing whitespaces"
     ```
   - Mong đợi: `pre-commit` hook sẽ chạy, block hành vi commit này và tự động sửa/báo lỗi trên console.
5. Chụp màn hình terminal hiển thị tiến trình block lỗi đó và lưu vào thư mục `screenshots/pre-commit-block.png`.

---

### Part E — So sánh các Git Workflow

Chúng ta sẽ biên soạn một báo cáo chi tiết trong file `workflow-comparison.md` để so sánh 3 mô hình workflow cốt lõi: Trunk-based, GitFlow, và GitHub Flow dựa trên bảng so sánh và các phân tích chuyên sâu.

| Tiêu chí                  | Trunk-based Development                                                                      | GitFlow                                                                                            | GitHub Flow                                                                          |
| :------------------------ | :------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------- |
| **Số nhánh sống dài hạn** | 1 (`main` / `trunk`)                                                                         | Tối thiểu 2 (`main`, `develop`)                                                                    | 1 (`main`)                                                                           |
| **Kịch bản phù hợp**      | Dự án CI/CD tốc độ cao, đội ngũ kinh nghiệm, kiểm thử tự động tốt                            | Dự án release theo phiên bản định kỳ (on-premise, app mobile), quy trình QA nghiêm ngặt            | Dự án web SaaS, deploy liên tục, mô hình đóng góp pull request                       |
| **Tần suất Release**      | Hàng ngày / Hàng giờ (Deploy liên tục)                                                       | Theo chu kỳ tuần/tháng/quý (Scheduled)                                                             | Bất cứ khi nào merge PR (Continuous Delivery)                                        |
| **Khó khăn áp dụng**      | Đòi hỏi kỹ thuật Feature Flag tốt, kỷ luật code cao, test suite phải cực nhanh và đủ tin cậy | Quản lý nhánh phức tạp, dễ gặp "merge hell" khi merge các nhánh dài hạn, tốn nhiều chi phí quản lý | Dễ làm vỡ môi trường production nếu hệ thống kiểm thử tự động của PR không vững chắc |

---
