# setup: kiểm tra Docker, tạo .env từ .env.example.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"

# Tiếng Việt trên console Windows
try { chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==> Kiểm tra Docker..."
Require-Docker
docker --version
docker compose version

Write-Host "==> Kiến trúc: $env:PROCESSOR_ARCHITECTURE"

$envPath = Join-Path $RootDir ".env"
$example = Join-Path $RootDir ".env.example"
if (-not (Test-Path $envPath)) {
    Copy-Item $example $envPath
    Write-Host "==> Đã tạo .env từ .env.example"
} else {
    Write-Host "==> .env đã tồn tại, giữ nguyên."
}

New-Item -ItemType Directory -Force -Path (Join-Path $RootDir "backup") | Out-Null
Write-Host "==> Setup xong. Tiếp theo: .\scripts\windows\db-up.ps1"
