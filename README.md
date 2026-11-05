# Hệ thống quản lý sở thú (Oracle)

Bài tập lớn môn Oracle — đề tài **Xây dựng cơ sở dữ liệu hệ thống quản lý sở thú**.

Trọng tâm điểm: **quản trị CSDL (5/10)** và schema/dữ liệu/PL/SQL. Ứng dụng web chỉ cần gọn, chạy ổn.

## Công nghệ

| Lớp | Công nghệ |
|---|---|
| CSDL | Oracle AI Database 26ai Free (Docker), PDB `FREEPDB1` |
| Backend | Python 3.12, FastAPI, python-oracledb (thin), JWT, bcrypt |
| Frontend | Vue 3 + Vite, Pinia, Element Plus, Chart.js |

## Tài khoản demo (ứng dụng web)

| Username | Role | Mật khẩu |
|---|---|---|
| `manager01` | MANAGER | `Zoo@123456` |
| `vet01` | VET | `Zoo@123456` |
| `keeper01` | KEEPER | `Zoo@123456` |
| `cashier01` | CASHIER | `Zoo@123456` |

> Hash bcrypt lưu trong bảng `app_accounts`. Đây là mật khẩu **demo**, khác user Oracle `ZOO`.

## Chạy nhanh

- **macOS:** xem [`docs/RUN_MACOS.md`](docs/RUN_MACOS.md)
- **Windows:** xem [`docs/RUN_WINDOWS.md`](docs/RUN_WINDOWS.md)

Tóm tắt (macOS):

```bash
cp .env.example .env
./scripts/mac/setup.sh
./scripts/mac/db-up.sh
# đợi DATABASE IS READY TO USE
./scripts/mac/db-init.sh   # Giai đoạn 1 trở đi
```

Kết nối: `localhost:1521/FREEPDB1`, user schema `ZOO`, tablespace `ZOO_DATA`.

## Tài liệu

| File | Nội dung |
|---|---|
| [`docs/MO_TA_HE_THONG.md`](docs/MO_TA_HE_THONG.md) | Mô tả hệ thống (13 mục) |
| [`docs/CAU_HOI_VAN_DAP.md`](docs/CAU_HOI_VAN_DAP.md) | ≥60 câu vấn đáp |
| [`docs/ERD.md`](docs/ERD.md) | Sơ đồ quan hệ Mermaid |
| [`docs/ADMIN_RUNBOOK.md`](docs/ADMIN_RUNBOOK.md) | Quản trị 7.1–7.5 + kết quả thật |
| [`docs/PHAN_CONG_2_TUAN.md`](docs/PHAN_CONG_2_TUAN.md) | Phân công 4 người / 2 tuần |
| [`docs/RUN_MACOS.md`](docs/RUN_MACOS.md) / [`RUN_WINDOWS.md`](docs/RUN_WINDOWS.md) | Chạy từ số 0 |

## Cấu trúc

Xem `PROMPT_CURSOR_ZOO.md` và thư mục `docs/`.

## Tiến độ

[`docs/PROGRESS.md`](docs/PROGRESS.md) — Giai đoạn 0–7 xong (nghiệm thu macOS đạt; Windows theo script, chưa chạy máy sạch).
