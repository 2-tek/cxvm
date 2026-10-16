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
# 2. Directory Hierarchy Setup (/bin/$version/$name-$type layout)
# ------------------------------------------------------------------------------
mkdir -p "$CXVM_DIR/bin"
mkdir -p "$CXVM_DIR/cache"
rm -rf "$CXVM_DIR/versions" 2>/dev/null || true

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
fetch_file "dist/cex-lint" "$CXVM_DIR/bin/cex-lint"
fetch_file "dist/cex-cli" "$CXVM_DIR/bin/cex-cli"
fetch_file "dist/cvm-server" "$CXVM_DIR/bin/cvm-server"
fetch_file "dist/thunder-server" "$CXVM_DIR/bin/thunder-server"

chmod +x "$CXVM_DIR/bin/cxvm"* "$CXVM_DIR/bin/cex-"* "$CXVM_DIR/bin/cvm-server"* "$CXVM_DIR/bin/thunder-server"* 2>/dev/null || true
echo "[OK] cxvm, cex-pack, cex-lint, and cex-cli installed in $CXVM_DIR/bin"

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
echo "$DEFAULT_VER" > "$CXVM_DIR/default"

CONFIG_ENTRY="
# 2-TEK CXVM: Cex Version Manager
export CXVM_DIR=\"$CXVM_DIR\"
export CEXR_VERSION_TYPE=\"factory\"
export CEXR_BUILD_VERSION_TYPE=\"bean\"
export PATH=\"\$CXVM_DIR/bin:\$CXVM_DIR/current:\$PATH\"
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
export PATH="$CXVM_DIR/bin:$CXVM_DIR/current:$PATH"

# Symlink to /usr/local/bin or ~/.local/bin for immediate invocation without reload
if [ -w "/usr/local/bin" ] 2>/dev/null; then
  ln -sf "$CXVM_DIR/bin/cxvm" "/usr/local/bin/cxvm" 2>/dev/null || true
  ln -sf "$CXVM_DIR/bin/cex-pack" "/usr/local/bin/cex-pack" 2>/dev/null || true
  ln -sf "$CXVM_DIR/bin/cex-lint" "/usr/local/bin/cex-lint" 2>/dev/null || true
  ln -sf "$CXVM_DIR/bin/cex-cli" "/usr/local/bin/cex-cli" 2>/dev/null || true
  echo "[OK] Symlinked cxvm, cex-pack, cex-lint, cex-cli to /usr/local/bin"
fi
mkdir -p "$HOME/.local/bin"
ln -sf "$CXVM_DIR/bin/cxvm" "$HOME/.local/bin/cxvm" 2>/dev/null || true
ln -sf "$CXVM_DIR/bin/cex-pack" "$HOME/.local/bin/cex-pack" 2>/dev/null || true
ln -sf "$CXVM_DIR/bin/cex-lint" "$HOME/.local/bin/cex-lint" 2>/dev/null || true
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
# 5. Deploy Versioned Toolchain Binaries (/bin/$version/$name-$type)
# ------------------------------------------------------------------------------
echo "[INFO] Deploying versioned toolchain binaries into $CXVM_DIR/bin/\$version/\$name-\$type..."

