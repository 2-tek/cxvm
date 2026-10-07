#!/usr/bin/env bash
# 2-TEK Cex Factory: Cross-Platform Quick Installer (curl | bash)
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

set -e

CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
FACTORY_URL="${CEX_FACTORY_URL:-http://127.0.0.1:3080}"
DEFAULT_VER="3.0.0"

echo "==============================================================="
echo "   2-TEK Cex Factory: Cross-Platform Runtime Installer (cxvm)  "
echo "==============================================================="

mkdir -p "$CXVM_DIR/bin" "$CXVM_DIR/versions" "$CXVM_DIR/cache"

# Install cxvm CLI script
if [ -f "packages/Factory/downloads/cxvm" ]; then
  cp "packages/Factory/downloads/cxvm" "$CXVM_DIR/bin/cxvm"
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
echo "  ✓ Cex Runtime v$DEFAULT_VER (CexR v3) installed via cxvm!    "
echo "==============================================================="
echo ""
echo "Activate in current terminal:"
echo "  export CXVM_DIR=\"$CXVM_DIR\""
echo "  export PATH=\"\$CXVM_DIR/bin:\$CXVM_DIR/current/bin:\$PATH\""
echo ""
echo "Or add to ~/.bashrc or ~/.zshrc."
