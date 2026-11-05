# sql-sys: sqlplus SYSDBA vào FREEPDB1 (mặc định) hoặc CDB (--cdb).
# Cách dùng:
#   .\scripts\windows\sql-sys.ps1
#   .\scripts\windows\sql-sys.ps1 -Cdb
#   .\scripts\windows\sql-sys.ps1 -SqlFile .\admin\02_tablespace_datafile.sql
param(
    [switch]$Cdb,
    [string]$SqlFile = ""
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
Load-Env
Require-Docker

try { chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:NLS_LANG = ".AL32UTF8"

$pwdVal = Get-OraclePwd
$target = if ($Cdb) { "FREE" } else { "FREEPDB1" }

if ($SqlFile -ne "") {
    if (-not (Test-Path $SqlFile)) { Write-Error "Không thấy file: $SqlFile" }
    Write-Host "==> Chạy $SqlFile với SYS@$target AS SYSDBA"
    Get-Content -Raw $SqlFile | docker compose exec -T -e NLS_LANG=.AL32UTF8 db `
        bash -c "sqlplus -s sys/${pwdVal}@${target} as sysdba"
} else {
    Write-Host "==> sqlplus SYS@$target AS SYSDBA (thoát: exit)"
    docker compose exec -e NLS_LANG=.AL32UTF8 db `
        sqlplus "sys/${pwdVal}@${target} as sysdba"
}
