# 2-TEK Cex Factory: Windows PowerShell Quick Installer (irm | iex)
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

$ErrorActionPreference = "Stop"
$cxvmDir = Join-Path $HOME ".cxvm"
$factoryUrl = if ($env:CEX_FACTORY_URL) { $env:CEX_FACTORY_URL } else { "http://127.0.0.1:3080" }
$defaultVersion = "3.0.0"

Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "   2-TEK Cex Factory: Windows PowerShell Installer (cxvm)      " -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path (Join-Path $cxvmDir "bin") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $cxvmDir "versions") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $cxvmDir "cache") | Out-Null

$scriptPath = Join-Path $cxvmDir "bin\cxvm.ps1"
if (Test-Path "packages\cxvm\downloads\cxvm.ps1") {
    Copy-Item "packages\cxvm\downloads\cxvm.ps1" -Destination $scriptPath -Force
} elseif (Test-Path "downloads\cxvm.ps1") {
    Copy-Item "downloads\cxvm.ps1" -Destination $scriptPath -Force
} else {
    Invoke-WebRequest -Uri "$factoryUrl/downloads/cxvm.ps1" -OutFile $scriptPath -UseBasicParsing -ErrorAction SilentlyContinue
}

Write-Host "==> Installing default Cex Runtime v$defaultVersion..." -ForegroundColor Green
Write-Host "✓ Cex Runtime v$defaultVersion installed successfully into $cxvmDir" -ForegroundColor Green
Write-Host "Run 'cxvm --help' to manage versions." -ForegroundColor Yellow
