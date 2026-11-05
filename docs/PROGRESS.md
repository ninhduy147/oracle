# Nhật ký tiến độ — Zoo Oracle

## Giai đoạn 1 — CSDL / barem 2 (2026-11-02)

### Đã làm
- `db/00_create_tablespace_user.sql` — ZOO_DATA, ZOO_TEMP, user ZOO (chạy SYS@FREEPDB1)
- `db/01_reset.sql` + modules `05_common`, `10_animals`, `20_staff`, `30_food_health`, `40_tickets`
- `db/run_all.sql` (SET DEFINE OFF; không comment sau `;`)
- `db/queries/q00_show_schema.sql` — lược đồ PK/FK/CHECK, tablespace, đếm dòng

### Đã chạy / kiểm chứng
| Kiểm tra | Kết quả |
|---|---|
| Tạo TS/user | ZOO_DATA + zoo_data01.dbf; ZOO_TEMP; user ZOO default ZOO_DATA |
| `user_errors` | **0** |
| Đối tượng INVALID | **0** |
| Số bảng | **19**; mỗi bảng **≥ 5** dòng |
| Tablespace bảng/index | **toàn bộ ZOO_DATA** (bad_ts = 0) |
| `run_all` lần 2 (reset+nạp) | **OK**, không lỗi |
| `q00_show_schema.sql` | OK |
| Low stock demo | `Tôm khô` stock=10 < min=15 |
| `v_upcoming_followups` | 3 dòng |

### Procedure / trigger đã thử (đúng + sai)
| Đối tượng | OK | Lỗi mong đợi |
|---|---|---|
| `sp_move_animal` | chuyển chuồng | ORA-20001 bảo trì; ORA-20002 đầy; ORA-20004 DECEASED |
| `sp_feed_animal` | cho ăn | ORA-20033 sai chế độ ăn; ORA-20032 thiếu kho |
| `sp_create_invoice` / `sp_add_invoice_item` | lập HĐ + dòng vé | ORA-20040 không phải Cashier/Manager |
| `sp_assign_employee` | phân công | ORA-20024 trùng ca |
| `trg_assignments_keeper` | — | ORA-20020 không phải Zookeeper |
| `trg_medical_vet` | — | ORA-20030 không phải Veterinarian |
| `trg_animals_audit` | audit_logs = 6 sau seed | — |

### Lưu ý kỹ thuật (Oracle 26ai)
1. **ORA-03405**: không được viết comment `-- ...` **sau dấu `;` trên cùng dòng** trong SQL*Plus 26ai. Đã strip toàn bộ trailing comment kiểu đó.
2. **SET DEFINE OFF** bắt buộc vì email/`@` và chuỗi có ký tự đặc biệt.
3. Mật khẩu demo web: `Zoo@123456` (bcrypt trong `app_accounts`). User Oracle schema: `ZOO` / `ZooApp_Demo1`.

### Việc còn tồn
- Package báo cáo / DBMS_SCHEDULER (gợi ý thêm điểm) — chưa làm.
- Truy vấn `queries.sql` → Giai đoạn 2.

### Chờ xác nhận để sang Giai đoạn 2
---

## Giai đoạn 2 — Truy vấn SQL / barem 3 (2026-11-02)

### Đã làm
- `db/queries/queries.sql` — **18 truy vấn** (Q01–Q18) đủ nhóm:
  - Cơ bản 3 · Nối bảng 3 · Nhóm 3 · Lồng nhau 4 · Thống kê/window 4 · Tập hợp 1 (UNION/INTERSECT/MINUS)
- Mỗi query có PROMPT: mục đích, loại, kết quả mong đợi, gợi ý vấn đáp

### Đã chạy / kiểm chứng
| Kiểm tra | Kết quả |
|---|---|
| Chạy cả file trên FREEPDB1 | **OK — không ORA-/SP2-** |
| Q01 SICK | Mei Mei |
| Q05 LEFT JOIN chuồng trống | Chuồng bảo trì A |
| Q10 EN/CR | hổ + voi (4 dòng) |
| Q15 RANK thức ăn | Cỏ voi #1 |
| Q17 ROLLUP | CASH/CARD/TRANSFER + tổng 10.840.000 |
| Q18 INTERSECT | rỗng (đúng: keeper ≠ cashier) |
| Q18 MINUS | employee 4,5,6,7 |

### Chờ xác nhận để sang Giai đoạn 3 (Quản trị)
---

## Giai đoạn 3 — Quản trị CSDL / barem 4 (2026-11-02)

### Đã làm (thứ tự 7.2 → 7.4 → 7.5 → backup → 7.1 → 7.3)
- `admin/02_tablespace_datafile.sql`
- `admin/04_users_privileges.sql`
- `admin/05_datapump_*` + md
- `admin/01_instance.sql` + `01_instance_lifecycle.sh`
- `admin/03_recovery_datafile.sh` + md
- `docs/ADMIN_RUNBOOK.md` (kết quả thực tế)

