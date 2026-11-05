# Hàm dùng chung cho script Windows PowerShell.
# Khi được dot-source từ scripts/windows/*.ps1, $PSScriptRoot = scripts/windows.
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RootDir = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
Set-Location $RootDir

function Load-Env {
    $envFile = Join-Path $RootDir ".env"
    if (-not (Test-Path $envFile)) {
        Write-Error "Chưa có .env — chạy .\scripts\windows\setup.ps1 trước."
    }
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $idx = $line.IndexOf("=")
        if ($idx -lt 1) { return }
        $key = $line.Substring(0, $idx).Trim()
        $val = $line.Substring($idx + 1).Trim()
        Set-Item -Path "Env:$key" -Value $val
    }
}

function Require-Docker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Không tìm thấy Docker. Cài Docker Desktop (WSL2) rồi thử lại."
    }
    docker info 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker daemon chưa chạy. Mở Docker Desktop."
    }
}

function Get-OraclePwd {
    if ($env:ORACLE_PWD) { return $env:ORACLE_PWD }
    if ($env:ORACLE_PASSWORD) { return $env:ORACLE_PASSWORD }
    return "ZooOracle_Demo1"
}
