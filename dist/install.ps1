# 2-TEK Cex Factory: Windows PowerShell Quick Installer (irm | iex)
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

$ErrorActionPreference = "Stop"
$cxvmDir = Join-Path $HOME ".cxvm"
$githubRawUrl = "https://raw.githubusercontent.com/2-tek/cxvm/main"
$factoryUrl = if ($env:CEX_FACTORY_URL) { $env:CEX_FACTORY_URL } else { $githubRawUrl }
$defaultVersion = "8.0.0"
$env:CEX_FACTORY_URL = $factoryUrl

Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "   2-TEK Cex Factory: Windows PowerShell Installer (cxvm)      " -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path (Join-Path $cxvmDir "bin") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $cxvmDir "versions") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $cxvmDir "cache") | Out-Null

$scriptPath = Join-Path $cxvmDir "bin\cxvm.ps1"
$cmdPath = Join-Path $cxvmDir "bin\cxvm.cmd"

if (Test-Path "cxvm\downloads\cxvm.ps1") {
    Copy-Item "cxvm\downloads\cxvm.ps1" -Destination $scriptPath -Force
} elseif (Test-Path "packages\cxvm\downloads\cxvm.ps1") {
    Copy-Item "packages\cxvm\downloads\cxvm.ps1" -Destination $scriptPath -Force
} elseif (Test-Path "downloads\cxvm.ps1") {
    Copy-Item "downloads\cxvm.ps1" -Destination $scriptPath -Force
} else {
    Invoke-WebRequest -Uri "$factoryUrl/downloads/cxvm.ps1" -OutFile $scriptPath -UseBasicParsing -ErrorAction SilentlyContinue
}

if (Test-Path "cxvm\downloads\cxvm.cmd") {
    Copy-Item "cxvm\downloads\cxvm.cmd" -Destination $cmdPath -Force
} elseif (Test-Path "downloads\cxvm.cmd") {
    Copy-Item "downloads\cxvm.cmd" -Destination $cmdPath -Force
} else {
    Invoke-WebRequest -Uri "$factoryUrl/downloads/cxvm.cmd" -OutFile $cmdPath -UseBasicParsing -ErrorAction SilentlyContinue
}

if (Test-Path "downloads\cvm-server") {
    Copy-Item "downloads\cvm-server" -Destination (Join-Path $cxvmDir "bin\cvm-server") -Force
} else {
    Invoke-WebRequest -Uri "$factoryUrl/downloads/cvm-server" -OutFile (Join-Path $cxvmDir "bin\cvm-server") -UseBasicParsing -ErrorAction SilentlyContinue
}

if (Test-Path "downloads\thunder-server") {
    Copy-Item "downloads\thunder-server" -Destination (Join-Path $cxvmDir "bin\thunder-server") -Force
} else {
    Invoke-WebRequest -Uri "$factoryUrl/downloads/thunder-server" -OutFile (Join-Path $cxvmDir "bin\thunder-server") -UseBasicParsing -ErrorAction SilentlyContinue
}

Write-Host "==> Installing default Cex Runtime v$defaultVersion via cxvm..." -ForegroundColor Green
if (Test-Path $scriptPath) {
    & $scriptPath -Command "install" -Version $defaultVersion
    & $scriptPath -Command "use" -Version $defaultVersion
}

$binDir = Join-Path $cxvmDir "bin"
$currentBin = Join-Path $cxvmDir "current\bin"
if ($env:PATH -notlike "*$binDir*") {
    $env:PATH = "$binDir;$currentBin;$env:PATH"
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host "  [OK] Cex Runtime v$defaultVersion (CexR v8) installed via cxvm!    " -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Green
Write-Host "Activate in PowerShell session:" -ForegroundColor Yellow
Write-Host "  `$env:CXVM_DIR = `"$cxvmDir`"" -ForegroundColor Yellow
Write-Host "  `$env:PATH = `"`$env:CXVM_DIR\bin;`$env:CXVM_DIR\current\bin;`$env:PATH`"" -ForegroundColor Yellow
Write-Host "Run 'cxvm --help' or 'cexr --version' to get started." -ForegroundColor Green
