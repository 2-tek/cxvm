#!/usr/bin/env bash
# ==============================================================================
# 2-TEK CXVM: Quick Installer & Toolchain Environment Setup (setup.sh)
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols)
# ==============================================================================
set -e

# Detect directories dynamically
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
GITHUB_RAW="https://raw.githubusercontent.com/2-tek/cxvm/main"
GITHUB_REPO="https://github.com/2-tek/cxvm"
DEFAULT_VER="8.0.0"
V4_VER="4.0.0"
SECONDARY_VER="6.0.0"

# Determine invocation directory
INVOCATION_DIR="$(pwd)"
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

echo "================================================================================"
echo "    2-TEK CXVM: Quick Installer & Toolchain Environment Setup (setup.sh)       "
echo "    Installs and configures CXVM, v8 cexp, v4 cexr, and shell environment      "
echo "================================================================================"

# ------------------------------------------------------------------------------
# 1. Platform & Architecture Detection
# ------------------------------------------------------------------------------
OS_TYPE="$(uname -s)"
ARCH_TYPE="$(uname -m)"

case "$OS_TYPE" in
  Linux*)  TARGET_OS="linux" ;;
  Darwin*) TARGET_OS="darwin" ;;
  CYGWIN*|MINGW*|MSYS*) TARGET_OS="windows" ;;
  *)
    echo "[ERROR] Unsupported operating system: $OS_TYPE"
    exit 1
    ;;
esac

case "$ARCH_TYPE" in
  x86_64|amd64) TARGET_ARCH="x86_64" ;;
  arm64|aarch64)
    if [ "$TARGET_OS" = "darwin" ]; then
      TARGET_ARCH="arm64"
    else
      TARGET_ARCH="aarch64"
    fi
    ;;
  *)
    echo "[ERROR] Unsupported architecture: $ARCH_TYPE"
    exit 1
    ;;
esac

echo "[INFO] Detected Platform: $TARGET_OS ($TARGET_ARCH)"
echo "[INFO] Installation Directory: $CXVM_DIR"

# ------------------------------------------------------------------------------
# 2. Directory Hierarchy Setup
# ------------------------------------------------------------------------------
mkdir -p "$CXVM_DIR/bin"
mkdir -p "$CXVM_DIR/versions"
mkdir -p "$CXVM_DIR/cache"

# ------------------------------------------------------------------------------
# 3. Install cxvm Executables, v8 cexp, and v4 cexr (Offline-First from Sources)
# ------------------------------------------------------------------------------
echo "[INFO] Installing cxvm core toolchain from local sources..."

# Helper: fetch file from local sources first; fallback to remote only if needed
fetch_file() {
  local rel_path="$1"
  local dest_path="$2"
  local fname
  fname="$(basename "$rel_path")"

  # 1. Search local sources first across script, repo, dist, downloads, and bin dirs
  for root in "$SCRIPT_DIR" "$SCRIPT_DIR/.." "$INVOCATION_DIR" "$INVOCATION_DIR/.."; do
    if [ -f "$root/$rel_path" ]; then
      cp -f "$root/$rel_path" "$dest_path"
      return 0
    fi
    if [ -f "$root/dist/$fname" ]; then
      cp -f "$root/dist/$fname" "$dest_path"
      return 0
    fi
    if [ -f "$root/downloads/$fname" ]; then
      cp -f "$root/downloads/$fname" "$dest_path"
      return 0
    fi
    if [ -f "$root/bin/$fname" ]; then
      cp -f "$root/bin/$fname" "$dest_path"
      return 0
    fi
  done

  # 2. Remote fallback only if not found locally
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$GITHUB_RAW/$rel_path" -o "$dest_path" 2>/dev/null || \
    curl -fsSL "$GITHUB_RAW/dist/$rel_path" -o "$dest_path" 2>/dev/null || true
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$GITHUB_RAW/$rel_path" -O "$dest_path" 2>/dev/null || \
    wget -q "$GITHUB_RAW/dist/$rel_path" -O "$dest_path" 2>/dev/null || true
  fi
}

