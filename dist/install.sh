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

# Install cxvm CLI script, cvm-server, and thunder-server
if [ -f "cxvm/downloads/cxvm" ]; then
  cp "cxvm/downloads/cxvm" "$CXVM_DIR/bin/cxvm"
  cp "cxvm/downloads/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  cp "cxvm/downloads/thunder-server" "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
elif [ -f "packages/cxvm/downloads/cxvm" ]; then
  cp "packages/cxvm/downloads/cxvm" "$CXVM_DIR/bin/cxvm"
  cp "packages/cxvm/downloads/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  cp "packages/cxvm/downloads/thunder-server" "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
elif [ -f "downloads/cxvm" ]; then
  cp "downloads/cxvm" "$CXVM_DIR/bin/cxvm"
  cp "downloads/cvm-server" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
  cp "downloads/thunder-server" "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
fi
for tool in cexp cexp.cmd cexp.ps1 cexr-v4 cexr-v4.cmd cexr-v4.ps1; do
  if [ -f "cxvm/downloads/$tool" ]; then
    cp "cxvm/downloads/$tool" "$CXVM_DIR/bin/$tool" 2>/dev/null || true
  elif [ -f "downloads/$tool" ]; then
    cp "downloads/$tool" "$CXVM_DIR/bin/$tool" 2>/dev/null || true
  fi
done
chmod +x "$CXVM_DIR/bin/cxvm"* "$CXVM_DIR/bin/cex"* "$CXVM_DIR/bin/cvm-server"* "$CXVM_DIR/bin/thunder-server"* 2>/dev/null || true
cp "$CXVM_DIR/bin/cxvm" "$CXVM_DIR/bin/cxvm.sh" 2>/dev/null || true

# Run cxvm install
if [ -f "$CXVM_DIR/bin/cxvm" ]; then
  source "$CXVM_DIR/bin/cxvm"
  cxvm install "$DEFAULT_VER"
  cxvm use "$DEFAULT_VER"
fi

echo ""
echo "==============================================================="
echo "  [OK] Cex Runtime v$DEFAULT_VER (CexR v8) installed via cxvm! "
echo "==============================================================="
echo ""
echo "Activate in current terminal:"
echo "  export CXVM_DIR=\"$CXVM_DIR\""
echo "  export PATH=\"\$CXVM_DIR/bin:\$CXVM_DIR/current/bin:\$PATH\""
echo ""
echo "Or add to ~/.bashrc or ~/.zshrc."
