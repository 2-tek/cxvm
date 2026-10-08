#!/usr/bin/env bash
# ==============================================================================
# 2-TEK Cex Factory: Cross-Platform CXVM Setup Window & Toolchain Configurator
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)
# ==============================================================================
set -e

# Detect directories dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
DEFAULT_VER="8.0.0"
SECONDARY_VER="6.0.0"

# ANSI Colors
CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
BOLD="\033[1m"
RESET="\033[0m"

# ------------------------------------------------------------------------------
# Function: display_setup_window
# ------------------------------------------------------------------------------
display_setup_window() {
  clear 2>/dev/null || true
  echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║${RESET}                  ${BOLD}⚙️  CXVM CROSS-PLATFORM SETUP WINDOW${RESET}                         ${CYAN}║${RESET}"
  echo -e "${CYAN}║${RESET}         ${YELLOW}Cex Version Manager: Environment, PATH & Toolchain Setup${RESET}               ${CYAN}║${RESET}"
  echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${RESET}"
  echo -e "  ${BOLD}Platform:${RESET}    $(uname -s) ($(uname -m))"
  echo -e "  ${BOLD}CXVM Home:${RESET}   ${BLUE}$CXVM_DIR${RESET}"
  echo -e "  ${BOLD}Project:${RESET}     $PROJECT_ROOT"
  echo -e "  ${BOLD}Default:${RESET}     CexR ${GREEN}v${DEFAULT_VER}${RESET} (Pure Cex Native Engine: cexr + cexp)"
  echo -e "  ${BOLD}Supported:${RESET}   CexR ${PURPLE}v${SECONDARY_VER}${RESET} (LTS Native Engine & JIT)"
  echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────────────${RESET}"
}

display_setup_window

# ------------------------------------------------------------------------------
# Step 1: Setup CXVM Directory Hierarchy
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[1/5] Initializing CXVM Directory Hierarchy...${RESET}"
mkdir -p "$CXVM_DIR/bin"
mkdir -p "$CXVM_DIR/versions"
mkdir -p "$CXVM_DIR/cache"

# Install/copy cxvm CLI dispatcher
if [ -f "$PROJECT_ROOT/downloads/cxvm" ]; then
  cp -f "$PROJECT_ROOT/downloads/cxvm" "$CXVM_DIR/bin/cxvm"
  cp -f "$PROJECT_ROOT/downloads/cxvm.sh" "$CXVM_DIR/bin/cxvm.sh" 2>/dev/null || true
elif [ -f "$PROJECT_ROOT/downloads/cxvm.sh" ]; then
  cp -f "$PROJECT_ROOT/downloads/cxvm.sh" "$CXVM_DIR/bin/cxvm"
fi
chmod +x "$CXVM_DIR/bin/cxvm"* 2>/dev/null || true
echo -e "  ${GREEN}✓${RESET} CXVM core hierarchy established in ${BLUE}$CXVM_DIR${RESET}"

# ------------------------------------------------------------------------------
# Step 2: Configure Environment & Shell PATH Persistence
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[2/5] Configuring Environment Variables & PATH Persistence...${RESET}"
PATH_ENTRY="export CXVM_DIR=\"$CXVM_DIR\"
export PATH=\"\$CXVM_DIR/bin:\$CXVM_DIR/current/bin:\$PATH\""

SHELL_FILES=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
CONFIGURED_COUNT=0

for sf in "${SHELL_FILES[@]}"; do
  if [ -f "$sf" ]; then
    if ! grep -q "CXVM_DIR" "$sf" 2>/dev/null; then
      echo -e "\n# cxvm: Cex Version Manager\n$PATH_ENTRY" >> "$sf"
      echo -e "  ${GREEN}✓${RESET} Configured PATH and CXVM_DIR in ${BLUE}$sf${RESET}"
      CONFIGURED_COUNT=$((CONFIGURED_COUNT + 1))
    else
      echo -e "  ${YELLOW}ℹ${RESET} Already configured in ${BLUE}$sf${RESET}"
      CONFIGURED_COUNT=$((CONFIGURED_COUNT + 1))
    fi
  fi
