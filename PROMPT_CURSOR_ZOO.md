# PROMPT TỔNG CHO CURSOR: BÀI TẬP LỚN ORACLE "HỆ THỐNG QUẢN LÝ SỞ THÚ"

> **Cách dùng:** đặt file này vào thư mục gốc repo (đặt tên `PROMPT.md`), mở Cursor ở chế độ **Agent**, gõ:
> `Đọc @PROMPT.md thật kỹ rồi làm lần lượt từng GIAI ĐOẠN. Dừng sau mỗi giai đoạn để tôi kiểm tra.`
> Mỗi lần chỉ cho Cursor làm **một giai đoạn** (mục 13). Nếu nó làm sai, copy nguyên thông báo lỗi `ORA-xxxxx` dán lại.

---

## 1. VAI TRÒ VÀ MỤC TIÊU

Bạn là một kỹ sư CSDL Oracle kiêm full-stack developer. Hãy xây dựng trọn bộ **bài tập lớn môn Oracle** cho nhóm 4 sinh viên, đề tài **"Xây dựng cơ sở dữ liệu hệ thống quản lý sở thú"**.

Bài được chấm theo barem bên dưới. **Quản trị CSDL chiếm 5/10 điểm, còn ứng dụng web chỉ 1/10 điểm (cộng thêm 2-3 điểm nếu làm tốt).** Vì vậy hãy dồn công sức vào CSDL, quản trị, và tài liệu. Web chỉ cần gọn, chạy ổn, đẹp vừa đủ.

Môn thi cuối kỳ là **vấn đáp về chính hệ thống này**, nên sản phẩm phải **giải thích được từng dòng**. Với mỗi script, hãy viết chú thích tiếng Việt nói rõ "làm gì, vì sao, kết quả mong đợi".

## 2. BAREM VÀ SẢN PHẨM TƯƠNG ỨNG

| STT | Nội dung barem | Điểm | Sản phẩm bắt buộc |
|---|---|---|---|
| 1 | Giới thiệu đề tài, mô tả các thực thể, mối quan hệ các thực thể | 0.5 | `docs/MO_TA_HE_THONG.md` (mục 1-3), `docs/ERD.md` |
| 2 | Tạo bảng, khóa chính, liên kết (khóa ngoại), ràng buộc, **hiển thị lược đồ quan hệ**, nhập dữ liệu (**tối thiểu 5 bản ghi/bảng**). **Toàn bộ bảng nằm trong 1 user mới; dữ liệu lưu trong 1 tablespace mới hoàn toàn (không dùng tablespace có sẵn)** | 2.5 | `db/*.sql`, `db/queries/q00_show_schema.sql` |
| 3 | Tối thiểu 10 truy vấn SQL: cơ bản, lồng nhau, nhóm, hàm thống kê... | 1 | `db/queries/queries.sql` |
| 4 | Quản trị CSDL Oracle (chi tiết ở mục 7) | 5 | thư mục `admin/` + `docs/ADMIN_RUNBOOK.md` |
| 5 | Ứng dụng web đơn giản kết nối CSDL Oracle | 1 (+2-3 ưu tiên) | `zoo-api/`, `zoo-web/` |

## 3. RÀNG BUỘC CỨNG (vi phạm là mất điểm)

1. **Một user mới** tên `ZOO` sở hữu toàn bộ đối tượng của đề tài. Không tạo bảng trong `SYS`, `SYSTEM` hay user có sẵn.
2. **Một tablespace mới hoàn toàn** tên `ZOO_DATA` (kèm datafile riêng). User `ZOO` có `DEFAULT TABLESPACE ZOO_DATA`, và mọi bảng, index đều phải nằm trong đó. Tuyệt đối **không** dùng `USERS`, `SYSTEM`, `SYSAUX`. Phải có script **chứng minh** điều này (truy vấn `USER_TABLES.tablespace_name`, `USER_INDEXES.tablespace_name`, `DBA_SEGMENTS`).
3. **Mỗi bảng ≥ 5 bản ghi** (kể cả `audit_logs`, `app_accounts`, các bảng chi tiết). Dữ liệu mẫu phải có ý nghĩa (tên thật, ngày hợp lý), không để "abc", "test".
4. Phiên bản: **Oracle AI Database 26ai Free**, chạy bằng Docker. Container database `FREE`, pluggable database **`FREEPDB1`** (đối tượng đề tài nằm trong PDB). Kết nối ứng dụng: `localhost:1521/FREEPDB1`.
5. **Tên bảng, cột, procedure, view bằng tiếng Anh**, dạng `snake_case`, khóa chính tên `id`, khóa ngoại dạng `<bảng_số_ít>_id`. **Giao diện web bằng tiếng Việt có dấu**; thông báo lỗi nghiệp vụ trong `RAISE_APPLICATION_ERROR` cũng bằng tiếng Việt có dấu.
6. Procedure **không `COMMIT` bên trong**; nơi gọi (API hoặc script) quyết định commit/rollback.
7. Không đưa mật khẩu thật vào git. Dùng `.env` (thêm vào `.gitignore`), có `.env.example`. Mật khẩu demo trong script SQL chỉ dùng cho tài khoản demo và ghi chú rõ.
8. **Chạy được trên cả macOS (Apple Silicon hoặc Intel) và Windows 10/11.** Xem mục 10.
9. **Phải tự chạy và kiểm tra** mọi script trên container Oracle thật bằng terminal. Script lỗi thì sửa tới khi chạy sạch. Không được báo "đã xong" khi chưa chạy. Nếu thật sự không chạy được thì nói rõ phần nào chưa kiểm chứng.
10. Trước khi sửa một file, đọc nó. Không đoán tên bảng/cột: lấy từ `db/*.sql` hoặc truy vấn `USER_TAB_COLUMNS`.
11. Dùng bind variable (`:name`) trong mọi truy vấn của API. Không nối chuỗi SQL.

