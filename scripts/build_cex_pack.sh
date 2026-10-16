#!/usr/bin/env bash
# 2-TEK Factory: CexPack, CexP & CexR Versioned Binary Deployment Engine
# Deploys built binaries strictly by exact version and type into ./bin/$version/$name-$type:
#   - ./bin/$cexPackVer/cex-pack-bean & ./bin/$cexPackVer/cex-pack (e.g. ./bin/1.0.5/cex-pack)
#   - ./bin/$cexpVer/cexp-$type (e.g. ./bin/8.0.0/cexp-v8, ./bin/6.0.2/cexp-v6, ./bin/3.0.1/cexp-v3, ./bin/1.0.0/cexp-v1)
#   - ./bin/$cexrVer/cexr-$type (e.g. ./bin/1.0.26/cexr-bean, ./bin/1.0.26/cexr-delivery, ./bin/1.0.26/cexr-drawer, ./bin/1.0.26/cexr-factory)
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), RULE_PURE_CEX_BIN

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPS_CEX_PACK_DIR="$(cd "$ROOT_DIR/../deps/cex-pack" 2>/dev/null && pwd || echo "")"
CEX_PACK_DIR="$(cd "$ROOT_DIR/../cex-pack" 2>/dev/null && pwd || echo "")"
CEXP_REPO_DIR="$(cd "$ROOT_DIR/../cexp" 2>/dev/null && pwd || echo "")"
CEXR_REPO_DIR="$(cd "$ROOT_DIR/../cexr" 2>/dev/null && pwd || echo "")"
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"

STAGE_DIR="$(mktemp -d -t cxvm-bin-stage-XXXXXX)"
trap 'rm -rf "$STAGE_DIR"' EXIT

read_manifest_field() {
  local mf="$1"
  local field="$2"
  if [ -f "$mf" ]; then
    sed -n "s/.*\"$field\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$mf" | head -n 1
  fi
}

echo "==============================================================="
echo "   2-TEK Cex Factory: Versioned Binary Deployment Engine       "
echo "   Target Pattern: ./bin/\$version/\$name-\$type               "
echo "==============================================================="

mkdir -p "$ROOT_DIR/dist" "$ROOT_DIR/downloads" "$ROOT_DIR/bin"

# Stage any existing binaries from ./bin before cleaning legacy flat/hardcoded paths
if [ -d "$ROOT_DIR/bin" ]; then
  cp -a "$ROOT_DIR/bin/." "$STAGE_DIR/" 2>/dev/null || true
fi

# Clean legacy flat binaries and hardcoded non-version directories in ./bin
rm -f \
  "$ROOT_DIR/bin/app" \
  "$ROOT_DIR/bin/cexp" \
  "$ROOT_DIR/bin/cexp-v"* \
  "$ROOT_DIR/bin/cex-pack" \
  "$ROOT_DIR/bin/cex-pack.cex" \
  "$ROOT_DIR/bin/cex-pack.cmd" \
  "$ROOT_DIR/bin/cexr-bean" \
  "$ROOT_DIR/bin/cexr-delivery" \
  "$ROOT_DIR/bin/cexr-drawer" \
  "$ROOT_DIR/bin/cexr-factory" \
  "$ROOT_DIR/bin/cvm-server" \
  "$ROOT_DIR/bin/cvm-server.cex" \
  "$ROOT_DIR/bin/thunder-server" \
  "$ROOT_DIR/bin/thunder-server.cex"
rm -rf \
  "$ROOT_DIR/bin/bean" \
  "$ROOT_DIR/bin/delivery" \
  "$ROOT_DIR/bin/drawer" \
  "$ROOT_DIR/bin/factory" \
  "$ROOT_DIR/bin"/v*

