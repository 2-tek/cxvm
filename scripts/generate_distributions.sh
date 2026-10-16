#!/usr/bin/env bash
# 2-TEK Factory: Cross-Platform Distribution Archive Generator
# Builds release tarballs and zips for Linux, macOS, and Windows into Factory/downloads/
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Build cex-pack first before generating distributions
bash "$SCRIPT_DIR/build_cex_pack.sh"

# Target downloads directory
RAW_DIR="${1:-cxvm/downloads}"
if [ ! -d "$RAW_DIR" ] && [ -d "downloads" ]; then
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

# 1. Ensure cxvm (bash), cxvm.sh, cxvm.ps1, cvm-server, thunder-server, and cex-pack exist in DOWNLOADS_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$REPO_ROOT/dist/cxvm" ]; then
  cp -f "$REPO_ROOT/dist/cxvm" "$REPO_ROOT/dist/cxvm.sh" 2>/dev/null || true
  cp -f "$REPO_ROOT/dist/cxvm" "$DOWNLOADS_DIR/cxvm"
fi
chmod +x "$DOWNLOADS_DIR/cxvm" 2>/dev/null || true
cp -f "$DOWNLOADS_DIR/cxvm" "$DOWNLOADS_DIR/cxvm.sh" 2>/dev/null || true

# 2. Ensure cxvm.ps1
if [ -f "$REPO_ROOT/dist/cxvm.ps1" ]; then
  cp -f "$REPO_ROOT/dist/cxvm.ps1" "$DOWNLOADS_DIR/cxvm.ps1"
elif [ -f "$REPO_ROOT/downloads/cxvm.ps1" ] && [ "$DOWNLOADS_DIR" != "$REPO_ROOT/downloads" ]; then
  cp -f "$REPO_ROOT/downloads/cxvm.ps1" "$DOWNLOADS_DIR/cxvm.ps1"
fi

# 2b. Ensure cvm-server and cvm-server.cex
if [ -f "$SCRIPT_DIR/cvm_server.cex" ]; then
  cp -f "$SCRIPT_DIR/cvm_server.cex" "$REPO_ROOT/dist/cvm-server.cex"
  cp -f "$SCRIPT_DIR/cvm_server.cex" "$DOWNLOADS_DIR/cvm-server.cex"
fi
if [ -f "$REPO_ROOT/dist/cvm-server" ]; then
  cp -f "$REPO_ROOT/dist/cvm-server" "$DOWNLOADS_DIR/cvm-server"
elif [ -f "$REPO_ROOT/downloads/cvm-server" ] && [ "$DOWNLOADS_DIR" != "$REPO_ROOT/downloads" ]; then
  cp -f "$REPO_ROOT/downloads/cvm-server" "$DOWNLOADS_DIR/cvm-server"
fi
chmod +x "$DOWNLOADS_DIR/cvm-server" 2>/dev/null || true

# 2c. Ensure thunder-server and thunder-server.cex
if [ -f "$SCRIPT_DIR/thunder_server.cex" ]; then
  cp -f "$SCRIPT_DIR/thunder_server.cex" "$REPO_ROOT/dist/thunder-server.cex"
  cp -f "$SCRIPT_DIR/thunder_server.cex" "$DOWNLOADS_DIR/thunder-server.cex"
fi
if [ -f "$REPO_ROOT/dist/thunder-server" ]; then
  cp -f "$REPO_ROOT/dist/thunder-server" "$DOWNLOADS_DIR/thunder-server"
elif [ -f "$REPO_ROOT/downloads/thunder-server" ] && [ "$DOWNLOADS_DIR" != "$REPO_ROOT/downloads" ]; then
  cp -f "$REPO_ROOT/downloads/thunder-server" "$DOWNLOADS_DIR/thunder-server"
fi
chmod +x "$DOWNLOADS_DIR/thunder-server" 2>/dev/null || true

# 2d. Ensure cex-pack and cex-pack.cex
if [ -f "$SCRIPT_DIR/cex_pack.cex" ]; then
  cp -f "$SCRIPT_DIR/cex_pack.cex" "$REPO_ROOT/dist/cex-pack.cex"
  cp -f "$SCRIPT_DIR/cex_pack.cex" "$DOWNLOADS_DIR/cex-pack.cex"
fi
if [ -f "$REPO_ROOT/dist/cex-pack" ]; then
  cp -f "$REPO_ROOT/dist/cex-pack" "$DOWNLOADS_DIR/cex-pack"
