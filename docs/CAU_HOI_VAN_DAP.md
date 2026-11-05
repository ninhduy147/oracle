# Câu hỏi vấn đáp — Hệ thống quản lý sở thú

≥ 60 câu, đáp án ngắn, đúng với schema/admin đã chạy thật trên Oracle 26ai Free.

---

## A. Thiết kế CSDL và chuẩn hóa (1–10)

**1. Đề tài giải quyết bài toán gì?**  
Quản lý khu/chuồng, động vật, nhân sự, kho thức ăn, khám bệnh và bán vé sở thú trên Oracle, kèm nghiệp vụ có kiểm tra.

**2. Vì sao tách `species` khỏi `animals`?**  
Loài dùng chung thuộc tính (diet, IUCN, class); cá thể chỉ giữ FK — tránh lặp, đạt 3NF.

**3. `assignments` giải quyết quan hệ nào?**  
N–M giữa nhân viên và chuồng theo ca/thời gian.

**4. Vì sao `invoice_items.unit_price` không lấy JOIN từ `ticket_types` lúc báo cáo?**  
Snapshot giá lúc bán; đổi giá sau không làm lệch hóa đơn cũ.

**5. `total_amount` trên invoices có phá 3NF không?**  
Là dư thừa có chủ đích, đồng bộ bằng trigger — đổi lấy tốc độ báo cáo.

**6. Khóa chính dùng gì?**  
`NUMBER GENERATED ALWAYS AS IDENTITY` (trừ bảng items khóa kép).

**7. Đặt tên FK theo quy ước nào?**  
`<bảng_số_ít>_id`, ví dụ `enclosure_id`, `species_id`.

**8. Vì sao `animals.enclosure_id` cho phép NULL?**  
Thú chết/chuyển đi có thể không còn gắn chuồng; hoặc chờ xếp chuồng.

**9. Quan hệ `app_accounts`–`employees`?**  
1–1 (UK trên `employee_id`); tài khoản web gắn đúng một NV.

**10. Bảng nào dùng ON DELETE CASCADE?**  
`purchase_order_items` ← PO; `invoice_items` ← invoices — dòng chi tiết theo phiếu/HĐ.

---

## B. Ràng buộc và index (11–18)

**11. CHECK trên `animals.status` gồm những giá trị nào?**  
HEALTHY, SICK, QUARANTINE, DECEASED, TRANSFERRED.

**12. Ràng buộc ngày trên animals?**  
`birth_date IS NULL OR birth_date <= arrival_date`.

**13. UNIQUE nào trên employees?**  
`phone`, `email`.

**14. Index trên `animals` phục vụ gì?**  
`species_id`, `enclosure_id`, `status` — JOIN/lọc thường xuyên.

**15. Toàn bộ bảng/index nằm tablespace nào?**  
`ZOO_DATA` (chứng minh `USER_TABLES`/`USER_INDEXES`/`DBA_SEGMENTS`).

**16. `capacity > 0` thuộc loại ràng buộc gì?**  
CHECK trên `enclosures`.

**17. Vì sao có index `(animal_id, fed_at)` trên feeding_logs?**  
Truy vấn lịch sử cho ăn theo thú + thời gian.

**18. NOT NULL khác PRIMARY KEY thế nào?**  
NN chỉ cấm null; PK = NN + UNIQUE + dùng làm định danh/tham chiếu.

---

## C. PL/SQL (19–30)

**19. Procedure khác function?**  
Proc không trả giá trị (có thể OUT); function trả đúng một kết quả, dùng trong SQL.

**20. Vì sao procedure không `COMMIT`?**  
Caller (API/script) gom nhiều bước một transaction; lỗi → rollback đồng bộ.

**21. `FOR UPDATE` trong `sp_move_animal` để làm gì?**  
Khóa dòng thú/chuồng, tránh hai phiên cùng chuyển làm vượt capacity.

**22. `sp_move_animal` báo lỗi khi nào?**  
Chuồng MAINTENANCE (-20001), đầy (-20002), thú DECEASED/TRANSFERRED (-20004).

**23. `sp_feed_animal` kiểm tra chế độ ăn ra sao?**  
CARNIVORE không ăn PLANT; HERBIVORE không ăn MEAT (-20033).

**24. Trigger `trg_animals_audit` ghi khi nào?**  
AFTER UPDATE (đổi status/enclosure) hoặc DELETE → `audit_logs`.

