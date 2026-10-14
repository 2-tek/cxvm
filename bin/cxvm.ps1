# 2-TEK cxvm CLI Windows PowerShell Launcher
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)
$cxvmDir = if ($env:CXVM_DIR) { $env:CXVM_DIR } else { Join-Path $HOME ".cxvm" }
$installedCxvm = Join-Path $cxvmDir "bin\cxvm.ps1"
if (Test-Path $installedCxvm) {
  & $installedCxvm @args
} else {
  $repoDir = Split-Path -Parent $PSScriptRoot
  $distCxvm = Join-Path $repoDir "dist\cxvm.ps1"
  $localCxvm = Join-Path $repoDir "downloads\cxvm.ps1"
  if (Test-Path $distCxvm) {
    & $distCxvm @args
  } elseif (Test-Path $localCxvm) {
    & $localCxvm @args
  } else {
    Write-Error "cxvm CLI not found. Run scripts/setup.ps1"
    exit 1
  }
}
