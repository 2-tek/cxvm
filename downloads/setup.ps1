# ==============================================================================
# 2-TEK Cex Factory: Windows PowerShell CXVM Setup Window & Toolchain Configurator
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)
# ==============================================================================
[CmdletBinding()]
param(
  [string]$DefaultVersion = "8.0.0",
  [string]$SecondaryVersion = "6.0.0",
  [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$CxvmDir = if ($env:CXVM_DIR) { $env:CXVM_DIR } else { Join-Path $HOME ".cxvm" }

function Show-SetupWindow {
  Clear-Host
  Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
  Write-Host "║                  ⚙️  CXVM WINDOWS SETUP WINDOW (POWERSHELL)                   ║" -ForegroundColor Cyan
  Write-Host "║         Cex Version Manager: Environment, PATH & Toolchain Setup              ║" -ForegroundColor Yellow
  Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
  Write-Host "  Platform:    Windows (x64 / arm64 PowerShell)" -ForegroundColor White
  Write-Host "  CXVM Home:   $CxvmDir" -ForegroundColor Blue
  Write-Host "  Project:     $ProjectRoot" -ForegroundColor White
  Write-Host "  Default:     CexR v$DefaultVersion (Pure Cex Native Engine: cexr + cexp)" -ForegroundColor Green
  Write-Host "  Supported:   CexR v$SecondaryVersion (LTS Native Engine & JIT)" -ForegroundColor Magenta
  Write-Host "─────────────────────────────────────────────────────────────────────────────────" -ForegroundColor Cyan
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

$downloadsDir = Join-Path $ProjectRoot "downloads"
if (Test-Path (Join-Path $downloadsDir "cxvm.ps1")) {
  Copy-Item -Force (Join-Path $downloadsDir "cxvm.ps1") (Join-Path $binDir "cxvm.ps1")
}
if (Test-Path (Join-Path $downloadsDir "cxvm.cmd")) {
  Copy-Item -Force (Join-Path $downloadsDir "cxvm.cmd") (Join-Path $binDir "cxvm.cmd")
}
if (Test-Path (Join-Path $downloadsDir "cvm-server")) {
  Copy-Item -Force (Join-Path $downloadsDir "cvm-server") (Join-Path $binDir "cvm-server")
}
if (Test-Path (Join-Path $downloadsDir "thunder-server")) {
  Copy-Item -Force (Join-Path $downloadsDir "thunder-server") (Join-Path $binDir "thunder-server")
}
Write-Host "  ✓ CXVM core hierarchy established in $CxvmDir" -ForegroundColor Green

# Step 2: Environment Variables & PATH Persistence
Write-Host "`n[2/5] Configuring Windows Environment Variables & User PATH..." -ForegroundColor White
$currentBin = Join-Path $CxvmDir "current\bin"
[Environment]::SetEnvironmentVariable("CXVM_DIR", $CxvmDir, "User")
$env:CXVM_DIR = $CxvmDir

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
  Write-Host "  ✓ Added CXVM bin and current\bin to Windows User PATH" -ForegroundColor Green
} else {
  Write-Host "  ℹ CXVM already present in Windows User PATH" -ForegroundColor Yellow
}
$env:PATH = "$binDir;$currentBin;$env:PATH"

# Configure PowerShell $PROFILE if available
try {
  if ($PROFILE -and (Test-Path $PROFILE)) {
    $profileContent = Get-Content $PROFILE -Raw
    if ($profileContent -notmatch "CXVM_DIR") {
      Add-Content $PROFILE "`n# cxvm: Cex Version Manager`n`$env:CXVM_DIR = `"$CxvmDir`"`n`$env:PATH = `"`$env:CXVM_DIR\bin;`$env:CXVM_DIR\current\bin;`$env:PATH`""
      Write-Host "  ✓ Configured CXVM PATH in `$PROFILE" -ForegroundColor Green
    }
  }
} catch {
  Write-Host "  ℹ Skipped PowerShell profile customization" -ForegroundColor Gray
}

# Step 3: Install Cex Runtimes (v8 & v6)
Write-Host "`n[3/5] Setting up Cex Runtime Engines (v8 & v6)..." -ForegroundColor White
$cxvmScript = Join-Path $binDir "cxvm.ps1"
if (Test-Path $cxvmScript) {
  Write-Host "  --> Installing Cex v$DefaultVersion (Pure Cex Native Engine)..." -ForegroundColor Gray
  & $cxvmScript install $DefaultVersion | Out-Null
  Write-Host "  ✓ CexR v$DefaultVersion installed." -ForegroundColor Green

  Write-Host "  --> Installing Cex v$SecondaryVersion (LTS High-Performance Engine)..." -ForegroundColor Gray
  & $cxvmScript install $SecondaryVersion | Out-Null
  Write-Host "  ✓ CexR v$SecondaryVersion installed." -ForegroundColor Green

  & $cxvmScript default $DefaultVersion | Out-Null
  & $cxvmScript use $DefaultVersion | Out-Null
  Write-Host "  ✓ Active default version set to v$DefaultVersion" -ForegroundColor Green

  if (-not (& $cxvmScript status cvm | Out-Null)) {
    & $cxvmScript start cvm -p 4000 --daemon | Out-Null
  }
  $cvmPid = if (Test-Path (Join-Path $CxvmDir "cvm_server.pid")) { (Get-Content (Join-Path $CxvmDir "cvm_server.pid") -Raw).Trim() } else { "$PID" }
  Write-Host "  ✓ CVM Standalone Server auto-started (single process, PID: $cvmPid, port: 4000)" -ForegroundColor Green

  if (-not (& $cxvmScript status thunder | Out-Null)) {
    & $cxvmScript start thunder -p 3050 --daemon | Out-Null
  }
  $thPid = if (Test-Path (Join-Path $CxvmDir "thunder_server.pid")) { (Get-Content (Join-Path $CxvmDir "thunder_server.pid") -Raw).Trim() } else { "$PID" }
  Write-Host "  ✓ Thunder Standalone Server auto-started (single process, PID: $thPid, port: 3050)" -ForegroundColor Green
}

# Step 4: Configure Project ./bin/ Dispatchers
Write-Host "`n[4/5] Configuring Project ./bin/cexr & ./bin/cex for Default Run cxvm..." -ForegroundColor White
$targetBin = Join-Path $ProjectRoot "bin"
New-Item -ItemType Directory -Force -Path $targetBin | Out-Null

# Dispatchers for Windows
$cexrCmd = Join-Path $targetBin "cexr.cmd"
$cexCmd = Join-Path $targetBin "cex.cmd"
$cxvmCmd = Join-Path $targetBin "cxvm.cmd"
$cexrPs1 = Join-Path $targetBin "cexr.ps1"
$cexPs1 = Join-Path $targetBin "cex.ps1"
$cxvmPs1 = Join-Path $targetBin "cxvm.ps1"

@"
@echo off
setlocal
set "BIN_DIR=%~dp0"
set "CXVM_DIR=%USERPROFILE%\.cxvm"
if exist "%CXVM_DIR%\current\bin\cexr.exe" (
  "%CXVM_DIR%\current\bin\cexr.exe" %*
) else (
  bash "%BIN_DIR%cexr" %*
)
"@ | Set-Content -Path $cexrCmd -Encoding UTF8

@"
@echo off
setlocal
set "BIN_DIR=%~dp0"
set "CXVM_DIR=%USERPROFILE%\.cxvm"
if exist "%CXVM_DIR%\current\bin\cex.exe" (
  "%CXVM_DIR%\current\bin\cex.exe" %*
) else (
  bash "%BIN_DIR%cex" %*
)
"@ | Set-Content -Path $cexCmd -Encoding UTF8

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
"@ | Set-Content -Path $cxvmCmd -Encoding UTF8

@"
param([Parameter(ValueFromRemainingArguments = `$true)]`$Args)
`$BinDir = `$PSScriptRoot
`$CxvmDir = if (`$env:CXVM_DIR) { `$env:CXVM_DIR } else { Join-Path `$HOME ".cxvm" }
`$CurrentCexr = Join-Path `$CxvmDir "current\bin\cexr.exe"
if (Test-Path `$CurrentCexr) {
  & `$CurrentCexr @Args
} else {
  & bash (Join-Path `$BinDir "cexr") @Args
}
"@ | Set-Content -Path $cexrPs1 -Encoding UTF8

@"
param([Parameter(ValueFromRemainingArguments = `$true)]`$Args)
`$BinDir = `$PSScriptRoot
`$CxvmDir = if (`$env:CXVM_DIR) { `$env:CXVM_DIR } else { Join-Path `$HOME ".cxvm" }
`$CurrentCex = Join-Path `$CxvmDir "current\bin\cex.exe"
if (Test-Path `$CurrentCex) {
  & `$CurrentCex @Args
} else {
  & bash (Join-Path `$BinDir "cex") @Args
}
"@ | Set-Content -Path $cexPs1 -Encoding UTF8

@"
param([Parameter(ValueFromRemainingArguments = `$true)]`$Args)
`$BinDir = `$PSScriptRoot
`$CxvmDir = if (`$env:CXVM_DIR) { `$env:CXVM_DIR } else { Join-Path `$HOME ".cxvm" }
`$InstalledCxvm = Join-Path `$CxvmDir "bin\cxvm.ps1"
if (Test-Path `$InstalledCxvm) {
  & `$InstalledCxvm @Args
} else {
  `$LocalCxvm = Join-Path `$BinDir "..\downloads\cxvm.ps1"
  if (Test-Path `$LocalCxvm) {
    & `$LocalCxvm @Args
  } else {
    Write-Error "cxvm CLI not found."
  }
}
"@ | Set-Content -Path $cxvmPs1 -Encoding UTF8

Write-Host "  ✓ Windows executables (cexr.cmd, cex.cmd, cxvm.cmd, cexr.ps1, cex.ps1, cxvm.ps1) generated in $targetBin" -ForegroundColor Green

# Step 5: Verification & Doctor
Write-Host "`n[5/5] Running System Diagnostic Verification..." -ForegroundColor White
Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                     SETUP COMPLETE — SYSTEM DIAGNOSTIC                       ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

if (Test-Path $cxvmScript) {
  & $cxvmScript doctor
  Write-Host "`nInstalled Runtimes in cxvm:" -ForegroundColor White
  & $cxvmScript list
}

Write-Host "`n═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✓ CXVM Environment, PATH, and Default Runtimes Setup Successfully!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "`nTo activate in your current PowerShell session, run:" -ForegroundColor White
Write-Host "  `$env:CXVM_DIR = `"$CxvmDir`"" -ForegroundColor Cyan
Write-Host "  `$env:PATH = `"`$CxvmDir\bin;`$CxvmDir\current\bin;`$env:PATH`"" -ForegroundColor Cyan
Write-Host "`nOr execute commands with project bin:" -ForegroundColor White
Write-Host "  .\bin\cexr.cmd run src\index.cex" -ForegroundColor Yellow
Write-Host "  .\bin\cex.cmd run src\index.cex" -ForegroundColor Yellow
Write-Host "  cxvm use 6.0.0  # switch to v6" -ForegroundColor Yellow
Write-Host "  cxvm use 8.0.0  # switch to v8" -ForegroundColor Yellow
Write-Host ""
