# api-dev: chạy FastAPI (Giai đoạn 4).
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
Load-Env

$req = Join-Path $RootDir "zoo-api\requirements.txt"
if (-not (Test-Path $req)) {
    Write-Error "Chưa có zoo-api — chờ Giai đoạn 4."
}

Set-Location (Join-Path $RootDir "zoo-api")
if (-not (Test-Path ".venv")) {
    py -3.12 -m venv .venv
}
& .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
$hostBind = if ($env:API_HOST) { $env:API_HOST } else { "0.0.0.0" }
$port = if ($env:API_PORT) { $env:API_PORT } else { "8000" }
uvicorn app.main:app --reload --host $hostBind --port $port
