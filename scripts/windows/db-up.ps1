# db-up: khởi động container Oracle.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
Load-Env
Require-Docker

Write-Host "==> Image: $($env:ORACLE_IMAGE)"
Write-Host "==> docker compose up -d db"
docker compose up -d db

Write-Host ""
Write-Host "==> Đợi Oracle sẵn sàng (lần đầu có thể 5–15 phút)..."
Write-Host "    Theo dõi: docker compose logs -f db"
Write-Host "    Báo hiệu: DATABASE IS READY TO USE"
Write-Host ""

$ready = $false
for ($i = 1; $i -le 120; $i++) {
    $logs = docker compose logs db 2>$null | Out-String
    if ($logs -match "DATABASE IS READY TO USE") {
        $ready = $true
        break
    }
    $status = "starting"
    try {
        $status = docker inspect --format="{{.State.Health.Status}}" zoo-oracle 2>$null
    } catch {}
    if ($status -eq "healthy") {
        $ready = $true
        break
    }
    Write-Host "`r    [$i/120] trạng thái=$status ..." -NoNewline
    Start-Sleep -Seconds 10
}
Write-Host ""

if ($ready) {
    Write-Host "==> Oracle đã sẵn sàng. Thử: .\scripts\windows\sql-sys.ps1"
} else {
    Write-Error "Hết thời gian chờ. Kiểm tra: docker compose logs db"
}
