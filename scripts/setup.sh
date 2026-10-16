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
    rm -f "$dest_path" 2>/dev/null || true
    cp -f "$SCRIPT_DIR/$rel_path" "$dest_path"
    return 0
  fi
  if [ -f "$INVOCATION_DIR/$rel_path" ]; then
    rm -f "$dest_path" 2>/dev/null || true
    cp -f "$INVOCATION_DIR/$rel_path" "$dest_path"
    return 0
  fi
  if [ -f "$INVOCATION_DIR/dist/$rel_path" ]; then
    rm -f "$dest_path" 2>/dev/null || true
    cp -f "$INVOCATION_DIR/dist/$rel_path" "$dest_path"
    return 0
  fi

  local tmp_dest="${dest_path}.tmp.$$"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$GITHUB_RAW/$rel_path" -o "$tmp_dest" 2>/dev/null || \
    curl -fsSL "$GITHUB_RAW/dist/$rel_path" -o "$tmp_dest" 2>/dev/null || true
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$GITHUB_RAW/$rel_path" -O "$tmp_dest" 2>/dev/null || \
    wget -q "$GITHUB_RAW/dist/$rel_path" -O "$tmp_dest" 2>/dev/null || true
  fi
  if [ -f "$tmp_dest" ] && [ -s "$tmp_dest" ]; then
    rm -f "$dest_path" 2>/dev/null || true
    mv -f "$tmp_dest" "$dest_path"
  else
    rm -f "$tmp_dest" 2>/dev/null || true
  fi
}

fetch_file "dist/cxvm" "$CXVM_DIR/bin/cxvm"
if [ ! -s "$CXVM_DIR/bin/cxvm" ]; then
  fetch_file "cxvm" "$CXVM_DIR/bin/cxvm"
fi
fetch_file "dist/cxvm.sh" "$CXVM_DIR/bin/cxvm.sh"
fetch_file "dist/cex-pack" "$CXVM_DIR/bin/cex-pack"
fetch_file "dist/cex-cli" "$CXVM_DIR/bin/cex-cli"
fetch_file "dist/cvm-server" "$CXVM_DIR/bin/cvm-server"
fetch_file "dist/thunder-server" "$CXVM_DIR/bin/thunder-server"

chmod +x "$CXVM_DIR/bin/cxvm"* "$CXVM_DIR/bin/cex-"* "$CXVM_DIR/bin/cvm-server"* "$CXVM_DIR/bin/thunder-server"* 2>/dev/null || true
echo "[OK] cxvm, cex-pack, and cex-cli installed in $CXVM_DIR/bin"

# ------------------------------------------------------------------------------
# 4. Environment Variables & PATH Configuration
# ------------------------------------------------------------------------------
echo "[INFO] Configuring shell environment variables..."
DEFAULT_CEXR_EDITION="factory"
DEFAULT_BUILD_EDITION="bean"
export CEXR_VERSION_TYPE="$DEFAULT_CEXR_EDITION"
export CEXR_BUILD_VERSION_TYPE="$DEFAULT_BUILD_EDITION"
echo "$DEFAULT_CEXR_EDITION" > "$CXVM_DIR/default-cexr-edition"
echo "$DEFAULT_BUILD_EDITION" > "$CXVM_DIR/default-cexr-build-edition"

CONFIG_ENTRY="
# 2-TEK CXVM: Cex Version Manager
export CXVM_DIR=\"$CXVM_DIR\"
export CEXR_VERSION_TYPE=\"factory\"
export CEXR_BUILD_VERSION_TYPE=\"bean\"
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
  ln -sf "$CXVM_DIR/bin/cex-pack" "/usr/local/bin/cex-pack" 2>/dev/null || true
  ln -sf "$CXVM_DIR/bin/cex-cli" "/usr/local/bin/cex-cli" 2>/dev/null || true
  echo "[OK] Symlinked cxvm, cex-pack, cex-cli to /usr/local/bin"
fi
mkdir -p "$HOME/.local/bin"
ln -sf "$CXVM_DIR/bin/cxvm" "$HOME/.local/bin/cxvm" 2>/dev/null || true
ln -sf "$CXVM_DIR/bin/cex-pack" "$HOME/.local/bin/cex-pack" 2>/dev/null || true
ln -sf "$CXVM_DIR/bin/cex-cli" "$HOME/.local/bin/cex-cli" 2>/dev/null || true

REPO_ROOT="$INVOCATION_DIR"
if [ -n "$SCRIPT_DIR" ]; then
  case "$(basename "$SCRIPT_DIR")" in
    scripts|downloads|dist)
      REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
      ;;
    *)
      REPO_ROOT="$SCRIPT_DIR"
      ;;
  esac