for sub in "$ROOT_DIR/bin"/*/; do
  [ -d "$sub" ] && rm -rf "$sub"
done

printf "# Keep directory structure for Git and CVM\n" > "$ROOT_DIR/bin/.gitkeep"
printf "# Keep directory structure for Git and CVM\n" > "$ROOT_DIR/bin/.cvmkeep"

# 1. Resolve and deploy cex-pack -> ./bin/$CEX_PACK_VER/cex-pack & ./bin/$CEX_PACK_VER/cex-pack-bean
CEX_PACK_MF=""
if [ -n "$DEPS_CEX_PACK_DIR" ] && [ -f "$DEPS_CEX_PACK_DIR/cex-pack.json" ]; then
  CEX_PACK_MF="$DEPS_CEX_PACK_DIR/cex-pack.json"
elif [ -n "$CEX_PACK_DIR" ] && [ -f "$CEX_PACK_DIR/cex-pack.json" ]; then
  CEX_PACK_MF="$CEX_PACK_DIR/cex-pack.json"
fi

CEX_PACK_VER="$(read_manifest_field "$CEX_PACK_MF" "version")"
CEX_PACK_VER="${CEX_PACK_VER:-1.0.5}"
CEX_PACK_NAME="$(read_manifest_field "$CEX_PACK_MF" "name")"
CEX_PACK_NAME="${CEX_PACK_NAME##*/}"
CEX_PACK_NAME="${CEX_PACK_NAME#@}"
CEX_PACK_NAME="${CEX_PACK_NAME:-cex-pack}"

CEX_PACK_BIN="$ROOT_DIR/dist/cex-pack"
CEX_PACK_CEX="$ROOT_DIR/dist/cex-pack.cex"
cp -f "$SCRIPT_DIR/cex_pack.cex" "$CEX_PACK_CEX"
cp -f "$SCRIPT_DIR/cex_pack.cex" "$ROOT_DIR/downloads/cex-pack.cex"

BUILT_CEX_PACK=""
for cp_cand in \
  "$DEPS_CEX_PACK_DIR/bin/$CEX_PACK_VER/$CEX_PACK_NAME-bean" \
  "$DEPS_CEX_PACK_DIR/bin/$CEX_PACK_VER/$CEX_PACK_NAME" \
  "$DEPS_CEX_PACK_DIR/bin/$CEX_PACK_NAME" \
  "$CEX_PACK_DIR/bin/$CEX_PACK_VER/$CEX_PACK_NAME" \
  "$CEX_PACK_DIR/bin/$CEX_PACK_NAME" \
  "$STAGE_DIR/$CEX_PACK_VER/$CEX_PACK_NAME-bean" \
  "$STAGE_DIR/$CEX_PACK_VER/$CEX_PACK_NAME" \
  "$STAGE_DIR/$CEX_PACK_NAME"; do
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
  echo "[OK] Located built native $CEX_PACK_NAME binary: $BUILT_CEX_PACK"
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
  "$SELF_DIR/../cexr" \
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

PACK_TARGET_DIR="$ROOT_DIR/bin/$CEX_PACK_VER"
mkdir -p "$PACK_TARGET_DIR"
cp -f "$CEX_PACK_BIN" "$PACK_TARGET_DIR/${CEX_PACK_NAME}-bean"
cp -f "$CEX_PACK_BIN" "$PACK_TARGET_DIR/${CEX_PACK_NAME}"
cp -f "$CEX_PACK_CEX" "$PACK_TARGET_DIR/cex-pack.cex"
chmod +x "$PACK_TARGET_DIR/${CEX_PACK_NAME}-bean" "$PACK_TARGET_DIR/${CEX_PACK_NAME}"
printf "# Keep directory structure for Git and CVM\n" > "$PACK_TARGET_DIR/.gitkeep"
printf "# Keep directory structure for Git and CVM\n" > "$PACK_TARGET_DIR/.cvmkeep"
echo "[OK] Deployed ./bin/$CEX_PACK_VER/${CEX_PACK_NAME}-bean & ./bin/$CEX_PACK_VER/${CEX_PACK_NAME}"