## 4. STACK CHỐT

| Lớp | Công nghệ |
|---|---|
| CSDL | Oracle AI Database 26ai Free (Docker) |
| Backend | Python 3.12, FastAPI, `python-oracledb` (thin mode, không cần Instant Client), PyJWT, bcrypt |
| Frontend | Vue 3 + Vite, Vue Router, Pinia, Axios, Element Plus, Chart.js |
| Triển khai dev | Docker Compose (db + api); web chạy `npm run dev`; chia sẻ cho nhóm bằng Cloudflare Tunnel (cách A) |
| Công cụ | Git/GitHub, SQL*Plus trong container (không bắt buộc cài gì thêm trên máy), tùy chọn SQL Developer |

## 5. CẤU TRÚC REPO

```
zoo-project/
  PROMPT.md
  README.md                      # tóm tắt + link tới docs
  .gitignore  .gitattributes     # *.sh *.sql *.md eol=lf  (quan trọng cho Windows)
  .env.example
  docker-compose.yml
  db/
    00_create_tablespace_user.sql   # chạy bằng SYS trong FREEPDB1: tạo tablespace + user
    01_reset.sql                    # xóa sạch đối tượng schema ZOO để dựng lại
    05_common.sql                   # audit_logs
    10_animals.sql                  # zones, enclosures, species, animals (+view/proc/trigger/dữ liệu)
    20_staff.sql                    # positions, employees, assignments, app_accounts
    30_food_health.sql              # suppliers, foods, purchase_orders(+items), feeding_logs, medical_records
    40_tickets.sql                  # ticket_types, customers, invoices, invoice_items
    run_all.sql                     # chạy theo thứ tự, cuối cùng in lỗi biên dịch + đếm số dòng mỗi bảng
    queries/ q00_show_schema.sql, queries.sql
  admin/
    01_instance.sql   02_tablespace_datafile.sql   03_recovery_datafile.md + .sql/.rman
    04_users_privileges.sql   05_datapump.md + script   99_cleanup.sql
  scripts/
    mac/*.sh        windows/*.ps1       # cùng một bộ chức năng (mục 10)
  zoo-api/   (FastAPI)
  zoo-web/   (Vue 3)
  docs/
    MO_TA_HE_THONG.md  CAU_HOI_VAN_DAP.md  ERD.md  ADMIN_RUNBOOK.md
    RUN_MACOS.md  RUN_WINDOWS.md  PHAN_CONG_2_TUAN.md  PROGRESS.md
```

## 6. MÔ HÌNH DỮ LIỆU (nguồn sự thật, 19 bảng)

Kiểu khóa chính: `NUMBER GENERATED ALWAYS AS IDENTITY`. Dữ liệu mẫu chèn theo thứ tự cố định để id xác định (1, 2, 3...) rồi tham chiếu bằng số; kèm chú thích `-- id = n`.

**Module A: động vật và chuồng trại**
- `zones(id, name UNIQUE NN, description, area_m2 >0)`
- `enclosures(id, name NN, zone_id FK NN, capacity >0 NN, status CHECK ACTIVE|MAINTENANCE)`
- `species(id, name NN, scientific_name, class_group CHECK MAMMAL|BIRD|REPTILE|AMPHIBIAN|FISH, conservation_status CHECK LC|NT|VU|EN|CR|EW, diet CHECK CARNIVORE|HERBIVORE|OMNIVORE)`
- `animals(id, name NN, species_id FK NN, enclosure_id FK NULL, gender CHECK M|F, birth_date, arrival_date NN DEFAULT SYSDATE, origin, weight_kg >0, status CHECK HEALTHY|SICK|QUARANTINE|DECEASED|TRANSFERRED; CHECK birth_date <= arrival_date)`

**Module B: nhân sự**
- `positions(id, name UNIQUE NN, base_salary >=0)`: Manager, Veterinarian, Zookeeper, Cashier, Security Guard
- `employees(id, full_name NN, gender, birth_date, phone UNIQUE, email UNIQUE, address, hire_date, position_id FK NN, zone_id FK NULL, status CHECK ACTIVE|RESIGNED)`
- `assignments(id, employee_id FK NN, enclosure_id FK NN, start_date NN, end_date, shift CHECK MORNING|AFTERNOON|NIGHT; CHECK end_date >= start_date)`
- `app_accounts(id, username UNIQUE NN, password_hash NN, role CHECK MANAGER|VET|KEEPER|CASHIER, employee_id FK UNIQUE)` (tài khoản đăng nhập web, bcrypt, **khác** user của Oracle)

**Module C: thức ăn, kho, y tế**
- `suppliers(id, name NN, phone, address)`
- `foods(id, name UNIQUE NN, category CHECK MEAT|PLANT|MIXED, unit NN, stock_qty >=0 DEFAULT 0, min_stock DEFAULT 10)`
- `purchase_orders(id, supplier_id FK NN, employee_id FK NN, order_date DEFAULT SYSDATE, total_amount DEFAULT 0)`
- `purchase_order_items(PK(purchase_order_id, food_id), quantity >0, unit_price >=0, expiry_date)`, FK `purchase_order_id` có `ON DELETE CASCADE`
- `feeding_logs(id, animal_id FK, food_id FK, employee_id FK, fed_at TIMESTAMP DEFAULT SYSTIMESTAMP, quantity >0, note)`
- `medical_records(id, animal_id FK, vet_id FK→employees, exam_date, diagnosis, treatment, follow_up_date)`

