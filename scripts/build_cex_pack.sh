#!/usr/bin/env bash
# 2-TEK Factory: CexPack, CexP & CexR Binary Integration Engine
# Integrates built versions of:
#   - ./bin/$lastVersion/cex-pack (1.0.5 / 8.0.0) -> ./bin/cex-pack
#   - ./bin/8.x.x/cexp (and standalone 1.0.0..8.0.0) -> ./bin/cexp
#   - ./bin/$versionType/cexr-$type (bean, delivery, drawer, factory) -> ./bin/cexr-$type
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), RULE_PURE_CEX_BIN

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPS_CEX_PACK_DIR="$(cd "$ROOT_DIR/../deps/cex-pack" 2>/dev/null && pwd || echo "")"
CEX_PACK_DIR="$(cd "$ROOT_DIR/../cex-pack" 2>/dev/null && pwd || echo "")"
CEXP_REPO_DIR="$(cd "$ROOT_DIR/../cexp" 2>/dev/null && pwd || echo "")"
CEXR_REPO_DIR="$(cd "$ROOT_DIR/../cexr" 2>/dev/null && pwd || echo "")"
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"

echo "==============================================================="
echo "   2-TEK Cex Factory: Toolchain Binary Integration Engine      "
echo "==============================================================="

# 1. Integrate built cex-pack binary and cex_pack.cex source
CEX_PACK_BIN="$ROOT_DIR/dist/cex-pack"
CEX_PACK_CEX="$ROOT_DIR/dist/cex-pack.cex"
mkdir -p "$ROOT_DIR/dist" "$ROOT_DIR/downloads" "$ROOT_DIR/bin"

printf "# Keep directory structure for Git and CVM\n" > "$ROOT_DIR/bin/.gitkeep"
printf "# Keep directory structure for Git and CVM\n" > "$ROOT_DIR/bin/.cvmkeep"

cp -f "$SCRIPT_DIR/cex_pack.cex" "$CEX_PACK_CEX"
cp -f "$SCRIPT_DIR/cex_pack.cex" "$ROOT_DIR/downloads/cex-pack.cex"
cp -f "$SCRIPT_DIR/cex_pack.cex" "$ROOT_DIR/bin/cex-pack.cex"

BUILT_CEX_PACK=""
for cp_cand in \
  "$DEPS_CEX_PACK_DIR/bin/cex-pack" \
  "$CEX_PACK_DIR/bin/cex-pack" \
  "$ROOT_DIR/bin/1.0.5/cex-pack" \
  "$ROOT_DIR/bin/8.0.0/cex-pack"; do
  if [ -n "$cp_cand" ] && [ -x "$cp_cand" ] && [ ! -d "$cp_cand" ]; then
    if ! head -c 2 "$cp_cand" 2>/dev/null | grep -q "^#!"; then
      BUILT_CEX_PACK="$cp_cand"
      break
    fi
  fi
done

if [ -n "$BUILT_CEX_PACK" ]; then
  cp -f "$BUILT_CEX_PACK" "$CEX_PACK_BIN"
  chmod +x "$CEX_PACK_BIN"
  echo "[OK] Located built native cex-pack binary: $BUILT_CEX_PACK"
else
  cat << 'CEXP_BIN_EOF' > "$CEX_PACK_BIN"
#!/usr/bin/env bash
# 2-TEK Cex-Pack: Native Manifest Validator & Package Manager Dispatcher (.cex via cexr runtime)
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), RULE_PURE_CEX_BIN

set -e

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"

CEXR_BIN=""
for r_cand in \
  "$SELF_DIR/cexr" \
  "$SELF_DIR/../bin/cexr" \
  "$CXVM_DIR/current/bin/cexr" \
  "$CXVM_DIR/bin/cexr"; do
  if [ -x "$r_cand" ] && [ ! -d "$r_cand" ]; then
    CEXR_BIN="$r_cand"
    break
  fi
done
if [ -z "$CEXR_BIN" ]; then
  CEXR_BIN="$(command -v cexr 2>/dev/null || echo "cexr")"
fi

CEX_PACK_SRC=""
for s_cand in \
  "$SELF_DIR/cex-pack.cex" \
  "$SELF_DIR/../scripts/cex_pack.cex" \
  "$SELF_DIR/../../scripts/cex_pack.cex" \
  "$(pwd)/scripts/cex_pack.cex" \
  "$(pwd)/bin/cex-pack.cex" \
  "$CXVM_DIR/bin/cex-pack.cex"; do
  if [ -f "$s_cand" ]; then
    CEX_PACK_SRC="$s_cand"
    break
  fi
done

if [ -n "$CEX_PACK_SRC" ]; then
  exec "$CEXR_BIN" "$CEX_PACK_SRC" "$@"
fi

echo "[ERROR] cex-pack.cex not found for cexr runtime execution" >&2
exit 1
CEXP_BIN_EOF
  chmod +x "$CEX_PACK_BIN"
fi

cp -f "$CEX_PACK_BIN" "$ROOT_DIR/downloads/cex-pack"