**25. `trg_assignments_keeper` / `trg_medical_vet`?**  
BEFORE: chỉ Zookeeper được phân công; chỉ Veterinarian được ghi khám.

**26. Mutating table là gì?**  
Trigger row-level SELECT/MODIFY cùng bảng đang bị statement thay đổi → ORA-04091. Audit ghi bảng khác nên tránh lỗi này.

**27. `fn_enclosure_free_slots` tính thế nào?**  
`capacity − COUNT(animals còn nuôi trên chuồng)`.

**28. Trigger `trg_po_items_ai` làm gì?**  
Cộng `stock_qty` và cộng `PO.total_amount`.

**29. Ai được `sp_create_invoice`?**  
Nhân viên ACTIVE chức danh Cashier hoặc Manager (-20040 nếu không).

**30. Exception tự định nghĩa dùng khoảng mã nào?**  
`RAISE_APPLICATION_ERROR(-20000 … -20999)`; dự án dùng -20001…-20042.

---

## D. SQL (31–40)

**31. INNER JOIN vs LEFT JOIN?**  
INNER chỉ dòng khớp cả hai; LEFT giữ trái, phải có thể NULL.

**32. Q05 tìm chuồng trống bằng cách nào?**  
LEFT JOIN animals + `WHERE a.id IS NULL` (anti-join).

**33. WHERE khác HAVING?**  
WHERE lọc trước GROUP BY; HAVING lọc sau gom nhóm.

**34. Subquery tương quan là gì?**  
Subquery tham chiếu cột dòng ngoài (vd thú nặng hơn AVG cùng loài — Q12).

**35. `NOT EXISTS` thường hơn `NOT IN` khi nào?**  
Khi subquery có thể NULL — NOT IN với NULL cho kết quả rỗng bất ngờ.

**36. `RANK` vs `DENSE_RANK` vs `ROW_NUMBER`?**  
RANK nhảy hạng sau hòa; DENSE_RANK không nhảy; ROW_NUMBER luôn duy nhất.

**37. `ROLLUP(payment_method)` cho thêm gì?**  
Thêm dòng tổng (payment_method NULL) — Q17.

**38. `LISTAGG` dùng để làm gì?**  
Nối tên vé trong một hóa đơn thành một chuỗi.

**39. `UNION` vs `UNION ALL` vs `MINUS`?**  
UNION loại trùng; ALL giữ trùng; MINUS hiệu tập hợp.

**40. `FETCH FIRST n ROWS ONLY`?**  
Giới hạn top-N (Oracle 12c+), dùng ở Q03.

---

## E. Kiến trúc Oracle (41–52)

**41. Instance khác database?**  
Instance = SGA + background processes; database = control/data/redo files.

**42. SGA vs PGA?**  
SGA dùng chung instance; PGA riêng từng process/server.

**43. Tablespace → segment → extent → block?**  
TS chứa segment (bảng/index); segment gồm extent; extent gồm block.

**44. Control file chứa gì?**  
Cấu trúc DB, tên datafile/redo, checkpoint — cần để MOUNT.

**45. Redo log vs archive log?**  
Redo online ghi thay đổi; archive là bản redo đã đầy được lưu (khi ARCHIVELOG).

**46. CDB / PDB?**  
CDB chứa root + PDB; đề tài nằm PDB `FREEPDB1` trong CDB `FREE`.

**47. Các giai đoạn STARTUP?**  
NOMOUNT (đọc spfile/control) → MOUNT (gắn control, chưa mở datafile user) → OPEN.

**48. Bốn chế độ SHUTDOWN?**  
NORMAL (đợi disconnect), TRANSACTIONAL (đợi txn), IMMEDIATE (rollback + kick), ABORT (cắt ngay, cần recovery).

**49. Sau SHUTDOWN, kết nối `@FREE` lỗi gì?**  
ORA-12514 — listener không còn service; dùng bequeath `sqlplus / as sysdba`.

**50. Restricted session?**  
Chỉ user có quyền đặc biệt; ZOO thường → ORA-01035.

**51. BIGFILE vs SMALLFILE?**  
BIGFILE một datafile lớn; SMALLFILE nhiều file — Free tạo ZOO_DATA BIGFILE nên ADD DATAFILE → ORA-32771.

**52. Online MOVE datafile trên Free?**  
ORA-00439 feature not enabled → offline copy + `RENAME DATAFILE`.

---

## F. Sao lưu và khôi phục (53–58)