**Module D: bán vé và nhật ký**
- `ticket_types(id, name UNIQUE NN, price >=0)`: Adult, Child, Senior, Group
- `customers(id, full_name NN, phone, email)`
- `invoices(id, customer_id FK NULL, employee_id FK NN, issued_at DEFAULT SYSDATE, payment_method CHECK CASH|CARD|TRANSFER, total_amount DEFAULT 0)`
- `invoice_items(PK(invoice_id, ticket_type_id), quantity >0, unit_price >=0)`, FK `invoice_id` có `ON DELETE CASCADE`
- `audit_logs(id, table_name, action, record_id, db_user DEFAULT USER, created_at, details)`

**Quan hệ:** zones 1-N enclosures; enclosures 1-N animals; species 1-N animals; positions 1-N employees; zones 1-N employees; employees N-M enclosures (qua assignments); animals N-M foods (qua feeding_logs, kèm employee); animals 1-N medical_records (vet là employee); suppliers 1-N purchase_orders; purchase_orders N-M foods (qua purchase_order_items); customers 1-N invoices; invoices N-M ticket_types (qua invoice_items); employees 1-N purchase_orders/invoices; employees 1-1 app_accounts.

**Index:** mọi cột khóa ngoại + `animals(status)`, `feeding_logs(animal_id, fed_at)`, `invoices(issued_at)`, `audit_logs(created_at)`. Index tạo trong `ZOO_DATA`.

**Đối tượng PL/SQL (đặt trong file module tương ứng):**
- Views: `v_animal_details`, `v_enclosure_occupancy`, `v_animals_per_zone`, `v_employee_details`, `v_current_assignments`, `v_low_stock_foods`, `v_upcoming_followups` (tái khám trong 7 ngày), `v_food_consumption_30d`, `v_daily_revenue`, `v_invoice_details`
- Functions: `fn_enclosure_free_slots(enclosure_id)`, `fn_food_consumed(food_id, from, to)`, `fn_revenue(from, to)`
- Procedures:
  - `sp_move_animal(animal_id, enclosure_id)`: khóa dòng, báo lỗi nếu chuồng bảo trì (-20001), đầy (-20002), động vật đã chết/chuyển đi (-20004)
  - `sp_assign_employee(employee_id, enclosure_id, start, end, shift)`: nhân viên phải đang làm, không trùng ca trong cùng khoảng ngày
  - `sp_resign_employee(employee_id)`: đặt `RESIGNED` và kết thúc mọi phân công còn hiệu lực
  - `sp_feed_animal(animal_id, food_id, employee_id, quantity, note)`: kiểm tra tồn kho, **kiểm tra loại thức ăn hợp chế độ ăn** (thú ăn thịt không ăn `PLANT`, thú ăn cỏ không ăn `MEAT`), ghi `feeding_logs`, trừ kho
  - `sp_create_invoice(customer_id, employee_id, payment_method, OUT invoice_id)`: chỉ Cashier/Manager đang làm việc được lập
  - `sp_add_invoice_item(invoice_id, ticket_type_id, quantity)`: lấy giá hiện hành từ `ticket_types`
- Triggers: `trg_animals_audit` (ghi log khi đổi trạng thái/chuồng hoặc xóa), `trg_assignments_keeper` (chỉ Zookeeper được phân công chuồng), `trg_po_items_ai` (nhập kho: cộng tồn + cộng tổng tiền phiếu), `trg_medical_vet` (chỉ Veterinarian được khám), `trg_invoice_items_ai` (cộng tổng tiền hóa đơn)
- **Gợi ý thêm điểm** (làm nếu còn thời gian): package `pkg_zoo_report` gom các hàm báo cáo, một cursor/BULK COLLECT, một job `DBMS_SCHEDULER` ghi cảnh báo kho thấp vào `audit_logs` mỗi ngày.

Dữ liệu mẫu tối thiểu (đảm bảo mỗi bảng ≥ 5): 5 zones, 11 enclosures (1 chuồng `MAINTENANCE` để demo lỗi), 10 species, ~22 animals (có 1 `SICK`, 1 `QUARANTINE`), 5 positions, 10 employees (≥2 bác sĩ, ≥4 người chăm sóc, ≥2 thu ngân), ~9 assignments, 5 app_accounts (mật khẩu demo `Zoo@123456`, băm bcrypt, ghi rõ trong README), 5 suppliers, 9 foods (≥1 món dưới `min_stock` để demo cảnh báo), 5 purchase_orders (≥10 dòng items, chèn bằng INSERT để trigger tự cộng kho), ≥20 feeding_logs (gọi `sp_feed_animal`, dàn trải 7 ngày), ≥5 medical_records (≥2 tái khám trong 7 ngày tới), 5 ticket_types, 5 customers, ≥20 invoices dàn trải 14 ngày (gọi procedure), ≥40 invoice_items, `audit_logs` có ≥5 dòng do trigger sinh ra.

## 7. QUẢN TRỊ CSDL (5 ĐIỂM, PHẦN QUAN TRỌNG NHẤT)

Mỗi mục là **một script chạy được** trong `admin/`, kèm: (a) chú thích từng lệnh, (b) kết quả mong đợi, (c) cách hoàn tác, (d) đoạn "giải thích khi vấn đáp" trong `docs/ADMIN_RUNBOOK.md`. Kết nối bằng SYSDBA từ trong container (`sqlplus / as sysdba`) trên CDB `FREE` hoặc PDB `FREEPDB1` tùy lệnh; ghi rõ lệnh nào chạy ở đâu.

