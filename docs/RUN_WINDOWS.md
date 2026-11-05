# Chạy dự án trên Windows (từ số 0)

Khuyến nghị: **Docker Desktop + WSL2 (Ubuntu)**. Các script `.sh` chạy trong WSL. File `.ps1` chỉ là bọc gọi sang WSL.

## 1. Cài phần mềm

1. Cài [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) → bật **Use WSL 2 based engine**.
2. Cài WSL2 + Ubuntu từ Microsoft Store; mở Ubuntu lần đầu để tạo user.
3. Trong Ubuntu:

```bash
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip
# Node 20+
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

4. Clone repo **trong filesystem Linux** (tránh `/mnt/c/...` — chậm + lỗi LF):

```bash
cd ~
git clone <url-repo>
cd oracle
```

## 2. Setup

```bash
chmod +x scripts/mac/*.sh scripts/common/*.sh
./scripts/mac/setup.sh
# hoặc từ PowerShell (đã cài WSL):
.\scripts\win\setup.ps1
```

Copy `.env.example` → `.env` nếu chưa có.

## 3. Oracle + schema

```bash
./scripts/mac/db-up.sh
./scripts/mac/db-init.sh
```

Từ PowerShell (tương đương):

```powershell
.\scripts\win\db-up.ps1
.\scripts\win\db-init.ps1
```

## 4. API + Web

Trong WSL:

```bash
./scripts/mac/api-dev.sh   # :8000
./scripts/mac/web-dev.sh   # :5173
```

Hoặc PowerShell: `api-dev.ps1` / `web-dev.ps1`.

Mở trình duyệt Windows: `http://127.0.0.1:5173` (Docker Desktop forward cổng).

Đăng nhập demo: `manager01` / `Zoo@123456` (và `vet01`, `keeper01`, `cashier01`).

## 5. Bài quản trị

Giống macOS — chạy trong WSL:

```bash
./scripts/mac/admin-run.sh 02
./scripts/mac/sql-sys.sh ./admin/04_users_privileges.sql
./scripts/mac/dp-export.sh
./scripts/mac/dp-import.sh
# Backup volume rồi mới chạy 01 / 03 — xem RUN_MACOS.md mục 6
```

PowerShell: `admin-run.ps1`, `dp-export.ps1`, `dp-import.ps1`.

## 6. Lỗi thường gặp trên Windows

| Triệu chứng | Cách xử lý |
|---|---|
| Script lỗi `^M` / không chạy | Repo phải `eol=lf` (đã có `.gitattributes`); clone lại trong WSL `~/` |
| Docker không thấy từ WSL | Docker Desktop → Settings → Resources → WSL Integration → bật distro |
| Cổng 1521/8000/5173 bận | `netstat -ano` / tắt process hoặc đổi map trong compose |
| Antivirus khoá volume | Thêm exception thư mục Docker WSL data |
| Path OneDrive / khoảng trắng | Đưa project ra `~/oracle` trong WSL |
| Hyper-V / WSL chưa bật | Bật trong “Turn Windows features on or off” |
| `sqlplus` encoding | `export NLS_LANG=.AL32UTF8` trong shell WSL |

## 7. Ghi chú cho người Mac / Windows cùng nhóm

- Schema và script SQL **giống nhau**; chỉ khác cách gọi shell.
- File dump Data Pump và backup volume nên để trong `backup/` (đã `.gitignore`).
- Khi demo GV: ưu tiên máy đã chạy ổn (thường Mac của trưởng nhóm) + tunnel nếu cần.
