#!/usr/bin/env bash
# ==============================================================================
# 2-TEK CXVM: Quick Installer & Toolchain Environment Setup (setup.sh -> setup.cex)
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CEXR_BIN=""

if command -v cexr >/dev/null 2>&1; then
  CEXR_BIN="cexr"
elif [ -x "$HOME/.cxvm/bin/cexr" ]; then
  CEXR_BIN="$HOME/.cxvm/bin/cexr"
elif [ -x "$SCRIPT_DIR/bin/cexr" ]; then
  CEXR_BIN="$SCRIPT_DIR/bin/cexr"
elif [ -x "$HOME/.cex/bin/cexr" ]; then
  CEXR_BIN="$HOME/.cex/bin/cexr"
fi

if [ -n "$CEXR_BIN" ]; then
  if [ -f "$SCRIPT_DIR/setup.cex" ]; then
    exec "$CEXR_BIN" "$SCRIPT_DIR/setup.cex" "$@"
  elif [ -f "setup.cex" ]; then
    exec "$CEXR_BIN" "setup.cex" "$@"
  elif [ -f "$SCRIPT_DIR/dist/setup.cex" ]; then
    exec "$CEXR_BIN" "$SCRIPT_DIR/dist/setup.cex" "$@"
  fi
fi

# Fallback: bootstrap cxvm setup directly
if [ -f "$SCRIPT_DIR/cxvm" ]; then
  exec bash "$SCRIPT_DIR/cxvm" setup "$@"
elif [ -f "$SCRIPT_DIR/install.sh" ]; then
  exec bash "$SCRIPT_DIR/install.sh"
elif command -v cxvm >/dev/null 2>&1; then
  exec cxvm setup "$@"
fi

echo "[ERROR] cexr runtime and cxvm not found. Please run install.sh first." >&2
exit 1