> Lưu ý 26ai Free: dùng `SYS` để chạy `GRANT`/lệnh quản trị (user `SYSTEM` có thể gặp `ORA-01031` ở một số lệnh). Tự kiểm tra thực tế và ghi lại.

### 7.1 Quản lý Instance (`01_instance.sql`)
- Xem trạng thái: `V$INSTANCE` (status), `V$DATABASE` (open_mode, log_mode), `SHOW PDBS`.
- `SHUTDOWN` đủ 4 chế độ: `NORMAL`, `TRANSACTIONAL`, `IMMEDIATE`, `ABORT`; **bảng so sánh** hành vi từng chế độ (có chờ phiên không, có rollback không, có cần recovery khi mở lại không), kèm demo thực tế bằng một phiên đang giữ giao dịch.
- `STARTUP` theo từng giai đoạn: `NOMOUNT` → `MOUNT` → `OPEN`; giải thích mỗi giai đoạn đọc file nào (spfile, control file, datafile) và truy vấn `V$INSTANCE`/`V$DATABASE` ở từng bước.
- Chế độ **READ ONLY**: `STARTUP MOUNT` rồi `ALTER DATABASE OPEN READ ONLY`; thử `INSERT` để thấy `ORA-16000`; sau đó đưa về `READ WRITE`. Kèm bản cho PDB: `ALTER PLUGGABLE DATABASE FREEPDB1 CLOSE IMMEDIATE; ... OPEN READ ONLY;`.
- **RESTRICTED SESSION**: `ALTER SYSTEM ENABLE RESTRICTED SESSION` và `STARTUP RESTRICT`; chứng minh user thường (`ZOO`) không đăng nhập được (`ORA-01035`), còn user có `RESTRICTED SESSION` hoặc SYSDBA thì vào được; tắt lại bằng `DISABLE RESTRICTED SESSION`.
- Xem/đổi tham số: `SHOW PARAMETER`, `V$PARAMETER`, `ALTER SYSTEM SET ... SCOPE=MEMORY|SPFILE|BOTH`.
- **Lưu ý Docker:** thử xem sau `SHUTDOWN` container có dừng không, và cách mở lại (`STARTUP` trong sqlplus hoặc `docker start`). Ghi kết quả thực tế vào runbook.

### 7.2 Tablespace và Datafile (`02_tablespace_datafile.sql`)
Làm toàn bộ trên PDB `FREEPDB1`. **Không lấy đường dẫn cố định**: truy vấn `DBA_DATA_FILES` để biết thư mục datafile, rồi dùng đúng thư mục đó.
- **Tạo** tablespace `ZOO_DATA` (permanent, `AUTOEXTEND ON NEXT 10M MAXSIZE 500M`) và tablespace tạm `ZOO_TEMP` (temporary) dùng cho user `ZOO`.
- **Thêm** datafile thứ hai vào `ZOO_DATA` (`ALTER TABLESPACE ... ADD DATAFILE`).
- **Sửa:** `RESIZE` datafile; bật/tắt **autoextend** (`ALTER DATABASE DATAFILE ... AUTOEXTEND ON/OFF`); đổi tên tablespace (`RENAME TO`); đặt `READ ONLY`/`READ WRITE`; `OFFLINE`/`ONLINE`.
- **Xóa:** tạo một tablespace thử `ZOO_TEST`, rồi `DROP TABLESPACE ZOO_TEST INCLUDING CONTENTS AND DATAFILES`. **Tuyệt đối không xóa `ZOO_DATA` thật.**
- **Di chuyển datafile:** cách online `ALTER DATABASE MOVE DATAFILE '...' TO '...'` và cách offline (đưa tablespace offline → copy file ở mức OS bằng `docker compose exec` → `ALTER TABLESPACE ... RENAME DATAFILE` → online). Chứng minh bằng truy vấn đường dẫn trước và sau.
- **Truy vấn thông tin:** `DBA_TABLESPACES`, `DBA_DATA_FILES`, `DBA_TEMP_FILES`, `DBA_FREE_SPACE` (dung lượng trống/đã dùng theo tablespace, tính %), `DBA_SEGMENTS` (bảng nào chiếm bao nhiêu MB), `V$DATAFILE`, `V$TABLESPACE`, `DBA_USERS` (default/temporary tablespace), `DBA_TS_QUOTAS`. Viết thành **một báo cáo** dễ đọc.
- Chứng minh dữ liệu ZOO nằm trong `ZOO_DATA` (xem ràng buộc cứng số 2).

### 7.3 Khôi phục datafile bị mất (`03_recovery_datafile.*`)
Làm trên một **tablespace thử** (`ZOO_TEST` có bảng nhỏ) để không phá dữ liệu thật.
- Bật `ARCHIVELOG` (cần `SHUTDOWN IMMEDIATE` → `STARTUP MOUNT` → `ALTER DATABASE ARCHIVELOG` → `OPEN`; kiểm tra thư mục/dung lượng recovery area).
- Sao lưu bằng **RMAN** (`BACKUP TABLESPACE` hoặc `BACKUP DATABASE`) ra thư mục mount ra ngoài container (`./backup`).
- Giả lập mất file: xóa datafile bằng lệnh OS trong container; chứng minh lỗi (`ORA-01157`/`ORA-27041`).
- Khôi phục: `ALTER DATABASE DATAFILE n OFFLINE` → `RESTORE DATAFILE n` → `RECOVER DATAFILE n` → `ONLINE`; kiểm tra dữ liệu còn nguyên. Ghi lại **từng bước, từng lệnh, từng thông báo**.
- Trình bày thêm 2 tình huống trong runbook: mất datafile khi `NOARCHIVELOG`, và mất khi database đang đóng.
- Nếu một bước bị giới hạn bởi bản Free hoặc Docker, nói rõ và đưa phương án thay thế gần nhất.