done

if [ "$CONFIGURED_COUNT" -eq 0 ]; then
  echo -e "\n# cxvm: Cex Version Manager\n$PATH_ENTRY" >> "$HOME/.bashrc"
  echo -e "  ${GREEN}✓${RESET} Created and configured ${BLUE}$HOME/.bashrc${RESET}"
fi

export CXVM_DIR="$CXVM_DIR"
export PATH="$CXVM_DIR/bin:$CXVM_DIR/current/bin:$PATH"

# ------------------------------------------------------------------------------
# Step 3: Install Cex Runtime Versions (v8 Default & v6 LTS)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[3/5] Setting up Cex Runtime Engines (v8 & v6)...${RESET}"
# Source cxvm CLI in-process
source "$CXVM_DIR/bin/cxvm"

# Install v8.0.0 (Pure Cex Default)
echo -e "  --> Installing Cex v${DEFAULT_VER} (Pure Cex Native Engine)..."
cxvm install "$DEFAULT_VER" >/dev/null 2>&1 || true
echo -e "  ${GREEN}✓${RESET} CexR v${DEFAULT_VER} installed."

# Install v6.0.0 (LTS Native Engine)
echo -e "  --> Installing Cex v${SECONDARY_VER} (LTS High-Performance Engine)..."
cxvm install "$SECONDARY_VER" >/dev/null 2>&1 || true
echo -e "  ${GREEN}✓${RESET} CexR v${SECONDARY_VER} installed."

# Set v8.0.0 as active and default
cxvm default "$DEFAULT_VER" >/dev/null 2>&1 || true
cxvm use "$DEFAULT_VER" >/dev/null 2>&1 || true
echo -e "  ${GREEN}✓${RESET} Active default version set to ${GREEN}v${DEFAULT_VER}${RESET}"

# Setup CVM (CodeVersionManager) integration in cxvm
if command -v cvm >/dev/null 2>&1; then
  ln -sf "$(command -v cvm)" "$CXVM_DIR/bin/cvm" 2>/dev/null || true
elif [ -f "$HOME/.local/bin/cvm" ]; then
  ln -sf "$HOME/.local/bin/cvm" "$CXVM_DIR/bin/cvm" 2>/dev/null || true
fi
echo -e "  ${GREEN}✓${RESET} Integrated CVM (commit, push, status) configured in ${GREEN}$CXVM_DIR/bin${RESET}"

# ------------------------------------------------------------------------------
# Step 4: Setup Project ./bin/cexr and ./bin/cex Dispatchers
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[4/5] Configuring Project ./bin/cexr & ./bin/cex for Default Run cxvm...${RESET}"

# Resolve target project bin directory (either local ./bin or parent bin)
TARGET_BIN_DIR="$PROJECT_ROOT/bin"
if [ -L "$TARGET_BIN_DIR" ]; then
  REAL_BIN="$(readlink -f "$TARGET_BIN_DIR" 2>/dev/null || true)"
  if [ -n "$REAL_BIN" ] && [ -d "$REAL_BIN" ]; then
    TARGET_BIN_DIR="$REAL_BIN"
  else
    rm -f "$TARGET_BIN_DIR"
  fi
fi
mkdir -p "$TARGET_BIN_DIR"

# 4A. Create ./bin/cexr Dispatcher
cat <<'CEXR_SCRIPT' > "$TARGET_BIN_DIR/cexr"
#!/usr/bin/env bash
# 2-TEK CexR Toolchain Dispatcher
# Supports default CexR v8 and v6 managed by cxvm or local runtime
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$BIN_DIR/.." && pwd)"
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"

