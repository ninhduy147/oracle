# ADMIN RUNBOOK — Quản trị Oracle (barem 4)

Chạy bằng **SYS AS SYSDBA**. Mật khẩu demo: xem `.env` (`ORACLE_PWD`).  
App web dùng user schema `ZOO`; các user `zoo_*` ở 7.4 chỉ **minh họa phân quyền CSDL**.

Thứ tự an toàn: **7.2 → 7.4 → 7.5 → (backup volume) → 7.1 → 7.3**.

---

## 7.2 Tablespace & Datafile

**Script:** `admin/02_tablespace_datafile.sql`  
**Chạy:** `docker compose exec -T db sqlplus sys/...@FREEPDB1 as sysdba @/admin/02_tablespace_datafile.sql`

### Kết quả thực tế (2026-11-02)
| Hạng mục | Kết quả |
|---|---|
| `ZOO_DATA` | BIGFILE=YES, 1 datafile `zoo_data01.dbf` |
| ADD DATAFILE vào `ZOO_DATA` | **ORA-32771** (không thêm file vào BIGFILE) |
| RESIZE `zoo_data01` | 100M → **120M** |
| AUTOEXTEND OFF rồi ON | AUT=NO rồi YES, MAXSIZE 500M |
| `ZOO_TEST` SMALLFILE | Tạo OK; **ADD** `zoo_test02.dbf` OK |
| READ ONLY | INSERT → **ORA-00372** file cannot be modified |
| OFFLINE | SELECT → **ORA-00376** file cannot be read |
| RENAME | `ZOO_TEST` ↔ `ZOO_TEST_REN` OK |
| Online MOVE | **ORA-00439** feature not enabled (Free) |
| Offline MOVE | `cp` OS + `RENAME DATAFILE` → `zoo_test01_moved.dbf`, data còn |
| DROP `ZOO_TEST` | OK; `ZOO_DATA`/`ZOO_TEMP` còn |
| Object ZOO ngoài ZOO_DATA | **0 dòng** (đạt ràng buộc) |

### Giải thích vấn đáp
- **BIGFILE** = 1 datafile lớn; **SMALLFILE** = nhiều datafile → ADD DATAFILE chỉ SMALLFILE.
- Free **không bật** online move datafile → dùng offline.
- Không hard-code path: lấy từ `DBA_DATA_FILES`.

### Hoàn tác
- Datafile ZOO_DATA giữ 120M autoextend (an toàn).  
- `ZOO_TEST` đã DROP.

---

## 7.4 Users / Roles / Profiles

**Script:** `admin/04_users_privileges.sql`

### Kết quả thực tế
| Kiểm tra | Kết quả |
|---|---|
| Profile `pf_zoo_staff` / `pf_zoo_manager` | Tạo OK (FAILED_LOGIN_ATTEMPTS, LIFE_TIME, …) |
| Role `r_manager/vet/keeper/cashier` | CREATE SESSION + quyền đối tượng khác nhau |
| User `zoo_manager/vet/keeper/cashier` | Password demo `ZooRole_Demo1` |
| `zoo_vet` → `medical_records` | **OK** (6 dòng) |
| `zoo_cashier` → `medical_records` | **ORA-00942** |
| `zoo_keeper` → `medical_records` | **ORA-00942** |
| `zoo_cashier` → `invoices` | **OK** (22) |
| `zoo_keeper` → `animals` | **OK** (22) |
| LOCK/UNLOCK, PASSWORD EXPIRE, DROP user tạm | OK |

### Giải thích vấn đáp
- **ROLE** gom quyền; **PROFILE** giới hạn mật khẩu/session.  
- Web: một pool `ZOO` + phân quyền `app_accounts.role` ở API — tách biệt phân quyền Oracle demo.

### Hoàn tác
```sql
DROP USER zoo_manager CASCADE; -- tương tự vet/keeper/cashier
DROP ROLE r_manager; -- ...
DROP PROFILE pf_zoo_staff CASCADE;
```

---

## 7.5 Data Pump

**Scripts:** `admin/05_datapump_*.sh` · DIRECTORY `dp_zoo` → `/backup`

### Kết quả thực tế
| Bước | Kết quả |
|---|---|
| `expdp SCHEMAS=ZOO` | `/backup/zoo_01.dmp` (~1.4M), 19 bảng exported |
| `impdp REMAP_SCHEMA=ZOO:ZOO_COPY` | Import OK; ORA-31684 USER exists (chấp nhận) |
| So sánh số dòng | **19/19 OK**, DIFF=0 |
| Cleanup | `DROP USER ZOO_COPY CASCADE` |

### Tham số / vấn đáp
- `TABLE_EXISTS_ACTION`, `CONTENT`, `EXCLUDE/INCLUDE`, `REMAP_*` — xem `admin/05_datapump.md`.  
- Data Pump > `exp`/`imp`: parallel, binary dump, remap, metadata fine-grained.

