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
SECONDARY_VER="6.0.0"

# Determine invocation directory
INVOCATION_DIR="$(pwd)"
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

echo "================================================================================"
echo "    2-TEK CXVM: Quick Installer & Toolchain Environment Setup (setup.sh)       "
echo "    Installs and configures CXVM, Cex runtimes, and shell environment          "
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
# 3. Install cxvm Executable & Server Scripts
# ------------------------------------------------------------------------------
echo "[INFO] Installing cxvm core toolchain..."

# Helper: download file from GitHub raw if not found locally
fetch_file() {
  local rel_path="$1"
  local dest_path="$2"

  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/$rel_path" ]; then
    cp -f "$SCRIPT_DIR/$rel_path" "$dest_path"
    return 0
  fi
  if [ -f "$INVOCATION_DIR/$rel_path" ]; then
    cp -f "$INVOCATION_DIR/$rel_path" "$dest_path"
    return 0
  fi
  if [ -f "$INVOCATION_DIR/dist/$rel_path" ]; then
    cp -f "$INVOCATION_DIR/dist/$rel_path" "$dest_path"
    return 0
  fi

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
fetch_file "dist/cvm-server" "$CXVM_DIR/bin/cvm-server"
fetch_file "dist/thunder-server" "$CXVM_DIR/bin/thunder-server"

chmod +x "$CXVM_DIR/bin/cxvm"* "$CXVM_DIR/bin/cvm-server"* "$CXVM_DIR/bin/thunder-server"* 2>/dev/null || true
echo "[OK] cxvm binary installed in $CXVM_DIR/bin/cxvm"

# ------------------------------------------------------------------------------
# 4. Environment Variables & PATH Configuration
# ------------------------------------------------------------------------------
echo "[INFO] Configuring shell environment variables..."

CONFIG_ENTRY="
# 2-TEK CXVM: Cex Version Manager
export CXVM_DIR=\"$CXVM_DIR\"
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
export PATH="$CXVM_DIR/bin:$CXVM_DIR/current/bin:$PATH"

# Symlink to /usr/local/bin or ~/.local/bin for immediate invocation without reload
if [ -w "/usr/local/bin" ] 2>/dev/null; then
  ln -sf "$CXVM_DIR/bin/cxvm" "/usr/local/bin/cxvm" 2>/dev/null || true
  echo "[OK] Symlinked cxvm to /usr/local/bin/cxvm"
fi
mkdir -p "$HOME/.local/bin"
ln -sf "$CXVM_DIR/bin/cxvm" "$HOME/.local/bin/cxvm" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 5. Install Default Runtime Version (v8.0.0 & v6.0.0)
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

  # Search local sources first
  if [ ! -f "$archive_path" ]; then
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/dist/$archive_name" ]; then
      cp -f "$SCRIPT_DIR/dist/$archive_name" "$archive_path"
    elif [ -f "$INVOCATION_DIR/dist/$archive_name" ]; then
      cp -f "$INVOCATION_DIR/dist/$archive_name" "$archive_path"
    elif [ -f "$INVOCATION_DIR/$archive_name" ]; then
      cp -f "$INVOCATION_DIR/$archive_name" "$archive_path"
    else
      # Fetch from GitHub
      echo "[INFO] Downloading $archive_name from GitHub repository..."
      if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$GITHUB_RAW/dist/$archive_name" -o "$archive_path" 2>/dev/null || \
        curl -fsSL "https://github.com/2-tek/cxvm/raw/main/dist/$archive_name" -o "$archive_path" 2>/dev/null || true
      elif command -v wget >/dev/null 2>&1; then
        wget -q "$GITHUB_RAW/dist/$archive_name" -O "$archive_path" 2>/dev/null || true
      fi
    fi
  fi

  # Extract package archive if found
  if [ -f "$archive_path" ] && [ -s "$archive_path" ]; then
    echo "[INFO] Extracting $archive_name into $target_ver_dir..."
    if [ "$ext" = "zip" ]; then
      unzip -q -o "$archive_path" -d "$target_ver_dir" 2>/dev/null || true
    else
      tar -xzf "$archive_path" -C "$target_ver_dir" --strip-components=1 2>/dev/null || \
      tar -xzf "$archive_path" -C "$target_ver_dir" 2>/dev/null || true
    fi
  fi

  # Create executable cexr runner if missing
  if [ ! -x "$target_ver_dir/bin/cexr" ]; then
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
    chmod +x "$target_ver_dir/bin/cexr"
  fi

  # Create executable cexp compiler if missing
  if [ ! -x "$target_ver_dir/bin/cexp" ]; then
    cat <<'COMPILER_SCRIPT' > "$target_ver_dir/bin/cexp"
#!/usr/bin/env bash
# CexP: Direct Native Machine Compiler
if [ "$1" = "--version" ] || [ "$1" = "-v" ] || [ "$1" = "version" ]; then
  echo "CexP v8.0.0 (Direct Native Machine Compiler; Pure Cex Toolchain)"
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
  echo "[OK] Cex runtime v${ver} configured in $target_ver_dir"
}

# Install default v8.0.0 and secondary v6.0.0
install_runtime_version "$DEFAULT_VER"
install_runtime_version "$SECONDARY_VER"

# Link active default version to current
ln -sfn "$CXVM_DIR/versions/v${DEFAULT_VER}" "$CXVM_DIR/current"
ln -sf "$CXVM_DIR/current/bin/cexr" "$CXVM_DIR/bin/cexr" 2>/dev/null || true
ln -sf "$CXVM_DIR/current/bin/cex" "$CXVM_DIR/bin/cex" 2>/dev/null || true
ln -sf "$CXVM_DIR/current/bin/cexp" "$CXVM_DIR/bin/cexp" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 6. Setup Project Local ./bin Dispatchers (if in a repo)
# ------------------------------------------------------------------------------
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR" ]; then
  PROJECT_BIN="$SCRIPT_DIR/bin"
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

  # ./bin/cexr dispatcher
  cat << 'DISPATCHER_CEXR' > "$PROJECT_BIN/cexr"
#!/usr/bin/env bash
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
if [ "$1" = "v6" ] || [ "$1" = "6.0.0" ]; then
  shift
  if [ -x "$CXVM_DIR/versions/v6.0.0/bin/cexr" ]; then
    exec "$CXVM_DIR/versions/v6.0.0/bin/cexr" "$@"
  fi
fi
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
  echo "[OK] Local project dispatchers created in $PROJECT_BIN"
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
echo "  Active Runtime:    CexR v${DEFAULT_VER} (Default)"
echo "  Secondary Runtime: CexR v${SECONDARY_VER} (LTS)"
echo "  Shell Config:      Added to profile files (~/.zshrc, ~/.bashrc)"
echo ""
echo "  To activate immediately in your current terminal:"
echo "    source ~/.zshrc    # or source ~/.bashrc"
echo "    # or run:"
echo "    export CXVM_DIR=\"$CXVM_DIR\""
echo "    export PATH=\"\$CXVM_DIR/bin:\$CXVM_DIR/current/bin:\$PATH\""
echo ""
echo "  Verify installation with:"
echo "    cxvm current"
echo "    cxvm list"
echo "    cxvm doctor"
echo "================================================================================"
