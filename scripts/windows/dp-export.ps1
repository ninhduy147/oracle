# dp-export: Data Pump export (Giai đoạn 3).
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
Load-Env
Require-Docker

$script = Join-Path $RootDir "admin\05_datapump_export.sh"
if (-not (Test-Path $script)) {
    Write-Error "Chưa có admin/05_datapump_export.sh — chờ Giai đoạn 3."
}
bash $script