---

## Backup volume trước 7.1 / 7.3

```text
backup/zoo_oradata_pre_71_73.tgz  (~488MB)  — 2026-11-02
```
Cách: `docker compose stop db` → `tar` volume `zoo_oradata` → `start`.

---

## 7.1 Instance

**Scripts:** `admin/01_instance.sql` + `admin/01_instance_lifecycle.sh`

### Kết quả thực tế
| Hạng mục | Kết quả |
|---|---|
| `v$instance` | FREE / OPEN |
| `log_mode` | **ARCHIVELOG** (Free image sẵn) |
| `open_cursors` SCOPE=MEMORY | 300 → 350 → 300 |
| PDB READ ONLY | OPEN READ ONLY; trả READ WRITE OK |
| RESTRICTED SESSION | ZOO login → **ORA-01035** |
| SHUTDOWN IMMEDIATE/ABORT/TRANSACTIONAL/NORMAL | Đóng instance OK |
| Sau SHUTDOWN qua TNS `@FREE` | **ORA-12514** (listener không còn service) |
| STARTUP | Dùng **bequeath** `sqlplus / as sysdba` |
| NOMOUNT→MOUNT→OPEN | STATUS STARTED → MOUNTED → OPEN |
| CDB READ ONLY | `open_mode=READ ONLY`; PDB ghi → ORA-01109 |
| Container sau SHUTDOWN | Vẫn **Up** (process entrypoint); Oracle down tới khi STARTUP |

### Bảng so sánh SHUTDOWN
| Mode | Chờ session? | Rollback txn? | Recovery khi mở? |
|---|---|---|---|
| NORMAL | Có (đợi disconnect) | Có | Không |
| TRANSACTIONAL | Đợi txn xong, từ chối txn mới | Có | Không |
| IMMEDIATE | Kick session | Có rollback | Không |
| ABORT | Kick ngay | Không | Crash recovery khi STARTUP |

### Hoàn tác / Docker
- Mở lại: trong container `sqlplus / as sysdba` → `STARTUP` → `ALTER PLUGGABLE DATABASE ALL OPEN`.  
- Nếu container stop: `docker compose start db`.

---

## 7.3 Recovery datafile

**Script:** `admin/03_recovery_datafile.sh` (đã chỉnh sau lần chạy thật)

### Kết quả thực tế (2026-11-02)
| Bước | Kết quả |
|---|---|
| ARCHIVELOG | Đã bật sẵn |
| FRA | `db_recovery_file_dest` trống / size 0 (Free) — backup ra `/backup` mount |
| Tạo `ZOO_TEST` + `demo_recovery` | file# **20** `zoo_test_rec01.dbf` |
| `RMAN BACKUP TABLESPACE ZOO_TEST` | `/backup/zoo_ts_zoo_test_...` (~1.2M) |
| Insert id=3 sau backup | OK |
| `rm` datafile | File mất |
| Hậu quả | FREEPDB1 rơi về **MOUNTED**; TNS PDB lỗi ORA-28547 |
| `DATAFILE 20 OFFLINE` | OK (bequeath + `ALTER SESSION SET CONTAINER`) |
| `RESTORE DATAFILE 20` | Restore từ piece `/backup/zoo_ts_...` |
| `RECOVER DATAFILE 20` | media recovery complete |
| `ONLINE` + `OPEN READ WRITE` | OK |
| Dữ liệu | **id 1,2,3** còn đủ (gồm dòng sau backup nhờ redo) |
| Cleanup | DROP table + tablespace |

### Tình huống phụ
1. **NOARCHIVELOG:** restore được bản backup nhưng **không** apply redo sau backup → mất dòng id=3.  
2. **Mất file khi DB đóng:** `STARTUP MOUNT` → RESTORE/RECOVER → `ALTER DATABASE OPEN`.

### Giới hạn Free/Docker đã gặp
- `CONFIGURE CHANNEL` khi RMAN connected PDB → **RMAN-07536**.  
- RMAN `ALTER SESSION SET CONTAINER` → **RMAN-06815**; restore datafile từ CDB target `/` vẫn được.  
- Online move datafile → ORA-00439 (mục 7.2).

---

## Checklist nhanh
- [x] 7.2 thêm/sửa/xóa TS demo, resize, autoextend, offline move, báo cáo, chứng minh ZOO_DATA  
- [x] 7.4 profile/role/user + login thật ORA-00942  
- [x] 7.5 expdp/impdp số dòng khớp  
- [x] 7.1 4 shutdown + startup giai đoạn + RO + restricted  
- [x] 7.3 mất datafile → restore/recover thật, còn đủ 3 dòng  