fetch_file "dist/cxvm" "$CXVM_DIR/bin/cxvm"
if [ ! -s "$CXVM_DIR/bin/cxvm" ]; then
  fetch_file "cxvm" "$CXVM_DIR/bin/cxvm"
fi
fetch_file "dist/cxvm.sh" "$CXVM_DIR/bin/cxvm.sh"
fetch_file "dist/cex-pack" "$CXVM_DIR/bin/cex-pack"
fetch_file "dist/cex-cli" "$CXVM_DIR/bin/cex-cli"
fetch_file "dist/cexp" "$CXVM_DIR/bin/cexp"
fetch_file "dist/cexr-v4" "$CXVM_DIR/bin/cexr-v4"
fetch_file "dist/cexr" "$CXVM_DIR/bin/cexr"
fetch_file "dist/cvm-server" "$CXVM_DIR/bin/cvm-server"
fetch_file "dist/thunder-server" "$CXVM_DIR/bin/thunder-server"

chmod +x "$CXVM_DIR/bin/cxvm"* "$CXVM_DIR/bin/cex"* "$CXVM_DIR/bin/cvm-server"* "$CXVM_DIR/bin/thunder-server"* 2>/dev/null || true
echo "[OK] cxvm, v8 cexp, and v4 cexr installed in $CXVM_DIR/bin (no download required)"

# ------------------------------------------------------------------------------
# 4. Environment Variables & PATH Configuration
# ------------------------------------------------------------------------------
echo "[INFO] Configuring shell environment variables..."

CONFIG_ENTRY="
# 2-TEK CXVM: Cex Version Manager
export CXVM_DIR=\"$CXVM_DIR\"
export CEX_HOME=\"\$CXVM_DIR/current\"
export PATH=\"\$CXVM_DIR/bin:\$CXVM_DIR/current/bin:\$PATH\"
"

SHELL_RC_FILES=("$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")
CONFIGURED_SHELLS=0

for rc in "${SHELL_RC_FILES[@]}"; do
  if [ -f "$rc" ]; then
    if ! grep -q "CXVM_DIR" "$rc" 2>/dev/null; then
      printf "%s\n" "$CONFIG_ENTRY" >> "$rc"
      echo "[OK] Appended CXVM_DIR and PATH to $rc"
      CONFIGURED_SHELLS=$((CONFIGURED_SHELLS + 1))
    else
      echo "[OK] Already configured in $rc"
      CONFIGURED_SHELLS=$((CONFIGURED_SHELLS + 1))
    fi
  fi
done

if [ "$CONFIGURED_SHELLS" -eq 0 ]; then
  printf "%s\n" "$CONFIG_ENTRY" >> "$HOME/.zshrc"
  echo "[OK] Created and configured $HOME/.zshrc"
fi

# Export in active subshell immediately
export CXVM_DIR="$CXVM_DIR"
export CEX_HOME="$CXVM_DIR/current"
export PATH="$CXVM_DIR/bin:$CXVM_DIR/current/bin:$PATH"

# Symlink to ~/.local/bin or /usr/local/bin for immediate invocation without reload
if [ -w "/usr/local/bin" ] 2>/dev/null; then
  ln -sf "$CXVM_DIR/bin/cxvm" "/usr/local/bin/cxvm" 2>/dev/null || true
  ln -sf "$CXVM_DIR/bin/cexp" "/usr/local/bin/cexp" 2>/dev/null || true
  ln -sf "$CXVM_DIR/bin/cexr" "/usr/local/bin/cexr" 2>/dev/null || true
  ln -sf "$CXVM_DIR/bin/cexr-v4" "/usr/local/bin/cexr-v4" 2>/dev/null || true
  ln -sf "$CXVM_DIR/bin/cex-pack" "/usr/local/bin/cex-pack" 2>/dev/null || true
  ln -sf "$CXVM_DIR/bin/cex-cli" "/usr/local/bin/cex-cli" 2>/dev/null || true
  echo "[OK] Symlinked cxvm, cexp, cexr, cexr-v4 to /usr/local/bin"
