# Mô tả hệ thống — Quản lý sở thú (Oracle)

Tài liệu vấn đáp. Số liệu lấy từ PDB `FREEPDB1`, user `ZOO` (2026-11-02): **19 bảng**, toàn bộ segment trong `ZOO_DATA`.

---

## 1. Giới thiệu đề tài

**Bài toán:** Sở thú cần quản lý khu/chuồng, động vật, nhân sự ca làm, kho thức ăn, khám bệnh và bán vé trong một CSDL Oracle thống nhất, kèm vài nghiệp vụ có kiểm tra (chuyển chuồng, cho ăn, lập hóa đơn).

**Đối tượng dùng:** Quản lý (Manager), bác sĩ thú y (Vet), người chăm sóc (Keeper), thu ngân (Cashier). Tài khoản web nằm ở `app_accounts` (bcrypt), **khác** user Oracle schema `ZOO`.

**Phạm vi:** Schema + PL/SQL + ≥10 truy vấn + quản trị 7.1–7.5 + web CRUD/nghiệp vụ tối thiểu. Không làm bán hàng online, app mobile, hay HR đầy đủ.

**Công nghệ và lý do:**
| Thành phần | Lý do |
|---|---|
| Oracle 26ai Free (Docker) | Đúng môn; Free đủ CDB/PDB, ARCHIVELOG, Data Pump, RMAN cơ bản |
| PDB `FREEPDB1` | Đối tượng đề tài tách khỏi CDB root |
| FastAPI + `oracledb` thin | API mỏng, không cần Instant Client |
| Vue 3 + Element Plus | UI tiếng Việt nhanh cho demo barem 5 |
| JWT + bcrypt | Auth ứng dụng; Oracle user/role demo riêng ở mục 7.4 |

---

## 2. Mô tả các thực thể

### Module A — Động vật & chuồng
| Thực thể | Ý nghĩa | Thuộc tính / ràng buộc nổi bật | Ví dụ |
|---|---|---|---|
| **zones** | Khu trưng bày | `name` UNIQUE; `area_m2 > 0` | Khu châu Á |
| **enclosures** | Chuồng trong khu | FK `zone_id`; `capacity > 0`; status ACTIVE\|MAINTENANCE | Chuồng hổ; id=11 bảo trì (demo lỗi) |
| **species** | Loài | class_group, conservation_status, diet (CHECK) | Hổ Bengal EN / CARNIVORE |
| **animals** | Cá thể | FK species, enclosure; status; `birth_date ≤ arrival_date` | Raja, Mei Mei (SICK) |

### Module B — Nhân sự
| Thực thể | Ý nghĩa | Ghi chú |
|---|---|---|
| **positions** | Chức danh + lương cơ bản | Manager, Veterinarian, Zookeeper, Cashier, Security Guard |
| **employees** | Nhân viên | FK position, zone; phone/email UNIQUE; ACTIVE\|RESIGNED |
| **assignments** | Phân công keeper ↔ chuồng | shift MORNING\|AFTERNOON\|NIGHT; `end_date ≥ start_date` |
| **app_accounts** | Login web | username UNIQUE; role MANAGER\|VET\|KEEPER\|CASHIER; 1–1 employee |

### Module C — Thức ăn & y tế
| Thực thể | Ý nghĩa | Ghi chú |
|---|---|---|
| **suppliers** | Nhà cung cấp | |
| **foods** | Mặt hàng kho | category MEAT\|PLANT\|MIXED; `stock_qty ≥ 0` |
| **purchase_orders** / **items** | Phiếu nhập + dòng | PK kép items; CASCADE khi xóa phiếu; trigger cộng kho + `total_amount` |
| **feeding_logs** | Nhật ký cho ăn | quantity > 0 |
| **medical_records** | Phiếu khám | trigger chỉ Veterinarian |

### Module D — Vé
| Thực thể | Ý nghĩa | Ghi chú |
|---|---|---|
| **ticket_types** | Loại vé + giá | |
| **customers** | Khách (tuỳ chọn trên HĐ) | |
| **invoices** / **invoice_items** | Hóa đơn + dòng | payment CASH\|CARD\|TRANSFER; CASCADE items; trigger cộng `total_amount` |