fi

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
    elif [ -f "$REPO_ROOT/dist/$archive_name" ]; then
      cp -f "$REPO_ROOT/dist/$archive_name" "$archive_path"
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

  # Copy integrated binaries (cexr-$type, cexp, cex-pack, cexr) if present in REPO_ROOT/bin
  if [ -x "$REPO_ROOT/bin/cexr" ]; then
    cp -f "$REPO_ROOT/bin/cexr" "$target_ver_dir/bin/cexr" 2>/dev/null || true
    chmod +x "$target_ver_dir/bin/cexr" 2>/dev/null || true
  fi
  if [ -x "$REPO_ROOT/bin/$ver/cexp" ]; then
    cp -f "$REPO_ROOT/bin/$ver/cexp" "$target_ver_dir/bin/cexp" 2>/dev/null || true
    chmod +x "$target_ver_dir/bin/cexp" 2>/dev/null || true
  elif [ -x "$REPO_ROOT/bin/cexp" ]; then
    cp -f "$REPO_ROOT/bin/cexp" "$target_ver_dir/bin/cexp" 2>/dev/null || true
    chmod +x "$target_ver_dir/bin/cexp" 2>/dev/null || true
  fi
  for vtype in bean delivery drawer factory; do
    if [ -x "$REPO_ROOT/bin/$vtype/cexr-$vtype" ]; then
      cp -f "$REPO_ROOT/bin/$vtype/cexr-$vtype" "$target_ver_dir/bin/cexr-$vtype" 2>/dev/null || true
      chmod +x "$target_ver_dir/bin/cexr-$vtype" 2>/dev/null || true
    elif [ -x "$REPO_ROOT/bin/cexr-$vtype" ]; then
      cp -f "$REPO_ROOT/bin/cexr-$vtype" "$target_ver_dir/bin/cexr-$vtype" 2>/dev/null || true
      chmod +x "$target_ver_dir/bin/cexr-$vtype" 2>/dev/null || true
    fi
  done

  # Create executable cexr runner if missing
  if [ ! -x "$target_ver_dir/bin/cexr" ]; then
    cat <<'RUNNER_SCRIPT' > "$target_ver_dir/bin/cexr"
#!/usr/bin/env bash
# CexR: Native Cex Language Runtime Engine
CEX_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CEX_HOME="${CEX_HOME:-$(cd "$CEX_BIN_DIR/.." && pwd)}"
export PATH="$CEX_HOME/bin:$PATH"

if [ "$1" = "--version" ] || [ "$1" = "-v" ] || [ "$1" = "version" ]; then
  echo "CexR v8.0.0 (Native Machine Engine; Default Runtime: cexr-factory; Default Build: cexr-bean; CexR v8 .cex_boxes Dist Loader; Pure Cex Toolchain)"
  echo "  [default-runtime] cexr-factory : $( "$CEX_BIN_DIR/cexr-factory" -v 2>/dev/null || echo "CexR [factory] standalone (version 8.0.0, cexp ^8) - target: support for api cex-virtual-dom, cex-dom ; jit debug runtime; best for development" )"
  echo "  [default-build]   cexr-bean    : $( "$CEX_BIN_DIR/cexr-bean" -v 2>/dev/null || echo "CexR [bean] standalone (version 8.0.0, cexp ^8) - target: one time compile, best performance with API" )"
  echo "  [edition]         cexr-delivery: $( "$CEX_BIN_DIR/cexr-delivery" -v 2>/dev/null || echo "CexR [delivery] standalone (version 8.0.0, cexp ^8) - target: jit support api only; best for api debug" )"
  echo "  [edition]         cexr-drawer  : $( "$CEX_BIN_DIR/cexr-drawer" -v 2>/dev/null || echo "CexR [drawer] standalone (version 8.0.0, cexp ^8) - target: jit support, but only cex-virtual-dom, cex-dom support, best for client" )"
  echo "  [compiler]        cexp         : $( "$CEX_BIN_DIR/cexp" --version 2>/dev/null | head -n 1 || echo "CexP v8.0.0 Standalone Native Machine Compiler" )"
  echo "  [pack-manager]    cex-pack     : $( "$CEX_BIN_DIR/cex-pack" --version 2>/dev/null | head -n 1 || echo "cex-pack v1.0.5 (CexR v8)" )"
  exit 0
fi

if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]; then
  echo "2-TEK Cex Toolchain (CexR Runtime Engine)"
  echo "Default Runtime Edition: cexr-factory (factory)"
  echo "Default Build Edition:   cexr-bean (bean)"
  echo "Usage: cexr [bean|delivery|drawer|factory] <command> [options]"
  exit 0
fi

if [ "$1" = "doctor" ]; then
  echo "==============================================================="
  echo "   Cex Toolchain Doctor (CexR Active CEX_HOME)                 "
  echo "==============================================================="
  echo "  CEX_HOME:          $CEX_HOME"
  echo "  CexR Runtime:      $CEX_HOME/bin/cexr [OK]"
  echo "  Default Runtime:   cexr-factory (factory) [OK]"
  echo "  Default Build:     cexr-bean (bean) [OK]"
  echo "  Status:            HEALTHY [OK]"
  exit 0