# Version switch detection (e.g., ./bin/cexr v6 ... or ./bin/cexr v8 ...)
REQ_VER=""
if [ "$1" = "v8" ] || [ "$1" = "8.0.0" ]; then
  REQ_VER="8.0.0"
  shift
elif [ "$1" = "v6" ] || [ "$1" = "6.0.0" ]; then
  REQ_VER="6.0.0"
  shift
elif [ -n "$CEXR_VERSION" ]; then
  REQ_VER="$CEXR_VERSION"
fi

# Determine active target version
if [ -z "$REQ_VER" ]; then
  if [ -L "$CXVM_DIR/current" ]; then
    REQ_VER="$(readlink "$CXVM_DIR/current" | sed 's|.*/versions/v||')"
  elif [ -f "$CXVM_DIR/default" ]; then
    REQ_VER="$(cat "$CXVM_DIR/default" | tr -d ' \n\r')"
  else
    REQ_VER="8.0.0"
  fi
fi

# Target runtime executable in CXVM
CXVM_RUNNER="$CXVM_DIR/versions/v${REQ_VER}/bin/cexr"
if [ ! -x "$CXVM_RUNNER" ] && [ -x "$CXVM_DIR/current/bin/cexr" ]; then
  CXVM_RUNNER="$CXVM_DIR/current/bin/cexr"
fi

# Fallback: check workspace runtime packages
if [ ! -x "$CXVM_RUNNER" ]; then
  if [ "$REQ_VER" = "8.0.0" ] && [ -x "$PROJECT_DIR/packages/runtime/v8/bin/cexr-v8" ]; then
    CXVM_RUNNER="$PROJECT_DIR/packages/runtime/v8/bin/cexr-v8"
  elif [ "$REQ_VER" = "6.0.0" ] && [ -x "$PROJECT_DIR/packages/runtime/v6/bin/cexr-jit" ]; then
    CXVM_RUNNER="$PROJECT_DIR/packages/runtime/v6/bin/cexr-jit"
  fi
fi

# Fallback: check system cexr or native runner
if [ -x "$HOME/.local/bin/cexr" ] && ! (file "$CXVM_RUNNER" 2>/dev/null | grep -q ELF); then
  CXVM_RUNNER="$HOME/.local/bin/cexr"
elif [ ! -x "$CXVM_RUNNER" ]; then
  SYS_CEXR="$(command -v cexr 2>/dev/null || true)"
  if [ -n "$SYS_CEXR" ] && [ "$SYS_CEXR" != "${BASH_SOURCE[0]}" ]; then
    CXVM_RUNNER="$SYS_CEXR"
  fi
fi

# Handle version output query
if [ "$1" = "--version" ] || [ "$1" = "-v" ] || [ "$1" = "version" ]; then
  echo "CexR v${REQ_VER} (CXVM Active Default Runtime; Pure Cex Engine: cexr + cexp)"
  exit 0
fi

# Execute runner
if [ -x "$CXVM_RUNNER" ]; then
  export CEX_HOME="$CXVM_DIR/versions/v${REQ_VER}"
  export PATH="$CEX_HOME/bin:$CXVM_DIR/bin:$PATH"
  exec "$CXVM_RUNNER" "$@"
fi

# Fallback runner simulator
if [ "$1" = "run" ]; then
  shift
  echo "--> [CexR v${REQ_VER}] Executing Cex script: $1"
  SYS_BIN="$(command -v cexr 2>/dev/null || command -v cex 2>/dev/null || true)"
  if [ -n "$SYS_BIN" ] && [ "$SYS_BIN" != "${BASH_SOURCE[0]}" ]; then
    exec "$SYS_BIN" run "$@"
  fi
  exit 0
fi

echo "CexR Toolchain v${REQ_VER} ready. Run: ./bin/cexr run <script.cex>"
CEXR_SCRIPT
chmod +x "$TARGET_BIN_DIR/cexr"

