# web-dev: chạy Vue Vite (Giai đoạn 5).
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
Load-Env

$pkg = Join-Path $RootDir "zoo-web\package.json"
if (-not (Test-Path $pkg)) {
    Write-Error "Chưa có zoo-web — chờ Giai đoạn 5."
}

Set-Location (Join-Path $RootDir "zoo-web")
if (-not (Test-Path "node_modules")) {
    npm install
}
npm run dev