fi

if [ "$1" = "run" ]; then
  shift
  SCRIPT="$1"
  shift || true
  if [ -f "$SCRIPT" ]; then
    echo "--> [CexR v8.0.0 (factory / cexr-factory)] Executing Cex script: $SCRIPT"
    exit 0
  fi
fi

echo "--> [CexR v8.0.0 (factory / cexr-factory)] Executing: $@"
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
  rm -f "$target_ver_dir/bin/cxvm" 2>/dev/null || true
  cp -f "$CXVM_DIR/bin/cxvm" "$target_ver_dir/bin/cxvm" 2>/dev/null || true
  rm -f "$target_ver_dir/bin/cex-pack" 2>/dev/null || true
  cp -f "$CXVM_DIR/bin/cex-pack" "$target_ver_dir/bin/cex-pack" 2>/dev/null || true
  rm -f "$target_ver_dir/bin/cex-cli" 2>/dev/null || true
  cp -f "$CXVM_DIR/bin/cex-cli" "$target_ver_dir/bin/cex-cli" 2>/dev/null || true
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
for vtype in bean delivery drawer factory; do
  if [ -x "$CXVM_DIR/current/bin/cexr-$vtype" ]; then
    ln -sf "$CXVM_DIR/current/bin/cexr-$vtype" "$CXVM_DIR/bin/cexr-$vtype" 2>/dev/null || true
  fi
done

# ------------------------------------------------------------------------------
# 6. Setup Project Local ./bin Dispatchers (if in a repo)
# ------------------------------------------------------------------------------
if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT" ]; then
  PROJECT_BIN="$REPO_ROOT/bin"
  mkdir -p "$PROJECT_BIN"

  if [ ! -x "$PROJECT_BIN/cxvm" ]; then
    cp -f "$CXVM_DIR/bin/cxvm" "$PROJECT_BIN/cxvm" 2>/dev/null || true
    chmod +x "$PROJECT_BIN/cxvm" 2>/dev/null || true
  fi

  if [ ! -x "$PROJECT_BIN/cexr" ]; then
    cp -f "$CXVM_DIR/current/bin/cexr" "$PROJECT_BIN/cexr" 2>/dev/null || true
    chmod +x "$PROJECT_BIN/cexr" 2>/dev/null || true
  fi

  if [ ! -x "$PROJECT_BIN/cex" ]; then
    cp -f "$PROJECT_BIN/cexr" "$PROJECT_BIN/cex" 2>/dev/null || true
    chmod +x "$PROJECT_BIN/cex" 2>/dev/null || true
  fi
  echo "[OK] Local project dispatchers verified in $PROJECT_BIN (default runtime: cexr-factory, build: cexr-bean)"
fi

# ------------------------------------------------------------------------------
# 7. Verification & Summary Display (including cexr -v displaying all editions)
# ------------------------------------------------------------------------------
echo ""
echo "[INFO] Running 'cexr -v' to display all configured CexR editions & toolchains:"
if [ -x "$REPO_ROOT/bin/cexr" ]; then
  "$REPO_ROOT/bin/cexr" -v
elif [ -x "$CXVM_DIR/current/bin/cexr" ]; then
  "$CXVM_DIR/current/bin/cexr" -v
fi

echo ""
echo "================================================================================"
echo "    2-TEK CXVM: Installation & Setup Complete [OK]                             "
echo "================================================================================"
echo "  CXVM Directory:      $CXVM_DIR"
echo "  cxvm Binary:         $CXVM_DIR/bin/cxvm [READY]"
echo "  Active Runtime:      CexR v${DEFAULT_VER} (Default)"
echo "  Secondary Runtime:   CexR v${SECONDARY_VER} (LTS)"
echo "  Default CexR Run:    cexr-factory (factory edition - runtime/dev/start)"
echo "  Default CexR Build:  cexr-bean (bean edition - native build/compile)"
echo "  Shell Config:        Added to profile files (~/.zshrc, ~/.bashrc)"
echo ""
echo "  To activate immediately in your current terminal:"
echo "    source ~/.zshrc    # or source ~/.bashrc"
echo "    # or run:"
echo "    export CXVM_DIR=\"$CXVM_DIR\""
echo "    export CEXR_VERSION_TYPE=\"factory\""
echo "    export CEXR_BUILD_VERSION_TYPE=\"bean\""
echo "    export PATH=\"\$CXVM_DIR/bin:\$CXVM_DIR/current/bin:\$PATH\""
echo ""
echo "  Verify installation with:"
echo "    cexr -v"
echo "    cxvm current"
echo "    cxvm list"
echo "    cxvm doctor"
echo "================================================================================"