### Hệ thống
| **audit_logs** | Nhật ký UPDATE/DELETE animals (và mở rộng) | `db_user` DEFAULT USER |

Số dòng mẫu (đã kiểm chứng): zones 5, enclosures 11, species 10, animals 22, positions 5, employees 10, assignments 9, app_accounts 5, suppliers 5, foods 9, PO 5 / items 12, feeding_logs 21, medical 6, ticket_types 5, customers 5, invoices 24 / items 59, audit_logs ≥5.

---

## 3. Mối quan hệ giữa các thực thể

| Quan hệ | Cardinality | Bảng / FK | ON DELETE |
|---|---|---|---|
| zone → enclosures | 1–N | `enclosures.zone_id` | NO ACTION |
| zone → employees | 1–N (nullable) | `employees.zone_id` | NO ACTION |
| enclosure → animals | 1–N (nullable) | `animals.enclosure_id` | NO ACTION |
| species → animals | 1–N | `animals.species_id` | NO ACTION |
| position → employees | 1–N | `employees.position_id` | NO ACTION |
| employee ↔ enclosure (ca) | N–M | **assignments** | NO ACTION |
| employee ↔ app_account | 1–1 | `app_accounts.employee_id` UK | NO ACTION |
| supplier → PO | 1–N | | NO ACTION |
| PO ↔ food | N–M | **purchase_order_items** | CASCADE từ PO |
| animal/food/employee → feeding | N | feeding_logs | NO ACTION |
| animal/vet → medical | N | medical_records | NO ACTION |
| customer → invoices | 1–N | nullable | NO ACTION |
| invoice ↔ ticket_type | N–M | **invoice_items** | CASCADE từ invoice |

**Lý do thiết kế:** bảng trung gian cho N–M (phân công, nhập kho, dòng vé). `enclosure_id` trên animals nullable để thú chết/chuyển có thể không gắn chuồng. Không CASCADE xóa động vật/nhân viên để tránh mất lịch sử; CASCADE chỉ trên dòng chi tiết phụ thuộc phiếu/HĐ.

---

## 4. ERD, lược đồ quan hệ, chuẩn hóa

ERD Mermaid đầy đủ: xem [`ERD.md`](ERD.md).

### Lược đồ quan hệ (19 bảng)

```
zones(id PK, name UK, description, area_m2)
enclosures(id PK, name, zone_id FK→zones, capacity, status)
species(id PK, name, scientific_name, class_group, conservation_status, diet)
animals(id PK, name, species_id FK→species, enclosure_id FK→enclosures, gender, birth_date, arrival_date, origin, weight_kg, status)
positions(id PK, name UK, base_salary)
employees(id PK, full_name, gender, birth_date, phone UK, email UK, address, hire_date, position_id FK→positions, zone_id FK→zones, status)
assignments(id PK, employee_id FK→employees, enclosure_id FK→enclosures, start_date, end_date, shift)
app_accounts(id PK, username UK, password_hash, role, employee_id FK→employees UK)
suppliers(id PK, name, phone, address)
foods(id PK, name UK, category, unit, stock_qty, min_stock)
purchase_orders(id PK, supplier_id FK→suppliers, employee_id FK→employees, order_date, total_amount)
purchase_order_items(purchase_order_id FK→PO PK, food_id FK→foods PK, quantity, unit_price, expiry_date)
feeding_logs(id PK, animal_id FK, food_id FK, employee_id FK, fed_at, quantity, note)
medical_records(id PK, animal_id FK, vet_id FK→employees, exam_date, diagnosis, treatment, follow_up_date)
ticket_types(id PK, name UK, price)
customers(id PK, full_name, phone, email)
invoices(id PK, customer_id FK→customers, employee_id FK, issued_at, payment_method, total_amount)
invoice_items(invoice_id FK→invoices PK, ticket_type_id FK→ticket_types PK, quantity, unit_price)
audit_logs(id PK, table_name, action, record_id, db_user, created_at, details)
```

### Chuẩn hóa tới 3NF

