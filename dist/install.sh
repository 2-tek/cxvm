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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || true)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd || true)"

# Install cxvm CLI script, cex-pack, cvm-server, and thunder-server
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/cxvm" ]; then
  cp -f "$SCRIPT_DIR/cxvm" "$CXVM_DIR/bin/cxvm"
  cp -f "$SCRIPT_DIR/cex-pack" "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
  cp -f "$SCRIPT_DIR/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  cp -f "$SCRIPT_DIR/thunder-server" "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
  cp -f "$SCRIPT_DIR"/cex-v*.tar.gz "$CXVM_DIR/cache/" 2>/dev/null || true
  cp -f "$SCRIPT_DIR"/cex-v*.zip "$CXVM_DIR/cache/" 2>/dev/null || true
elif [ -n "$REPO_DIR" ] && [ -f "$REPO_DIR/dist/cxvm" ]; then
  cp -f "$REPO_DIR/dist/cxvm" "$CXVM_DIR/bin/cxvm"
  cp -f "$REPO_DIR/dist/cex-pack" "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
  cp -f "$REPO_DIR/dist/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  cp -f "$REPO_DIR/dist/thunder-server" "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
  cp -f "$REPO_DIR/dist"/cex-v*.tar.gz "$CXVM_DIR/cache/" 2>/dev/null || true
  cp -f "$REPO_DIR/dist"/cex-v*.zip "$CXVM_DIR/cache/" 2>/dev/null || true
elif [ -n "$ROOT_DIR" ] && [ -f "$ROOT_DIR/cxvm/dist/cxvm" ]; then
  cp -f "$ROOT_DIR/cxvm/dist/cxvm" "$CXVM_DIR/bin/cxvm"
  cp -f "$ROOT_DIR/cxvm/dist/cex-pack" "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
  cp -f "$ROOT_DIR/cxvm/dist/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  cp -f "$ROOT_DIR/cxvm/dist/thunder-server" "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
  cp -f "$ROOT_DIR/cxvm/dist"/cex-v*.tar.gz "$CXVM_DIR/cache/" 2>/dev/null || true
  cp -f "$ROOT_DIR/cxvm/dist"/cex-v*.zip "$CXVM_DIR/cache/" 2>/dev/null || true
elif [ -f "cxvm/dist/cxvm" ]; then
  cp -f "cxvm/dist/cxvm" "$CXVM_DIR/bin/cxvm"
  cp -f "cxvm/dist/cex-pack" "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
  cp -f "cxvm/dist/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  cp -f "cxvm/dist/thunder-server" "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
  cp -f cxvm/dist/cex-v*.tar.gz "$CXVM_DIR/cache/" 2>/dev/null || true
  cp -f cxvm/dist/cex-v*.zip "$CXVM_DIR/cache/" 2>/dev/null || true
elif [ -f "dist/cxvm" ]; then
  cp -f "dist/cxvm" "$CXVM_DIR/bin/cxvm"
  cp -f "dist/cex-pack" "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
  cp -f "dist/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  cp -f "dist/thunder-server" "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
  cp -f dist/cex-v*.tar.gz "$CXVM_DIR/cache/" 2>/dev/null || true
  cp -f dist/cex-v*.zip "$CXVM_DIR/cache/" 2>/dev/null || true
elif [ -f "cxvm/downloads/cxvm" ]; then
  cp -f "cxvm/downloads/cxvm" "$CXVM_DIR/bin/cxvm"
  cp -f "cxvm/downloads/cex-pack" "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
  cp -f "cxvm/downloads/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  cp -f "cxvm/downloads/thunder-server" "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
elif [ -f "downloads/cxvm" ]; then
  cp -f "downloads/cxvm" "$CXVM_DIR/bin/cxvm"
  cp -f "downloads/cex-pack" "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
  cp -f "downloads/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  cp -f "downloads/thunder-server" "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL "$FACTORY_URL/dist/cxvm" -o "$CXVM_DIR/bin/cxvm" 2>/dev/null || \
  curl -fsSL "$FACTORY_URL/downloads/cxvm" -o "$CXVM_DIR/bin/cxvm" 2>/dev/null || \
  curl -fsSL "https://raw.githubusercontent.com/2-tek/cxvm/main/dist/cxvm" -o "$CXVM_DIR/bin/cxvm" 2>/dev/null || \
  curl -fsSL "https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/cxvm" -o "$CXVM_DIR/bin/cxvm" 2>/dev/null || true
  curl -fsSL "$FACTORY_URL/dist/cex-pack" -o "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
  curl -fsSL "$FACTORY_URL/dist/cvm-server" -o "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  curl -fsSL "$FACTORY_URL/dist/thunder-server" -o "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
elif command -v wget >/dev/null 2>&1; then
  wget -q "$FACTORY_URL/dist/cxvm" -O "$CXVM_DIR/bin/cxvm" 2>/dev/null || \
  wget -q "$FACTORY_URL/downloads/cxvm" -O "$CXVM_DIR/bin/cxvm" 2>/dev/null || true
  wget -q "$FACTORY_URL/dist/cex-pack" -O "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
  wget -q "$FACTORY_URL/dist/cvm-server" -O "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  wget -q "$FACTORY_URL/dist/thunder-server" -O "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
fi

if [ ! -f "$CXVM_DIR/bin/cxvm" ]; then
  echo "Error: Failed to install or locate cxvm binary in $CXVM_DIR/bin/cxvm" >&2
  exit 1
fi

chmod +x "$CXVM_DIR/bin/cxvm"* "$CXVM_DIR/bin/cex-pack"* "$CXVM_DIR/bin/cvm-server"* "$CXVM_DIR/bin/thunder-server"* 2>/dev/null || true
cp -f "$CXVM_DIR/bin/cxvm" "$CXVM_DIR/bin/cxvm.sh" 2>/dev/null || true

# Run cxvm install
export PATH="$CXVM_DIR/bin:$CXVM_DIR/current/bin:$PATH"
source "$CXVM_DIR/bin/cxvm"
cxvm install "$DEFAULT_VER"
cxvm use "$DEFAULT_VER"

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