**53. ARCHIVELOG giúp recovery thế nào?**  
Apply redo sau điểm backup → không mất txn đã commit (vd dòng id=3 sau backup).

**54. Các bước khi mất datafile (đã demo)?**  
OFFLINE datafile → RESTORE → RECOVER → ONLINE → OPEN READ WRITE.

**55. RMAN khác copy file tay?**  
RMAN biết backup piece, catalog, recover tự tìm redo cần thiết.

**56. NOARCHIVELOG mất datafile thì sao?**  
Restore được bản backup; không recover thay đổi sau backup → mất dữ liệu mới.

**57. FRA trên Free image gặp gì?**  
`db_recovery_file_dest` hạn chế/0 — backup RMAN ra thư mục `/backup` mount.

**58. Trước 7.1/7.3 nhóm làm gì?**  
Sao lưu volume Docker `zoo_oradata` (file ~488MB) để hoàn tác.

---

## G. Bảo mật (59–64)

**59. User vs Role vs Profile?**  
User = danh tính; Role = tập quyền gán được; Profile = hạn chế mật khẩu/session.

**60. `GRANT` trực tiếp vs qua ROLE?**  
Role dễ thu hồi/gán hàng loạt; quyền trực tiếp bám user cụ thể.

**61. Demo 7.4: `zoo_cashier` đọc `medical_records`?**  
ORA-00942 — không được cấp SELECT.

**62. Quota trên ZOO_DATA?**  
`QUOTA UNLIMITED ON ZOO_DATA` — user không ghi được TS khác nếu không quota.

**63. Phân quyền web khác Oracle 7.4 thế nào?**  
Web: JWT + `app_accounts.role`. Oracle role `zoo_*` chỉ minh họa; API pool dùng user `ZOO`.

**64. Mật khẩu có trong git không?**  
Không — `.env` gitignore; `.env.example` + mật khẩu demo ghi rõ trong docs/script.

---

## H. Data Pump (65–68)

**65. `expdp SCHEMAS=ZOO` tạo gì?**  
Dump binary + log trong DIRECTORY `dp_zoo` → `/backup/zoo_01.dmp`.

**66. Import kiểm chứng thế nào?**  
`REMAP_SCHEMA=ZOO:ZOO_COPY` rồi so COUNT 19 bảng — DIFF=0.

**67. Data Pump hơn exp/imp cổ?**  
Parallel, remap, filter metadata/data, dump binary hiện đại.

**68. `TABLE_EXISTS_ACTION`?**  
SKIP / APPEND / TRUNCATE / REPLACE khi bảng đích đã có.

---

## I. Ứng dụng web (69–75)

**69. Vì sao bắt buộc bind variable?**  
Chống SQL injection; chia sẻ cursor; không nối chuỗi user input.

**70. JWT dùng làm gì?**  
Sau login, client gửi token; API đọc role/sub mà không giữ session server nặng.

**71. Mật khẩu web lưu thế nào?**  
bcrypt hash trong `app_accounts.password_hash` — không lưu plain text.

**72. Connection pool?**  
`oracledb` tạo pool tới `ZOO@FREEPDB1`; mỗi request mượn/trả connection.

**73. Lỗi ORA-20xxx map ra sao?**  
FastAPI bắt → HTTP 400 + message tiếng Việt có dấu.

**74. Package PyPI nào?**  
`oracledb` (thin mode); tên cũ `python-oracledb` không còn trên index hiện tại.

**75. CORS chỉnh ở đâu?**  
`.env` `CORS_ORIGINS` (vd `http://127.0.0.1:5173`); tunnel thì thêm origin Cloudflare.

---

## J. Dự án / vận hành (76–80)

**76. User schema đề tài tên gì? Tablespace?**  
User `ZOO`; tablespace `ZOO_DATA` (+ temp `ZOO_TEMP`).

**77. Mỗi bảng tối thiểu bao nhiêu dòng?**  
≥ 5 (ràng buộc cứng barem).

**78. ORA-03405 trên 26ai sqlplus?**  
Không viết comment `--` sau dấu `;` trên cùng dòng.

**79. Thứ tự an toàn chạy admin?**  
7.2 → 7.4 → 7.5 → backup volume → 7.1 → 7.3.

**80. Script nạp schema từ đầu?**  
SYS: `00_create_tablespace_user.sql`; ZOO: `run_all.sql` (hoặc `./scripts/mac/db-init.sh`).