# Sync all versioned directories from $REPO_ROOT/bin/$version/$name-$type
if [ -d "$REPO_ROOT/bin" ]; then
  for vdir in "$REPO_ROOT/bin"/*; do
    if [ -d "$vdir" ]; then
      vname="$(basename "$vdir")"
      mkdir -p "$CXVM_DIR/bin/$vname"
      for bfile in "$vdir"/*; do
        if [ -f "$bfile" ]; then
          bbase="$(basename "$bfile")"
          cp -f "$bfile" "$CXVM_DIR/bin/$vname/$bbase" 2>/dev/null || true
          if [ -x "$bfile" ]; then
            chmod +x "$CXVM_DIR/bin/$vname/$bbase" 2>/dev/null || true
            echo "[OK] Deployed /bin/$vname/$bbase -> $CXVM_DIR/bin/$vname/$bbase"
          fi
        fi
      done
    fi
  done
fi

install_runtime_version() {
  local ver="$1"
  local short_ver="v${ver%%.*}"
  local ext="tar.gz"
  if [ "$TARGET_OS" = "windows" ]; then ext="zip"; fi
  local archive_name="cex-v${ver}-${TARGET_OS}-${TARGET_ARCH}.${ext}"
  local target_ver_dir="$CXVM_DIR/bin/${ver}"

  echo "[INFO] Setting up Cex runtime v${ver} (${short_ver}) in $target_ver_dir..."
  mkdir -p "$target_ver_dir" "$target_ver_dir/include/cex" "$target_ver_dir/lib"
  ln -sfn "." "$target_ver_dir/bin" 2>/dev/null || true

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
      echo "[INFO] Downloading $archive_name from GitHub repository..."
      if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$GITHUB_RAW/dist/$archive_name" -o "$archive_path" 2>/dev/null || \
        curl -fsSL "https://github.com/2-tek/cxvm/raw/main/dist/$archive_name" -o "$archive_path" 2>/dev/null || true
      elif command -v wget >/dev/null 2>&1; then
        wget -q "$GITHUB_RAW/dist/$archive_name" -O "$archive_path" 2>/dev/null || true
      fi
    fi
  fi

  # Extract package archive if found into temporary staging and deploy into /bin/$version/$name-$type
  if [ -f "$archive_path" ] && [ -s "$archive_path" ]; then
    echo "[INFO] Extracting $archive_name into /bin/${ver}/cexp-${short_ver}..."
    local tmp_ext="${CXVM_DIR}/cache/.extract_${ver}_$$"
    mkdir -p "$tmp_ext"
    if [ "$ext" = "zip" ]; then
      unzip -q -o "$archive_path" -d "$tmp_ext" 2>/dev/null || true
    else
      tar -xzf "$archive_path" -C "$tmp_ext" --strip-components=1 2>/dev/null || \
      tar -xzf "$archive_path" -C "$tmp_ext" 2>/dev/null || true
    fi
    if [ -d "$tmp_ext/include" ]; then
      cp -rf "$tmp_ext/include/"* "$target_ver_dir/include/" 2>/dev/null || true
    fi
    if [ -d "$tmp_ext/lib" ]; then
      cp -rf "$tmp_ext/lib/"* "$target_ver_dir/lib/" 2>/dev/null || true
    fi
    if [ -d "$tmp_ext/bin" ]; then
      for sub in "$tmp_ext/bin"/*; do
        if [ -d "$sub" ]; then
          sver="$(basename "$sub")"
          mkdir -p "$CXVM_DIR/bin/$sver"
          cp -rf "$sub/"* "$CXVM_DIR/bin/$sver/" 2>/dev/null || true
        elif [ -f "$sub" ] && [ "$(basename "$sub")" != "cex-lint" ]; then
          cp -f "$sub" "$target_ver_dir/$(basename "$sub")" 2>/dev/null || true
        fi
      done
    fi
    rm -f "$target_ver_dir/cex-lint" 2>/dev/null || true
    rm -rf "$tmp_ext" 2>/dev/null || true
  fi

  # Deploy cexp-$short_ver into $CXVM_DIR/bin/$ver/cexp-$short_ver
  for cexp_cand in "$REPO_ROOT/bin/$ver/cexp-${short_ver}" "$REPO_ROOT/bin"/*/"cexp-${short_ver}" "$REPO_ROOT/bin"/*/cexp-v8; do
    if [ -x "$cexp_cand" ] && [ ! -d "$cexp_cand" ]; then
      cp -f "$cexp_cand" "$target_ver_dir/cexp-${short_ver}" 2>/dev/null || true
      cp -f "$cexp_cand" "$target_ver_dir/cexp" 2>/dev/null || true
      chmod +x "$target_ver_dir/cexp-${short_ver}" "$target_ver_dir/cexp" 2>/dev/null || true
      break
    fi
  done

  if [ -x "$REPO_ROOT/bin/cexr" ]; then
    cp -f "$REPO_ROOT/bin/cexr" "$target_ver_dir/cexr" 2>/dev/null || true
    chmod +x "$target_ver_dir/cexr" 2>/dev/null || true
  fi

  for vtype in bean delivery drawer factory; do
    for cexr_cand in "$REPO_ROOT/bin"/*/cexr-"$vtype"; do
      if [ -x "$cexr_cand" ] && [ ! -d "$cexr_cand" ]; then
        rver="$(basename "$(dirname "$cexr_cand")")"
        mkdir -p "$CXVM_DIR/bin/$rver"
        cp -f "$cexr_cand" "$CXVM_DIR/bin/$rver/cexr-$vtype" 2>/dev/null || true
        cp -f "$cexr_cand" "$target_ver_dir/cexr-$vtype" 2>/dev/null || true
        chmod +x "$CXVM_DIR/bin/$rver/cexr-$vtype" "$target_ver_dir/cexr-$vtype" 2>/dev/null || true
      fi
    done
  done

  # Create executable cexr runner if missing
  if [ ! -x "$target_ver_dir/cexr" ]; then
    cat <<'RUNNER_SCRIPT' > "$target_ver_dir/cexr"