### 7.4 Người dùng, phân quyền, chức danh (`04_users_privileges.sql`)
(Chức danh được hiện thực bằng **ROLE** và **PROFILE**.)
- **Profile** `pf_zoo_staff` (giới hạn mật khẩu: `FAILED_LOGIN_ATTEMPTS 3`, `PASSWORD_LIFE_TIME 90`, `PASSWORD_LOCK_TIME 1`, `PASSWORD_REUSE_MAX`, `SESSIONS_PER_USER`, `IDLE_TIME`) và `pf_zoo_manager` (nới hơn).
- **Role** theo chức danh: `r_manager`, `r_vet`, `r_keeper`, `r_cashier`, mỗi role có quyền hệ thống (`CREATE SESSION`) và quyền đối tượng khác nhau (bảng, view, `EXECUTE` procedure). Quyền khác nhau thực sự: ví dụ cashier không đọc được `medical_records`.
- Tạo user demo `zoo_manager`, `zoo_vet`, `zoo_keeper`, `zoo_cashier` (gán profile, role, quota, default tablespace `ZOO_DATA`).
- Minh họa: `GRANT`/`REVOKE`, `WITH GRANT OPTION`, `WITH ADMIN OPTION`, khóa/mở khóa user (`ACCOUNT LOCK/UNLOCK`), đổi mật khẩu, hết hạn mật khẩu, đổi quota, xóa user.
- **Kiểm chứng bằng cách đăng nhập thật** từng user và chạy lệnh được/không được (in ra `ORA-00942`/`ORA-01031` khi bị từ chối). Truy vấn `DBA_ROLE_PRIVS`, `DBA_SYS_PRIVS`, `DBA_TAB_PRIVS`, `DBA_PROFILES`, `DBA_USERS`.
- Ghi chú: ứng dụng web dùng **một** kết nối `ZOO` và tự kiểm tra vai trò ở tầng API (`app_accounts.role`); các user Oracle ở đây để **minh họa phân quyền ở tầng CSDL**. Nêu rõ điều này trong tài liệu.

### 7.5 Import/Export một schema (`05_datapump.*`)
- Tạo `DIRECTORY dp_zoo` trỏ tới thư mục trong container (ví dụ `/opt/oracle/dpdump` hoặc thư mục mount ra `./backup`), `GRANT READ, WRITE` cho `ZOO`.
- **Export:** `expdp ... SCHEMAS=ZOO DIRECTORY=dp_zoo DUMPFILE=zoo_%U.dmp LOGFILE=zoo_exp.log` (chạy qua `docker compose exec`).
- **Import:** xóa một vài bảng (hoặc dùng `REMAP_SCHEMA=ZOO:ZOO_COPY` và `REMAP_TABLESPACE=ZOO_DATA:ZOO_DATA`) rồi `impdp`; chứng minh số dòng khớp trước/sau.
- Giải thích các tham số `TABLE_EXISTS_ACTION`, `CONTENT`, `EXCLUDE/INCLUDE`; và vì sao chọn Data Pump thay vì `exp/imp` cũ.

## 8. TRUY VẤN SQL (≥ 10, mục tiêu 15) trong `db/queries/queries.sql`

Mỗi truy vấn có: số thứ tự, **mục đích nghiệp vụ**, loại truy vấn, **kết quả mẫu mong đợi**, và một câu giải thích để vấn đáp. Phân bổ tối thiểu:
- **Cơ bản (3):** lọc + sắp xếp (động vật đang `SICK`), `LIKE`/`BETWEEN`/`IN`, `DISTINCT`/`FETCH FIRST`.
- **Nối bảng (3):** `INNER JOIN` nhiều bảng (động vật - loài - chuồng - khu), `LEFT JOIN` (chuồng chưa có động vật), self-join hoặc `JOIN` 4 bảng (lịch cho ăn kèm nhân viên).
- **Nhóm (3):** `GROUP BY` + `HAVING` (khu vực có > n động vật), doanh thu theo ngày, số động vật theo `class_group`.
- **Lồng nhau (3):** `IN`/`NOT IN`, `EXISTS`/`NOT EXISTS`, subquery tương quan (động vật nặng hơn trung bình cùng loài), subquery ở `FROM`.
- **Hàm thống kê (3):** `COUNT/SUM/AVG/MIN/MAX/STDDEV/MEDIAN`, hàm phân tích `RANK()/DENSE_RANK()/ROW_NUMBER() OVER (...)` (top thức ăn tiêu thụ, xếp hạng nhân viên bán vé), `ROLLUP` hoặc `LISTAGG`.
- **Tập hợp (1):** `UNION`/`MINUS`/`INTERSECT`.
Kèm `q00_show_schema.sql`: **hiển thị lược đồ quan hệ** bằng truy vấn từ `USER_TABLES`, `USER_TAB_COLUMNS`, `USER_CONSTRAINTS`, `USER_CONS_COLUMNS` (liệt kê PK, FK nối bảng nào với bảng nào, CHECK, UNIQUE), cộng truy vấn chứng minh tablespace và đếm số dòng mọi bảng.

