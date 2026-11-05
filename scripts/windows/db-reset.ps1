# db-reset: xóa sạch schema ZOO rồi nạp lại.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
Load-Env
Require-Docker

$resetFile = Join-Path $RootDir "db\01_reset.sql"
if (-not (Test-Path $resetFile)) {
    Write-Error "Chưa có db/01_reset.sql — chờ Giai đoạn 1."
}

$zooUser = if ($env:ORACLE_USER) { $env:ORACLE_USER } else { "ZOO" }
$zooPwd = if ($env:ORACLE_PASSWORD_ZOO) { $env:ORACLE_PASSWORD_ZOO } else { "ZooApp_Demo1" }

Write-Host "==> Reset schema ZOO..."
docker compose exec -T -e NLS_LANG=.AL32UTF8 db `
    bash -c "sqlplus -s ${zooUser}/${zooPwd}@FREEPDB1 @/db/01_reset.sql"

& "$PSScriptRoot\db-init.ps1"