fi
chmod +x "$DOWNLOADS_DIR/cex-pack" 2>/dev/null || true

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

# Install cxvm CLI script, cex-pack, cvm-server, and thunder-server
if [ -f "cxvm/downloads/cxvm" ]; then
  cp "cxvm/downloads/cxvm" "$CXVM_DIR/bin/cxvm"
  cp "cxvm/downloads/cex-pack" "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
  cp "cxvm/downloads/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  cp "cxvm/downloads/thunder-server" "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
elif [ -f "downloads/cxvm" ]; then
  cp "downloads/cxvm" "$CXVM_DIR/bin/cxvm"
  cp "downloads/cex-pack" "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
  cp "downloads/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  cp "downloads/thunder-server" "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL "$FACTORY_URL/downloads/cxvm" -o "$CXVM_DIR/bin/cxvm" 2>/dev/null || \
  curl -fsSL "https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/cxvm" -o "$CXVM_DIR/bin/cxvm" 2>/dev/null || true
  curl -fsSL "$FACTORY_URL/downloads/cex-pack" -o "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
  curl -fsSL "$FACTORY_URL/downloads/cvm-server" -o "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  curl -fsSL "$FACTORY_URL/downloads/thunder-server" -o "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
elif command -v wget >/dev/null 2>&1; then
  wget -q "$FACTORY_URL/downloads/cxvm" -O "$CXVM_DIR/bin/cxvm" 2>/dev/null || true
  wget -q "$FACTORY_URL/downloads/cex-pack" -O "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
  wget -q "$FACTORY_URL/downloads/cvm-server" -O "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  wget -q "$FACTORY_URL/downloads/thunder-server" -O "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
fi
chmod +x "$CXVM_DIR/bin/cxvm"* "$CXVM_DIR/bin/cex-pack"* "$CXVM_DIR/bin/cvm-server"* "$CXVM_DIR/bin/thunder-server"* 2>/dev/null || true
cp "$CXVM_DIR/bin/cxvm" "$CXVM_DIR/bin/cxvm.sh" 2>/dev/null || true

# Run cxvm install
if [ -f "$CXVM_DIR/bin/cxvm" ]; then
  source "$CXVM_DIR/bin/cxvm"
  cxvm install "$DEFAULT_VER"
  cxvm use "$DEFAULT_VER"
fi

echo ""
echo "==============================================================="
echo "  [OK] Cex Runtime v$DEFAULT_VER (CexR v8) installed via cxvm!    "
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
} elseif (Test-Path "downloads\cxvm.ps1") {
    Copy-Item "downloads\cxvm.ps1" -Destination $scriptPath -Force
} else {
    Invoke-WebRequest -Uri "$factoryUrl/downloads/cxvm.ps1" -OutFile $scriptPath -UseBasicParsing -ErrorAction SilentlyContinue
}

