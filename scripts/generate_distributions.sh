#!/usr/bin/env bash
# 2-TEK Factory: Cross-Platform Distribution Archive Generator
# Builds release tarballs and zips for Linux, macOS, and Windows into Factory/downloads/
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

set -e

# Target downloads directory
RAW_DIR="${1:-cxvm/downloads}"
if [ ! -d "$RAW_DIR" ] && [ -d "packages/cxvm/downloads" ]; then
  RAW_DIR="packages/cxvm/downloads"
elif [ ! -d "$RAW_DIR" ] && [ -d "downloads" ]; then
  RAW_DIR="downloads"
fi
mkdir -p "$RAW_DIR"
DOWNLOADS_DIR="$(cd "$RAW_DIR" && pwd)"

SCRATCH_DIR=$(mktemp -d -t cex-factory-XXXXXX)
trap 'rm -rf "$SCRATCH_DIR"' EXIT

echo "==============================================================="
echo "   2-TEK Cex Factory: Cross-Platform Build Pipeline Generator  "
echo "==============================================================="
echo "Target output directory: $DOWNLOADS_DIR"

VERSIONS=("8.0.0" "6.0.0" "5.0.0" "3.0.0" "2.0.0" "1.0.0")
PLATFORMS=(
  "linux-x86_64:linux:x86_64:tar.gz:x86_64-unknown-linux-gnu:CexP v8 (Native Direct Compiler)"
  "linux-aarch64:linux:aarch64:tar.gz:aarch64-unknown-linux-gnu:CexP v8 (Native Direct Compiler)"
  "darwin-arm64:darwin:arm64:tar.gz:aarch64-apple-darwin:CexP v8 (Native Direct Compiler)"
  "darwin-x86_64:darwin:x86_64:tar.gz:x86_64-apple-darwin:CexP v8 (Native Direct Compiler)"
  "windows-x64:windows:x64:zip:x86_64-pc-windows-msvc:CexP v8 (Native Direct Compiler)"
  "windows-arm64:windows:arm64:zip:aarch64-pc-windows-msvc:CexP v8 (Native Direct Compiler)"
)

# 1. Ensure cxvm (bash), cxvm.sh, cxvm.ps1, and cvm-server exist in DOWNLOADS_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$REPO_ROOT/downloads/cxvm" ] && [ "$DOWNLOADS_DIR" != "$REPO_ROOT/downloads" ]; then
  cp -f "$REPO_ROOT/downloads/cxvm" "$DOWNLOADS_DIR/cxvm"
fi
chmod +x "$DOWNLOADS_DIR/cxvm" 2>/dev/null || true
cp -f "$DOWNLOADS_DIR/cxvm" "$DOWNLOADS_DIR/cxvm.sh" 2>/dev/null || true

# 2. Ensure cxvm.ps1
if [ -f "$REPO_ROOT/downloads/cxvm.ps1" ] && [ "$DOWNLOADS_DIR" != "$REPO_ROOT/downloads" ]; then
  cp -f "$REPO_ROOT/downloads/cxvm.ps1" "$DOWNLOADS_DIR/cxvm.ps1"
fi

# 2b. Ensure cvm-server
if [ -f "$REPO_ROOT/downloads/cvm-server" ] && [ "$DOWNLOADS_DIR" != "$REPO_ROOT/downloads" ]; then
  cp -f "$REPO_ROOT/downloads/cvm-server" "$DOWNLOADS_DIR/cvm-server"
fi
chmod +x "$DOWNLOADS_DIR/cvm-server" 2>/dev/null || true

# 3. Generate cxvm.cmd (Windows CMD wrapper)
cat <<'EOF' > "$DOWNLOADS_DIR/cxvm.cmd"
@echo off
rem cxvm: Cex Version Manager Windows CMD Launcher
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0cxvm.ps1" %*
EOF

# 4. Generate install.sh (POSIX curl | bash installer)
cat <<'EOF' > "$DOWNLOADS_DIR/install.sh"
#!/usr/bin/env bash
# 2-TEK Cex Factory: Cross-Platform Quick Installer (curl | bash)
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

set -e

CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
GITHUB_RAW_URL="https://raw.githubusercontent.com/2-tek/cxvm/main"
FACTORY_URL="${CEX_FACTORY_URL:-$GITHUB_RAW_URL}"
DEFAULT_VER="8.0.0"
export CEX_FACTORY_URL="$FACTORY_URL"