## 9. ỨNG DỤNG WEB (GỌN, 1 ĐIỂM + ƯU TIÊN)

**Nguyên tắc:** ít màn hình nhưng chạy chắc, giao diện sạch. Viết **component CRUD dùng chung** (bảng + tìm kiếm + phân trang + form thêm/sửa + xác nhận xóa) rồi cấu hình cho từng bảng để tiết kiệm công.

- **Backend (`zoo-api/`):** FastAPI, routers theo module, `repositories` chứa SQL thuần với bind variable, pool `oracledb.create_pool`, JWT + bcrypt, decorator phân quyền theo `app_accounts.role`, CORS cấu hình qua `.env`, Swagger ở `/docs`. Bắt `oracledb.DatabaseError`: mã `ORA-20xxx` trả nguyên thông điệp tiếng Việt (HTTP 400); map `ORA-00001` (trùng khóa), `ORA-02291/02292` (khóa ngoại), `ORA-02290` (check) sang câu tiếng Việt dễ hiểu. Endpoint nghiệp vụ **gọi procedure/function có sẵn**, không viết lại logic bằng Python. Whitelist tên bảng/cột cho CRUD tổng quát.
- **Frontend (`zoo-web/`):** tiếng Việt có dấu toàn bộ; map enum sang nhãn tiếng Việt trong một file `labels`; ngày `dd/mm/yyyy`; tiền `1.234.000 ₫`; menu theo vai trò.
- **Màn hình:** Đăng nhập · Tổng quan (thẻ số liệu + biểu đồ doanh thu 7 ngày + biểu đồ động vật theo nhóm + cảnh báo kho thấp + tái khám sắp tới) · Động vật (CRUD, chi tiết, nút **Chuyển chuồng**) · Chuồng/Khu/Loài · Nhân viên (CRUD, phân công, **Cho nghỉ việc**) · Thức ăn & kho (CRUD, **phiếu nhập nhiều dòng**, **Cho ăn**) · Khám bệnh · **Bán vé** (chọn loại vé, số lượng, thanh toán, in hóa đơn bằng `window.print()`) · Báo cáo doanh thu theo khoảng ngày · Nhật ký hệ thống (chỉ Manager).
- Xác nhận bằng hộp thoại trước khi xóa; thông báo thành công/lỗi rõ ràng; giao diện dùng được trên màn hình nhỏ.

## 10. CHẠY TRÊN macOS VÀ WINDOWS

**Docker Compose:** service `db` dùng image cấu hình qua biến `ORACLE_IMAGE`, mặc định `container-registry.oracle.com/database/free:latest` (image Oracle 26ai Free, đa kiến trúc: chạy native trên Apple Silicon lẫn Windows/Intel). Đặt **cả** `ORACLE_PWD` và `ORACLE_PASSWORD` cùng giá trị trong `environment` để tương thích nếu đổi sang image `gvenzl/oracle-free`. Dùng named volume cho `/opt/oracle/oradata`, mount `./db:/db:ro`, `./admin:/admin:ro`, `./backup:/backup`. Có `healthcheck` kiểm tra kết nối `FREEPDB1`. Mở cổng `1521`. Nếu image mặc định lỗi kiến trúc, ghi trong runbook cách ép `--platform` hoặc đổi sang `gvenzl/oracle-free:latest`.

**Hai bộ script cùng chức năng** (đặt tên giống nhau): `scripts/mac/*.sh` (bash, có `chmod +x`) và `scripts/windows/*.ps1` (PowerShell):
`setup` (kiểm tra Docker, tạo `.env` từ `.env.example`) · `db-up` · `db-down` · `db-init` (tạo tablespace + user, nạp `run_all.sql`) · `db-reset` · `sql-zoo` / `sql-sys` (mở sqlplus) · `admin-run <số>` (chạy từng script quản trị) · `dp-export` / `dp-import` · `api-dev` · `web-dev` · `tunnel` (Cloudflare Tunnel để chia sẻ API cho nhóm).

**`docs/RUN_MACOS.md` và `docs/RUN_WINDOWS.md`** viết từ con số 0 cho người chưa quen, gồm:
1. Cài gì: Docker Desktop (Windows: bật WSL2; ghi cách cấp **≥ 4GB RAM** cho Docker), Git, Python 3.12, Node 20+, `cloudflared`; kèm lệnh cài bằng `brew` (macOS) hoặc `winget` (Windows).
2. Các bước đầu tiên: clone → `setup` → `db-up` → chờ thông báo `DATABASE IS READY TO USE` → `db-init` → chạy API → chạy web → mở trình duyệt, tài khoản demo.
3. Cách chạy từng bài quản trị (mục 7) trên từng hệ điều hành.
4. Xử lý lỗi thường gặp: cổng 1521 bận, hết RAM, container thoát, `ORA-12514`, sai kiến trúc image (Apple Silicon), tiếng Việt bị `???` (đặt `NLS_LANG=.AL32UTF8`; Windows: `chcp 65001` và `[Console]::OutputEncoding`), `Execution Policy` của PowerShell, CRLF/LF làm hỏng `.sh`/`.sql`, để repo ngoài OneDrive/đường dẫn có dấu cách.
5. Cách chia sẻ API dev cho cả nhóm bằng `cloudflared tunnel --url http://localhost:8000` và cách chỉnh `VITE_API_URL`, `CORS_ORIGINS`.

## 11. TÀI LIỆU BẮT BUỘC (SỐNG CÒN KHI VẤN ĐÁP)

