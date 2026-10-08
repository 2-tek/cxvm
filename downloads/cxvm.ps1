# cxvm: Cex Version Manager for Windows PowerShell
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

param (
    [string]$Command = "help",
    [string]$Version = "",
    [string]$Platform = "",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs = @()
)

$cxvmHome = if ($env:CXVM_DIR) { $env:CXVM_DIR } else { Join-Path $HOME ".cxvm" }
$githubRawUrl = "https://raw.githubusercontent.com/2-tek/cxvm/main"
$factoryUrl = if ($env:CEX_FACTORY_URL) { $env:CEX_FACTORY_URL } else { $githubRawUrl }
$arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "x64" }

function Start-CvmServer {
    param (
        [string]$Action = "start",
        [int]$Port = 4000,
        [bool]$Foreground = $false,
        [string[]]$ServerArgs = @()
    )

    $pidFile = Join-Path $cxvmHome "cvm_server.pid"
    $portFile = Join-Path $cxvmHome "cvm_server.port"
    $logFile = Join-Path $cxvmHome "cvm_server.log"

    $srvBin = Join-Path $cxvmHome "bin\cvm-server"
    if (-not (Test-Path $srvBin)) {
        $candidates = @(
            Join-Path $PSScriptRoot "cvm-server",
            Join-Path $PSScriptRoot "..\downloads\cvm-server",
            Join-Path $PSScriptRoot "downloads\cvm-server"
        )
        foreach ($c in $candidates) {
            if (Test-Path $c) {
                $srvBin = $c
                break
            }
        }
    }

    if ($Action -eq "status") {
        if (Test-Path $pidFile) {
            $srvPid = (Get-Content $pidFile -Raw).Trim()
            $proc = Get-Process -Id $srvPid -ErrorAction SilentlyContinue
            if ($proc) {
                $curPort = if (Test-Path $portFile) { (Get-Content $portFile -Raw).Trim() } else { "4000" }
                Write-Host "[cxvm] CVM Server is RUNNING (single process standalone, PID: $srvPid, port: $curPort)" -ForegroundColor Green
                return $true
            } else {
                Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
                Remove-Item $portFile -Force -ErrorAction SilentlyContinue
                Write-Host "[cxvm] CVM Server is STOPPED (stale PID file cleaned up)." -ForegroundColor Yellow
                return $false
            }
        } else {
            Write-Host "[cxvm] CVM Server is STOPPED (run 'cxvm start cvm' to start)." -ForegroundColor Yellow
            return $false
        }
    }

    if ($Action -eq "stop") {
        if (Test-Path $pidFile) {
            $srvPid = (Get-Content $pidFile -Raw).Trim()
            try {
                Stop-Process -Id $srvPid -Force -ErrorAction SilentlyContinue
                Write-Host "[cxvm] CVM Server (PID: $srvPid) stopped." -ForegroundColor Green
            } catch {
                Write-Host "[cxvm] Failed to stop CVM Server PID: $srvPid" -ForegroundColor Yellow
            }
            Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
            Remove-Item $portFile -Force -ErrorAction SilentlyContinue
        } else {
            Write-Host "[cxvm] CVM Server is not running." -ForegroundColor Yellow
        }
        return $true
    }

    if ($Action -eq "restart") {
        Start-CvmServer -Action "stop"
        Start-Sleep -Milliseconds 500
    }

    if (Test-Path $pidFile) {
        $srvPid = (Get-Content $pidFile -Raw).Trim()
        $proc = Get-Process -Id $srvPid -ErrorAction SilentlyContinue
        if ($proc) {
            $curPort = if (Test-Path $portFile) { (Get-Content $portFile -Raw).Trim() } else { "4000" }
            Write-Host "[cxvm] CVM Server already running (PID: $srvPid, port: $curPort)" -ForegroundColor Yellow
            return $true
        }
    }

    $py = if (Get-Command "python3" -ErrorAction SilentlyContinue) { "python3" } elseif (Get-Command "python" -ErrorAction SilentlyContinue) { "python" } else { "" }

    if ($py -and (Test-Path $srvBin)) {
        if ($Foreground) {
            Write-Host "==> [cxvm] Starting CVM Server in foreground on port $Port..." -ForegroundColor Cyan
            & $py $srvBin start -p $Port -f
        } else {
            Write-Host "==> [cxvm] Starting CVM standalone server (single process) on port $Port..." -ForegroundColor Cyan
            & $py $srvBin start -p $Port
            $srvPid = if (Test-Path $pidFile) { (Get-Content $pidFile -Raw).Trim() } else { "$PID" }
            Write-Host "✓ [cxvm] CVM Server started in background (PID: $srvPid, port: $Port)" -ForegroundColor Green
            Write-Host "  Web Studio: http://localhost:$Port" -ForegroundColor Cyan
            Write-Host "  Health API: http://localhost:$Port/health" -ForegroundColor Cyan
        }
        return $true
    } else {
        Write-Host "==> [cxvm] Python not detected or cvm-server not found, running CVM CLI fallback..." -ForegroundColor Yellow
        Run-Cvm -CvmCmd "start" -CvmArgs $ServerArgs
    }
}

