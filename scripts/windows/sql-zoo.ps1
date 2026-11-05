# sql-zoo: sqlplus user ZOO vào FREEPDB1.
param(
    [string]$SqlFile = ""
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
Load-Env
Require-Docker

try { chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:NLS_LANG = ".AL32UTF8"

$zooUser = if ($env:ORACLE_USER) { $env:ORACLE_USER } else { "ZOO" }
$zooPwd = if ($env:ORACLE_PASSWORD_ZOO) { $env:ORACLE_PASSWORD_ZOO } else { "ZooApp_Demo1" }
$service = if ($env:ORACLE_SERVICE) { $env:ORACLE_SERVICE } else { "FREEPDB1" }

if ($SqlFile -ne "") {
    if (-not (Test-Path $SqlFile)) { Write-Error "Không thấy file: $SqlFile" }
    Write-Host "==> Chạy $SqlFile với ${zooUser}@${service}"
    Get-Content -Raw $SqlFile | docker compose exec -T -e NLS_LANG=.AL32UTF8 db `
        bash -c "sqlplus -s ${zooUser}/${zooPwd}@${service}"
} else {
    Write-Host "==> sqlplus ${zooUser}@${service}"
    docker compose exec -e NLS_LANG=.AL32UTF8 db `
        sqlplus "${zooUser}/${zooPwd}@${service}"
}