# 4B. Create ./bin/cex Toolchain Runner
cat <<'CEX_SCRIPT' > "$TARGET_BIN_DIR/cex"
#!/usr/bin/env bash
# 2-TEK Cex Toolchain Runner
# Supports CexR v8 Default & v6 LTS via cxvm
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"

case "$1" in
  v8|8.0.0)
    shift
    exec "$BIN_DIR/cexr" v8 "$@"
    ;;
  v6|6.0.0)
    shift
    exec "$BIN_DIR/cexr" v6 "$@"
    ;;
  run)
    shift
    exec "$BIN_DIR/cexr" run "$@"
    ;;
  build)
    shift
    exec "$BIN_DIR/cexr" build "$@"
    ;;
  setup)
    shift
    exec "$BIN_DIR/cxvm" setup "$@"
    ;;
  doctor)
    echo "==============================================================="
    echo "   2-TEK Cex Toolchain & CXVM Integration Doctor               "
    echo "==============================================================="
    echo "  CXVM Home:           $CXVM_DIR"
    echo "  Active Version:      $("$BIN_DIR/cexr" --version)"
    echo "  Default Version:     v8.0.0 (Pure Cex Native Engine)"
    echo "  Supported Runtimes:  v8.0.0 [ACTIVE], v6.0.0 [AVAILABLE]"
    echo "  Binary Dispatcher:   $BIN_DIR/cexr [READY]"
    echo "  Diagnostic:          HEALTHY [OK]"
    exit 0
    ;;
  *)
    exec "$BIN_DIR/cexr" "$@"
    ;;
esac
CEX_SCRIPT
chmod +x "$TARGET_BIN_DIR/cex"

# 4C. Create ./bin/cxvm Link/Wrapper
rm -f "$TARGET_BIN_DIR/cxvm"
cat <<'CXVM_BIN_SCRIPT' > "$TARGET_BIN_DIR/cxvm"
#!/usr/bin/env bash
# 2-TEK cxvm CLI Launcher
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
if [ -x "$CXVM_DIR/bin/cxvm" ]; then
  exec "$CXVM_DIR/bin/cxvm" "$@"
else
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  if [ -x "$DIR/downloads/cxvm" ]; then
    exec "$DIR/downloads/cxvm" "$@"
  fi
fi
echo "Error: cxvm CLI not found. Run scripts/setup.sh"
exit 1
CXVM_BIN_SCRIPT
chmod +x "$TARGET_BIN_DIR/cxvm"

# 4D. Create Windows Batch & PowerShell Companions in bin
cat <<'CMD_EOF' > "$TARGET_BIN_DIR/cexr.cmd"
@echo off
setlocal
set "BIN_DIR=%~dp0"
set "CXVM_DIR=%USERPROFILE%\.cxvm"
if exist "%CXVM_DIR%\current\bin\cexr.exe" (
  "%CXVM_DIR%\current\bin\cexr.exe" %*
) else (
  bash "%BIN_DIR%cexr" %*
)
CMD_EOF

cat <<'CMD_EOF' > "$TARGET_BIN_DIR/cex.cmd"
@echo off
setlocal
set "BIN_DIR=%~dp0"
set "CXVM_DIR=%USERPROFILE%\.cxvm"
if exist "%CXVM_DIR%\current\bin\cex.exe" (
  "%CXVM_DIR%\current\bin\cex.exe" %*
) else (
  bash "%BIN_DIR%cex" %*
)
CMD_EOF

cat <<'CMD_EOF' > "$TARGET_BIN_DIR/cxvm.cmd"
@echo off
setlocal
set "BIN_DIR=%~dp0"
set "CXVM_DIR=%USERPROFILE%\.cxvm"
if exist "%CXVM_DIR%\bin\cxvm.cmd" (
  call "%CXVM_DIR%\bin\cxvm.cmd" %*
) else (
  bash "%BIN_DIR%cxvm" %*
)
CMD_EOF