# 1b. Resolve and deploy cex-lint -> ./bin/$CEX_LINT_VER/cex-lint-bean & ./bin/$CEX_LINT_VER/cex-lint
DEPS_CEX_LINT_DIR="$(cd "$ROOT_DIR/../deps/cex-lint" 2>/dev/null && pwd || echo "")"
CEX_LINT_MF=""
if [ -n "$DEPS_CEX_LINT_DIR" ] && [ -f "$DEPS_CEX_LINT_DIR/cex-pack.json" ]; then
  CEX_LINT_MF="$DEPS_CEX_LINT_DIR/cex-pack.json"
fi
CEX_LINT_VER="$(read_manifest_field "$CEX_LINT_MF" "version")"
CEX_LINT_VER="${CEX_LINT_VER:-1.0.8}"
CEX_LINT_NAME="$(read_manifest_field "$CEX_LINT_MF" "name")"
CEX_LINT_NAME="${CEX_LINT_NAME##*/}"
CEX_LINT_NAME="${CEX_LINT_NAME#@}"
CEX_LINT_NAME="${CEX_LINT_NAME:-cex-lint}"

BUILT_CEX_LINT=""
for cl_cand in \
  "$DEPS_CEX_LINT_DIR/bin/$CEX_LINT_VER/$CEX_LINT_NAME-bean" \
  "$DEPS_CEX_LINT_DIR/bin/$CEX_LINT_VER/$CEX_LINT_NAME" \
  "$DEPS_CEX_LINT_DIR/bin/$CEX_LINT_NAME" \
  "$STAGE_DIR/$CEX_LINT_VER/$CEX_LINT_NAME-bean" \
  "$STAGE_DIR/$CEX_LINT_VER/$CEX_LINT_NAME"; do
  if [ -n "$cl_cand" ] && [ -x "$cl_cand" ] && [ ! -d "$cl_cand" ]; then
    BUILT_CEX_LINT="$cl_cand"
    break
  fi
done

if [ -n "$BUILT_CEX_LINT" ]; then
  LINT_TARGET_DIR="$ROOT_DIR/bin/$CEX_LINT_VER"
  mkdir -p "$LINT_TARGET_DIR"
  cp -f "$BUILT_CEX_LINT" "$LINT_TARGET_DIR/${CEX_LINT_NAME}-bean"
  cp -f "$BUILT_CEX_LINT" "$LINT_TARGET_DIR/${CEX_LINT_NAME}"
  chmod +x "$LINT_TARGET_DIR/${CEX_LINT_NAME}-bean" "$LINT_TARGET_DIR/${CEX_LINT_NAME}"
  printf "# Keep directory structure for Git and CVM\n" > "$LINT_TARGET_DIR/.gitkeep"
  printf "# Keep directory structure for Git and CVM\n" > "$LINT_TARGET_DIR/.cvmkeep"
  echo "[OK] Deployed ./bin/$CEX_LINT_VER/${CEX_LINT_NAME}-bean & ./bin/$CEX_LINT_VER/${CEX_LINT_NAME}"
fi

# 2. Resolve and deploy standalone cexp versions -> ./bin/$version/cexp-$type
CEXP_ROOT_NAME="cexp"
if [ -n "$CEXP_REPO_DIR" ] && [ -f "$CEXP_REPO_DIR/cex-pack.json" ]; then
  _crn="$(read_manifest_field "$CEXP_REPO_DIR/cex-pack.json" "name")"
  if [ -n "$_crn" ]; then
    _crn="${_crn##*/}"
    _crn="${_crn#@}"
    CEXP_ROOT_NAME="$_crn"
  fi
fi
CEXP_ROOT_NAME="${CEXP_ROOT_NAME:-cexp}"