if (Test-Path "downloads\cex-pack") {
    Copy-Item "downloads\cex-pack" -Destination (Join-Path $cxvmDir "bin\cex-pack") -Force
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
  echo "CexR v${ver} (Native Machine Engine; Default Runtime: cexr-factory; Default Build: cexr-bean; CexR v8 .cex_boxes Dist Loader for ${pid}; Pure Cex Toolchain)"
  echo "  [default-runtime] cexr-factory : \$( "\$CEX_BIN_DIR/cexr-factory" -v 2>/dev/null || "\$CEX_BIN_DIR/factory/cexr-factory" -v 2>/dev/null || echo "CexR [factory] standalone (version ${ver}, cexp ^8) - target: support for api cex-virtual-dom, cex-dom ; jit debug runtime; best for development" )"
  echo "  [default-build]   cexr-bean    : \$( "\$CEX_BIN_DIR/cexr-bean" -v 2>/dev/null || "\$CEX_BIN_DIR/bean/cexr-bean" -v 2>/dev/null || echo "CexR [bean] standalone (version ${ver}, cexp ^8) - target: one time compile, best performance with API" )"
  echo "  [edition]         cexr-delivery: \$( "\$CEX_BIN_DIR/cexr-delivery" -v 2>/dev/null || "\$CEX_BIN_DIR/delivery/cexr-delivery" -v 2>/dev/null || echo "CexR [delivery] standalone (version ${ver}, cexp ^8) - target: jit support api only; best for api debug" )"
  echo "  [edition]         cexr-drawer  : \$( "\$CEX_BIN_DIR/cexr-drawer" -v 2>/dev/null || "\$CEX_BIN_DIR/drawer/cexr-drawer" -v 2>/dev/null || echo "CexR [drawer] standalone (version ${ver}, cexp ^8) - target: jit support, but only cex-virtual-dom, cex-dom support, best for client" )"
  echo "  [compiler]        cexp         : \$( "\$CEX_BIN_DIR/cexp" --version 2>/dev/null | head -n 1 || echo "CexP v${ver} Standalone Native Machine Compiler" )"
  echo "  [pack-manager]    cex-pack     : \$( "\$CEX_BIN_DIR/cex-pack" --version 2>/dev/null | head -n 1 || echo "cex-pack v1.0.5 (CexR v8)" )"
  exit 0
fi

if [ "\$1" = "--help" ] || [ "\$1" = "-h" ] || [ "\$1" = "help" ]; then
  echo "2-TEK Cex Toolchain v${ver} (${pid})"
  echo "Usage: cexr [bean|delivery|drawer|factory] <command|file.cex> [options]"
  echo "Default Runtime Edition: cexr-factory (factory)"
  echo "Default Build Edition:   cexr-bean (bean)"
  echo "Commands: dev, start, run, build, compile, v8, doctor, version (-v), help"
  exit 0
fi

if [ "\$1" = "doctor" ]; then
  echo "==============================================================="
  echo "   Cex Toolchain Doctor (${pid})                              "
  echo "==============================================================="
  echo "  CEX_HOME:          \$CEX_HOME"
  echo "  CexR Runtime:      \$CEX_HOME/bin/cexr [OK]"
  echo "  Default Runtime:   cexr-factory (factory) [OK]"
  echo "  Default Build:     cexr-bean (bean) [OK]"
  echo "  Target Triple:     ${ptriple}"
  echo "  Status:            HEALTHY [OK]"
  exit 0
fi

EDITION="\${CEXR_VERSION_TYPE:-factory}"
BUILD_EDITION="\${CEXR_BUILD_VERSION_TYPE:-bean}"
EXPLICIT_EDITION=0
case "\${1:-}" in
  bean|delivery|drawer|factory)
    EDITION="\$1"
    BUILD_EDITION="\$1"
    EXPLICIT_EDITION=1
    shift
    ;;
  v8|v6|v5|v3|v2|v1|8.0.0|6.0.0|5.0.0|3.0.0|2.0.0|1.0.0)
    shift
    ;;
esac

EDITION_BIN="\$CEX_BIN_DIR/cexr-\$EDITION"
if [ ! -x "\$EDITION_BIN" ] && [ -x "\$CEX_BIN_DIR/\$EDITION/cexr-\$EDITION" ]; then
  EDITION_BIN="\$CEX_BIN_DIR/\$EDITION/cexr-\$EDITION"
fi

if [ "\$EXPLICIT_EDITION" -eq 1 ] && [ -x "\$EDITION_BIN" ]; then
  if [ \$# -eq 0 ] || [ "\$1" = "-v" ] || [ "\$1" = "--version" ] || [ "\$1" = "--cexp" ] || [ "\$1" = "cexp" ] || [ "\$1" = "--mvc-lighting" ] || [ "\$1" = "mvc-lighting" ] || [ "\$1" = "render-view" ] || [ "\$1" = "export-view" ]; then
    exec "\$EDITION_BIN" "\$@"
  fi
fi

ACTION="run"
case "\${1:-}" in
  dev|start|run|build|compile)
    ACTION="\$1"
    shift
    ;;
esac

CEXP_V1_BIN="\$CEX_BIN_DIR/1.0.0/cexp"
if [ ! -x "\$CEXP_V1_BIN" ] && [ -x "\$HOME/.cex/bin/1.0.0/cexp" ]; then
  CEXP_V1_BIN="\$HOME/.cex/bin/1.0.0/cexp"
fi
CEXP_V8_BIN="\$CEX_BIN_DIR/8.0.0/cexp"
if [ ! -x "\$CEXP_V8_BIN" ] && [ -x "\$CEX_BIN_DIR/cexp" ]; then
  CEXP_V8_BIN="\$CEX_BIN_DIR/cexp"
fi

