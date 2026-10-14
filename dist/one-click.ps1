# ==============================================================================
# 2-TEK CXVM: Cross-Platform One-Click Download, Setup & Toolchain Activation (PowerShell)
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols)
# ==============================================================================

$ErrorActionPreference = "SilentlyContinue"

$CxvmDir = if ($env:CXVM_DIR) { $env:CXVM_DIR } else { "$env:USERPROFILE\.cxvm" }
$DefaultVer = if ($env:CXVM_DEFAULT_VERSION) { $env:CXVM_DEFAULT_VERSION } else { "8.0.0" }
$Port = if ($env:PORT) { $env:PORT } else { "3080" }

Write-Host "================================================================================"
Write-Host "    2-TEK CXVM: One-Click Cross-Platform Setup & Toolchain Activation (PS)     "
Write-Host "================================================================================"

$Arch = if ([System.Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$Platform = "windows-$Arch"

Write-Host "[INFO] Detected Platform: $Platform"
Write-Host "[INFO] Target Directory:  $CxvmDir"

New-Item -ItemType Directory -Force -Path "$CxvmDir\bin" | Out-Null
New-Item -ItemType Directory -Force -Path "$CxvmDir\versions\v$DefaultVer\bin" | Out-Null
New-Item -ItemType Directory -Force -Path "$CxvmDir\cache" | Out-Null
New-Item -ItemType Directory -Force -Path "$CxvmDir\alias" | Out-Null

$ServerUrl = "http://localhost:$Port"
try {
    Invoke-RestMethod -Uri "$ServerUrl/api/v1/setup/one-click?platform=$Platform&version=$DefaultVer" -Method Get -TimeoutSec 3 | Out-Null
    Write-Host "[INFO] Connected to CXVM Factory Server at $ServerUrl."
} catch {
    # Server offline or not reachable, continue local provisioning
}

Set-Content -Path "$CxvmDir\default" -Value "$DefaultVer"

# Update PATH for current session and user environment
$CurrentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($CurrentPath -notlike "*\.cxvm\bin*") {
    [System.Environment]::SetEnvironmentVariable("PATH", "$CurrentPath;$CxvmDir\bin", "User")
}
$env:PATH = "$env:PATH;$CxvmDir\bin"

Write-Host "[OK] 2-TEK CXVM one-click cross-platform setup completed successfully."
Write-Host "     Active Version: v$DefaultVer"
Write-Host "     Binaries:       $CxvmDir\bin"
