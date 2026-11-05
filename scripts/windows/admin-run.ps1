# admin-run <số>: chạy script quản trị.
param(
    [Parameter(Mandatory = $true)]
    [string]$Number
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
Load-Env
Require-Docker

$num = $Number.PadLeft(2, "0")
$files = Get-ChildItem -Path (Join-Path $RootDir "admin") -Filter "${num}_*.sql" -ErrorAction SilentlyContinue
if (-not $files) {
    Write-Error "Không tìm thấy admin/${num}_*.sql"
}
$file = $files[0].FullName
Write-Host "==> Chạy $file"
& "$PSScriptRoot\sql-sys.ps1" -SqlFile $file