# 2. Integrate cex-pack into ./bin/$lastVersion/cex-pack (1.0.5 & 8.0.0) and ./bin/cex-pack
PACK_VERSIONS=("1.0.5" "8.0.0" "7.0.0" "6.0.2" "6.0.0" "5.0.0" "4.0.0" "3.0.1" "3.0.0" "2.0.0" "1.0.0")
for ver in "${PACK_VERSIONS[@]}"; do
  VER_DIR="$ROOT_DIR/bin/$ver"
  mkdir -p "$VER_DIR"
  cp -f "$CEX_PACK_BIN" "$VER_DIR/cex-pack"
  cp -f "$CEX_PACK_CEX" "$VER_DIR/cex-pack.cex"
  chmod +x "$VER_DIR/cex-pack"
  cat << 'CMD_EOF' > "$VER_DIR/cex-pack.cmd"
@echo off
cexr "%~dp0cex-pack.cex" %*
CMD_EOF
  printf "# Keep directory structure for Git and CVM\n" > "$VER_DIR/.gitkeep"
  printf "# Keep directory structure for Git and CVM\n" > "$VER_DIR/.cvmkeep"

  V_DIR="$ROOT_DIR/bin/v$ver"
  mkdir -p "$V_DIR"
  cp -f "$CEX_PACK_BIN" "$V_DIR/cex-pack"
  cp -f "$CEX_PACK_CEX" "$V_DIR/cex-pack.cex"
  chmod +x "$V_DIR/cex-pack"
  cat << 'CMD_EOF' > "$V_DIR/cex-pack.cmd"
@echo off
cexr "%~dp0cex-pack.cex" %*
CMD_EOF
  printf "# Keep directory structure for Git and CVM\n" > "$V_DIR/.gitkeep"
  printf "# Keep directory structure for Git and CVM\n" > "$V_DIR/.cvmkeep"

  if [ -d "$CXVM_DIR/versions/v$ver/bin" ]; then
    cp -f "$CEX_PACK_BIN" "$CXVM_DIR/versions/v$ver/bin/cex-pack"
    cp -f "$CEX_PACK_CEX" "$CXVM_DIR/versions/v$ver/bin/cex-pack.cex"
    chmod +x "$CXVM_DIR/versions/v$ver/bin/cex-pack"
  fi
done

# Integrate ./bin/$lastVersion/cex-pack directly into ./bin/cex-pack
cp -f "$ROOT_DIR/bin/1.0.5/cex-pack" "$ROOT_DIR/bin/cex-pack"
chmod +x "$ROOT_DIR/bin/cex-pack"
echo "[OK] Integrated ./bin/1.0.5/cex-pack and ./bin/8.0.0/cex-pack -> ./bin/cex-pack"

# 3. Integrate standalone cexp versions (1.0.0 .. 8.0.0) into ./bin/$ver/cexp and ./bin/cexp
CEXP_VERSIONS=("8.0.0" "7.0.0" "6.0.2" "6.0.0" "5.0.0" "4.0.0" "3.0.1" "3.0.0" "2.0.0" "1.0.0")
for ver in "${CEXP_VERSIONS[@]}"; do
  FOUND_CEXP=""
  for cexp_cand in \
    "$CEXP_REPO_DIR/bin/$ver/cexp" \
    "$HOME/.cex/bin/$ver/cexp" \
    "$ROOT_DIR/bin/$ver/cexp"; do
    if [ -n "$cexp_cand" ] && [ -x "$cexp_cand" ] && [ ! -d "$cexp_cand" ]; then
      FOUND_CEXP="$cexp_cand"
      break
    fi
  done

  if [ -n "$FOUND_CEXP" ]; then
    mkdir -p "$ROOT_DIR/bin/$ver" "$ROOT_DIR/bin/v$ver"
    if [ "$FOUND_CEXP" != "$ROOT_DIR/bin/$ver/cexp" ]; then
      cp -f "$FOUND_CEXP" "$ROOT_DIR/bin/$ver/cexp"
    fi
    cp -f "$ROOT_DIR/bin/$ver/cexp" "$ROOT_DIR/bin/v$ver/cexp"
    chmod +x "$ROOT_DIR/bin/$ver/cexp" "$ROOT_DIR/bin/v$ver/cexp"
    if [ -d "$CXVM_DIR/versions/v$ver/bin" ]; then
      cp -f "$ROOT_DIR/bin/$ver/cexp" "$CXVM_DIR/versions/v$ver/bin/cexp"
      chmod +x "$CXVM_DIR/versions/v$ver/bin/cexp"
    fi
  fi
done