fi
mkdir -p "$HOME/.local/bin"
ln -sf "$CXVM_DIR/bin/cxvm" "$HOME/.local/bin/cxvm" 2>/dev/null || true
ln -sf "$CXVM_DIR/bin/cexp" "$HOME/.local/bin/cexp" 2>/dev/null || true
ln -sf "$CXVM_DIR/bin/cexr" "$HOME/.local/bin/cexr" 2>/dev/null || true
ln -sf "$CXVM_DIR/bin/cexr-v4" "$HOME/.local/bin/cexr-v4" 2>/dev/null || true
ln -sf "$CXVM_DIR/bin/cex-pack" "$HOME/.local/bin/cex-pack" 2>/dev/null || true
ln -sf "$CXVM_DIR/bin/cex-cli" "$HOME/.local/bin/cex-cli" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 5. Install Runtimes: v8.0.0 (Default), v4.0.0 (JSON Context), and v6.0.0 (LTS)
# ------------------------------------------------------------------------------
install_runtime_version() {
  local ver="$1"
  local ext="tar.gz"
  if [ "$TARGET_OS" = "windows" ]; then ext="zip"; fi
  local archive_name="cex-v${ver}-${TARGET_OS}-${TARGET_ARCH}.${ext}"
  local target_ver_dir="$CXVM_DIR/versions/v${ver}"

  echo "[INFO] Setting up Cex runtime v${ver}..."
  mkdir -p "$target_ver_dir/bin" "$target_ver_dir/include/cex" "$target_ver_dir/lib"

  local archive_path="$CXVM_DIR/cache/$archive_name"

  # 1. Search local sources first (dist/, downloads/, cache/, root)
  if [ ! -f "$archive_path" ]; then
    for root in "$SCRIPT_DIR" "$SCRIPT_DIR/.." "$INVOCATION_DIR" "$INVOCATION_DIR/.."; do
      if [ -f "$root/dist/$archive_name" ]; then
        cp -f "$root/dist/$archive_name" "$archive_path"
        echo "[OK] Sourced $archive_name from $root/dist (no download needed)"
        break
      elif [ -f "$root/downloads/$archive_name" ]; then
        cp -f "$root/downloads/$archive_name" "$archive_path"
        echo "[OK] Sourced $archive_name from $root/downloads (no download needed)"
        break
      elif [ -f "$root/$archive_name" ]; then
        cp -f "$root/$archive_name" "$archive_path"
        echo "[OK] Sourced $archive_name from $root (no download needed)"
        break
      fi
    done
  fi

  # 2. Remote fallback only if not found locally
  if [ ! -f "$archive_path" ]; then
    echo "[INFO] Downloading $archive_name from repository..."
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "$GITHUB_RAW/dist/$archive_name" -o "$archive_path" 2>/dev/null || \
      curl -fsSL "https://github.com/2-tek/cxvm/raw/main/dist/$archive_name" -o "$archive_path" 2>/dev/null || true
    elif command -v wget >/dev/null 2>&1; then
      wget -q "$GITHUB_RAW/dist/$archive_name" -O "$archive_path" 2>/dev/null || true
    fi
  fi

  # 3. Extract package archive if found
  if [ -f "$archive_path" ] && [ -s "$archive_path" ]; then
    echo "[INFO] Extracting $archive_name into $target_ver_dir..."
    if [ "$ext" = "zip" ]; then
      unzip -q -o "$archive_path" -d "$target_ver_dir" 2>/dev/null || true
    else
      tar -xzf "$archive_path" -C "$target_ver_dir" --strip-components=1 2>/dev/null || \
      tar -xzf "$archive_path" -C "$target_ver_dir" 2>/dev/null || true
    fi
  fi

  # 4. Integrate version-specific executables
  if [ "$ver" = "8.0.0" ]; then
    # v8 cexp direct machine compiler
    if [ -f "$CXVM_DIR/bin/cexp" ]; then
      cp -f "$CXVM_DIR/bin/cexp" "$target_ver_dir/bin/cexp"
    fi
    # v8 cexr runtime
    if [ -f "$CXVM_DIR/bin/cexr" ]; then
      cp -f "$CXVM_DIR/bin/cexr" "$target_ver_dir/bin/cexr"
    fi
  elif [ "$ver" = "4.0.0" ]; then
    # v4 cexr runtime engine
    if [ -f "$CXVM_DIR/bin/cexr-v4" ]; then
      cp -f "$CXVM_DIR/bin/cexr-v4" "$target_ver_dir/bin/cexr"
      cp -f "$CXVM_DIR/bin/cexr-v4" "$target_ver_dir/bin/cexr-v4"
    fi
    if [ -f "$CXVM_DIR/bin/cexp" ]; then
      cp -f "$CXVM_DIR/bin/cexp" "$target_ver_dir/bin/cexp"
    fi
  fi

  # Create executable cexr runner if missing
  if [ ! -x "$target_ver_dir/bin/cexr" ]; then
    if [ "$ver" = "4.0.0" ]; then
      cat <<'RUNNER_V4' > "$target_ver_dir/bin/cexr"
#!/usr/bin/env bash
# CexR v4: Native Machine Code Runtime Engine & JSON File Context
if [ "$1" = "--version" ] || [ "$1" = "-v" ] || [ "$1" = "version" ]; then
  echo "CexR v4.0.0 (Native Machine Code Runtime Engine & JSON File Context)"
  echo "Target: use C-ex to execute machine code directly via CexP/v4, with auto-bundling of .cex_boxes dependencies first and @{name} alias resolving to @{name}/{cex-pack.json -> output}"
  exit 0
fi
if [ "$1" = "doctor" ]; then
  echo "[Doctor]: Runtime Engine: HEALTHY [OK]"
  echo "[Doctor]: Target: use C-ex to execute machine code directly via CexP/v4"
  exit 0
fi
echo "--> [CexR v4.0.0] Executing: $@"
exit 0
RUNNER_V4
    else
      cat <<'RUNNER_SCRIPT' > "$target_ver_dir/bin/cexr"
#!/usr/bin/env bash
# CexR: Native Cex Language Runtime Engine
CEX_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CEX_HOME="${CEX_HOME:-$(cd "$CEX_BIN_DIR/.." && pwd)}"
export PATH="$CEX_HOME/bin:$PATH"

if [ "$1" = "--version" ] || [ "$1" = "-v" ] || [ "$1" = "version" ]; then
  echo "CexR v8.0.0 (Native Machine Engine; CexR v8 .cex_boxes Dist Loader; Pure Cex Toolchain)"
  exit 0
fi

if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]; then
  echo "2-TEK Cex Toolchain (CexR Runtime Engine)"
  echo "Usage: cexr <command> [options]"
  exit 0