LATEST_CEXP_V8=""
for vnum in 1 2 3 4 5 6 7 8; do
  ctype="v${vnum}"
  cver=""
  cname="$CEXP_ROOT_NAME"

  if [ -n "$CEXP_REPO_DIR" ] && [ -d "$CEXP_REPO_DIR" ]; then
    for wmf in "$CEXP_REPO_DIR/${ctype}"*/cex-pack.json; do
      if [ -f "$wmf" ]; then
        cver="$(read_manifest_field "$wmf" "version")"
        break
      fi
    done
  fi

  if [ -z "$cver" ]; then
    for sc in "$STAGE_DIR"/*/"${cname}-${ctype}" "$HOME/.cex/bin"/*/"${cname}-${ctype}"; do
      if [ -x "$sc" ] && [ ! -d "$sc" ]; then
        _pdir="$(basename "$(dirname "$sc")")"
        if [[ "$_pdir" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
          cver="$_pdir"
          break
        fi
      fi
    done
  fi
  cver="${cver:-${vnum}.0.0}"
  target_bin_name="${cname}-${ctype}"

  FOUND_CEXP=""
  for cexp_cand in \
    "$CEXP_REPO_DIR/bin/$cver/$target_bin_name" \
    "$CEXP_REPO_DIR/bin/$cver/$cname" \
    "$HOME/.cex/bin/$cver/$target_bin_name" \
    "$HOME/.cex/bin/$cver/$cname" \
    "$STAGE_DIR/$cver/$target_bin_name" \
    "$STAGE_DIR/$cver/$cname"; do
    if [ -n "$cexp_cand" ] && [ -x "$cexp_cand" ] && [ ! -d "$cexp_cand" ]; then
      FOUND_CEXP="$cexp_cand"
      break
    fi
  done

  if [ -n "$FOUND_CEXP" ]; then
    CEXP_VER_DIR="$ROOT_DIR/bin/$cver"
    mkdir -p "$CEXP_VER_DIR"
    cp -f "$FOUND_CEXP" "$CEXP_VER_DIR/$target_bin_name"
    chmod +x "$CEXP_VER_DIR/$target_bin_name"
    printf "# Keep directory structure for Git and CVM\n" > "$CEXP_VER_DIR/.gitkeep"
    printf "# Keep directory structure for Git and CVM\n" > "$CEXP_VER_DIR/.cvmkeep"
    if [ "$ctype" = "v8" ]; then
      LATEST_CEXP_V8="$CEXP_VER_DIR/$target_bin_name"
    fi
    if [ -d "$CXVM_DIR/versions/v$cver/bin" ]; then
      mkdir -p "$CXVM_DIR/versions/v$cver/bin/$cver"
      cp -f "$CEXP_VER_DIR/$target_bin_name" "$CXVM_DIR/versions/v$cver/bin/$cver/$target_bin_name"
      cp -f "$CEXP_VER_DIR/$target_bin_name" "$CXVM_DIR/versions/v$cver/bin/cexp"
      chmod +x "$CXVM_DIR/versions/v$cver/bin/$cver/$target_bin_name" "$CXVM_DIR/versions/v$cver/bin/cexp"
    fi
    echo "[OK] Deployed ./bin/$cver/$target_bin_name"
  fi
done

if [ -n "$LATEST_CEXP_V8" ] && [ -x "$LATEST_CEXP_V8" ]; then
  cp -f "$LATEST_CEXP_V8" "$ROOT_DIR/dist/cexp"
  cp -f "$LATEST_CEXP_V8" "$ROOT_DIR/downloads/cexp"
  chmod +x "$ROOT_DIR/dist/cexp" "$ROOT_DIR/downloads/cexp"
  if [ -d "$CXVM_DIR/bin" ]; then
    cp -f "$LATEST_CEXP_V8" "$CXVM_DIR/bin/cexp"
    chmod +x "$CXVM_DIR/bin/cexp"
  fi
fi

# 3. Resolve and deploy cexr editions -> ./bin/$CEXR_VER/cexr-$type
CEXR_VER=""
CEXR_NAME="cexr"
if [ -n "$CEXR_REPO_DIR" ] && [ -f "$CEXR_REPO_DIR/cex-pack.json" ]; then
  CEXR_VER="$(read_manifest_field "$CEXR_REPO_DIR/cex-pack.json" "version")"
  _rn="$(read_manifest_field "$CEXR_REPO_DIR/cex-pack.json" "name")"
  if [ -n "$_rn" ]; then
    _rn="${_rn##*/}"
    _rn="${_rn#@}"
    CEXR_NAME="$_rn"
  fi
fi
if [ -z "$CEXR_VER" ]; then
  for rc in "$STAGE_DIR"/*/"cexr-bean"; do
    if [ -x "$rc" ] && [ ! -d "$rc" ]; then
      _rdir="$(basename "$(dirname "$rc")")"
      if [[ "$_rdir" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && [ "$_rdir" != "8.0.0" ]; then
        CEXR_VER="$_rdir"
        break
      fi
    fi
  done
fi
CEXR_VER="${CEXR_VER:-1.0.26}"
CEXR_NAME="${CEXR_NAME:-cexr}"

CEXR_TYPES=("bean" "delivery" "drawer" "factory")
for vtype in "${CEXR_TYPES[@]}"; do
  target_cexr_name="${CEXR_NAME}-${vtype}"
  FOUND_CEXR_TYPE=""
  for cr_cand in \
    "$CEXR_REPO_DIR/bin/$CEXR_VER/$target_cexr_name" \
    "$CEXR_REPO_DIR/bin/$vtype/$target_cexr_name" \
    "$CEXR_REPO_DIR/bin/$target_cexr_name" \
    "$STAGE_DIR/$CEXR_VER/$target_cexr_name" \
    "$STAGE_DIR/8.0.0/$target_cexr_name" \
    "$STAGE_DIR/$vtype/$target_cexr_name" \
    "$STAGE_DIR/$target_cexr_name"; do
    if [ -n "$cr_cand" ] && [ -x "$cr_cand" ] && [ ! -d "$cr_cand" ]; then
      FOUND_CEXR_TYPE="$cr_cand"
      break
    fi
  done

  if [ -n "$FOUND_CEXR_TYPE" ]; then
    CEXR_VER_DIR="$ROOT_DIR/bin/$CEXR_VER"
    mkdir -p "$CEXR_VER_DIR"
    cp -f "$FOUND_CEXR_TYPE" "$CEXR_VER_DIR/$target_cexr_name"
    cp -f "$CEXR_VER_DIR/$target_cexr_name" "$ROOT_DIR/dist/$target_cexr_name"
    cp -f "$CEXR_VER_DIR/$target_cexr_name" "$ROOT_DIR/downloads/$target_cexr_name"
    chmod +x "$CEXR_VER_DIR/$target_cexr_name" "$ROOT_DIR/dist/$target_cexr_name" "$ROOT_DIR/downloads/$target_cexr_name"
    printf "# Keep directory structure for Git and CVM\n" > "$CEXR_VER_DIR/.gitkeep"
    printf "# Keep directory structure for Git and CVM\n" > "$CEXR_VER_DIR/.cvmkeep"
    if [ -d "$CXVM_DIR/bin" ]; then
      mkdir -p "$CXVM_DIR/bin/$CEXR_VER"
      cp -f "$CEXR_VER_DIR/$target_cexr_name" "$CXVM_DIR/bin/$CEXR_VER/$target_cexr_name"
      cp -f "$CEXR_VER_DIR/$target_cexr_name" "$CXVM_DIR/bin/$target_cexr_name"
      chmod +x "$CXVM_DIR/bin/$CEXR_VER/$target_cexr_name" "$CXVM_DIR/bin/$target_cexr_name"
    fi
    if [ -d "$CXVM_DIR/versions/v8.0.0/bin" ]; then
      mkdir -p "$CXVM_DIR/versions/v8.0.0/bin/$CEXR_VER"
      cp -f "$CEXR_VER_DIR/$target_cexr_name" "$CXVM_DIR/versions/v8.0.0/bin/$CEXR_VER/$target_cexr_name"
      cp -f "$CEXR_VER_DIR/$target_cexr_name" "$CXVM_DIR/versions/v8.0.0/bin/$target_cexr_name"
      chmod +x "$CXVM_DIR/versions/v8.0.0/bin/$CEXR_VER/$target_cexr_name" "$CXVM_DIR/versions/v8.0.0/bin/$target_cexr_name"
    fi
    echo "[OK] Deployed ./bin/$CEXR_VER/$target_cexr_name"
  fi
done

# 4. Preserve project build artifact in ./bin/$CXVM_VER/${CXVM_NAME}-$type if previously built
if [ -f "$ROOT_DIR/cex-pack.json" ]; then
  CXVM_VER="$(read_manifest_field "$ROOT_DIR/cex-pack.json" "version")"
  CXVM_VER="${CXVM_VER:-2.0.0}"
  CXVM_NAME="$(read_manifest_field "$ROOT_DIR/cex-pack.json" "name")"
  CXVM_NAME="${CXVM_NAME##*/}"
  CXVM_NAME="${CXVM_NAME#@}"
  CXVM_NAME="${CXVM_NAME:-cxvm}"
  for proj_cand in "$STAGE_DIR/$CXVM_VER/${CXVM_NAME}"-*; do
    if [ -x "$proj_cand" ] && [ ! -d "$proj_cand" ]; then
      mkdir -p "$ROOT_DIR/bin/$CXVM_VER"
      cp -f "$proj_cand" "$ROOT_DIR/bin/$CXVM_VER/$(basename "$proj_cand")"
      chmod +x "$ROOT_DIR/bin/$CXVM_VER/$(basename "$proj_cand")"
      printf "# Keep directory structure for Git and CVM\n" > "$ROOT_DIR/bin/$CXVM_VER/.gitkeep"
      printf "# Keep directory structure for Git and CVM\n" > "$ROOT_DIR/bin/$CXVM_VER/.cvmkeep"
    fi
  done
fi

# Sync cex-pack to global $CXVM_DIR/bin and current if available
if [ -d "$CXVM_DIR/bin" ]; then
  mkdir -p "$CXVM_DIR/bin/$CEX_PACK_VER"
  cp -f "$CEX_PACK_BIN" "$CXVM_DIR/bin/$CEX_PACK_VER/$CEX_PACK_NAME"
  cp -f "$CEX_PACK_BIN" "$CXVM_DIR/bin/$CEX_PACK_NAME"
  cp -f "$CEX_PACK_CEX" "$CXVM_DIR/bin/cex-pack.cex"
  chmod +x "$CXVM_DIR/bin/$CEX_PACK_VER/$CEX_PACK_NAME" "$CXVM_DIR/bin/$CEX_PACK_NAME"
fi
if [ -d "$CXVM_DIR/current/bin" ]; then
  mkdir -p "$CXVM_DIR/current/bin/$CEX_PACK_VER"
  cp -f "$CEX_PACK_BIN" "$CXVM_DIR/current/bin/$CEX_PACK_VER/$CEX_PACK_NAME"
  cp -f "$CEX_PACK_BIN" "$CXVM_DIR/current/bin/$CEX_PACK_NAME"
  cp -f "$CEX_PACK_CEX" "$CXVM_DIR/current/bin/cex-pack.cex"
  chmod +x "$CXVM_DIR/current/bin/$CEX_PACK_VER/$CEX_PACK_NAME" "$CXVM_DIR/current/bin/$CEX_PACK_NAME"
fi

echo "==============================================================="
echo "  [OK] Toolchain binaries deployed to ./bin/\$version/\$name-\$type!"
echo "==============================================================="