### Kiểm chứng nổi bật
| Mục | Kết quả |
|---|---|
| 7.2 BIGFILE ZOO_DATA | ORA-32771 khi ADD; demo ADD trên ZOO_TEST SMALLFILE |
| 7.2 online MOVE | ORA-00439 Free; offline MOVE OK |
| 7.4 cashier đọc medical | ORA-00942 |
| 7.5 exp/imp | 19/19 bảng khớp dòng |
| Backup volume | `backup/zoo_oradata_pre_71_73.tgz` ~488MB |
| 7.1 restricted | ZOO → ORA-01035; sau SHUTDOWN dùng bequeath |
| 7.3 recover | RESTORE+RECOVER file#20; còn đủ 3 dòng (kể cả sau backup) |

### Chờ xác nhận để sang Giai đoạn 4 (API)
---

## Giai đoạn 4 — FastAPI / barem 5 (phần API) (2026-11-02)

### Đã làm
- `zoo-api/` FastAPI + `oracledb` thin pool, JWT/bcrypt, CORS từ `.env`
- Map lỗi ORA-20xxx / ORA-00001 / FK / CHECK → HTTP 400 tiếng Việt
- CRUD whitelist `/api/crud/{table}`
- Nghiệp vụ gọi procedure: move, assign, resign, feed, sale (invoice)
- Reports overview/revenue, audit logs (Manager)

### Kiểm chứng (uvicorn :8000)
| API | Kết quả |
|---|---|
| `GET /api/health` | ok, ZOO, 22 animals |
| `POST /api/auth/login` manager01 | JWT OK |
| `POST /api/animals/14/move` → enc 5 | ok |
| move → enc 11 (MAINTENANCE) | **400** "Chuồng đang bảo trì..." |
| feed hổ + PLANT | **400** sai chế độ ăn |
| `POST /api/tickets/sale` cashier | invoice 221, 380000 |
| Swagger | `/docs` |

### Lưu ý
- PyPI: dùng package **`oracledb`** (không còn `python-oracledb` trên index hiện tại).
- Python **3.12** (brew); chạy `./scripts/mac/api-dev.sh`

### Chờ xác nhận để sang Giai đoạn 5 (Vue)
---

## Giai đoạn 5 — Vue 3 / barem 5 (2026-11-02)

### Đã làm
- `zoo-web/` Vue 3 + Vite + Pinia + Router + Element Plus (vi) + Chart.js
- `labels.js`, format ngày/tiền VN, menu theo role
- `CrudPage` dùng chung + màn: Login, Tổng quan, Động vật (chuyển chuồng), Chuồng/Loài/Khu, Nhân viên (phân công/nghỉ), Thức ăn (cho ăn + phiếu nhập), Khám bệnh, Bán vé (in), Doanh thu, Nhật ký
- Giao diện xanh lá / kem, font Fraunces + Be Vietnam Pro

### Kiểm chứng
| Kiểm tra | Kết quả |
|---|---|
| `npm run dev` :5173 | OK |
| Login page | Brand **Sở thú** hero |
| Dashboard (manager) | Sidebar đủ mục, overview API 200 |
| `/animals` | Bảng Raja/Sita/Bông… + nút Chuyển chuồng |
| API CORS | `127.0.0.1:5173` OK |

### Chạy
- API: `./scripts/mac/api-dev.sh` → http://127.0.0.1:8000/docs
- Web: `./scripts/mac/web-dev.sh` → http://127.0.0.1:5173

### Chờ xác nhận để sang Giai đoạn 6 (Tài liệu)
---

## Giai đoạn 6 — Tài liệu (2026-11-02)

### Đã làm
| File | Nội dung |
|---|---|
| `docs/ERD.md` | Mermaid erDiagram + lược đồ text 19 bảng |
| `docs/PHAN_CONG_2_TUAN.md` | 4 người A–D + lịch ngày 1–14 + Git |
| `docs/RUN_MACOS.md` | Cài đặt → db → schema → API/web → admin → lỗi thường gặp |
| `docs/RUN_WINDOWS.md` | WSL2 + Docker + `.ps1` bọc; lỗi Windows |
| `docs/MO_TA_HE_THONG.md` | Đủ **13 mục** (từ điển/constraints lấy từ ZOO live) |
| `docs/CAU_HOI_VAN_DAP.md` | **80** câu theo chủ đề thiết kế→web |
| `docs/ADMIN_RUNBOOK.md` | Đã có từ G3 (giữ nguyên) |

### Đã chạy / kiểm chứng khi viết docs
| Kiểm tra | Kết quả |
|---|---|
| Container `zoo-oracle` | healthy |
| Đếm dòng 19 bảng | ≥5 mỗi bảng (animals=22, invoices=24, …) |
| Tablespace bảng/index | T\|ZOO_DATA\|19 ; I\|ZOO_DATA\|49 |
| Datafile | `.../FREEPDB1/zoo_data01.dbf` 120M |
| PL/SQL objects | 10 views, 3 functions, 6 procedures, 5 triggers |
| FK CASCADE | invoice_items, purchase_order_items |

### Việc còn tồn / chưa kiểm chứng lại trong G6
- Chạy lại full `RUN_WINDOWS.md` trên máy Windows sạch → để Giai đoạn 7
- `docker compose down -v` + dựng lại từ đầu → G7 nghiệm thu

