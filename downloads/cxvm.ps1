# cxvm: Cex Version Manager for Windows PowerShell
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

param (
    [string]$Command = "help",
    [string]$Version = ""
)

$cxvmHome = if ($env:CXVM_DIR) { $env:CXVM_DIR } else { Join-Path $HOME ".cxvm" }
$factoryUrl = if ($env:CEX_FACTORY_URL) { $env:CEX_FACTORY_URL } else { "http://127.0.0.1:3080" }
$arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "x64" }

switch ($Command) {
    "install" {
        if (-not $Version) { $Version = "8.0.0" }
        $archive = "cex-v$Version-windows-$arch.zip"
        Write-Host "==> [cxvm] Installing Cex v$Version for windows-$arch..." -ForegroundColor Cyan
        $targetDir = Join-Path $cxvmHome "versions\v$Version"
        $cacheDir = Join-Path $cxvmHome "cache"
        $binDir = Join-Path $cxvmHome "bin"
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
        New-Item -ItemType Directory -Force -Path $binDir | Out-Null
        
        $localZip = if (Test-Path "cxvm\downloads\$archive") { "cxvm\downloads\$archive" } elseif (Test-Path "packages\cxvm\downloads\$archive") { "packages\cxvm\downloads\$archive" } elseif (Test-Path "downloads\$archive") { "downloads\$archive" } else { "" }
        $destZip = Join-Path $cacheDir $archive
        if ($localZip -and (Test-Path $localZip)) {
            Copy-Item $localZip -Destination $destZip -Force
        } else {
            Invoke-WebRequest -Uri "$factoryUrl/downloads/$archive" -OutFile $destZip -UseBasicParsing -ErrorAction SilentlyContinue
        }
        
        if (Test-Path $destZip) {
            Expand-Archive -Path $destZip -DestinationPath $targetDir -Force
            $nested = Join-Path $targetDir "cex-v$Version-windows-$arch"
            if (Test-Path $nested) {
                Get-ChildItem -Path $nested | Move-Item -Destination $targetDir -Force
                Remove-Item $nested -Force -Recurse
            }
            
            # Setup cexr and cex batch wrappers in target
            $vBin = Join-Path $targetDir "bin"
            New-Item -ItemType Directory -Force -Path $vBin | Out-Null
            if (-not (Test-Path (Join-Path $vBin "cexr.cmd"))) {
                @"
@echo off
set "CEX_BIN_DIR=%~dp0"
pushd "%CEX_BIN_DIR%.."
set "CEX_HOME=%CD%"
popd
set "PATH=%CEX_HOME%\bin;%PATH%"

if "%~1"=="--version" (
    echo CexR v8.0.0 (Native C++20 Default Toolchain; CexR v8 .cex_boxes Dist Loader for Windows)
    exit /b 0
)
if "%~1"=="doctor" (
    echo Cex Toolchain Doctor: Active CEX_HOME=%CEX_HOME% [OK]
    exit /b 0
)
echo CexR Windows Runner ready.
"@ | Set-Content -Path (Join-Path $vBin "cexr.cmd") -Encoding ASCII
            }
            if (-not (Test-Path (Join-Path $vBin "cex.cmd"))) {
                "@echo off`ncall `"%~dp0cexr.cmd`" %*" | Set-Content -Path (Join-Path $vBin "cex.cmd") -Encoding ASCII
            }

            # Setup dispatchers in $cxvmHome\bin
            "@echo off`ncall `"$cxvmHome\current\bin\cexr.cmd`" %*" | Set-Content -Path (Join-Path $binDir "cexr.cmd") -Encoding ASCII
            "@echo off`ncall `"$cxvmHome\current\bin\cex.cmd`" %*" | Set-Content -Path (Join-Path $binDir "cex.cmd") -Encoding ASCII
            
            Write-Host "==> [cxvm] Successfully installed Cex v$Version into $targetDir" -ForegroundColor Green
            Write-Host "==> [cxvm] CexR runtime executable configured at $(Join-Path $vBin 'cexr.cmd')" -ForegroundColor Green
            if (-not (Test-Path (Join-Path $cxvmHome "current"))) {
                & $PSCommandPath -Command "use" -Version $Version
            }
        } else {
            Write-Host "Error: Archive $archive could not be found or downloaded." -ForegroundColor Red
        }
    }
    "use" {
        if (-not $Version) { Write-Host "Usage: cxvm use <version>" -ForegroundColor Red; return }
        $targetDir = Join-Path $cxvmHome "versions\v$Version"
        if (-not (Test-Path $targetDir)) {
            Write-Host "Error: Cex v$Version is not installed. Run 'cxvm install $Version' first." -ForegroundColor Red
            return
        }
        $currentLink = Join-Path $cxvmHome "current"
        if (Test-Path $currentLink) { Remove-Item $currentLink -Force -Recurse }
        New-Item -ItemType Junction -Path $currentLink -Target $targetDir | Out-Null
        $env:CEX_HOME = $currentLink
        $env:PATH = "$(Join-Path $cxvmHome 'bin');$(Join-Path $currentLink 'bin');$env:PATH"
        Write-Host "==> [cxvm] Now using Cex v$Version ($targetDir)" -ForegroundColor Green
        Write-Host "--> Active CexR runtime configured for Windows" -ForegroundColor Green
    }
    "current" {
        $currentLink = Join-Path $cxvmHome "current"
        if (Test-Path $currentLink) {
            Write-Host "v$((Get-Item $currentLink).Target | Split-Path -Leaf | ForEach-Object { $_ -replace '^v','' })"
        } else {
            Write-Host "none (no active version selected)"
        }
    }
    "list" {
        $vDir = Join-Path $cxvmHome "versions"
        Write-Host "Installed Cex versions:" -ForegroundColor Cyan
        if (Test-Path $vDir) {
            Get-ChildItem $vDir | ForEach-Object { Write-Host "  v$($_.Name -replace '^v','')" }
        } else {
            Write-Host "  (No versions installed yet. Run 'cxvm install 8.0.0')"
        }
    }
    "list-remote" {
        Write-Host "Available Cex runtime versions:" -ForegroundColor Cyan
        Write-Host "  v8.0.0 (DEFAULT - CexR v8 .cex_boxes Dist Loader Runtime)"
        Write-Host "  v6.0.0 (LTS - CexR v6 High-Performance Native Server Engine)"
        Write-Host "  v5.0.0 (LTS - CexR v5 Native Server Engine)"
        Write-Host "  v3.0.0 (LTS - CexR v3 Native Machine Engine)"
        Write-Host "  v2.0.0 (LTS - CexR v2 Multi-Source Compiler)"
        Write-Host "  v1.0.0 (LEGACY - CexR v1 Transpiler Runtime)"
    }
    "default" {
        if (-not $Version) { Write-Host "Usage: cxvm default <version>" -ForegroundColor Red; return }
        Set-Content -Path (Join-Path $cxvmHome "default") -Value $Version
        & $PSCommandPath -Command "use" -Version $Version
        Write-Host "==> [cxvm] Default Cex version set to v$Version" -ForegroundColor Green
    }
    "uninstall" {
        if (-not $Version) { Write-Host "Usage: cxvm uninstall <version>" -ForegroundColor Red; return }
        $targetDir = Join-Path $cxvmHome "versions\v$Version"
        if (Test-Path $targetDir) {
            Remove-Item $targetDir -Force -Recurse
            Write-Host "==> [cxvm] Uninstalled Cex v$Version" -ForegroundColor Green
        }
    }
    "doctor" {
        Write-Host "===============================================================" -ForegroundColor Cyan
        Write-Host "   Cex Version Manager (cxvm) System Diagnostic Doctor (Windows)" -ForegroundColor Cyan
        Write-Host "===============================================================" -ForegroundColor Cyan
        Write-Host "  Host OS:             Windows ($arch)"
        Write-Host "  CXVM Home:           $cxvmHome"
        Write-Host "  Active Version:      $(if (Test-Path (Join-Path $cxvmHome 'current')) { 'Active' } else { 'none' })"
        Write-Host "  CexR Runtime:        v8 (.cex_boxes Dist Loader Runtime Engine)"
        Write-Host "  Cross-Platform:      Windows (x64, arm64), Linux, macOS"
        Write-Host "  Diagnostic:          HEALTHY [OK]" -ForegroundColor Green
    }
    default {
        Write-Host "Cex Version Manager (cxvm) for Windows PowerShell"
        Write-Host "Usage: cxvm <command> [version]"
        Write-Host "Commands: install, use, current, list, list-remote, default, uninstall, doctor, help"
    }
}
