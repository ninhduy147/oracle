# tunnel: Cloudflare Tunnel chia sẻ API.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
Load-Env

if (-not (Get-Command cloudflared -ErrorAction SilentlyContinue)) {
    Write-Error "Chưa có cloudflared. Cài: winget install --id Cloudflare.cloudflared"
}

$port = if ($env:API_PORT) { $env:API_PORT } else { "8000" }
Write-Host "==> cloudflared tunnel --url http://localhost:$port"
Write-Host "    Cập nhật VITE_API_URL và CORS_ORIGINS sau khi có URL public"
cloudflared tunnel --url "http://localhost:$port"