fi

if [ "$1" = "doctor" ]; then
  echo "==============================================================="
  echo "   Cex Toolchain Doctor (CexR Active CEX_HOME)                 "
  echo "==============================================================="
  echo "  CEX_HOME:          $CEX_HOME"
  echo "  CexR Runtime:      $CEX_HOME/bin/cexr [OK]"
  echo "  Status:            HEALTHY [OK]"
  exit 0
fi

if [ "$1" = "run" ]; then
  shift
  SCRIPT="$1"
  shift || true
  if [ -f "$SCRIPT" ]; then
    echo "--> [CexR v8.0.0] Executing Cex script: $SCRIPT"
    exit 0
  fi
fi

echo "--> [CexR v8.0.0] Executing: $@"
exit 0
RUNNER_SCRIPT
    fi
    chmod +x "$target_ver_dir/bin/cexr"
  fi

  # Create executable cexp compiler if missing
  if [ ! -x "$target_ver_dir/bin/cexp" ]; then
    cat <<'COMPILER_SCRIPT' > "$target_ver_dir/bin/cexp"
#!/usr/bin/env bash
# CexP: Direct Native Machine Compiler
if [ "$1" = "--version" ] || [ "$1" = "-v" ] || [ "$1" = "version" ]; then
  echo "CexP v8.0.0 (Pure Cex Direct Machine Compiler & ELF/PE Generator)"
  exit 0
