# cxvm: Cex Version Manager for Windows PowerShell
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

param (
    [string]$Command = "help",
    [string]$Version = ""
)

$cxvmHome = if ($env:CXVM_DIR) { $env:CXVM_DIR } else { Join-Path $HOME ".cxvm" }
$factoryUrl = if ($env:CEX_FACTORY_URL) { $env:CEX_FACTORY_URL } else { "http://127.0.0.1:3080" }

switch ($Command) {
    "install" {
        if (-not $Version) { Write-Host "Usage: cxvm install <version>" -ForegroundColor Red; return }
        $archive = "cex-v$Version-windows-x64.zip"
        Write-Host "==> [cxvm] Installing Cex v$Version for windows-x64..." -ForegroundColor Cyan
        $targetDir = Join-Path $cxvmHome "versions\v$Version"
        $cacheDir = Join-Path $cxvmHome "cache"
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
        
        $localZip = if (Test-Path "cxvm\downloads\$archive") { "cxvm\downloads\$archive" } elseif (Test-Path "packages\cxvm\downloads\$archive") { "packages\cxvm\downloads\$archive" } elseif (Test-Path "downloads\$archive") { "downloads\$archive" } else { "" }
        $destZip = Join-Path $cacheDir $archive
        if ($localZip -and (Test-Path $localZip)) {
            Copy-Item $localZip -Destination $destZip -Force
        } else {
            Invoke-WebRequest -Uri "$factoryUrl/downloads/$archive" -OutFile $destZip -UseBasicParsing -ErrorAction SilentlyContinue
        }
        
        if (Test-Path $destZip) {
            Expand-Archive -Path $destZip -DestinationPath $targetDir -Force
            Write-Host "==> [cxvm] Successfully installed Cex v$Version" -ForegroundColor Green
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
        $env:PATH = "$(Join-Path $currentLink 'bin');$env:PATH"
        Write-Host "==> [cxvm] Now using Cex v$Version" -ForegroundColor Green
    }
    "current" {
        $currentLink = Join-Path $cxvmHome "current"
        if (Test-Path $currentLink) {
            Write-Host "v$((Get-Item $currentLink).Target | Split-Path -Leaf | ForEach-Object { $_ -replace '^v','' })"
        } else {
            Write-Host "none"
        }
    }
    "list" {
        $vDir = Join-Path $cxvmHome "versions"
        Write-Host "Installed Cex versions:" -ForegroundColor Cyan
        if (Test-Path $vDir) {
            Get-ChildItem $vDir | ForEach-Object { Write-Host "  v$($_.Name -replace '^v','')" }
        }
    }
    "list-remote" {
        Write-Host "Available Cex runtime versions:" -ForegroundColor Cyan
        Write-Host "  v6.0.0 (DEFAULT - CexR v6 High-Performance Native Server Engine)"
        Write-Host "  v5.0.0 (LTS - CexR v5 Native Server Engine)"
        Write-Host "  v3.0.0 (LTS - CexR v3 Native Machine Engine)"
        Write-Host "  v2.0.0 (LTS - CexR v2 Multi-Source Compiler)"
        Write-Host "  v1.0.0 (LEGACY - CexR v1 Transpiler Runtime)"
    }
    default {
        Write-Host "Cex Version Manager (cxvm) for Windows PowerShell"
        Write-Host "Commands: install, use, current, list, list-remote, doctor"
    }
}