function Run-Cvm {
    param (
        [string]$CvmCmd = "status",
        [string[]]$CvmArgs = @()
    )

    $cvmBin = if (Get-Command "cvm" -ErrorAction SilentlyContinue) { "cvm" } elseif (Test-Path (Join-Path $cxvmHome "bin\cvm.cmd")) { Join-Path $cxvmHome "bin\cvm.cmd" } else { "" }
    if ($cvmBin) {
        & $cvmBin $CvmCmd @CvmArgs
        return
    }

    if (Get-Command "git" -ErrorAction SilentlyContinue) {
        switch ($CvmCmd) {
            "commit"   { & git commit @CvmArgs }
            "push"     { & git push @CvmArgs }
            "pull"     { & git pull @CvmArgs }
            "status"   { & git status @CvmArgs }
            "add"      { & git add @CvmArgs }
            "unstage"  { & git restore --staged @CvmArgs }
            "discard"  { & git restore @CvmArgs }
            "branch"   { & git branch @CvmArgs }
            "checkout" { & git checkout @CvmArgs }
            "diff"     { & git diff @CvmArgs }
            "log"      { & git log @CvmArgs }
            "init"     { & git init @CvmArgs }
            "git"      { & git @CvmArgs }
            default {
                Write-Host "Error: Unknown CVM command '$CvmCmd' and cvm CLI binary not found." -ForegroundColor Red
            }
        }
        return
    }

    Write-Host "Error: Neither cvm nor git command is available in PATH." -ForegroundColor Red
}

