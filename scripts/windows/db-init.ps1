# db-init: tạo tablespace + user, nạp run_all.sql (Giai đoạn 1).
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
Load-Env
Require-Docker

$createFile = Join-Path $RootDir "db\00_create_tablespace_user.sql"
if (-not (Test-Path $createFile)) {
    Write-Error "Chưa có db/00_create_tablespace_user.sql — chờ Giai đoạn 1."
}

$pwdVal = Get-OraclePwd
$zooUser = if ($env:ORACLE_USER) { $env:ORACLE_USER } else { "ZOO" }
$zooPwd = if ($env:ORACLE_PASSWORD_ZOO) { $env:ORACLE_PASSWORD_ZOO } else { "ZooApp_Demo1" }

Write-Host "==> [1/2] Tạo tablespace + user (SYS@FREEPDB1)"
docker compose exec -T -e NLS_LANG=.AL32UTF8 db `
    bash -c "sqlplus -s sys/${pwdVal}@FREEPDB1 as sysdba @/db/00_create_tablespace_user.sql"

Write-Host "==> [2/2] Nạp schema ZOO"
docker compose exec -T -e NLS_LANG=.AL32UTF8 db `
    bash -c "sqlplus -s ${zooUser}/${zooPwd}@FREEPDB1 @/db/run_all.sql"

Write-Host "==> db-init xong."
