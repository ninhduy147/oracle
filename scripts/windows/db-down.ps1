# db-down: dừng container (giữ volume).
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
Require-Docker

Write-Host "==> docker compose stop db"
docker compose stop db
Write-Host "==> Đã dừng. Volume zoo_oradata vẫn giữ dữ liệu."
Write-Host "    Xóa sạch: docker compose down -v"
