# 7.3 Khôi phục datafile bị mất

Làm trên tablespace thử **ZOO_TEST** (không đụng ZOO_DATA).

## Tình huống phụ (runbook)
1. **NOARCHIVELOG + mất datafile khi OPEN:** không recover được tới thời điểm hiện tại bằng redo; chỉ restore backup cũ (mất dữ liệu sau backup) hoặc dựng lại tablespace.
2. **Mất datafile khi DB đang đóng:** `STARTUP` sẽ báo thiếu file; `STARTUP MOUNT` → `RESTORE/RECOVER DATAFILE` → `ALTER DATABASE OPEN`.

## Script
```bash
docker compose exec -T -e ORACLE_PWD=... db bash /admin/03_recovery_datafile.sh
```