**Cách làm:** sinh phần "từ điển dữ liệu" **từ CSDL đang chạy** (truy vấn `USER_TAB_COLUMNS`, `USER_CONSTRAINTS`...) để không lệch với thực tế, rồi viết văn giải thích xung quanh.

### `docs/MO_TA_HE_THONG.md` (một file duy nhất, đầy đủ, viết cho người sẽ bị hỏi vấn đáp)
1. **Giới thiệu đề tài:** bài toán, đối tượng sử dụng, phạm vi, công nghệ (kèm lý do chọn từng thứ).
2. **Mô tả các thực thể:** mỗi thực thể một mục: ý nghĩa nghiệp vụ, các thuộc tính quan trọng, ràng buộc, ví dụ dữ liệu.
3. **Mối quan hệ giữa các thực thể:** bảng quan hệ (1-1, 1-N, N-M, bảng trung gian), lý do thiết kế, ràng buộc tham chiếu (`ON DELETE`).
4. **ERD** (Mermaid) + **lược đồ quan hệ** dạng `Bảng(khóa chính, khóa ngoại, ...)` cho cả 19 bảng, và phần **chuẩn hóa tới 3NF** (chỉ ra phụ thuộc hàm, vì sao đạt 1NF/2NF/3NF; giải thích chỗ cố ý lưu dư `total_amount` và `unit_price` để làm gì).
5. **Từ điển dữ liệu** đầy đủ (bảng, cột, kiểu, null, mặc định, ràng buộc, mô tả).
6. **Kiến trúc lưu trữ:** user `ZOO`, tablespace `ZOO_DATA`, `ZOO_TEMP`, vị trí datafile, quota; sơ đồ CDB `FREE` → PDB `FREEPDB1`.
7. **Danh mục đối tượng PL/SQL:** view, function, procedure, trigger: mỗi cái có mục đích, tham số, luồng xử lý từng bước, mã lỗi, ví dụ gọi, ví dụ kết quả, và **câu hỏi thầy có thể hỏi**.
8. **Danh mục 10+ truy vấn:** đề bài, SQL, giải thích, kết quả.
9. **Quản trị CSDL:** từng mục 7.1-7.5: lý thuyết ngắn, lệnh đã dùng, kết quả thực tế, lỗi gặp phải và cách xử lý, so sánh các lựa chọn (4 chế độ shutdown, move datafile online/offline, ARCHIVELOG/NOARCHIVELOG, Data Pump vs exp/imp).
10. **Kiến trúc ứng dụng:** sơ đồ web ↔ API ↔ Oracle, luồng một nghiệp vụ điển hình đi qua từng tầng (ví dụ "cho ăn": Vue → endpoint → `sp_feed_animal` → trigger/log), cách xử lý lỗi, xác thực, phân quyền hai tầng (web và Oracle).
11. **Hướng dẫn chạy và demo:** kịch bản demo 10 phút theo đúng thứ tự barem.
12. **Hạn chế đã biết và hướng phát triển** (nêu thật, kể cả những gì chưa kiểm chứng).
13. **Bảng "ai làm gì"** cho 4 thành viên.

### `docs/CAU_HOI_VAN_DAP.md`
Ít nhất **60 câu hỏi kèm đáp án ngắn gọn, chính xác**, nhóm theo chủ đề: thiết kế CSDL và chuẩn hóa · ràng buộc và index · PL/SQL (procedure vs function, trigger, vì sao không commit trong procedure, `FOR UPDATE`, mutating table) · SQL (join, subquery, window function) · kiến trúc Oracle (instance vs database, SGA/PGA, tablespace/segment/extent/block, control file/redo log/archive log, CDB/PDB, các giai đoạn startup, các chế độ shutdown) · sao lưu và khôi phục (RMAN, ARCHIVELOG, mất datafile) · bảo mật (user/role/profile/quota, `GRANT` vs `ROLE`) · Data Pump · ứng dụng web (bind variable, SQL injection, connection pool, JWT).

### `docs/ERD.md`, `docs/ADMIN_RUNBOOK.md`, `docs/PROGRESS.md`
ERD bằng Mermaid (kèm hướng dẫn xuất ảnh) · runbook quản trị (lệnh + kết quả thực tế + cách hoàn tác + giải thích vấn đáp) · nhật ký từng giai đoạn: đã làm gì, đã chạy lệnh nào, kết quả, việc còn tồn, **điều gì chưa kiểm chứng được**.

## 12. KẾ HOẠCH 2 TUẦN VÀ PHÂN CÔNG 4 NGƯỜI (viết vào `docs/PHAN_CONG_2_TUAN.md`)

Nhóm có một bài kiểm tra xen giữa, nên chừa đệm; mốc cứng là hết ngày 12, ngày 13-14 chỉ ôn vấn đáp và sửa lỗi.

| Người | Phụ trách chính (đúng barem) | Phụ trách phụ |
|---|---|---|
| **A** (macOS, trưởng nhóm) | Hạ tầng Docker + script 2 hệ điều hành; **4a: Instance + Tablespace/Datafile + khôi phục datafile** | Review PR, tích hợp |
| **B** | **2: schema, dữ liệu mẫu, PL/SQL**; ERD | Đảm bảo ≥5 dòng/bảng |
| **C** | **3: 10+ truy vấn**; **4b: user/role/profile + Data Pump** | Câu hỏi vấn đáp |
| **D** | **5: web (API + Vue)**; **1: mô tả đề tài, thực thể** | Demo web |

