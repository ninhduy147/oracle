# Phân công 2 tuần — Nhóm 4

Mốc cứng: hết ngày 12 hoàn thiện sản phẩm; ngày 13–14 ôn vấn đáp và sửa lỗi. Có bài kiểm tra xen giữa → chừa đệm.

## Phân công theo barem

| Người | Phụ trách chính | Phụ trách phụ |
|---|---|---|
| **A** (macOS, trưởng nhóm) | Hạ tầng Docker + script mac/Windows; **4a** Instance + Tablespace/Datafile + khôi phục datafile | Review PR, tích hợp |
| **B** | **2** Schema, dữ liệu mẫu, PL/SQL; ERD | Đảm bảo ≥5 dòng/bảng |
| **C** | **3** Truy vấn SQL; **4b** user/role/profile + Data Pump | Câu hỏi vấn đáp |
| **D** | **5** Web (API + Vue); **1** mô tả đề tài/thực thể | Demo web |

## Lịch theo ngày

| Ngày | Mục tiêu |
|---|---|
| 1–2 | Họp, chốt phân công; A dựng Docker + script; cả nhóm chạy được DB |
| 3–5 | B xong schema + dữ liệu; D khung API/Vue; C truy vấn nháp; A làm instance |
| 6–8 | B hoàn thiện PL/SQL; C truy vấn + phân quyền; A tablespace/datafile; D CRUD + login |
| 9–10 | A recovery; C Data Pump; D nghiệp vụ (cho ăn, chuyển chuồng, bán vé, báo cáo) |
| 11–12 | Hợp nhất, test chéo, hoàn thiện `MO_TA_HE_THONG.md` + `CAU_HOI_VAN_DAP.md` |
| 13–14 | Tập vấn đáp (mỗi người giải thích được phần người khác), chạy thử từ DB trống |

## Quy tắc Git

- Không push thẳng `main`
- Nhánh `feature/<ten>`, PR vào `develop`, người khác review
- Chỉ sửa file thuộc phần mình; xung đột nhờ trưởng nhóm

## Mapping thư mục ↔ người

| Thư mục / file | Người |
|---|---|
| `docker-compose.yml`, `scripts/`, `admin/01*`, `admin/02*`, `admin/03*` | A |
| `db/*.sql` (trừ queries), `docs/ERD.md` | B |
| `db/queries/`, `admin/04*`, `admin/05*`, phần Q&A CSDL | C |
| `zoo-api/`, `zoo-web/`, phần mô tả ứng dụng trong docs | D |
| `docs/MO_TA_HE_THONG.md`, `docs/ADMIN_RUNBOOK.md` | Cả nhóm (A chủ trì admin, B schema, C SQL, D web) |