- **1NF:** mọi cột nguyên tử; không nhóm lặp (dòng vé/PO tách bảng items).
- **2NF:** khóa đơn IDENTITY trên hầu hết bảng; bảng items khóa kép `(invoice_id, ticket_type_id)` / `(po_id, food_id)` — mọi thuộc tính phụ thuộc đủ cả khóa (qty, price).
- **3NF:** không phụ thuộc bắc cầu lưu dư — tên loài/chuồng lấy qua FK; lương theo `positions`, không copy vào employees.

**Cố ý lưu dư (denormalize có kiểm soát):**
- `invoices.total_amount`, `purchase_orders.total_amount` — tổng tiền đồng bộ bằng trigger AFTER INSERT items; phục vụ báo cáo nhanh, tránh SUM mỗi lần.
- `invoice_items.unit_price`, `purchase_order_items.unit_price` — **snapshot giá tại thời điểm bán/nhập**; nếu sau này đổi `ticket_types.price` / giá NCC, lịch sử HĐ không bị lệch.

---

## 5. Từ điển dữ liệu

Nguồn: `USER_TAB_COLUMNS` / `USER_CONSTRAINTS` (ZOO). PK: `NUMBER GENERATED ALWAYS AS IDENTITY` trừ bảng items (PK kép).

### zones
| Cột | Kiểu | Null | Ràng buộc | Mô tả |
|---|---|---|---|---|
| id | NUMBER | N | PK | |
| name | VARCHAR2(100) | N | UK | Tên khu |
| description | VARCHAR2(500) | Y | | |
| area_m2 | NUMBER(10,2) | Y | >0 hoặc NULL | Diện tích |

### enclosures
| Cột | Kiểu | Null | Ràng buộc | Mô tả |
|---|---|---|---|---|
| id | NUMBER | N | PK | |
| name | VARCHAR2(100) | N | | |
| zone_id | NUMBER | N | FK→zones | |
| capacity | NUMBER | N | >0 | Sức chứa |
| status | VARCHAR2(20) | N | ACTIVE\|MAINTENANCE; DEFAULT ACTIVE | |

### species
| Cột | Kiểu | Null | Ràng buộc | Mô tả |
|---|---|---|---|---|
| id | NUMBER | N | PK | |
| name | VARCHAR2(100) | N | | Tên thường |
| scientific_name | VARCHAR2(150) | Y | | |
| class_group | VARCHAR2(20) | N | MAMMAL\|BIRD\|REPTILE\|AMPHIBIAN\|FISH | |
| conservation_status | VARCHAR2(5) | N | LC\|NT\|VU\|EN\|CR\|EW; DEFAULT LC | IUCN |
| diet | VARCHAR2(20) | N | CARNIVORE\|HERBIVORE\|OMNIVORE | |

### animals
| Cột | Kiểu | Null | Ràng buộc | Mô tả |
|---|---|---|---|---|
| id | NUMBER | N | PK | |
| name | VARCHAR2(100) | N | | |
| species_id | NUMBER | N | FK→species | |
| enclosure_id | NUMBER | Y | FK→enclosures | |
| gender | VARCHAR2(1) | Y | M\|F | |
| birth_date | DATE | Y | ≤ arrival_date | |
| arrival_date | DATE | N | DEFAULT SYSDATE | |
| origin | VARCHAR2(200) | Y | | |
| weight_kg | NUMBER(8,2) | Y | >0 | |
| status | VARCHAR2(20) | N | HEALTHY\|SICK\|QUARANTINE\|DECEASED\|TRANSFERRED | |

### positions / employees / assignments / app_accounts
| Bảng.Cột chính | Kiểu / ràng buộc |
|---|---|
| positions.name | UK; base_salary ≥0 DEFAULT 0 |
| employees.full_name NN; position_id FK; zone_id FK nullable; phone/email UK; status ACTIVE\|RESIGNED DEFAULT ACTIVE; hire_date DEFAULT SYSDATE |
| assignments.employee_id, enclosure_id FK; start_date NN; end_date ≥ start; shift MORNING\|AFTERNOON\|NIGHT |
| app_accounts.username UK; password_hash NN; role CHECK; employee_id FK UK |