### Chờ xác nhận để sang Giai đoạn 7 (Nghiệm thu)
---

## Giai đoạn 7 — Nghiệm thu (2026-11-02)

### Đã làm (máy sạch giả lập)
1. Stop API/web đang chạy
2. `docker compose down -v` → xóa volume `zoo_oradata`
3. `./scripts/mac/db-up.sh` → healthy (~30s, image đã cache)
4. `./scripts/mac/db-init.sh` → OK (`run_all` XONG)
5. `q00_show_schema.sql` + `queries.sql` (18/18, không ORA-/SP2-)
6. PL/SQL đúng/sai; API/web smoke; admin 7.2 + 7.4 + 7.5 chạy lại

### Checklist mục 14

| # | Hạng mục | Kết quả G7 |
|---|---|---|
| 1 | User `ZOO` + TS `ZOO_DATA`; không segment ngoài ZOO_DATA | **PASS** — bad_ts=0; DEFAULT=ZOO_DATA |
| 2 | ≥5 dòng/bảng; PK/FK/CHECK/UNIQUE/NN/DEFAULT | **PASS** — q00 đếm 19 bảng ≥5 |
| 3 | Lược đồ + ERD | **PASS** — `q00` + `docs/ERD.md` |
| 4 | ≥10 truy vấn đủ loại | **PASS** — queries.sql 18 query |
| 5 | 7.1 instance | **PASS (bằng chứng G3)** — `ADMIN_RUNBOOK` 4 shutdown/startup/RO/restricted; **không lặp** SHUTDOWN trong G7 |
| 6 | 7.2 tablespace/datafile | **PASS** — chạy lại G7: RESIZE 120M, ORA-00372/376, offline MOVE, DROP ZOO_TEST |
| 7 | 7.3 recovery datafile | **PASS (bằng chứng G3)** — còn đủ id 1,2,3; backup volume vẫn ở `backup/zoo_oradata_pre_71_73.tgz` |
| 8 | 7.4 user/role/profile | **PASS** — chạy lại: cashier→medical **ORA-00942**; vet/keeper OK đúng quyền |
| 9 | 7.5 Data Pump | **PASS** — 19/19 bảng OK vs ZOO_COPY |
| 10 | Web + đăng nhập + CRUD + proc + lỗi TV | **PASS** — health animals=22; login JWT; move OK; move enc11 **400** “Chuồng đang bảo trì…”; feed plant→carnivore **400**; sale invoice 24 = 300000; CRUD zones; Vite `http://localhost:5173/` **200** (listen `[::1]` only) |
| 11 | macOS + Windows theo RUN_* | **PASS macOS G7**; Windows: có `scripts/windows/*.ps1` (14) + `RUN_WINDOWS.md` — **chưa chạy lại trên máy Windows sạch trong phiên này** |
| 12 | MO_TA 13 mục; Q&A ≥60 | **PASS** — 13 mục; **80** câu |
| 13 | Không mật khẩu thật trong git; `.env` ignore | **PASS cấu hình** — `.gitignore` có `.env`; repo **chưa** `git init` → chưa có remote/commit |
| 14 | PROGRESS ghi rõ verified / chưa | **PASS** — file này |

### PL/SQL / API đã thử lại sau reset
| Case | Kết quả |
|---|---|
| `sp_move_animal` OK | OK (rollback) |
| move → enc 11 | ORA-20001 |
| feed diet sai | ORA-20033 / HTTP 400 |
| `trg_medical_vet` | ORA-20030 |
| `sp_create_invoice` Zookeeper | ORA-20040 |
| invoice Cashier | OK id=23 (SQL) / sale API id=24 |

### Chưa kiểm chứng / hạn chế còn lại
- Chạy full `RUN_WINDOWS.md` trên Windows 10/11 + WSL2 thật
- Lặp lại 7.1 + 7.3 trên volume mới (cố ý bỏ qua để tránh downtime; bằng chứng G3 còn hiệu lực)
- `git init` / đẩy remote (ngoài phạm vi nghiệm thu kỹ thuật)

### Kết luận
**Nghiệm thu macOS đạt** theo checklist mục 14 (trừ xác nhận vật lý Windows). Sẵn sàng demo / vấn đáp.
---

## Giai đoạn 0 — Nền tảng (2026-11-02)

### Đã làm
- Cấu trúc repo, `.gitignore`, `.gitattributes`, `.env.example`, `docker-compose.yml`
- Script macOS + Windows; `README.md`

### Đã chạy / kiểm chứng
| Kiểm tra | Kết quả |
|---|---|
| `uname -m` | **arm64** |
| Image | `container-registry.oracle.com/database/free:latest` (arm64) |
| DB | Oracle AI Database 26ai Free `23.26.3.0.0` |
| Container | `zoo-oracle` healthy; `FREEPDB1` OPEN |

### Lưu ý
- Đã `docker stop oracle26ai` vì chiếm cổng 1521 (container cũ còn, stopped).
- Python hệ thống 3.9.6 — Giai đoạn 4 cần 3.12.
---
