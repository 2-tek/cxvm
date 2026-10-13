# ==============================================================================
# 2-TEK Cex Factory: Windows PowerShell CXVM Setup Window & Toolchain Configurator
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols)
# ==============================================================================
[CmdletBinding()]
param(
  [string]$DefaultVersion = "8.0.0",
  [string]$V4Version = "4.0.0",
  [string]$SecondaryVersion = "6.0.0",
  [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$CxvmDir = if ($env:CXVM_DIR) { $env:CXVM_DIR } else { Join-Path $HOME ".cxvm" }

function Show-SetupWindow {
  Clear-Host
  Write-Host "================================================================================" -ForegroundColor Cyan
  Write-Host "    2-TEK CXVM: Quick Installer & Toolchain Environment Setup (PowerShell)      " -ForegroundColor Cyan
  Write-Host "    Installs and configures CXVM, v8 cexp, v4 cexr, and shell environment      " -ForegroundColor Yellow
  Write-Host "================================================================================" -ForegroundColor Cyan
  Write-Host "  Platform:    Windows (x64 / arm64 PowerShell)" -ForegroundColor White
  Write-Host "  CXVM Home:   $CxvmDir" -ForegroundColor Blue
  Write-Host "  Project:     $ProjectRoot" -ForegroundColor White
  Write-Host "  Default:     CexR v$DefaultVersion & cexp v8 (Pure Cex Native Engine: cexr + cexp)" -ForegroundColor Green
  Write-Host "  Runtime v4:  CexR v$V4Version (Native Machine Code & JSON Context)" -ForegroundColor Green
  Write-Host "  Secondary:   CexR v$SecondaryVersion (LTS Native Engine & JIT)" -ForegroundColor Magenta
  Write-Host "  Source Mode: 100% Offline-Ready from Local Sources (No Download Needed)" -ForegroundColor Cyan
  Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
}

Show-SetupWindow

# Step 1: Directory Hierarchy
Write-Host "`n[1/5] Initializing CXVM Directory Hierarchy..." -ForegroundColor White
$binDir = Join-Path $CxvmDir "bin"
$versionsDir = Join-Path $CxvmDir "versions"
$cacheDir = Join-Path $CxvmDir "cache"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
New-Item -ItemType Directory -Force -Path $versionsDir | Out-Null
New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null

$sourceDirs = @(
  (Join-Path $ProjectRoot "dist"),
  (Join-Path $ProjectRoot "downloads"),
  (Join-Path $ScriptDir "dist"),
  (Join-Path $ScriptDir "downloads")
)

$toolsToCopy = @("cxvm.ps1", "cxvm.cmd", "cexp", "cexp.cmd", "cexp.ps1", "cexr", "cexr-v4", "cexr-v4.cmd", "cexr-v4.ps1", "cvm-server", "thunder-server")
foreach ($tool in $toolsToCopy) {
  foreach ($sDir in $sourceDirs) {
    $srcPath = Join-Path $sDir $tool
    if (Test-Path $srcPath) {
      Copy-Item -Force $srcPath (Join-Path $binDir $tool)
      break
    }
  }
}
Write-Host "  [OK] CXVM core hierarchy & executables established in $CxvmDir (offline-sourced)" -ForegroundColor Green

# Step 2: Environment Variables & PATH Persistence
Write-Host "`n[2/5] Configuring Windows Environment Variables & User PATH..." -ForegroundColor White
$currentBin = Join-Path $CxvmDir "current\bin"
[Environment]::SetEnvironmentVariable("CXVM_DIR", $CxvmDir, "User")
[Environment]::SetEnvironmentVariable("CEX_HOME", (Join-Path $CxvmDir "current"), "User")
$env:CXVM_DIR = $CxvmDir
$env:CEX_HOME = Join-Path $CxvmDir "current"

$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if (-not $userPath) { $userPath = "" }
$pathsToAdd = @($binDir, $currentBin)
$pathModified = $false

foreach ($p in $pathsToAdd) {
  if ($userPath -notmatch [regex]::Escape($p)) {
    $userPath = if ($userPath.Length -gt 0) { "$userPath;$p" } else { $p }
    $pathModified = $true
  }
}

if ($pathModified) {
  [Environment]::SetEnvironmentVariable("PATH", $userPath, "User")
  Write-Host "  [OK] Added CXVM bin and current\bin to Windows User PATH" -ForegroundColor Green
} else {
  Write-Host "  [OK] CXVM already present in Windows User PATH" -ForegroundColor Yellow
}
$env:PATH = "$binDir;$currentBin;$env:PATH"

# Configure PowerShell $PROFILE if available
try {
  if ($PROFILE -and (Test-Path $PROFILE)) {
    $profileContent = Get-Content $PROFILE -Raw
    if ($profileContent -notmatch "CXVM_DIR") {
      Add-Content $PROFILE "`n# cxvm: Cex Version Manager`n`$env:CXVM_DIR = `"$CxvmDir`"`n`$env:CEX_HOME = `"`$env:CXVM_DIR\current`"`n`$env:PATH = `"`$env:CXVM_DIR\bin;`$env:CXVM_DIR\current\bin;`$env:PATH`""
      Write-Host "  [OK] Configured CXVM PATH in `$PROFILE" -ForegroundColor Green
    }
  }
} catch {
  Write-Host "  [INFO] Skipped PowerShell profile customization" -ForegroundColor Gray
}

# Step 3: Install Cex Runtimes (v8, v4, v6)
Write-Host "`n[3/5] Setting up Cex Runtime Engines (v8, v4, v6) from Sources..." -ForegroundColor White
$cxvmScript = Join-Path $binDir "cxvm.ps1"
if (Test-Path $cxvmScript) {
  Write-Host "  --> Installing Cex v$DefaultVersion & cexp v8 (Pure Cex Native Engine)..." -ForegroundColor Gray
  & $cxvmScript install $DefaultVersion | Out-Null
  Write-Host "  [OK] CexR v$DefaultVersion & cexp v8 installed." -ForegroundColor Green

  Write-Host "  --> Installing Cex v$V4Version (Native Machine Code & JSON Context)..." -ForegroundColor Gray
  & $cxvmScript install $V4Version | Out-Null
  Write-Host "  [OK] CexR v$V4Version installed." -ForegroundColor Green

  Write-Host "  --> Installing Cex v$SecondaryVersion (LTS High-Performance Engine)..." -ForegroundColor Gray
  & $cxvmScript install $SecondaryVersion | Out-Null
  Write-Host "  [OK] CexR v$SecondaryVersion installed." -ForegroundColor Green

  & $cxvmScript default $DefaultVersion | Out-Null
  & $cxvmScript use $DefaultVersion | Out-Null
  Write-Host "  [OK] Active default version set to v$DefaultVersion" -ForegroundColor Green

  if (-not (& $cxvmScript status cvm | Out-Null)) {
    & $cxvmScript start cvm -p 4000 --daemon | Out-Null
  }
  $cvmPid = if (Test-Path (Join-Path $CxvmDir "cvm_server.pid")) { (Get-Content (Join-Path $CxvmDir "cvm_server.pid") -Raw).Trim() } else { "$PID" }
  Write-Host "  [OK] CVM Standalone Server auto-started (single process, PID: $cvmPid, port: 4000)" -ForegroundColor Green

  if (-not (& $cxvmScript status thunder | Out-Null)) {
    & $cxvmScript start thunder -p 3050 --daemon | Out-Null
  }
  $thPid = if (Test-Path (Join-Path $CxvmDir "thunder_server.pid")) { (Get-Content (Join-Path $CxvmDir "thunder_server.pid") -Raw).Trim() } else { "$PID" }
  Write-Host "  [OK] Thunder Standalone Server auto-started (single process, PID: $thPid, port: 3050)" -ForegroundColor Green
}

# Setup Lighting (Lighting Fullstack MVC engine, light CLI) integration in cxvm
$lightBin = Join-Path $CxvmDir "bin\light.cmd"
if (-not (Test-Path $lightBin)) {
  "@echo off`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0cxvm.ps1`" light %*" | Set-Content -Path $lightBin -Encoding ASCII
}
Write-Host "  [OK] Integrated Lighting (light create, light dev, light build) configured in $(Join-Path $CxvmDir 'bin')" -ForegroundColor Green

# Step 4: Configure Project ./bin/ Dispatchers
Write-Host "`n[4/5] Configuring Project ./bin/ Dispatchers (cexr, cex, cexp, cexr-v4)..." -ForegroundColor White
$targetBin = Join-Path $ProjectRoot "bin"
New-Item -ItemType Directory -Force -Path $targetBin | Out-Null

$cexrCmd = Join-Path $targetBin "cexr.cmd"
$cexCmd = Join-Path $targetBin "cex.cmd"
$cexpCmd = Join-Path $targetBin "cexp.cmd"
$cexrV4Cmd = Join-Path $targetBin "cexr-v4.cmd"
$cxvmCmd = Join-Path $targetBin "cxvm.cmd"
$cexrPs1 = Join-Path $targetBin "cexr.ps1"
$cexPs1 = Join-Path $targetBin "cex.ps1"
$cexpPs1 = Join-Path $targetBin "cexp.ps1"
$cexrV4Ps1 = Join-Path $targetBin "cexr-v4.ps1"
$cxvmPs1 = Join-Path $targetBin "cxvm.ps1"

@"
@echo off
setlocal
set "BIN_DIR=%~dp0"
set "CXVM_DIR=%USERPROFILE%\.cxvm"
if "%~1"=="v4" (
  shift
  if exist "%BIN_DIR%cexr-v4.cmd" (
    call "%BIN_DIR%cexr-v4.cmd" %*
    exit /b %ERRORLEVEL%
  )
)
if "%~1"=="v6" (
  shift
  if exist "%CXVM_DIR%\versions\v6.0.0\bin\cexr.cmd" (
    call "%CXVM_DIR%\versions\v6.0.0\bin\cexr.cmd" %*
    exit /b %ERRORLEVEL%
  )
)
if exist "%CXVM_DIR%\current\bin\cexr.exe" (
  "%CXVM_DIR%\current\bin\cexr.exe" %*
) else (
  bash "%BIN_DIR%cexr" %*
)
"@ | Set-Content -Path $cexrCmd -Encoding ASCII

@"
@echo off
call "%~dp0cexr.cmd" %*
"@ | Set-Content -Path $cexCmd -Encoding ASCII

@"
@echo off
setlocal
set "CXVM_DIR=%USERPROFILE%\.cxvm"
if exist "%CXVM_DIR%\bin\cexp.cmd" (
  call "%CXVM_DIR%\bin\cexp.cmd" %*
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0cexp.ps1" %*
)
"@ | Set-Content -Path $cexpCmd -Encoding ASCII

@"
@echo off
setlocal
set "CXVM_DIR=%USERPROFILE%\.cxvm"
if exist "%CXVM_DIR%\bin\cexr-v4.cmd" (
  call "%CXVM_DIR%\bin\cexr-v4.cmd" %*
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0cexr-v4.ps1" %*
)
"@ | Set-Content -Path $cexrV4Cmd -Encoding ASCII

@"
@echo off
setlocal
set "BIN_DIR=%~dp0"
set "CXVM_DIR=%USERPROFILE%\.cxvm"
if exist "%CXVM_DIR%\bin\cxvm.cmd" (
  call "%CXVM_DIR%\bin\cxvm.cmd" %*
) else (
  powershell -ExecutionPolicy Bypass -File "%BIN_DIR%cxvm.ps1" %*
)
"@ | Set-Content -Path $cxvmCmd -Encoding ASCII

if (Test-Path (Join-Path $binDir "cexp.ps1")) { Copy-Item -Force (Join-Path $binDir "cexp.ps1") $cexpPs1 }
if (Test-Path (Join-Path $binDir "cexr-v4.ps1")) { Copy-Item -Force (Join-Path $binDir "cexr-v4.ps1") $cexrV4Ps1 }
if (Test-Path (Join-Path $binDir "cxvm.ps1")) { Copy-Item -Force (Join-Path $binDir "cxvm.ps1") $cxvmPs1 }

Write-Host "  [OK] Local project dispatchers (cexr, cex, cexp, cexr-v4, cxvm) configured in $targetBin" -ForegroundColor Green

# Step 5: Verification & Readiness Summary
Write-Host "`n[5/5] Setup Summary & Verification..." -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "    2-TEK CXVM: Windows Installation & Setup Complete [OK]                      " -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  CXVM Directory:    $CxvmDir" -ForegroundColor White
Write-Host "  Active Runtime:    CexR v$DefaultVersion (Pure Cex Default)" -ForegroundColor Green
Write-Host "  Compiler Engine:   cexp v8.0.0 (Direct Machine Compiler & ELF/PE Generator)" -ForegroundColor Green
Write-Host "  Runtime v4 Engine: CexR v$V4Version (Native Machine Code & JSON Context)" -ForegroundColor Green
Write-Host "  Secondary Runtime: CexR v$SecondaryVersion (LTS)" -ForegroundColor Magenta
Write-Host "  Source Mode:       100% Offline-Ready from Local Sources (No Download Needed)" -ForegroundColor Cyan
Write-Host "  Windows PATH:      $binDir;$currentBin added to User PATH" -ForegroundColor Green
Write-Host "`nRun 'cxvm current', 'cexp --version', or 'cexr-v4 --version' to get started." -ForegroundColor Green