### foods / suppliers / PO / feeding / medical
| Bảng.Cột chính | Kiểu / ràng buộc |
|---|---|
| suppliers.name NN | |
| foods.name UK; category MEAT\|PLANT\|MIXED; unit NN; stock_qty≥0 DEFAULT 0; min_stock DEFAULT 10 |
| purchase_orders.supplier_id, employee_id FK; order_date DEFAULT SYSDATE; total_amount DEFAULT 0 |
| purchase_order_items PK (po_id, food_id); qty>0; unit_price≥0; FK po CASCADE |
| feeding_logs animal/food/employee FK; fed_at DEFAULT SYSTIMESTAMP; quantity>0 |
| medical_records animal_id, vet_id FK; exam_date DEFAULT SYSDATE |

### tickets
| Bảng.Cột chính | Kiểu / ràng buộc |
|---|---|
| ticket_types.name UK; price≥0 |
| customers.full_name NN |
| invoices.employee_id FK; customer_id nullable; issued_at DEFAULT SYSDATE; payment CASH\|CARD\|TRANSFER; total_amount DEFAULT 0 |
| invoice_items PK (invoice_id, ticket_type_id); CASCADE từ invoice; qty>0; unit_price≥0 |

### audit_logs
| Cột | Ghi chú |
|---|---|
| table_name, action, record_id, details | |
| db_user DEFAULT USER; created_at DEFAULT SYSTIMESTAMP | |

Script chứng minh: `db/queries/q00_show_schema.sql`.

---

## 6. Kiến trúc lưu trữ

```
CDB FREE
 └── PDB FREEPDB1
      ├── Tablespace ZOO_DATA (permanent) — datafile zoo_data01.dbf
      │     └── User ZOO (DEFAULT TABLESPACE ZOO_DATA, QUOTA UNLIMITED)
      │           19 tables + indexes (49 index segments) — đã chứng minh 0 segment ngoài ZOO_DATA
      └── Temporary ZOO_TEMP — tempfile zoo_temp01.dbf
```

| Hạng mục | Giá trị thực tế |
|---|---|
| Datafile ZOO_DATA | `/opt/oracle/oradata/FREE/FREEPDB1/zoo_data01.dbf` |
| Size sau demo 7.2 | **120M**, AUTOEXTEND ON MAX 500M |
| BIGFILE | YES (image Free) → không ADD DATAFILE thêm (ORA-32771) |
| User app | `ZOO` / `ZooApp_Demo1` (demo) |
| SYS | mật khẩu `ORACLE_PWD` trong `.env` |

Kết nối app: `localhost:1521/FREEPDB1`.

---

## 7. Danh mục đối tượng PL/SQL

### Views
| View | Mục đích |
|---|---|
| `v_animal_details` | Hồ sơ thú + loài + chuồng + khu |
| `v_enclosure_occupancy` | Sức chứa / số thú / chỗ trống |
| `v_animals_per_zone` | Đếm thú theo khu |
| `v_employee_details` | NV + chức danh + tài khoản app |
| `v_current_assignments` | Phân công còn hiệu lực |
| `v_low_stock_foods` | stock < min |
| `v_upcoming_followups` | Tái khám sắp tới |
| `v_food_consumption_30d` | Tiêu thụ 30 ngày |
| `v_daily_revenue` | Doanh thu theo ngày |
| `v_invoice_details` | HĐ + dòng vé |

### Functions
| Hàm | Tham số → kết quả | Ghi chú |
|---|---|---|
| `fn_enclosure_free_slots` | enclosure_id → NUMBER | capacity − thú còn nuôi; -20010 nếu không có chuồng |
| `fn_food_consumed` | food_id, from, to → SUM quantity | |
| `fn_revenue` | from, to DATE → SUM total_amount | |

### Procedures (không COMMIT bên trong)
| Proc | Luồng | Mã lỗi |
|---|---|---|
| `sp_move_animal(animal, enclosure)` | FOR UPDATE thú+chuồng → cấm DECEASED/TRANSFERRED → cấm MAINTENANCE → kiểm free slots → UPDATE | -20001,-20002,-20004 |
| `sp_assign_employee(...)` | NV ACTIVE, ngày/ca hợp lệ, không trùng ca → INSERT | -20020..-20024 (+ trigger) |
| `sp_resign_employee(id)` | Đặt RESIGNED; kết thúc assignments mở | -20025 |
| `sp_feed_animal(...)` | FOR UPDATE thú+kho → chế độ ăn → đủ kho → INSERT log + trừ stock | -20031..-20034 |
| `sp_create_invoice` / `sp_add_invoice_item` | Chỉ Cashier/Manager ACTIVE; thêm dòng (trigger cộng tổng) | -20040..-20042 |