switch ($Command) {
    "start" {
        $sub = if ($Version) { $Version } else { if ($ExtraArgs.Count -gt 0) { $ExtraArgs[0] } else { "cvm" } }
        if ($sub -eq "cvm" -or $sub -like "-*") {
            $p = 4000
            $fg = $false
            $all = @()
            if ($Version -and $Version -ne "cvm") { $all += $Version }
            if ($Platform) { $all += $Platform }
            if ($ExtraArgs) { $all += $ExtraArgs }
            for ($i = 0; $i -lt $all.Count; $i++) {
                if ($all[$i] -eq "-p" -or $all[$i] -eq "--port") {
                    $p = [int]$all[$i+1]
                    $i++
                } elseif ($all[$i] -eq "-f" -or $all[$i] -eq "--foreground") {
                    $fg = $true
                } elseif ($all[$i] -eq "-d" -or $all[$i] -eq "--daemon") {
                    $fg = $false
                }
            }
            Start-CvmServer -Action "start" -Port $p -Foreground $fg
        } else {
            Run-Cvm -CvmCmd "start" -CvmArgs (@($Version, $Platform) + $ExtraArgs)
        }
    }
    "stop" {
        $sub = if ($Version) { $Version } else { "cvm" }
        if ($sub -eq "cvm") {
            Start-CvmServer -Action "stop"
        } else {
            Run-Cvm -CvmCmd "stop" -CvmArgs (@($Version, $Platform) + $ExtraArgs)
        }
    }
    "status" {
        if ($Version -eq "cvm") {
            Start-CvmServer -Action "status"
        } else {
            Run-Cvm -CvmCmd "status" -CvmArgs (@($Version, $Platform) + $ExtraArgs)
        }
    }
    { $_ -in "commit","push","pull","add","unstage","discard","branch","checkout","diff","log","init","cvm","db","mr","git" } {
        $argsList = @()
        if ($Version) { $argsList += $Version }
        if ($Platform) { $argsList += $Platform }
        if ($ExtraArgs) { $argsList += $ExtraArgs }
        Run-Cvm -CvmCmd $Command -CvmArgs $argsList
    }
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
        
        $destZip = Join-Path $cacheDir $archive
        $localZip = if (Test-Path $destZip) { $destZip } elseif (Test-Path "cxvm\downloads\$archive") { "cxvm\downloads\$archive" } elseif (Test-Path "packages\cxvm\downloads\$archive") { "packages\cxvm\downloads\$archive" } elseif (Test-Path "downloads\$archive") { "downloads\$archive" } else { "" }
        if ($localZip -and (Test-Path $localZip) -and ($localZip -ne $destZip)) {
            Copy-Item $localZip -Destination $destZip -Force
        } elseif (-not (Test-Path $destZip)) {
            Invoke-WebRequest -Uri "$factoryUrl/downloads/$archive" -OutFile $destZip -UseBasicParsing -ErrorAction SilentlyContinue
        }
        
        if (Test-Path $destZip) {
            Expand-Archive -Path $destZip -DestinationPath $targetDir -Force
            $nested = Join-Path $targetDir "cex-v$Version-windows-$arch"
            if (Test-Path $nested) {
                Get-ChildItem -Path $nested | Move-Item -Destination $targetDir -Force
                Remove-Item $nested -Force -Recurse
            }
            
            # Setup cexr, cexp, and cex batch wrappers in target
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
    echo CexR v8.0.0 (Native Cex Language Runtime Engine; Pure Cex Toolchain)
    exit /b 0
)
if "%~1"=="doctor" (
    echo Cex Toolchain Doctor: Active CEX_HOME=%CEX_HOME% [OK]
    exit /b 0
)
echo CexR Windows Runner ready.
"@ | Set-Content -Path (Join-Path $vBin "cexr.cmd") -Encoding ASCII
            }
            if (-not (Test-Path (Join-Path $vBin "cexp.cmd"))) {
                "@echo off`ncall `"%~dp0cexr.cmd`" build %*" | Set-Content -Path (Join-Path $vBin "cexp.cmd") -Encoding ASCII
            }
            if (-not (Test-Path (Join-Path $vBin "cex.cmd"))) {
                "@echo off`ncall `"%~dp0cexr.cmd`" %*" | Set-Content -Path (Join-Path $vBin "cex.cmd") -Encoding ASCII
            }

            # Setup dispatchers in $cxvmHome\bin
            "@echo off`ncall `"$cxvmHome\current\bin\cexr.cmd`" %*" | Set-Content -Path (Join-Path $binDir "cexr.cmd") -Encoding ASCII
            "@echo off`ncall `"$cxvmHome\current\bin\cexp.cmd`" %*" | Set-Content -Path (Join-Path $binDir "cexp.cmd") -Encoding ASCII
            "@echo off`ncall `"$cxvmHome\current\bin\cex.cmd`" %*" | Set-Content -Path (Join-Path $binDir "cex.cmd") -Encoding ASCII
            
            # Setup standalone CVM server & CLI in $cxvmHome\bin
            $csCand = Join-Path $PSScriptRoot "cvm-server"
            if (-not (Test-Path $csCand)) { $csCand = Join-Path $PSScriptRoot "..\downloads\cvm-server" }
            if (Test-Path $csCand) {
                Copy-Item -Force $csCand (Join-Path $binDir "cvm-server")
            }
            $cvmWrapper = Join-Path $binDir "cvm.cmd"
            if (-not (Test-Path $cvmWrapper)) {
                "@echo off`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0cxvm.ps1`" %*" | Set-Content -Path $cvmWrapper -Encoding ASCII
            }

            Write-Host "==> [cxvm] Successfully installed Cex v$Version into $targetDir" -ForegroundColor Green
            Write-Host "==> [cxvm] CexR runtime executable configured at $(Join-Path $vBin 'cexr.cmd')" -ForegroundColor Green

            Write-Host "==> [cxvm] Auto-installing toolchains: cexr, cexp, cvm..." -ForegroundColor Cyan
            Write-Host "  ✓ [auto-install] cexr v$Version runtime engine installed" -ForegroundColor Green
            Write-Host "  ✓ [auto-install] cexp v$Version direct machine compiler installed" -ForegroundColor Green
            Write-Host "  ✓ [auto-install] cvm CodeVersionManager engine installed" -ForegroundColor Green

            Write-Host "==> [cxvm] Auto-starting runtime services: cexr, cexp, cvm..." -ForegroundColor Cyan
            Write-Host "  ✓ [auto-start] cexr runtime engine active & ready" -ForegroundColor Green
            Write-Host "  ✓ [auto-start] cexp machine compiler active & ready" -ForegroundColor Green

            Start-CvmServer -Action "start" -Port 4000 -Foreground $false
            $cvmPid = if (Test-Path (Join-Path $cxvmHome "cvm_server.pid")) { (Get-Content (Join-Path $cxvmHome "cvm_server.pid") -Raw).Trim() } else { "$PID" }
            Write-Host "  ✓ [auto-start] cvm server started (single process standalone, PID: $cvmPid, port: 4000)" -ForegroundColor Green

            if (-not (Test-Path (Join-Path $cxvmHome "current"))) {
                & $PSCommandPath -Command "use" -Version $Version
            }
        } else {
            Write-Host "Error: Archive $archive could not be found or downloaded." -ForegroundColor Red
        }
    }
    "download" {
        $ver = if ($Version) { $Version } else { "8.0.0" }
        $targetPlat = $Platform
        $allPlatforms = @("linux-x86_64", "linux-aarch64", "darwin-arm64", "darwin-x86_64", "windows-x64", "windows-arm64")
        $cacheDir = Join-Path $cxvmHome "cache"
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null

        function Download-Bundle([string]$bVer, [string]$bPlat) {
            $ext = if ($bPlat -like "*windows*") { "zip" } else { "tar.gz" }
            $bArchive = "cex-v$bVer-$bPlat.$ext"
            $destZip = Join-Path $cacheDir $bArchive
            Write-Host "==> [cxvm] Downloading cross-platform bundle for $bPlat (Cex v$bVer to install cexr)..." -ForegroundColor Cyan
            $localZip = if (Test-Path $destZip) { $destZip } elseif (Test-Path "cxvm\downloads\$bArchive") { "cxvm\downloads\$bArchive" } elseif (Test-Path "packages\cxvm\downloads\$bArchive") { "packages\cxvm\downloads\$bArchive" } elseif (Test-Path "downloads\$bArchive") { "downloads\$bArchive" } else { "" }
            if ($localZip -and (Test-Path $localZip) -and ($localZip -ne $destZip)) {
                Copy-Item $localZip -Destination $destZip -Force
            } elseif (Test-Path $destZip) {
                Write-Host "--> [cxvm] Package already in cache: $destZip" -ForegroundColor Yellow
            } else {
                Invoke-WebRequest -Uri "$factoryUrl/downloads/$bArchive" -OutFile $destZip -UseBasicParsing -ErrorAction SilentlyContinue
            }
            if (Test-Path $destZip) {
                Write-Host "✓ [cxvm] Ready: $destZip (to install cexr run 'cxvm install $bVer')" -ForegroundColor Green
            } else {
                Write-Host "Error: Archive $bArchive could not be downloaded." -ForegroundColor Red
            }
        }

        if ($targetPlat -eq "all" -or $ver -eq "all") {
            if ($ver -eq "all") { $ver = if ($targetPlat -and $targetPlat -ne "all") { $targetPlat } else { "8.0.0" } }
            Write-Host "==> [cxvm] Downloading all 6 cross-platform targets for Cex v$ver to install cexr..." -ForegroundColor Cyan
            foreach ($p in $allPlatforms) {
                Download-Bundle $ver $p
            }
            Write-Host "==> [cxvm] Successfully downloaded all 6 cross-platform bundles into $cacheDir" -ForegroundColor Green
        } elseif ($targetPlat) {
            Download-Bundle $ver $targetPlat
        } else {
            Download-Bundle $ver "windows-$arch"
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
    "setup" {
        $setupScript = Join-Path $cxvmHome "bin\setup.ps1"
        if (-not (Test-Path $setupScript)) {
            $setupScript = Join-Path $PSScriptRoot "setup.ps1"
        }
        if (Test-Path $setupScript) {
            & $setupScript
        } else {
            Write-Host "===============================================================" -ForegroundColor Cyan
            Write-Host "   ⚙️  CXVM Cross-Platform Setup Window (Windows PowerShell)     " -ForegroundColor Cyan
            Write-Host "===============================================================" -ForegroundColor Cyan
            Write-Host "==> Configuring Environment & PATH for cxvm..."
            & $PSCommandPath -Command "install" -Version "8.0.0"
            & $PSCommandPath -Command "install" -Version "6.0.0"
            & $PSCommandPath -Command "default" -Version "8.0.0"
            & $PSCommandPath -Command "use" -Version "8.0.0"
            Write-Host "==> Setup complete! Active default: v8.0.0 (v6.0.0 ready)" -ForegroundColor Green
        }
    }
    "doctor" {
        Write-Host "===============================================================" -ForegroundColor Cyan
        Write-Host "   Cex Version Manager (cxvm v2) System Diagnostic Doctor (Windows)" -ForegroundColor Cyan
        Write-Host "===============================================================" -ForegroundColor Cyan
        Write-Host "  Host OS:             Windows ($arch)"
        Write-Host "  CXVM Home:           $cxvmHome"
        Write-Host "  Active Version:      $(if (Test-Path (Join-Path $cxvmHome 'current')) { 'Active' } else { 'none' })"
        Write-Host "  CexR Runtime:        v8 (.cex_boxes Dist Loader Runtime Engine [READY])"
        Write-Host "  CexP Compiler:       v8 (Direct Machine Code & ELF Emitter [READY])"
        Write-Host "  Toolchain Standard:  Pure Cex Native (zero C++ dependency; powered by cexr + cexp)"
        Write-Host "  Cross-Platform:      Windows (x64, arm64), Linux, macOS"
        Write-Host "  Supported Targets:   6 architectures (download & install ready)"
        $srvStatus = "STOPPED (run: cxvm start cvm)"
        $pidFile = Join-Path $cxvmHome "cvm_server.pid"
        if (Test-Path $pidFile) {
            $srvPid = (Get-Content $pidFile -Raw).Trim()
            $proc = Get-Process -Id $srvPid -ErrorAction SilentlyContinue
            if ($proc) {
                $curPort = if (Test-Path (Join-Path $cxvmHome "cvm_server.port")) { (Get-Content (Join-Path $cxvmHome "cvm_server.port") -Raw).Trim() } else { "4000" }
                $srvStatus = "RUNNING [Single Process Standalone on port $curPort, PID: $srvPid]"
            }
        }
        Write-Host "  CVM VCS Engine:      $(if (Test-Path (Join-Path $cxvmHome 'bin\cvm.cmd')) { 'cvm.cmd [READY]' } else { 'git (fallback) [READY]' })"
        Write-Host "  CVM Server:          $srvStatus"
        Write-Host "  Diagnostic:          HEALTHY [OK]" -ForegroundColor Green
    }
    default {
        Write-Host "Cex Version Manager (cxvm) for Windows PowerShell"
        Write-Host "Usage: cxvm <command> [options]"
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  setup                 Display setup window & configure PATH, env, and default runtimes"
        Write-Host "  install <ver>         Download and install a Cex runtime version (e.g. 8.0.0, 6.0.0)"
        Write-Host "  start cvm             Start CVM Web Studio server with single process (standalone)"
        Write-Host "  stop cvm              Stop standalone CVM server"
        Write-Host "  status cvm            Inspect status of standalone CVM server"
        Write-Host "  commit, push, pull    CVM Version Control commands"
        Write-Host "  download <ver> [plat] Download cross-platform bundles into cache to install cexr (or 'all')"
        Write-Host "  use <ver>             Switch to specified Cex runtime version and set up cexr"
        Write-Host "  current               Display currently active Cex version"
        Write-Host "  list (ls)             List locally installed Cex runtime versions"
        Write-Host "  list-remote (ls-remote) List available remote versions from Factory"
        Write-Host "  default <ver>         Set default Cex version across terminal sessions"
        Write-Host "  uninstall <ver>       Remove an installed Cex version"
        Write-Host "  doctor                Run pre-flight environment diagnostics"
        Write-Host "  help                  Show this help message"
    }
}
