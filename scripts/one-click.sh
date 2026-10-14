#!/usr/bin/env bash
# ==============================================================================
# 2-TEK CXVM: Cross-Platform One-Click Download, Setup & Toolchain Activation
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols)
# ==============================================================================
set -e

CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
DEFAULT_VER="${CXVM_DEFAULT_VERSION:-8.0.0}"
PORT="${PORT:-3080}"
INVOCATION_DIR="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================================================"
echo "    2-TEK CXVM: One-Click Cross-Platform Setup & Toolchain Activation          "
echo "================================================================================"

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

PLATFORM="${TARGET_OS}-${TARGET_ARCH}"
echo "[INFO] Detected Platform: $PLATFORM"
echo "[INFO] Target Directory:  $CXVM_DIR"

mkdir -p "$CXVM_DIR/bin" "$CXVM_DIR/versions/v${DEFAULT_VER}/bin" "$CXVM_DIR/cache" "$CXVM_DIR/alias"

SERVER_URL="http://localhost:${PORT}"
if curl -s -f "${SERVER_URL}/api/v1/setup/one-click?platform=${PLATFORM}&version=${DEFAULT_VER}" >/dev/null 2>&1; then
  echo "[INFO] Connected to CXVM Factory Server at ${SERVER_URL}."
  curl -s "${SERVER_URL}/api/v1/setup/one-click?platform=${PLATFORM}&version=${DEFAULT_VER}" >/dev/null 2>&1 || true
fi

# Locate existing cxvm binary in workspace or downloads
CXVM_SRC=""
if [ -f "${INVOCATION_DIR}/dist/cxvm" ]; then
  CXVM_SRC="${INVOCATION_DIR}/dist/cxvm"
elif [ -f "${SCRIPT_DIR}/../dist/cxvm" ]; then
  CXVM_SRC="${SCRIPT_DIR}/../dist/cxvm"
elif [ -f "${INVOCATION_DIR}/bin/cxvm" ]; then
  CXVM_SRC="${INVOCATION_DIR}/bin/cxvm"
fi

if [ -n "$CXVM_SRC" ] && [ -f "$CXVM_SRC" ]; then
  cp -f "$CXVM_SRC" "$CXVM_DIR/bin/cxvm"
  chmod +x "$CXVM_DIR/bin/cxvm"
fi

# Link or copy cexr and cexp into active versions
for tool in cexr cexp cex; do
  if [ -f "${INVOCATION_DIR}/bin/${tool}" ]; then
    cp -f "${INVOCATION_DIR}/bin/${tool}" "$CXVM_DIR/bin/${tool}" 2>/dev/null || true
    chmod +x "$CXVM_DIR/bin/${tool}" 2>/dev/null || true
  elif command -v "$tool" >/dev/null 2>&1; then
    RESOLVED_TOOL="$(command -v "$tool")"
    ln -sf "$RESOLVED_TOOL" "$CXVM_DIR/bin/${tool}" 2>/dev/null || cp -f "$RESOLVED_TOOL" "$CXVM_DIR/bin/${tool}" 2>/dev/null || true
  fi
done

echo "${DEFAULT_VER}" > "$CXVM_DIR/default"
ln -sfn "$CXVM_DIR/versions/v${DEFAULT_VER}" "$CXVM_DIR/current" 2>/dev/null || true

# Run one-click setup via cxvm CLI if present
if [ -x "$CXVM_DIR/bin/cxvm" ]; then
  "$CXVM_DIR/bin/cxvm" setup --one-click 2>/dev/null || true
fi

# Export PATH in shell profile
EXPORT_LINE="export PATH=\"\$HOME/.cxvm/bin:\$PATH\""
for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
  if [ -f "$rc" ] && ! grep -q "\.cxvm/bin" "$rc"; then
    echo "" >> "$rc"
    echo "# 2-TEK CXVM Environment PATH" >> "$rc"
    echo "$EXPORT_LINE" >> "$rc"
  fi
done

echo "[OK] 2-TEK CXVM one-click cross-platform setup completed successfully."
echo "     Active Version: v${DEFAULT_VER}"
echo "     Binaries:       $CXVM_DIR/bin"