| Ngày | Mục tiêu |
|---|---|
| 1-2 | Họp, chốt phân công, A dựng Docker + script, cả nhóm chạy được DB trên máy mình |
| 3-5 | B hoàn thành schema + dữ liệu; D dựng khung API/Vue; C viết truy vấn nháp; A làm instance |
| 6-8 | B hoàn thiện PL/SQL; C xong truy vấn + phân quyền; A xong tablespace/datafile; D làm CRUD + đăng nhập |
| 9-10 | A làm recovery; C làm Data Pump; D làm nghiệp vụ (cho ăn, chuyển chuồng, bán vé, báo cáo) |
| 11-12 | Hợp nhất, test chéo, hoàn thiện `MO_TA_HE_THONG.md` và `CAU_HOI_VAN_DAP.md` |
| 13-14 | Tập vấn đáp (**mỗi người phải giải thích được phần của người khác**), chạy thử toàn bộ từ DB trống, sửa lỗi |

Quy tắc Git: không push thẳng `main`; mỗi người một nhánh `feature/<tên>`, tạo Pull Request vào `develop`, người khác review; mỗi người chỉ sửa file trong phần mình.

## 13. QUY TRÌNH LÀM VIỆC CHO CURSOR (DỪNG SAU MỖI GIAI ĐOẠN)

Sau mỗi giai đoạn: chạy kiểm tra, ghi vào `docs/PROGRESS.md`, tóm tắt cho tôi 5 dòng, rồi **dừng chờ xác nhận**.

- **Giai đoạn 0, Nền tảng:** cấu trúc repo, `.gitignore`, `.gitattributes`, `.env.example`, `docker-compose.yml`, bộ script mac/windows (`setup`, `db-up`, `db-down`, `sql-sys`, `sql-zoo`), khởi động Oracle và chờ sẵn sàng. *Kiểm tra:* `sqlplus` vào được `FREEPDB1`. Cho tôi biết kiến trúc máy (`uname -m`) và image kéo về là gì.
- **Giai đoạn 1, CSDL (barem 2):** `00_create_tablespace_user.sql` rồi các file module, `run_all.sql`, `q00_show_schema.sql`. *Kiểm tra:* `user_errors` rỗng; mọi bảng ≥ 5 dòng; mọi bảng/index nằm trong `ZOO_DATA`; chạy lại `db-reset` + `db-init` từ DB trống không lỗi; thử gọi từng procedure và từng trigger với cả trường hợp đúng lẫn sai (in ra mã `ORA-20xxx`).
- **Giai đoạn 2, Truy vấn (barem 3):** `queries.sql`. *Kiểm tra:* chạy cả file, không lỗi, kết quả hợp lý.
- **Giai đoạn 3, Quản trị (barem 4):** lần lượt 7.1 → 7.5, **chạy thật từng script**, dán kết quả thực tế vào runbook. Thứ tự gợi ý để ít rủi ro: 7.2 → 7.4 → 7.5 → 7.1 → 7.3. Trước khi chạy 7.1 và 7.3 phải **sao lưu volume Oracle**.
- **Giai đoạn 4, API:** khung, đăng nhập, `/api/health`, rồi từng module; thử bằng Swagger.
- **Giai đoạn 5, Vue:** layout, đăng nhập, component CRUD chung, từng màn hình.
- **Giai đoạn 6, Tài liệu:** `MO_TA_HE_THONG.md`, `CAU_HOI_VAN_DAP.md`, `ERD.md`, `ADMIN_RUNBOOK.md`, `RUN_MACOS.md`, `RUN_WINDOWS.md`, `PHAN_CONG_2_TUAN.md`.
- **Giai đoạn 7, Nghiệm thu:** chạy từ đầu theo đúng `RUN_*.md` trên máy sạch (giả lập: `docker compose down -v`), rồi đối chiếu checklist mục 14.

## 14. CHECKLIST NGHIỆM THU

- [ ] Toàn bộ bảng thuộc user `ZOO`; tablespace `ZOO_DATA` mới; không bảng/index nào ở `USERS`/`SYSTEM`/`SYSAUX`
- [ ] Mọi bảng ≥ 5 dòng; có khóa chính, khóa ngoại, CHECK, UNIQUE, NOT NULL, DEFAULT
- [ ] Có script hiển thị lược đồ quan hệ và ERD
- [ ] ≥ 10 truy vấn đủ 5 loại, đều chạy đúng
- [ ] 7.1 đủ: 4 chế độ shutdown, startup từng giai đoạn, read only, restricted session
- [ ] 7.2 đủ: thêm/sửa/xóa tablespace, thêm/resize datafile, autoextend on/off, move datafile, truy vấn thông tin
- [ ] 7.3: khôi phục datafile mất đã chạy thật, có ghi lại
- [ ] 7.4: user/role/profile, grant/revoke, kiểm chứng bằng đăng nhập thật
- [ ] 7.5: export và import schema, số dòng khớp
- [ ] Web chạy, đăng nhập, CRUD, gọi được procedure, thông báo lỗi tiếng Việt có dấu
- [ ] Chạy được trên macOS và Windows theo `RUN_*.md`
- [ ] `MO_TA_HE_THONG.md` đủ 13 mục; `CAU_HOI_VAN_DAP.md` ≥ 60 câu
- [ ] Không có mật khẩu thật trong git; `.env` bị ignore
- [ ] `PROGRESS.md` ghi rõ phần nào đã kiểm chứng, phần nào chưa

**Bắt đầu ngay Giai đoạn 0.** Nếu thiếu thông tin, hãy đọc file trong repo hoặc truy vấn CSDL thay vì hỏi lại; chỉ hỏi khi thật sự không thể tự quyết định.