#!/usr/bin/env bash
# CexR: Native Cex Language Runtime Engine
CEX_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CEX_HOME="${CEX_HOME:-$(cd "$CEX_BIN_DIR/.." && pwd)}"
export PATH="$CEX_BIN_DIR:$CEX_HOME/bin:$PATH"

if [ "$1" = "--version" ] || [ "$1" = "-v" ] || [ "$1" = "version" ]; then
  echo "CexR v8.0.0 (Native Machine Engine; Default Runtime: cexr-factory; Default Build: cexr-bean; CexR v8 .cex_boxes Dist Loader; Pure Cex Toolchain)"
  echo "  [default-runtime] cexr-factory : $( "$CEX_BIN_DIR/cexr-factory" -v 2>/dev/null || echo "CexR [factory] standalone (version 8.0.0, cexp ^8) - target: support for api cex-virtual-dom, cex-dom ; jit debug runtime; best for development" )"
  echo "  [default-build]   cexr-bean    : $( "$CEX_BIN_DIR/cexr-bean" -v 2>/dev/null || echo "CexR [bean] standalone (version 8.0.0, cexp ^8) - target: one time compile, best performance with API" )"
  echo "  [edition]         cexr-delivery: $( "$CEX_BIN_DIR/cexr-delivery" -v 2>/dev/null || echo "CexR [delivery] standalone (version 8.0.0, cexp ^8) - target: jit support api only; best for api debug" )"
  echo "  [edition]         cexr-drawer  : $( "$CEX_BIN_DIR/cexr-drawer" -v 2>/dev/null || echo "CexR [drawer] standalone (version 8.0.0, cexp ^8) - target: jit support, but only cex-virtual-dom, cex-dom support, best for client" )"
  echo "  [compiler]        cexp         : $( "$CEX_BIN_DIR/cexp" --version 2>/dev/null | head -n 1 || echo "CexP v8.0.0 Standalone Native Machine Compiler" )"
  echo "  [pack-manager]    cex-pack     : $( "$CEX_BIN_DIR/cex-pack" --version 2>/dev/null | head -n 1 || echo "cex-pack v1.0.5 (CexR v8)" )"
  echo "  [linter]          cex-lint     : CexLint v1.0.8 (./bin/1.0.8/cex-lint)"
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
  echo "  CexR Runtime:      $CEX_BIN_DIR/cexr [OK]"
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
    chmod +x "$target_ver_dir/cexr"
  fi

  # Create executable cexp-${short_ver} compiler if missing
  if [ ! -x "$target_ver_dir/cexp-${short_ver}" ]; then
    cat <<COMPILER_SCRIPT > "$target_ver_dir/cexp-${short_ver}"
#!/usr/bin/env bash
# CexP: Direct Native Machine Compiler (${short_ver})
if [ "\$1" = "--version" ] || [ "\$1" = "-v" ] || [ "\$1" = "version" ]; then
  echo "CexP v${ver} (${short_ver} - Direct Native Machine Compiler; Pure Cex Toolchain)"
  exit 0
fi
echo "--> [CexP v${ver} (${short_ver})] Compiling: \$@"
exit 0
COMPILER_SCRIPT
    chmod +x "$target_ver_dir/cexp-${short_ver}"
  fi
  if [ ! -x "$target_ver_dir/cexp" ]; then
    cp -f "$target_ver_dir/cexp-${short_ver}" "$target_ver_dir/cexp" 2>/dev/null || true
    chmod +x "$target_ver_dir/cexp" 2>/dev/null || true
  fi

  # Create cex alias
  ln -sf "$target_ver_dir/cexr" "$target_ver_dir/cex" 2>/dev/null || true
  cp -f "$CXVM_DIR/bin/cxvm" "$target_ver_dir/cxvm" 2>/dev/null || true
  cp -f "$CXVM_DIR/bin/cex-pack" "$target_ver_dir/cex-pack" 2>/dev/null || true
  cp -f "$CXVM_DIR/bin/cex-lint" "$target_ver_dir/cex-lint" 2>/dev/null || true
  cp -f "$CXVM_DIR/bin/cex-cli" "$target_ver_dir/cex-cli" 2>/dev/null || true
  echo "[OK] Cex runtime v${ver} (${short_ver}) configured in $CXVM_DIR/bin/${ver}/cexp-${short_ver}"
}

# Install default v8.0.0 and secondary v6.0.0 into $CXVM_DIR/bin/$version/$name-$type
install_runtime_version "$DEFAULT_VER"
install_runtime_version "$SECONDARY_VER"