**Ví dụ gọi:**
```sql
BEGIN sp_move_animal(14, 5); COMMIT; END;
/
BEGIN sp_feed_animal(1, 2, 4, 5, 'Buổi sáng'); COMMIT; END;
/
```

### Triggers
| Trigger | Thời điểm | Việc làm |
|---|---|---|
| `trg_animals_audit` | AFTER UPDATE/DELETE animals | Ghi `audit_logs` khi đổi status/enclosure hoặc xóa |
| `trg_assignments_keeper` | BEFORE INSERT/UPDATE assignments | Chỉ Zookeeper |
| `trg_medical_vet` | BEFORE INSERT/UPDATE vet_id | Chỉ Veterinarian |
| `trg_po_items_ai` | AFTER INSERT PO items | Cộng `foods.stock_qty` + `PO.total_amount` |
| `trg_invoice_items_ai` | AFTER INSERT invoice items | Cộng `invoices.total_amount` |

**Câu hỏi thầy có thể hỏi:** Vì sao `FOR UPDATE` trong move/feed? (tránh race chỗ trống/kho). Vì sao không COMMIT trong proc? (một transaction nghiệp vụ từ API; lỗi → rollback cả cụm). Mutating table? (trigger không SELECT cùng bảng đang mutating theo cách cấm — audit ghi bảng khác).

---

## 8. Danh mục truy vấn (≥10)

File: `db/queries/queries.sql` — **18 truy vấn**, đã chạy sạch trên FREEPDB1.

| # | Loại | Mục đích | Kết quả mẫu |
|---|---|---|---|
| Q01 | Cơ bản | Thú SICK | Mei Mei |
| Q02 | LIKE/BETWEEN/IN | MAMMAL 50–500kg tên có A | Bao Bao, Nala… |
| Q03 | DISTINCT + FETCH | 5 origin | |
| Q04 | INNER JOIN nhiều bảng | Hồ sơ thú chuồng ACTIVE | ~20 dòng |
| Q05 | LEFT JOIN anti | Chuồng trống / bảo trì | enc 11 |
| Q06 | JOIN + thời gian | Feeding 7 ngày | |
| Q07 | GROUP BY HAVING | Zone >3 thú | |
| Q08 | Nhóm ngày | Doanh thu 14 ngày | |
| Q09 | GROUP class | Cơ cấu loài | MAMMAL nhiều |
| Q10 | IN subquery | EN/CR | hổ, voi |
| Q11 | NOT EXISTS | NV chưa phân công | |
| Q12 | Correlated subquery | Nặng hơn TB loài | |
| Q13 | Inline view | Top zone | |
| Q14 | Thống kê | COUNT/SUM/AVG/… MAMMAL | |
| Q15 | RANK window | Tiêu thụ thức ăn 30d | Cỏ voi #1 |
| Q16 | DENSE_RANK/ROW_NUMBER | Xếp cashier | |
| Q17 | ROLLUP + LISTAGG | Doanh thu theo PTTT + tổng | ~10.840.000 |
| Q18 | UNION/INTERSECT/MINUS | Feed vs sale | INTERSECT rỗng |

---

## 9. Quản trị CSDL (7.1–7.5)

Chi tiết lệnh + output: [`ADMIN_RUNBOOK.md`](ADMIN_RUNBOOK.md). Tóm tắt vấn đáp:

| Mục | Lý thuyết ngắn | Kết quả thực tế nổi bật |
|---|---|---|
| **7.1 Instance** | Instance = SGA+process; DB = file. Startup NOMOUNT→MOUNT→OPEN. 4 shutdown. | ARCHIVELOG sẵn; restricted → ORA-01035; sau SHUTDOWN dùng bequeath `/ as sysdba` (TNS ORA-12514) |
| **7.2 TS/DF** | Tablespace chứa segment; datafile vật lý. BIGFILE vs SMALLFILE. | ZOO_DATA BIGFILE → ADD DF ORA-32771; online MOVE ORA-00439 Free; offline MOVE OK; resize 100→120M |
| **7.3 Recovery** | ARCHIVELOG + backup → restore DF + recover redo | Mất file#20; PDB MOUNTED; RESTORE+RECOVER; còn id 1,2,**3** (sau backup) |
| **7.4 User/Role/Profile** | Profile = policy mật khẩu; Role = gói quyền | cashier đọc medical → ORA-00942; vet OK |
| **7.5 Data Pump** | expdp/impdp binary, remap | 19/19 bảng DIFF=0 qua ZOO_COPY |