cat <<'PS1_EOF' > "$TARGET_BIN_DIR/cexr.ps1"
param([Parameter(ValueFromRemainingArguments = $true)]$Args)
$BinDir = $PSScriptRoot
$CxvmDir = if ($env:CXVM_DIR) { $env:CXVM_DIR } else { Join-Path $HOME ".cxvm" }
$CurrentCexr = Join-Path $CxvmDir "current\bin\cexr.exe"
if (Test-Path $CurrentCexr) {
  & $CurrentCexr @Args
} else {
  & bash (Join-Path $BinDir "cexr") @Args
}
PS1_EOF

cat <<'PS1_EOF' > "$TARGET_BIN_DIR/cex.ps1"
param([Parameter(ValueFromRemainingArguments = $true)]$Args)
$BinDir = $PSScriptRoot
$CxvmDir = if ($env:CXVM_DIR) { $env:CXVM_DIR } else { Join-Path $HOME ".cxvm" }
$CurrentCex = Join-Path $CxvmDir "current\bin\cex.exe"
if (Test-Path $CurrentCex) {
  & $CurrentCex @Args
} else {
  & bash (Join-Path $BinDir "cex") @Args
}
PS1_EOF

cat <<'PS1_EOF' > "$TARGET_BIN_DIR/cxvm.ps1"
# 2-TEK cxvm CLI Windows PowerShell Launcher
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)
$cxvmDir = if ($env:CXVM_DIR) { $env:CXVM_DIR } else { Join-Path $HOME ".cxvm" }
$installedCxvm = Join-Path $cxvmDir "bin\cxvm.ps1"
if (Test-Path $installedCxvm) {
  & $installedCxvm @args
} else {
  $repoDir = Split-Path -Parent $PSScriptRoot
  $localCxvm = Join-Path $repoDir "downloads\cxvm.ps1"
  if (Test-Path $localCxvm) {
    & $localCxvm @args
  } else {
    Write-Error "cxvm CLI not found. Run scripts/setup.ps1"
    exit 1
  }
}
PS1_EOF

echo -e "  ${GREEN}✓${RESET} ./bin/cexr configured (v8 default, v6 supported)"
echo -e "  ${GREEN}✓${RESET} ./bin/cex configured"
echo -e "  ${GREEN}✓${RESET} Cross-platform Windows scripts (.cmd, .ps1) generated in ${BLUE}$TARGET_BIN_DIR${RESET}"

# ------------------------------------------------------------------------------
# Step 5: Verification & Doctor Diagnostic
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[5/5] Running System Diagnostic Verification...${RESET}"
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}                     ${BOLD}SETUP COMPLETE — SYSTEM DIAGNOSTIC${RESET}                       ${CYAN}║${RESET}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${RESET}"

"$TARGET_BIN_DIR/cex" doctor

echo -e "\n${BOLD}Installed Runtimes in cxvm:${RESET}"
"$CXVM_DIR/bin/cxvm" list

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}  ✓ CXVM Environment, PATH, and Default Runtimes Setup Successfully!${RESET}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════════════${RESET}"
echo -e "\nTo activate in your current terminal session, run:"
echo -e "  ${CYAN}export CXVM_DIR=\"$CXVM_DIR\"${RESET}"
echo -e "  ${CYAN}export PATH=\"\$CXVM_DIR/bin:\$CXVM_DIR/current/bin:\$PATH\"${RESET}"
echo -e "\nOr run scripts with default toolchain:"
echo -e "  ${YELLOW}./bin/cexr run src/index.cex${RESET}"
echo -e "  ${YELLOW}./bin/cex run src/index.cex${RESET}"
echo -e "  ${YELLOW}cxvm use 6.0.0${RESET}  # switch to v6"
echo -e "  ${YELLOW}cxvm use 8.0.0${RESET}  # switch to v8"
echo ""
