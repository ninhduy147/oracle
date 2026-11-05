# Chạy dự án trên macOS (từ số 0)

Áp dụng Apple Silicon (arm64) và Intel. Đã kiểm chứng trên arm64 + Oracle 26ai Free.

## 1. Cài phần mềm

```bash
# Docker Desktop (≥ 4GB RAM trong Settings → Resources)
brew install --cask docker

# Git, Python 3.12, Node 20+
brew install git python@3.12 node

# (Tuỳ chọn) tunnel chia sẻ API
brew install cloudflare/cloudflare/cloudflared
```

Mở **Docker Desktop**, chờ engine sẵn sàng (`docker info` không lỗi).

## 2. Clone và setup

```bash
git clone <url-repo>
cd oracle   # hoặc tên thư mục repo
./scripts/mac/setup.sh
# tạo .env từ .env.example nếu chưa có
```

Sửa `.env` nếu cần (mật khẩu demo mặc định đã đủ cho local).

## 3. Khởi động Oracle

```bash
./scripts/mac/db-up.sh
# Lần đầu 5–15 phút. Theo dõi:
docker compose logs -f db
# Chờ: DATABASE IS READY TO USE
```

Nếu cổng **1521** bận: `docker ps` tìm container khác (vd `oracle26ai`) → `docker stop <tên>`.

## 4. Nạp schema

```bash
./scripts/mac/db-init.sh
# = SYS chạy 00_create_tablespace_user.sql + ZOO chạy run_all.sql
```

Kiểm tra:

```bash
./scripts/mac/sql-zoo.sh
# trong sqlplus:
SELECT COUNT(*) FROM animals;
SELECT tablespace_name FROM user_tables WHERE ROWNUM=1;
EXIT;
```

Reset sạch schema:

```bash
./scripts/mac/db-reset.sh
```

## 5. API + Web

```bash
# Terminal 1
./scripts/mac/api-dev.sh
# http://127.0.0.1:8000/docs

# Terminal 2
./scripts/mac/web-dev.sh
# http://127.0.0.1:5173
```

Tài khoản web demo (mật khẩu `Zoo@123456`): `manager01`, `vet01`, `keeper01`, `cashier01`.

## 6. Chạy bài quản trị (mục 7)

Thứ tự an toàn: **7.2 → 7.4 → 7.5 → backup volume → 7.1 → 7.3**.

```bash
./scripts/mac/admin-run.sh 02
./scripts/mac/sql-sys.sh ./admin/04_users_privileges.sql
./scripts/mac/dp-export.sh
./scripts/mac/dp-import.sh

# Sao lưu volume trước 7.1/7.3
docker compose stop db
docker run --rm -v zoo_oradata:/from:ro -v "$(pwd)/backup:/to" alpine \
  tar czf /to/zoo_oradata_backup.tgz -C /from .
docker compose start db

docker compose exec -T -e ORACLE_PWD="$(grep ORACLE_PWD .env|cut -d= -f2)" db \
  bash /admin/01_instance_lifecycle.sh
docker compose exec -T -e ORACLE_PWD="$(grep ORACLE_PWD .env|cut -d= -f2)" db \
  bash /admin/03_recovery_datafile.sh
```

Chi tiết kết quả: `docs/ADMIN_RUNBOOK.md`.

## 7. Lỗi thường gặp

| Triệu chứng | Cách xử lý |
|---|---|
| Cổng 1521 bận | `docker stop` container Oracle khác |
| Container thoát / hết RAM | Docker Desktop → Memory ≥ 4GB |
| `ORA-12514` sau SHUTDOWN | Dùng `sqlplus / as sysdba` (bequeath), không qua `@FREE` |
| Image sai kiến trúc | Đổi `ORACLE_IMAGE=gvenzl/oracle-free:latest` hoặc `--platform` |
| Tiếng Việt `???` | `export NLS_LANG=.AL32UTF8` |
| Script `.sh` lỗi lạ | `eol=lf` (đã có `.gitattributes`); tránh OneDrive/path có dấu cách |
| `python-oracledb` không cài được | Dùng package **`oracledb`** trên PyPI |
| Comment SQL sau `;` | Oracle 26ai sqlplus: **ORA-03405** — không comment cùng dòng sau `;` |

## 8. Chia sẻ API cho nhóm

```bash
./scripts/mac/tunnel.sh
# Lấy URL https://….trycloudflare.com
# Đặt VITE_API_URL và thêm origin vào CORS_ORIGINS trong .env, restart API
```