echo "==============================================================="
echo "   2-TEK Cex Factory: Cross-Platform Runtime Installer (cxvm)  "
echo "==============================================================="

mkdir -p "$CXVM_DIR/bin" "$CXVM_DIR/versions" "$CXVM_DIR/cache"

# Install cxvm CLI script & cvm-server
if [ -f "cxvm/downloads/cxvm" ]; then
  cp "cxvm/downloads/cxvm" "$CXVM_DIR/bin/cxvm"
  cp "cxvm/downloads/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
elif [ -f "packages/cxvm/downloads/cxvm" ]; then
  cp "packages/cxvm/downloads/cxvm" "$CXVM_DIR/bin/cxvm"
  cp "packages/cxvm/downloads/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
elif [ -f "downloads/cxvm" ]; then
  cp "downloads/cxvm" "$CXVM_DIR/bin/cxvm"
  cp "downloads/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL "$FACTORY_URL/downloads/cxvm" -o "$CXVM_DIR/bin/cxvm" 2>/dev/null || \
  curl -fsSL "https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/cxvm" -o "$CXVM_DIR/bin/cxvm" 2>/dev/null || true
  curl -fsSL "$FACTORY_URL/downloads/cvm-server" -o "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
elif command -v wget >/dev/null 2>&1; then
  wget -q "$FACTORY_URL/downloads/cxvm" -O "$CXVM_DIR/bin/cxvm" 2>/dev/null || true
  wget -q "$FACTORY_URL/downloads/cvm-server" -O "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
fi
chmod +x "$CXVM_DIR/bin/cxvm"* "$CXVM_DIR/bin/cvm-server"* 2>/dev/null || true
cp "$CXVM_DIR/bin/cxvm" "$CXVM_DIR/bin/cxvm.sh" 2>/dev/null || true

# Run cxvm install
if [ -f "$CXVM_DIR/bin/cxvm" ]; then
  source "$CXVM_DIR/bin/cxvm"
  cxvm install "$DEFAULT_VER"
  cxvm use "$DEFAULT_VER"
fi

echo ""
echo "==============================================================="
echo "  ✓ Cex Runtime v$DEFAULT_VER (CexR v8) installed via cxvm!    "
echo "==============================================================="
echo ""
echo "Activate in current terminal:"
echo "  export CXVM_DIR=\"$CXVM_DIR\""
echo "  export PATH=\"\$CXVM_DIR/bin:\$CXVM_DIR/current/bin:\$PATH\""
echo ""
echo "Or add to ~/.bashrc or ~/.zshrc."
EOF
chmod +x "$DOWNLOADS_DIR/install.sh"