if [ -x "$ROOT_DIR/bin/8.0.0/cexp" ]; then
  cp -f "$ROOT_DIR/bin/8.0.0/cexp" "$ROOT_DIR/bin/cexp"
  cp -f "$ROOT_DIR/bin/8.0.0/cexp" "$ROOT_DIR/dist/cexp"
  cp -f "$ROOT_DIR/bin/8.0.0/cexp" "$ROOT_DIR/downloads/cexp"
  chmod +x "$ROOT_DIR/bin/cexp" "$ROOT_DIR/dist/cexp" "$ROOT_DIR/downloads/cexp"
  if [ -d "$CXVM_DIR/bin" ]; then
    cp -f "$ROOT_DIR/bin/8.0.0/cexp" "$CXVM_DIR/bin/cexp"
    chmod +x "$CXVM_DIR/bin/cexp"
  fi
  echo "[OK] Integrated standalone ./bin/8.0.0/cexp (and v1.0.0..v8.0.0) -> ./bin/cexp"
fi

# 4. Integrate built cexr-$type editions into ./bin/$versionType/cexr-$type and ./bin/cexr-$type
CEXR_TYPES=("bean" "delivery" "drawer" "factory")
for vtype in "${CEXR_TYPES[@]}"; do
  FOUND_CEXR_TYPE=""
  for cr_cand in \
    "$CEXR_REPO_DIR/bin/$vtype/cexr-$vtype" \
    "$CEXR_REPO_DIR/bin/cexr-$vtype" \
    "$ROOT_DIR/bin/$vtype/cexr-$vtype" \
    "$ROOT_DIR/bin/cexr-$vtype"; do
    if [ -n "$cr_cand" ] && [ -x "$cr_cand" ] && [ ! -d "$cr_cand" ]; then
      FOUND_CEXR_TYPE="$cr_cand"
      break
    fi
  done

  if [ -n "$FOUND_CEXR_TYPE" ]; then
    TYPE_DIR="$ROOT_DIR/bin/$vtype"
    mkdir -p "$TYPE_DIR"
    if [ "$FOUND_CEXR_TYPE" != "$TYPE_DIR/cexr-$vtype" ]; then
      cp -f "$FOUND_CEXR_TYPE" "$TYPE_DIR/cexr-$vtype"
    fi
    cp -f "$TYPE_DIR/cexr-$vtype" "$ROOT_DIR/bin/cexr-$vtype"
    cp -f "$TYPE_DIR/cexr-$vtype" "$ROOT_DIR/bin/8.0.0/cexr-$vtype"
    cp -f "$TYPE_DIR/cexr-$vtype" "$ROOT_DIR/bin/v8.0.0/cexr-$vtype"
    cp -f "$TYPE_DIR/cexr-$vtype" "$ROOT_DIR/dist/cexr-$vtype"
    cp -f "$TYPE_DIR/cexr-$vtype" "$ROOT_DIR/downloads/cexr-$vtype"
    if [ -x "$ROOT_DIR/bin/8.0.0/cexp" ]; then
      cp -f "$ROOT_DIR/bin/8.0.0/cexp" "$TYPE_DIR/cexp"
      chmod +x "$TYPE_DIR/cexp"
    fi
    chmod +x "$TYPE_DIR/cexr-$vtype" "$ROOT_DIR/bin/cexr-$vtype" "$ROOT_DIR/bin/8.0.0/cexr-$vtype" "$ROOT_DIR/bin/v8.0.0/cexr-$vtype" "$ROOT_DIR/dist/cexr-$vtype" "$ROOT_DIR/downloads/cexr-$vtype"
    printf "# Keep directory structure for Git and CVM\n" > "$TYPE_DIR/.gitkeep"
    printf "# Keep directory structure for Git and CVM\n" > "$TYPE_DIR/.cvmkeep"
    if [ -d "$CXVM_DIR/bin" ]; then
      cp -f "$TYPE_DIR/cexr-$vtype" "$CXVM_DIR/bin/cexr-$vtype"
      chmod +x "$CXVM_DIR/bin/cexr-$vtype"
    fi
    if [ -d "$CXVM_DIR/versions/v8.0.0/bin" ]; then
      cp -f "$TYPE_DIR/cexr-$vtype" "$CXVM_DIR/versions/v8.0.0/bin/cexr-$vtype"
      chmod +x "$CXVM_DIR/versions/v8.0.0/bin/cexr-$vtype"
    fi
    echo "[OK] Integrated ./bin/$vtype/cexr-$vtype -> ./bin/cexr-$vtype"
  fi
done

# Sync cex-pack to global $CXVM_DIR/bin/cex-pack and current if available
if [ -d "$CXVM_DIR/bin" ]; then
  cp -f "$CEX_PACK_BIN" "$CXVM_DIR/bin/cex-pack"
  cp -f "$CEX_PACK_CEX" "$CXVM_DIR/bin/cex-pack.cex"
  chmod +x "$CXVM_DIR/bin/cex-pack"
fi
if [ -d "$CXVM_DIR/current/bin" ]; then
  cp -f "$CEX_PACK_BIN" "$CXVM_DIR/current/bin/cex-pack"
  cp -f "$CEX_PACK_CEX" "$CXVM_DIR/current/bin/cex-pack.cex"
  chmod +x "$CXVM_DIR/current/bin/cex-pack"
fi

echo "==============================================================="
echo "  [OK] Toolchain binaries integrated into ./bin/ successfully! "
echo "==============================================================="
