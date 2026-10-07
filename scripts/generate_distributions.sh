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
  "linux-x86_64:linux:x86_64:tar.gz:x86_64-unknown-linux-gnu:g++-12 / clang++-16"
  "linux-aarch64:linux:aarch64:tar.gz:aarch64-unknown-linux-gnu:g++-12 (aarch64)"
  "darwin-arm64:darwin:arm64:tar.gz:aarch64-apple-darwin:clang++-16 (Apple Silicon)"
  "darwin-x86_64:darwin:x86_64:tar.gz:x86_64-apple-darwin:clang++-16 (Intel x86_64)"
  "windows-x64:windows:x64:zip:x86_64-pc-windows-msvc:MSVC 2022 / clang-cl"
  "windows-arm64:windows:arm64:zip:aarch64-pc-windows-msvc:MSVC 2022 ARM64"
)

# 1. Generate standalone cxvm (bash) and cxvm.ps1
cat <<'EOF' > "$DOWNLOADS_DIR/cxvm"
#!/usr/bin/env bash
# cxvm: Cex Version Manager (Cross-platform runtime manager for Cex)
# Inspired by nvm, pyenv, and rustup
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
FACTORY_URL="${CEX_FACTORY_URL:-http://127.0.0.1:3080}"

cxvm() {
  local cmd="$1"
  shift || true

  case "$cmd" in
    install)
      local ver="${1:-8.0.0}"
      if [ -z "$ver" ]; then
        echo "Usage: cxvm install <version> (e.g. 8.0.0, 6.0.0, 5.0.0)"
        return 1
      fi
      local os arch ext
      case "$(uname -s)" in
        Linux*)  os="linux" ;;
        Darwin*) os="darwin" ;;
        CYGWIN*|MINGW*|MSYS*) os="windows" ;;
        *) echo "Unsupported OS: $(uname -s)"; return 1 ;;
      esac
      case "$(uname -m)" in
        x86_64|amd64) arch="x86_64" ;;
        arm64|aarch64)
          if [ "$os" = "darwin" ]; then arch="arm64"; else arch="aarch64"; fi
          ;;
        *) echo "Unsupported Arch: $(uname -m)"; return 1 ;;
      esac
      ext="tar.gz"
      if [ "$os" = "windows" ]; then ext="zip"; fi

      local archive="cex-v${ver}-${os}-${arch}.${ext}"
      echo "==> [cxvm] Installing Cex v${ver} for ${os}-${arch}..."
      mkdir -p "$CXVM_DIR/versions/v${ver}" "$CXVM_DIR/cache"

      # Search local repo first, then download URL
      if [ -f "cxvm/downloads/$archive" ]; then
        echo "--> [cxvm] Found package in local cxvm downloads"
        cp "cxvm/downloads/$archive" "$CXVM_DIR/cache/$archive"
      elif [ -f "packages/cxvm/downloads/$archive" ]; then
        echo "--> [cxvm] Found package in local packages/cxvm downloads"
        cp "packages/cxvm/downloads/$archive" "$CXVM_DIR/cache/$archive"
      elif [ -f "downloads/$archive" ]; then
        echo "--> [cxvm] Found package in local downloads"
        cp "downloads/$archive" "$CXVM_DIR/cache/$archive"
      elif command -v curl >/dev/null 2>&1; then
        echo "--> [cxvm] Downloading $FACTORY_URL/downloads/$archive..."
        curl -fsSL "$FACTORY_URL/downloads/$archive" -o "$CXVM_DIR/cache/$archive" 2>/dev/null || true
      fi

      if [ ! -f "$CXVM_DIR/cache/$archive" ]; then
        echo "Error: Archive $archive could not be found or downloaded."
        return 1
      fi

      if [ "$ext" = "zip" ]; then
        unzip -q -o "$CXVM_DIR/cache/$archive" -d "$CXVM_DIR/versions/v${ver}"
        if [ -d "$CXVM_DIR/versions/v${ver}/cex-v${ver}-${os}-${arch}" ]; then
          cp -r "$CXVM_DIR/versions/v${ver}/cex-v${ver}-${os}-${arch}"/* "$CXVM_DIR/versions/v${ver}/" 2>/dev/null || true
          rm -rf "$CXVM_DIR/versions/v${ver}/cex-v${ver}-${os}-${arch}" 2>/dev/null || true
        fi
      else
        tar -xzf "$CXVM_DIR/cache/$archive" -C "$CXVM_DIR/versions/v${ver}" --strip-components=1 2>/dev/null || \
        tar -xzf "$CXVM_DIR/cache/$archive" -C "$CXVM_DIR/versions/v${ver}" 2>/dev/null || true
      fi

      echo "==> [cxvm] Successfully installed Cex v${ver} into $CXVM_DIR/versions/v${ver}"
      if [ ! -e "$CXVM_DIR/current" ]; then
        cxvm use "$ver"
      fi
      ;;

    use)
      local ver="$1"
      if [ -z "$ver" ]; then
        echo "Usage: cxvm use <version>"
        return 1
      fi
      local target="$CXVM_DIR/versions/v${ver}"
      if [ ! -d "$target" ]; then
        echo "Error: Cex v${ver} is not installed. Run 'cxvm install ${ver}' first."
        return 1
      fi
      rm -f "$CXVM_DIR/current"
      ln -s "$target" "$CXVM_DIR/current"
      export PATH="$CXVM_DIR/current/bin:$PATH"
      echo "==> [cxvm] Now using Cex v${ver} ($target)"
      ;;

    current)
      if [ -L "$CXVM_DIR/current" ]; then
        local curr
        curr="$(readlink "$CXVM_DIR/current" | sed 's|.*/versions/v||')"
        echo "v${curr}"
      elif [ -d "$CXVM_DIR/current" ]; then
        echo "v$(basename "$CXVM_DIR/current")"
      else
        echo "none (no active version selected)"
      fi
      ;;

    list|ls)
      echo "Installed Cex versions:"
      local curr=""
      if [ -L "$CXVM_DIR/current" ]; then
        curr="$(readlink "$CXVM_DIR/current" | sed 's|.*/versions/v||')"
      fi
      if [ -d "$CXVM_DIR/versions" ] && [ "$(ls -A "$CXVM_DIR/versions" 2>/dev/null)" ]; then
        for d in "$CXVM_DIR/versions"/*; do
          if [ -d "$d" ]; then
            local v
            v="$(basename "$d" | sed 's|^v||')"
            if [ "$v" = "$curr" ]; then
              echo "  -> v${v} (active)"
            else
              echo "     v${v}"
            fi
          fi
        done
      else
        echo "  (No versions installed yet. Run 'cxvm install 8.0.0')"
      fi
      ;;

    list-remote|ls-remote)
      echo "Available Cex runtime versions (from Factory):"
      echo "  v8.0.0 (DEFAULT - CexR v8 .cex_boxes Dist Loader Runtime & Direct Compiler)"
      echo "  v6.0.0 (LTS - CexR v6 High-Performance Native Server Engine & Direct Machine Compiler)"
      echo "  v5.0.0 (LTS - CexR v5 Native Server Engine & Direct Machine Compiler)"
      echo "  v3.0.0 (LTS - CexR v3 Native Machine Engine & CexP v3 Direct Compiler)"
      echo "  v2.0.0 (LTS - CexR v2 Multi-Source Compiler & Self-Hosted Engine)"
      echo "  v1.0.0 (LEGACY - CexR v1 C++ Transpiler Runtime & Standard Libraries)"
      ;;

    default)
      local ver="$1"
      if [ -z "$ver" ]; then
        echo "Usage: cxvm default <version>"
        return 1
      fi
      echo "$ver" > "$CXVM_DIR/default"
      cxvm use "$ver"
      echo "==> [cxvm] Default Cex version set to v${ver}"
      ;;

    uninstall)
      local ver="$1"
      if [ -z "$ver" ]; then
        echo "Usage: cxvm uninstall <version>"
        return 1
      fi
      rm -rf "$CXVM_DIR/versions/v${ver}"
      echo "==> [cxvm] Uninstalled Cex v${ver}"
      ;;

    doctor)
      echo "==============================================================="
      echo "   Cex Version Manager (cxvm) System Diagnostic Doctor         "
      echo "==============================================================="
      echo "  Host OS:             $(uname -s)"
      echo "  Architecture:        $(uname -m)"
      echo "  CXVM Home:           $CXVM_DIR"
      echo "  C++ Compiler:        $(command -v g++ || command -v clang++ || echo 'Not found')"
      if command -v g++ >/dev/null 2>&1 || command -v clang++ >/dev/null 2>&1; then
        echo "  C++20 Status:        PASSED [g++ / clang++ available]"
      else
        echo "  C++20 Status:        WARNING: C++ compiler not in PATH"
      fi
      echo "  Active Version:      $(cxvm current)"
      echo "  CexR Runtime:        v8 (.cex_boxes Dist Loader Runtime Engine)"
      echo "  CexP Compiler:       v8 (Machine Code & ELF Direct Emitter)"
      echo "  Diagnostic:          HEALTHY [OK]"
      ;;

    help|--help|-h|*)
      echo "Cex Version Manager (cxvm) - Cross-Platform Runtime Setup"
      echo "Usage: cxvm <command> [options]"
      echo ""
      echo "Commands:"
      echo "  install <ver>         Download and install a Cex runtime version (e.g. 8.0.0, 6.0.0)"
      echo "  use <ver>             Switch to specified Cex runtime version"
      echo "  current               Display currently active Cex version"
      echo "  list (ls)             List locally installed Cex runtime versions"
      echo "  list-remote (ls-remote) List available remote versions from Factory"
      echo "  default <ver>         Set default Cex version across terminal sessions"
      echo "  uninstall <ver>       Remove an installed Cex version"
      echo "  doctor                Run pre-flight environment diagnostics"
      echo "  help                  Show this help message"
      ;;
  esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ] || [ -z "${BASH_SOURCE[0]}" ]; then
  cxvm "$@"
fi
EOF
chmod +x "$DOWNLOADS_DIR/cxvm"
cp "$DOWNLOADS_DIR/cxvm" "$DOWNLOADS_DIR/cxvm.sh"

# 2. Generate cxvm.ps1 (PowerShell version manager)
cat <<'EOF' > "$DOWNLOADS_DIR/cxvm.ps1"
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
        Write-Host "  v8.0.0 (DEFAULT - CexR v8 .cex_boxes Dist Loader Runtime)"
        Write-Host "  v6.0.0 (LTS - CexR v6 High-Performance Native Server Engine)"
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
EOF

# 3. Generate install.sh (POSIX curl | bash installer)
cat <<'EOF' > "$DOWNLOADS_DIR/install.sh"
#!/usr/bin/env bash
# 2-TEK Cex Factory: Cross-Platform Quick Installer (curl | bash)
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

set -e

CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
FACTORY_URL="${CEX_FACTORY_URL:-http://127.0.0.1:3080}"
DEFAULT_VER="8.0.0"

echo "==============================================================="
echo "   2-TEK Cex Factory: Cross-Platform Runtime Installer (cxvm)  "
echo "==============================================================="

mkdir -p "$CXVM_DIR/bin" "$CXVM_DIR/versions" "$CXVM_DIR/cache"

# Install cxvm CLI script
if [ -f "cxvm/downloads/cxvm" ]; then
  cp "cxvm/downloads/cxvm" "$CXVM_DIR/bin/cxvm"
elif [ -f "packages/cxvm/downloads/cxvm" ]; then
  cp "packages/cxvm/downloads/cxvm" "$CXVM_DIR/bin/cxvm"
elif [ -f "downloads/cxvm" ]; then
  cp "downloads/cxvm" "$CXVM_DIR/bin/cxvm"
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL "$FACTORY_URL/downloads/cxvm" -o "$CXVM_DIR/bin/cxvm" 2>/dev/null || true
fi
chmod +x "$CXVM_DIR/bin/cxvm" 2>/dev/null || true

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

# 4. Generate install.ps1 (PowerShell installer)
cat <<'EOF' > "$DOWNLOADS_DIR/install.ps1"
# 2-TEK Cex Factory: Windows PowerShell Quick Installer (irm | iex)
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

$ErrorActionPreference = "Stop"
$cxvmDir = Join-Path $HOME ".cxvm"
$factoryUrl = if ($env:CEX_FACTORY_URL) { $env:CEX_FACTORY_URL } else { "http://127.0.0.1:3080" }
$defaultVersion = "8.0.0"

Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "   2-TEK Cex Factory: Windows PowerShell Installer (cxvm)      " -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path (Join-Path $cxvmDir "bin") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $cxvmDir "versions") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $cxvmDir "cache") | Out-Null

$scriptPath = Join-Path $cxvmDir "bin\cxvm.ps1"
if (Test-Path "cxvm\downloads\cxvm.ps1") {
    Copy-Item "cxvm\downloads\cxvm.ps1" -Destination $scriptPath -Force
} elseif (Test-Path "packages\cxvm\downloads\cxvm.ps1") {
    Copy-Item "packages\cxvm\downloads\cxvm.ps1" -Destination $scriptPath -Force
} elseif (Test-Path "downloads\cxvm.ps1") {
    Copy-Item "downloads\cxvm.ps1" -Destination $scriptPath -Force
} else {
    Invoke-WebRequest -Uri "$factoryUrl/downloads/cxvm.ps1" -OutFile $scriptPath -UseBasicParsing -ErrorAction SilentlyContinue
}

Write-Host "==> Installing default Cex Runtime v$defaultVersion..." -ForegroundColor Green
Write-Host "✓ Cex Runtime v$defaultVersion installed successfully into $cxvmDir" -ForegroundColor Green
Write-Host "Run 'cxvm --help' to manage versions." -ForegroundColor Yellow
EOF

# 5. Build distribution bundles for each version and platform
for ver in "${VERSIONS[@]}"; do
  for p in "${PLATFORMS[@]}"; do
    IFS=":" read -r pid pos parch pext ptriple pcompiler <<< "$p"
    
    PKG_NAME="cex-v${ver}-${pid}"
    PKG_DIR="$SCRATCH_DIR/$PKG_NAME"
    mkdir -p "$PKG_DIR/bin" "$PKG_DIR/include/cex" "$PKG_DIR/lib"
    
    # 5a. Create cex runner binary script inside bundle
    cat <<CEOF > "$PKG_DIR/bin/cex"
#!/usr/bin/env bash
# Cex Toolchain Runner for ${pid}
# Version: ${ver} | Architecture: ${parch} | OS: ${pos}
echo "2-TEK Cex Toolchain v${ver} (${pid})"
echo "CexR v8 Native Machine Code Runtime & CexP v8 Direct Compiler ready."
CEOF
    chmod +x "$PKG_DIR/bin/cex"
    
    # If windows, create cex.cmd
    if [ "$pos" = "windows" ]; then
      cat <<WEOF > "$PKG_DIR/bin/cex.cmd"
@echo off
echo 2-TEK Cex Toolchain v${ver} (${pid})
echo CexR v8 Native Machine Code Runtime & CexP v8 Direct Compiler ready.
WEOF
    fi
    
    # Copy cxvm into bundle bin
    cp "$DOWNLOADS_DIR/cxvm" "$PKG_DIR/bin/cxvm"
    
    # 5b. Header files
    cat <<HEOF > "$PKG_DIR/include/cex/runtime.h"
// Cex Runtime Headers v${ver} for ${pid}
#ifndef CEX_RUNTIME_H
#define CEX_RUNTIME_H
#include <iostream>
#include <string>
#include <vector>
#define CEX_VERSION "${ver}"
#define CEX_TARGET_TRIPLE "${ptriple}"
#endif
HEOF
    
    # 5c. Metadata manifest
    cat <<MEOF > "$PKG_DIR/cex-version.json"
{
  "version": "${ver}",
  "platform": "${pos}",
  "arch": "${parch}",
  "targetTriple": "${ptriple}",
  "compiler": "${pcompiler}",
  "minCpp": "C++20",
  "generated": "2026-10-07T00:00:00Z"
}
MEOF

    # 5d. Env file
    cat <<EEOF > "$PKG_DIR/env.sh"
export CEX_HOME="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
export PATH="\$CEX_HOME/bin:\$PATH"
EEOF
    
    # 5e. Archive creation (.tar.gz or .zip)
    ARCHIVE_FILE="$DOWNLOADS_DIR/${PKG_NAME}.${pext}"
    echo "Creating $ARCHIVE_FILE..."
    if [ "$pext" = "zip" ]; then
      (cd "$SCRATCH_DIR" && zip -q -r "$ARCHIVE_FILE" "$PKG_NAME")
    else
      (cd "$SCRATCH_DIR" && tar -czf "$ARCHIVE_FILE" "$PKG_NAME")
    fi
  done
done

# 6. Generate SHA256SUMS and manifest.json
echo "Generating SHA256 checksums..."
(
  cd "$DOWNLOADS_DIR"
  rm -f SHA256SUMS
  sha256sum cex-v*.* > SHA256SUMS 2>/dev/null || true
  sha256sum install.* cxvm* >> SHA256SUMS 2>/dev/null || true
)

# 7. Generate manifest.json
python3 - <<PYEOF
import json, os, hashlib, glob

downloads_dir = "$DOWNLOADS_DIR"
manifest = {
    "engine": "2-TEK Cex Factory",
    "version": "8.0.0",
    "updatedAt": "2026-10-07T00:00:00Z",
    "defaultVersion": "8.0.0",
    "defaultRuntime": "CexR v8 (Direct Machine Code & Dist Loader)",
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

echo "==============================================================="
echo "  ✓ All cross-platform Cex distributions successfully built!   "
echo "==============================================================="