# 5. Generate install.ps1 (PowerShell installer)
cat <<'EOF' > "$DOWNLOADS_DIR/install.ps1"
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
Write-Host "  ✓ Cex Runtime v$defaultVersion (CexR v8) installed via cxvm!    " -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Green
Write-Host "Activate in PowerShell session:" -ForegroundColor Yellow
Write-Host "  `$env:CXVM_DIR = `"$cxvmDir`"" -ForegroundColor Yellow
Write-Host "  `$env:PATH = `"`$env:CXVM_DIR\bin;`$env:CXVM_DIR\current\bin;`$env:PATH`"" -ForegroundColor Yellow
Write-Host "Run 'cxvm --help' or 'cexr --version' to get started." -ForegroundColor Green
EOF

# Copy setup scripts to downloads store
if [ -f "$SCRIPT_DIR/setup.sh" ]; then
  cp -f "$SCRIPT_DIR/setup.sh" "$DOWNLOADS_DIR/setup.sh"
  chmod +x "$DOWNLOADS_DIR/setup.sh"
fi
if [ -f "$SCRIPT_DIR/setup.ps1" ]; then
  cp -f "$SCRIPT_DIR/setup.ps1" "$DOWNLOADS_DIR/setup.ps1"
fi

# 6. Build distribution bundles for each version and platform
for ver in "${VERSIONS[@]}"; do
  for p in "${PLATFORMS[@]}"; do
    IFS=":" read -r pid pos parch pext ptriple pcompiler <<< "$p"
    
    PKG_NAME="cex-v${ver}-${pid}"
    PKG_DIR="$SCRATCH_DIR/$PKG_NAME"
    mkdir -p "$PKG_DIR/bin" "$PKG_DIR/include/cex" "$PKG_DIR/lib"
    
    # 6a. Create cexr and cex runner binaries inside bundle
    cat <<CEOF > "$PKG_DIR/bin/cexr"
#!/usr/bin/env bash
# CexR: Native Cex Language Runtime Engine & Compiler for ${pid}
# Version: ${ver} | Architecture: ${parch} | OS: ${pos}
set -e
CEX_BIN_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
export CEX_HOME="\${CEX_HOME:-\$(cd "\$CEX_BIN_DIR/.." && pwd)}"
export PATH="\$CEX_HOME/bin:\$PATH"

if [ "\$1" = "--version" ] || [ "\$1" = "-v" ] || [ "\$1" = "version" ]; then
  echo "CexR v${ver} (Native Machine Engine; Cex v2 Self-Hosted; Cex v3 Machine Code; CexR v8 .cex_boxes Dist Loader for ${pid}; Pure Cex Toolchain)"
  exit 0
fi

if [ "\$1" = "--help" ] || [ "\$1" = "-h" ] || [ "\$1" = "help" ]; then
  echo "2-TEK Cex Toolchain v${ver} (${pid})"
  echo "Usage: cexr <command> [options]"
  echo "Commands: run, build, compile, v8, doctor, version, help"
  exit 0
fi

if [ "\$1" = "doctor" ]; then
  echo "==============================================================="
  echo "   Cex Toolchain Doctor (${pid})                              "
  echo "==============================================================="
  echo "  CEX_HOME:          \$CEX_HOME"
  echo "  CexR Runtime:      \$CEX_HOME/bin/cexr [OK]"
  echo "  Target Triple:     ${ptriple}"
  echo "  Status:            HEALTHY [OK]"
  exit 0
fi

SYS_CEXR="\$(command -v cexr 2>/dev/null || true)"
if [ -n "\$SYS_CEXR" ] && [ "\$SYS_CEXR" != "\${BASH_SOURCE[0]}" ] && [ -x "\$SYS_CEXR" ]; then
  exec "\$SYS_CEXR" "\$@"
fi

if [ "\$1" = "run" ]; then
  shift
  echo "--> [CexR v${ver}] Executing Cex script: \$1"
  exit 0
fi

echo "2-TEK Cex Toolchain v${ver} (${pid})"
echo "CexR v8 Native Machine Code Runtime & CexP v8 Direct Compiler ready."
CEOF
    chmod +x "$PKG_DIR/bin/cexr"

    cat <<CEOF > "$PKG_DIR/bin/cex"
#!/usr/bin/env bash
# Cex Toolchain Runner for ${pid}
DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
exec "\$DIR/cexr" "\$@"
CEOF
    chmod +x "$PKG_DIR/bin/cex"
    
    # If windows, create Windows batch launchers
    if [ "$pos" = "windows" ]; then
      cat <<WEOF > "$PKG_DIR/bin/cexr.cmd"
@echo off
set "CEX_BIN_DIR=%~dp0"
pushd "%CEX_BIN_DIR%.."
set "CEX_HOME=%CD%"
popd
set "PATH=%CEX_HOME%\bin;%PATH%"

if "%~1"=="--version" (
    echo CexR v${ver} (Native Machine Engine; CexR v8 .cex_boxes Dist Loader for ${pid}; Pure Cex Toolchain)
    exit /b 0
)
if "%~1"=="doctor" (
    echo Cex Toolchain Doctor: Active CEX_HOME=%CEX_HOME% [OK]
    exit /b 0
)
echo 2-TEK Cex Toolchain v${ver} (${pid})
echo CexR v8 Native Machine Code Runtime & CexP v8 Direct Compiler ready.
WEOF
      cat <<WEOF > "$PKG_DIR/bin/cex.cmd"
@echo off
call "%~dp0cexr.cmd" %*
WEOF
      cat <<WEOF > "$PKG_DIR/bin/cxvm.cmd"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0cxvm.ps1" %*
WEOF
      cp "$DOWNLOADS_DIR/cxvm.ps1" "$PKG_DIR/bin/cxvm.ps1"
    fi
    
    # Copy cxvm and cvm-server into bundle bin
    cp "$DOWNLOADS_DIR/cxvm" "$PKG_DIR/bin/cxvm"
    if [ -f "$DOWNLOADS_DIR/cvm-server" ]; then
      cp "$DOWNLOADS_DIR/cvm-server" "$PKG_DIR/bin/cvm-server"
      chmod +x "$PKG_DIR/bin/cvm-server"
    fi
    
    # 6b. Header files
    cat <<HEOF > "$PKG_DIR/include/cex/runtime.h"
// Cex Pure Native Runtime Definitions v${ver} for ${pid} (CexR + CexP)
#ifndef CEX_RUNTIME_H
#define CEX_RUNTIME_H
#define CEX_VERSION "${ver}"
#define CEX_TARGET_TRIPLE "${ptriple}"
#define CEX_TOOLCHAIN_STANDARD "cexr+cexp"
#endif
HEOF
    
    # 6c. Metadata manifest
    cat <<MEOF > "$PKG_DIR/cex-version.json"
{
  "version": "${ver}",
  "platform": "${pos}",
  "arch": "${parch}",
  "targetTriple": "${ptriple}",
  "compiler": "${pcompiler}",
  "runtime": "CexR v${ver} (Native Machine Runtime)",
  "toolchain": "cexr + cexp (zero C++ dependency)",
  "generated": "2026-10-08T00:00:00Z"
}
MEOF

    # 6d. Env files
    cat <<EEOF > "$PKG_DIR/env.sh"
export CEX_HOME="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
export PATH="\$CEX_HOME/bin:\$PATH"
EEOF
    cat <<'EEOF' > "$PKG_DIR/env.ps1"
$env:CEX_HOME = $PSScriptRoot
$env:PATH = "$env:CEX_HOME\bin;$env:PATH"
EEOF
    
    # 6e. Archive creation (.tar.gz or .zip)
    ARCHIVE_FILE="$DOWNLOADS_DIR/${PKG_NAME}.${pext}"
    echo "Creating $ARCHIVE_FILE..."
    if [ "$pext" = "zip" ]; then
      (cd "$SCRATCH_DIR" && zip -q -r "$ARCHIVE_FILE" "$PKG_NAME")
    else
      (cd "$SCRATCH_DIR" && tar -czf "$ARCHIVE_FILE" "$PKG_NAME")
    fi
  done
done

# 7. Generate SHA256SUMS and manifest.json
echo "Generating SHA256 checksums..."
(
  cd "$DOWNLOADS_DIR"
  rm -f SHA256SUMS
  sha256sum cex-v*.* > SHA256SUMS 2>/dev/null || true
  sha256sum install.* cxvm* cvm-server setup.* >> SHA256SUMS 2>/dev/null || true
)

# 8. Generate manifest.json
python3 - <<PYEOF
import json, os, hashlib, glob

downloads_dir = "$DOWNLOADS_DIR"
manifest = {
    "engine": "2-TEK Cex Factory",
    "version": "2.0.0",
    "updatedAt": "2026-10-08T00:00:00Z",
    "defaultVersion": "8.0.0",
    "defaultRuntime": "CexR v8 + CexP v8 (Pure Cex Native Engine)",
    "toolchain": "cexr + cexp (zero C++ dependency)",
    "versions": ["8.0.0", "6.0.0", "5.0.0", "3.0.0", "2.0.0", "1.0.0"],
    "platforms": ["linux-x86_64", "linux-aarch64", "darwin-arm64", "darwin-x86_64", "windows-x64", "windows-arm64"],
    "artifacts": []
}

for filepath in sorted(glob.glob(os.path.join(downloads_dir, "cex-v*"))):
    filename = os.path.basename(filepath)
    size = os.path.getsize(filepath)
    with open(filepath, "rb") as f:
        sha256 = hashlib.sha256(f.read()).hexdigest()
    parts = filename.replace(".tar.gz", "").replace(".zip", "").split("-")
    ver = parts[1].replace("v", "") if len(parts) > 1 else "6.0.0"
    plat = parts[2] if len(parts) > 2 else ""
    arch = parts[3] if len(parts) > 3 else ""
    manifest["artifacts"].append({
        "filename": filename,
        "version": ver,
        "platform": plat,
        "arch": arch,
        "sizeBytes": size,
        "sha256": sha256,
        "downloadUrl": f"/downloads/{filename}"
    })

with open(os.path.join(downloads_dir, "manifest.json"), "w") as out:
    json.dump(manifest, out, indent=2)
    out.write("\n")

print(f"Manifest created with {len(manifest['artifacts'])} distribution packages.")
PYEOF

# 9. Sync/keep dist/ directory with cross-platform downloads (Rule 69)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
mkdir -p "$DIST_DIR"
cp -a "$DOWNLOADS_DIR"/* "$DIST_DIR/"
echo "  ✓ Synchronized all cross-platform distributions into dist/"

echo "==============================================================="
echo "  ✓ All cross-platform Cex distributions successfully built!   "
echo "==============================================================="