So sánh nhanh: IMMEDIATE vs ABORT; Data Pump vs exp/imp cổ điển; ARCHIVELOG vs NOARCHIVELOG (mất dòng sau backup nếu NOARCHIVELOG).

---

## 10. Kiến trúc ứng dụng

```
Vue (zoo-web :5173)  --JWT-->  FastAPI (zoo-api :8000)  --pool thin-->  Oracle ZOO@FREEPDB1
```

**Luồng “cho ăn”:**
1. Keeper chọn thú + thức ăn trên Vue → `POST /api/.../feed`
2. API kiểm tra JWT role KEEPER|MANAGER
3. Gọi `sp_feed_animal` với bind variables → trigger/logic trừ kho + `feeding_logs`
4. API `connection.commit()`; lỗi ORA-20033 → HTTP 400 tiếng Việt

**Hai tầng phân quyền:**
- Web: `app_accounts.role` → route/menu + Depends trên FastAPI
- Oracle demo 7.4: user `zoo_keeper`… + role `r_*` (không dùng bởi pool app — app luôn connect `ZOO`)

**Bảo mật SQL:** mọi câu API dùng bind (`:name`), không nối chuỗi.

---

## 11. Hướng dẫn chạy và demo (≈10 phút)

1. `db-up` → `db-init` (hoặc DB đã sẵn) → `api-dev` + `web-dev`
2. Login `manager01` / `Zoo@123456` — Dashboard
3. SQL*Plus: `q00_show_schema` (ZOO_DATA, ≥5 dòng)
4. Chạy nhanh 2–3 query (Q01, Q10, Q17)
5. Demo proc: chuyển chuồng OK + chuyển vào enc 11 → lỗi bảo trì
6. Cho ăn sai chế độ → lỗi tiếng Việt trên web
7. Bán vé `cashier01` → doanh thu Chart
8. Mở `ADMIN_RUNBOOK` kể 7.2 BIGFILE, 7.3 còn 3 dòng, 7.4 ORA-00942, 7.5 DIFF=0

Chi tiết OS: [`RUN_MACOS.md`](RUN_MACOS.md), [`RUN_WINDOWS.md`](RUN_WINDOWS.md).

---

## 12. Hạn chế đã biết và hướng phát triển

- Oracle Free: không online MOVE datafile; BIGFILE hạn chế ADD file; FRA mặc định hạn chế → backup RMAN ra `/backup`.
- Chưa: package báo cáo, DBMS_SCHEDULER, audit đầy đủ mọi bảng, test tự động CI.
- Windows: script `.ps1` bọc WSL — cần Docker Desktop + WSL2; chưa chạy lại toàn bộ recovery trên máy Windows sạch trong phiên này.
- Web: CRUD whitelist, UI đủ demo — chưa UX nâng cao / phân trang lớn.
- Hướng phát triển: soft-delete thú, báo cáo Materialized View, role Oracle gắn session app (proxy user), monitoring AWR cơ bản.

---

## 13. Ai làm gì (4 thành viên)

| Người | Chính (barem) | Phụ |
|---|---|---|
| **A** (macOS, trưởng nhóm) | Docker/script 2 OS; 7.1 Instance; 7.2 TS/DF; 7.3 Recovery | Review, tích hợp |
| **B** | Schema, dữ liệu ≥5/bảng, PL/SQL, ERD | |
| **C** | ≥10 truy vấn; 7.4 user/role/profile; 7.5 Data Pump | Q&A CSDL |
| **D** | Web API+Vue; mô tả đề tài/thực thể (mục 1–3) | Demo web |

Chi tiết lịch 2 tuần: [`PHAN_CONG_2_TUAN.md`](PHAN_CONG_2_TUAN.md).