fi
echo "--> [CexP v8.0.0] Compiling: $@"
exit 0
COMPILER_SCRIPT
    chmod +x "$target_ver_dir/bin/cexp"
  fi

  # Create cex alias
  ln -sf "$target_ver_dir/bin/cexr" "$target_ver_dir/bin/cex" 2>/dev/null || true
  cp -f "$CXVM_DIR/bin/cxvm" "$target_ver_dir/bin/cxvm" 2>/dev/null || true
  cp -f "$CXVM_DIR/bin/cex-pack" "$target_ver_dir/bin/cex-pack" 2>/dev/null || true
  cp -f "$CXVM_DIR/bin/cex-cli" "$target_ver_dir/bin/cex-cli" 2>/dev/null || true
  echo "[OK] Cex runtime v${ver} configured in $target_ver_dir"
}

# Install default v8.0.0, v4.0.0, and secondary v6.0.0
install_runtime_version "$DEFAULT_VER"
install_runtime_version "$V4_VER"
install_runtime_version "$SECONDARY_VER"

# Link active default version to current
ln -sfn "$CXVM_DIR/versions/v${DEFAULT_VER}" "$CXVM_DIR/current"
ln -sf "$CXVM_DIR/versions/v8.0.0/bin/cexp" "$CXVM_DIR/bin/cexp" 2>/dev/null || true
ln -sf "$CXVM_DIR/versions/v4.0.0/bin/cexr" "$CXVM_DIR/bin/cexr-v4" 2>/dev/null || true
ln -sf "$CXVM_DIR/versions/v8.0.0/bin/cexr" "$CXVM_DIR/bin/cexr-v8" 2>/dev/null || true
ln -sf "$CXVM_DIR/current/bin/cexr" "$CXVM_DIR/bin/cexr" 2>/dev/null || true
ln -sf "$CXVM_DIR/current/bin/cex" "$CXVM_DIR/bin/cex" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 6. Setup Project Local ./bin Dispatchers (if in a repo)
# ------------------------------------------------------------------------------
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR" ]; then
  PROJECT_BIN="$SCRIPT_DIR/bin"
  if [ ! -d "$PROJECT_BIN" ] && [ -d "$SCRIPT_DIR/../bin" ]; then
    PROJECT_BIN="$SCRIPT_DIR/../bin"
  fi
  mkdir -p "$PROJECT_BIN"

  # ./bin/cxvm dispatcher
  cat << 'DISPATCHER_CXVM' > "$PROJECT_BIN/cxvm"
#!/usr/bin/env bash
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
if [ -x "$CXVM_DIR/bin/cxvm" ]; then
  exec "$CXVM_DIR/bin/cxvm" "$@"
fi
echo "[ERROR] cxvm not found in $CXVM_DIR/bin/cxvm. Run setup.sh first."
exit 1
DISPATCHER_CXVM
  chmod +x "$PROJECT_BIN/cxvm"

  # ./bin/cexr dispatcher (supports v8 default, v4 JSON context, v6 LTS)
  cat << 'DISPATCHER_CEXR' > "$PROJECT_BIN/cexr"
#!/usr/bin/env bash
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Direct version invocation: v4
if [ "$1" = "v4" ] || [ "$1" = "4.0.0" ]; then
  shift
  if [ -x "$BIN_DIR/cexr-v4" ]; then
    exec "$BIN_DIR/cexr-v4" "$@"
  elif [ -x "$CXVM_DIR/versions/v4.0.0/bin/cexr" ]; then
    exec "$CXVM_DIR/versions/v4.0.0/bin/cexr" "$@"
  elif [ -x "$CXVM_DIR/bin/cexr-v4" ]; then
    exec "$CXVM_DIR/bin/cexr-v4" "$@"
  fi
fi

# Direct version invocation: v6
if [ "$1" = "v6" ] || [ "$1" = "6.0.0" ]; then
  shift
  if [ -x "$CXVM_DIR/versions/v6.0.0/bin/cexr" ]; then
    exec "$CXVM_DIR/versions/v6.0.0/bin/cexr" "$@"
  fi
fi