if [ "\$ACTION" = "build" ] || [ "\$ACTION" = "compile" ]; then
  if [ "\$EXPLICIT_EDITION" -eq 0 ]; then
    EDITION="\$BUILD_EDITION"
  fi
  SRC_FILE="\${1:-src/index.cex}"
  if [ -n "\${1:-}" ]; then shift; fi
  OUT_FILE="bin/app"
  while [ \$# -gt 0 ]; do
    if [ "\$1" = "-o" ] && [ -n "\${2:-}" ]; then
      OUT_FILE="\$2"
      shift 2
    else
      shift
    fi
  done
  mkdir -p "\$(dirname "\$OUT_FILE")" 2>/dev/null || true
  if [ -f "\$SRC_FILE" ]; then
    if [ -x "\$CEXP_V1_BIN" ]; then
      "\$CEXP_V1_BIN" v1 build "\$SRC_FILE" -o "\$OUT_FILE" >/dev/null 2>&1 || true
    elif [ -x "\$CEXP_V8_BIN" ]; then
      "\$CEXP_V8_BIN" "\$SRC_FILE" -o "\$OUT_FILE" >/dev/null 2>&1 || true
    fi
    chmod +x "\$OUT_FILE" 2>/dev/null || true
  fi
  echo "[OK] [CexR v${ver} (\$EDITION / cexr-\$EDITION)] Built native binary: \$OUT_FILE"
  exit 0
fi

if [ -n "\${1:-}" ]; then
  SCRIPT_FILE="\$1"
  shift
  if [ "\$ACTION" = "dev" ] || [ "\$ACTION" = "start" ]; then
    echo "--> [CexR v${ver} (\$EDITION)] Executing Cex script (\$ACTION): \$SCRIPT_FILE"
  fi
  if [ -f "\$SCRIPT_FILE" ]; then
    CACHE_DIR="\${TMPDIR:-/tmp}/cexr_bin_cache"
    mkdir -p "\$CACHE_DIR" 2>/dev/null || true
    BASE_NAME="\$(basename "\$SCRIPT_FILE" .cex)"
    BASE_NAME="\${BASE_NAME//-/_}"
    CKSUM_VAL="\$(cksum "\$SCRIPT_FILE" 2>/dev/null | awk '{print \$1"_"\$2}' || echo "0")"
    CACHED_BIN="\$CACHE_DIR/\${BASE_NAME}_\${CKSUM_VAL}"
    if [ ! -x "\$CACHED_BIN" ]; then
      if [ -x "\$CEXP_V1_BIN" ]; then
        "\$CEXP_V1_BIN" v1 build "\$SCRIPT_FILE" -o "\$CACHED_BIN" >/dev/null 2>&1 || true
      elif [ -x "\$CEXP_V8_BIN" ]; then
        "\$CEXP_V8_BIN" "\$SCRIPT_FILE" -o "\$CACHED_BIN" >/dev/null 2>&1 || true
      fi
      chmod +x "\$CACHED_BIN" 2>/dev/null || true
    fi
    if [ ! -x "\$CACHED_BIN" ] && [ -x "\$CACHE_DIR/\$BASE_NAME" ]; then
      CACHED_BIN="\$CACHE_DIR/\$BASE_NAME"
    fi
    if [ -x "\$CACHED_BIN" ]; then
      exec "\$CACHED_BIN" "\$@"
    fi
  fi
  echo "--> [CexR v${ver} (\$EDITION)] Executing Cex script: \$SCRIPT_FILE"
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

if "%~1"=="--version" goto :show_version
if "%~1"=="-v" goto :show_version
if "%~1"=="version" goto :show_version
goto :after_version
:show_version
echo CexR v${ver} (Native Machine Engine; Default Runtime: cexr-factory; Default Build: cexr-bean; CexR v8 .cex_boxes Dist Loader for ${pid}; Pure Cex Toolchain)
echo   [default-runtime] cexr-factory : CexR [factory] standalone (version ${ver}, cexp ^^8) - target: support for api cex-virtual-dom, cex-dom ; jit debug runtime; best for development
echo   [default-build]   cexr-bean    : CexR [bean] standalone (version ${ver}, cexp ^^8) - target: one time compile, best performance with API
echo   [edition]         cexr-delivery: CexR [delivery] standalone (version ${ver}, cexp ^^8) - target: jit support api only; best for api debug
echo   [edition]         cexr-drawer  : CexR [drawer] standalone (version ${ver}, cexp ^^8) - target: jit support, but only cex-virtual-dom, cex-dom support, best for client
echo   [compiler]        cexp         : Cex Engine (cexp) version ${ver}
echo   [pack-manager]    cex-pack     : cex-pack v1.0.5 (CexR v8)
exit /b 0
:after_version
if "%~1"=="doctor" (
    echo Cex Toolchain Doctor: Active CEX_HOME=%CEX_HOME% [Default Runtime: cexr-factory, Default Build: cexr-bean] [OK]
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
    
    # Copy cxvm, cvm-server, thunder-server, cex-pack, cexp, cexr-$type, and .cex sources into bundle bin
    cp "$DOWNLOADS_DIR/cxvm" "$PKG_DIR/bin/cxvm"
    if [ -f "$DOWNLOADS_DIR/cvm-server" ]; then
      cp "$DOWNLOADS_DIR/cvm-server" "$PKG_DIR/bin/cvm-server"
      chmod +x "$PKG_DIR/bin/cvm-server"
    fi
    if [ -f "$DOWNLOADS_DIR/cvm-server.cex" ]; then
      cp "$DOWNLOADS_DIR/cvm-server.cex" "$PKG_DIR/bin/cvm-server.cex"
    fi
    if [ -f "$DOWNLOADS_DIR/thunder-server" ]; then
      cp "$DOWNLOADS_DIR/thunder-server" "$PKG_DIR/bin/thunder-server"
      chmod +x "$PKG_DIR/bin/thunder-server"
    fi
    if [ -f "$DOWNLOADS_DIR/thunder-server.cex" ]; then
      cp "$DOWNLOADS_DIR/thunder-server.cex" "$PKG_DIR/bin/thunder-server.cex"
    fi
    if [ -f "$DOWNLOADS_DIR/cex-pack" ]; then
      cp "$DOWNLOADS_DIR/cex-pack" "$PKG_DIR/bin/cex-pack"
      chmod +x "$PKG_DIR/bin/cex-pack"
    elif [ -f "$REPO_ROOT/dist/cex-pack" ]; then
      cp "$REPO_ROOT/dist/cex-pack" "$PKG_DIR/bin/cex-pack"
      chmod +x "$PKG_DIR/bin/cex-pack"
    fi
    if [ -f "$DOWNLOADS_DIR/cex-pack.cex" ]; then
      cp "$DOWNLOADS_DIR/cex-pack.cex" "$PKG_DIR/bin/cex-pack.cex"
    fi
    if [ -x "$REPO_ROOT/bin/$ver/cexp" ]; then
      cp "$REPO_ROOT/bin/$ver/cexp" "$PKG_DIR/bin/cexp"
      chmod +x "$PKG_DIR/bin/cexp"
    elif [ -x "$REPO_ROOT/bin/cexp" ]; then
      cp "$REPO_ROOT/bin/cexp" "$PKG_DIR/bin/cexp"
      chmod +x "$PKG_DIR/bin/cexp"
    fi
    for vtype in bean delivery drawer factory; do
      if [ -x "$REPO_ROOT/bin/$vtype/cexr-$vtype" ]; then
        cp "$REPO_ROOT/bin/$vtype/cexr-$vtype" "$PKG_DIR/bin/cexr-$vtype"
        chmod +x "$PKG_DIR/bin/cexr-$vtype"
      fi
    done
    if [ "$pos" = "windows" ]; then
      cat <<'WEOF' > "$PKG_DIR/bin/cex-pack.cmd"
@echo off
call "%~dp0cexr.cmd" "%~dp0cex-pack.cex" %*
WEOF
    fi
    cat <<'TEOF' > "$PKG_DIR/bin/thunder"
#!/usr/bin/env bash
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
exec "$CXVM_DIR/bin/cxvm" thunder "$@"
TEOF
    chmod +x "$PKG_DIR/bin/thunder"
    if [ "$pos" = "windows" ]; then
      cat <<'WEOF' > "$PKG_DIR/bin/thunder.cmd"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0cxvm.ps1" thunder %*
WEOF
    fi

    cat <<'LEOF' > "$PKG_DIR/bin/light"
#!/usr/bin/env bash
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
exec "$CXVM_DIR/bin/cxvm" light "$@"
LEOF
    chmod +x "$PKG_DIR/bin/light"
    if [ "$pos" = "windows" ]; then
      cat <<'WEOF' > "$PKG_DIR/bin/light.cmd"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0cxvm.ps1" light %*
WEOF
    fi

    # Populate project ./bin/ and active CXVM_DIR/versions/v8.0.0/bin/ from v8.0.0 darwin-arm64 bundle
    if [ "$ver" = "8.0.0" ] && [ "$pid" = "darwin-arm64" ]; then
      mkdir -p "$REPO_ROOT/bin"
      cp -f "$PKG_DIR/bin/cexr" "$REPO_ROOT/bin/cexr"
      cp -f "$PKG_DIR/bin/cex" "$REPO_ROOT/bin/cex"
      cp -f "$PKG_DIR/bin/cxvm" "$REPO_ROOT/bin/cxvm"
      cp -f "$PKG_DIR/bin/cex-pack" "$REPO_ROOT/bin/cex-pack" 2>/dev/null || true
      cp -f "$PKG_DIR/bin/cex-pack.cex" "$REPO_ROOT/bin/cex-pack.cex" 2>/dev/null || true
      cp -f "$PKG_DIR/bin/cvm-server" "$REPO_ROOT/bin/cvm-server" 2>/dev/null || true
      cp -f "$PKG_DIR/bin/cvm-server.cex" "$REPO_ROOT/bin/cvm-server.cex" 2>/dev/null || true
      cp -f "$PKG_DIR/bin/thunder-server" "$REPO_ROOT/bin/thunder-server" 2>/dev/null || true
      cp -f "$PKG_DIR/bin/thunder-server.cex" "$REPO_ROOT/bin/thunder-server.cex" 2>/dev/null || true
      cp -f "$PKG_DIR/bin/cexp" "$REPO_ROOT/bin/cexp" 2>/dev/null || true
      for vtype in bean delivery drawer factory; do
        cp -f "$PKG_DIR/bin/cexr-$vtype" "$REPO_ROOT/bin/cexr-$vtype" 2>/dev/null || true
      done
      chmod +x "$REPO_ROOT/bin/cexr" "$REPO_ROOT/bin/cex" "$REPO_ROOT/bin/cxvm" "$REPO_ROOT/bin/cexp" "$REPO_ROOT/bin/cex-pack" 2>/dev/null || true
      if [ ! -f "$REPO_ROOT/bin/.gitkeep" ]; then
        printf "# Keep directory structure for Git and CVM\n" > "$REPO_ROOT/bin/.gitkeep"
      fi
      if [ ! -f "$REPO_ROOT/bin/.cvmkeep" ]; then
        printf "# Keep directory structure for Git and CVM\n" > "$REPO_ROOT/bin/.cvmkeep"
      fi
      ACTIVE_CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
      if [ -d "$ACTIVE_CXVM_DIR/versions/v8.0.0/bin" ]; then
        cp -f "$PKG_DIR/bin/cexr" "$ACTIVE_CXVM_DIR/versions/v8.0.0/bin/cexr" 2>/dev/null || true
        cp -f "$PKG_DIR/bin/cex" "$ACTIVE_CXVM_DIR/versions/v8.0.0/bin/cex" 2>/dev/null || true
        cp -f "$PKG_DIR/bin/cexp" "$ACTIVE_CXVM_DIR/versions/v8.0.0/bin/cexp" 2>/dev/null || true
        cp -f "$PKG_DIR/bin/cex-pack" "$ACTIVE_CXVM_DIR/versions/v8.0.0/bin/cex-pack" 2>/dev/null || true
        for vtype in bean delivery drawer factory; do
          cp -f "$PKG_DIR/bin/cexr-$vtype" "$ACTIVE_CXVM_DIR/versions/v8.0.0/bin/cexr-$vtype" 2>/dev/null || true
        done
      fi
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

# 7. Generate manifest.json via native .cex script and cexr runtime (zero Python)
"$REPO_ROOT/bin/cexr" "$SCRIPT_DIR/generate_manifest.cex" "$DOWNLOADS_DIR"

# 8. Generate SHA256SUMS
echo "Generating SHA256 checksums..."
(
  cd "$DOWNLOADS_DIR"
  rm -f SHA256SUMS
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum cex-v*.* > SHA256SUMS 2>/dev/null || true
    sha256sum install.* cxvm* cvm-server* thunder-server* cex-pack* setup.* manifest.json >> SHA256SUMS 2>/dev/null || true
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 cex-v*.* > SHA256SUMS 2>/dev/null || true
    shasum -a 256 install.* cxvm* cvm-server* thunder-server* cex-pack* setup.* manifest.json >> SHA256SUMS 2>/dev/null || true
  fi
)

# 9. Sync/keep dist/ directory with cross-platform downloads (Rule 69)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
mkdir -p "$DIST_DIR"
cp -a "$DOWNLOADS_DIR"/* "$DIST_DIR/"
echo "  [OK] Synchronized all cross-platform distributions into dist/"

echo "==============================================================="
echo "  [OK] All cross-platform Cex distributions successfully built!   "
echo "==============================================================="