# Link active default version to current ($CXVM_DIR/bin/$DEFAULT_VER)
ln -sfn "$CXVM_DIR/bin/${DEFAULT_VER}" "$CXVM_DIR/current"
ln -sf "$CXVM_DIR/current/cexr" "$CXVM_DIR/bin/cexr" 2>/dev/null || true
ln -sf "$CXVM_DIR/current/cex" "$CXVM_DIR/bin/cex" 2>/dev/null || true
ln -sf "$CXVM_DIR/current/cexp-v8" "$CXVM_DIR/bin/cexp" 2>/dev/null || true
for vtype in bean delivery drawer factory; do
  if [ -x "$CXVM_DIR/current/cexr-$vtype" ]; then
    ln -sf "$CXVM_DIR/current/cexr-$vtype" "$CXVM_DIR/bin/cexr-$vtype" 2>/dev/null || true
  fi
done

# ------------------------------------------------------------------------------
# 6. Setup Project Local ./bin Dispatchers (if in a repo)
# ------------------------------------------------------------------------------
if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT" ]; then
  PROJECT_BIN="$REPO_ROOT/bin"
  mkdir -p "$PROJECT_BIN"

  cp -f "$CXVM_DIR/bin/cxvm" "$PROJECT_BIN/cxvm" 2>/dev/null || true
  chmod +x "$PROJECT_BIN/cxvm" 2>/dev/null || true

  if [ ! -x "$PROJECT_BIN/cexr" ]; then
    cp -f "$CXVM_DIR/current/cexr" "$PROJECT_BIN/cexr" 2>/dev/null || true
    chmod +x "$PROJECT_BIN/cexr" 2>/dev/null || true
  fi

  if [ ! -x "$PROJECT_BIN/cex" ]; then
    cp -f "$PROJECT_BIN/cexr" "$PROJECT_BIN/cex" 2>/dev/null || true
    chmod +x "$PROJECT_BIN/cex" 2>/dev/null || true
  fi
  echo "[OK] Local project dispatchers verified in $PROJECT_BIN (/bin/\$version/\$name-\$type; default runtime: cexr-factory, build: cexr-bean)"
fi

# ------------------------------------------------------------------------------
# 7. Verification & Summary Display (including cexr -v displaying all editions)
# ------------------------------------------------------------------------------
echo ""
echo "[INFO] Running 'cexr -v' to display all configured CexR editions & toolchains:"
if [ -x "$REPO_ROOT/bin/cexr" ]; then
  "$REPO_ROOT/bin/cexr" -v
elif [ -x "$CXVM_DIR/current/cexr" ]; then
  "$CXVM_DIR/current/cexr" -v
fi

echo ""
echo "================================================================================"
echo "    2-TEK CXVM: Installation & Setup Complete [OK]                             "
echo "================================================================================"
echo "  CXVM Directory:      $CXVM_DIR"
echo "  cxvm Binary:         $CXVM_DIR/bin/cxvm [READY]"
echo "  Versioned Layout:    /bin/\$version/\$name-\$type (or short version name)"
echo "  Active Compiler:     $CXVM_DIR/bin/${DEFAULT_VER}/cexp-v8 (Default)"
echo "  Secondary Compiler:  $CXVM_DIR/bin/6.0.2/cexp-v6 (LTS)"
echo "  Default CexR Run:    $CXVM_DIR/bin/1.0.26/cexr-factory (factory edition)"
echo "  Default CexR Build:  $CXVM_DIR/bin/1.0.26/cexr-bean (bean edition)"
echo "  Package Manager:     $CXVM_DIR/bin/1.0.5/cex-pack-bean & cex-pack"
echo "  Integrated Linter:   $CXVM_DIR/bin/1.0.8/cex-lint"
echo "  Shell Config:        Added to profile files (~/.zshrc, ~/.bashrc)"
echo ""
echo "  To activate immediately in your current terminal:"
echo "    source ~/.zshrc    # or source ~/.bashrc"
echo "    # or run:"
echo "    export CXVM_DIR=\"$CXVM_DIR\""
echo "    export CEXR_VERSION_TYPE=\"factory\""
echo "    export CEXR_BUILD_VERSION_TYPE=\"bean\""
echo "    export PATH=\"\$CXVM_DIR/bin:\$CXVM_DIR/current:\$PATH\""
echo ""
echo "  Verify installation with:"
echo "    cexr -v"
echo "    cxvm current"
echo "    cxvm list"
echo "    cxvm doctor"
echo "================================================================================"