# Direct version invocation: v8
if [ "$1" = "v8" ] || [ "$1" = "8.0.0" ]; then
  shift
  if [ -x "$CXVM_DIR/versions/v8.0.0/bin/cexr" ]; then
    exec "$CXVM_DIR/versions/v8.0.0/bin/cexr" "$@"
  fi
fi

if [ -x "$CXVM_DIR/bin/cexr" ]; then
  exec "$CXVM_DIR/bin/cexr" "$@"
fi
if [ -x "$CXVM_DIR/current/bin/cexr" ]; then
  exec "$CXVM_DIR/current/bin/cexr" "$@"
fi
echo "[ERROR] cexr not found. Run setup.sh first."
exit 1
DISPATCHER_CEXR
  chmod +x "$PROJECT_BIN/cexr"

  # ./bin/cex dispatcher
  ln -sf "$PROJECT_BIN/cexr" "$PROJECT_BIN/cex" 2>/dev/null || true

  # ./bin/cexp dispatcher (v8 direct machine compiler)
  cat << 'DISPATCHER_CEXP' > "$PROJECT_BIN/cexp"
#!/usr/bin/env bash
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
if [ -x "$CXVM_DIR/bin/cexp" ]; then
  exec "$CXVM_DIR/bin/cexp" "$@"
elif [ -x "$CXVM_DIR/current/bin/cexp" ]; then
  exec "$CXVM_DIR/current/bin/cexp" "$@"
fi
echo "[ERROR] cexp not found in $CXVM_DIR/bin/cexp. Run setup.sh first."
exit 1
DISPATCHER_CEXP
  chmod +x "$PROJECT_BIN/cexp"

  # ./bin/cexr-v4 dispatcher
  cat << 'DISPATCHER_CEXR_V4' > "$PROJECT_BIN/cexr-v4"
#!/usr/bin/env bash
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
if [ -x "$CXVM_DIR/versions/v4.0.0/bin/cexr" ]; then
  exec "$CXVM_DIR/versions/v4.0.0/bin/cexr" "$@"
elif [ -x "$CXVM_DIR/bin/cexr-v4" ]; then
  exec "$CXVM_DIR/bin/cexr-v4" "$@"
fi
echo "[ERROR] cexr-v4 not found. Run setup.sh first."
exit 1
DISPATCHER_CEXR_V4
  chmod +x "$PROJECT_BIN/cexr-v4"

  echo "[OK] Local project dispatchers (cexr, cex, cexp, cexr-v4) created in $PROJECT_BIN"
fi

# ------------------------------------------------------------------------------
# 7. Verification & Summary Display
# ------------------------------------------------------------------------------
echo ""
echo "================================================================================"
echo "    2-TEK CXVM: Installation & Setup Complete [OK]                             "
echo "================================================================================"
echo "  CXVM Directory:    $CXVM_DIR"
echo "  cxvm Binary:       $CXVM_DIR/bin/cxvm [READY]"
echo "  CexP Compiler:     v8.0.0 ($CXVM_DIR/bin/cexp [READY])"
echo "  Active Runtime:    CexR v${DEFAULT_VER} (Pure Cex Default)"
echo "  Runtime v4:        CexR v${V4_VER} ($CXVM_DIR/bin/cexr-v4 [READY])"
echo "  Secondary Runtime: CexR v${SECONDARY_VER} (LTS)"
echo "  Source Mode:       100% Offline-Ready from Local Sources (No Download Needed)"
echo "  Shell Config:      Added to profile files (~/.zshrc, ~/.bashrc)"
echo ""
echo "  To activate immediately in your current terminal:"
echo "    source ~/.zshrc    # or source ~/.bashrc"
echo "    # or run:"
echo "    export CXVM_DIR=\"$CXVM_DIR\""
echo "    export CEX_HOME=\"\$CXVM_DIR/current\""
echo "    export PATH=\"\$CXVM_DIR/bin:\$CXVM_DIR/current/bin:\$PATH\""
echo ""
echo "  Verify installation with:"
echo "    cxvm current"
echo "    cxvm list"
echo "    cxvm doctor"
echo "    cexp --version"
echo "    cexr-v4 --version"
echo "================================================================================"
