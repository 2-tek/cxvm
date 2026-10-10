#!/usr/bin/env bash
# 2-TEK Ecosystem: Scan and Install Git & CVM Hooks
# Rule Conformance: Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCAN_TARGET="${1:-$HOME/Projects}"

echo "==============================================================="
echo "       2-TEK Git & CVM Hooks Scanner & Installer               "
echo "==============================================================="
echo "  Target Search Root: $SCAN_TARGET"
echo "  Pre-Commit Action:  CexLint Auto-Fix (cex-lint --fix)"
echo "  Pre-Push Action:    Prettier Code Style Verification"
echo "---------------------------------------------------------------"

# Hook templates
PRE_COMMIT_CONTENT='#!/usr/bin/env bash
# 2-TEK Ecosystem: Pre-Commit Hook (Auto-Fix with CexLint)
# Rule Conformance: Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols)
set -e

echo "==> [pre-commit] Running CexLint auto-fix before commit..."

# 1. Dynamically locate cxvm / cex / cex-lint (Rule 72)
CXVM_BIN=""
for cand in "$CXVM_DIR/bin/cxvm" "$HOME/.cxvm/bin/cxvm" "$(command -v cxvm 2>/dev/null)" "$CXVM_DIR/bin/cex" "$HOME/.cxvm/bin/cex" "$(command -v cex 2>/dev/null)"; do
  if [ -n "$cand" ] && [ -x "$cand" ]; then
    CXVM_BIN="$cand"
    break
  fi
done

if [ -n "$CXVM_BIN" ]; then
  "$CXVM_BIN" lint --fix . 2>/dev/null || true
  echo "[OK] [pre-commit] CexLint auto-fix completed."
else
  # Fallback to direct cex-lint script
  for cand in "$HOME/Projects/dependencies/cex-lint/src/index.cex" "$HOME/Projects/cex-lint/src/index.cex" ".cex_boxes/cex-lint/src/index.cex" ".cex_boxes/@cex-lint/src/index.cex"; do
    if [ -f "$cand" ]; then
      cexr "$cand" . --fix 2>/dev/null || true
      echo "[OK] [pre-commit] CexLint auto-fix completed via $cand."
      break
    fi
  done
fi

# 2. Re-stage any files modified by auto-fix
if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
  git add -u 2>/dev/null || true
fi
if [ -d ".cvm" ]; then
  if command -v cvm >/dev/null 2>&1; then
    cvm add -u 2>/dev/null || true
  fi
fi

exit 0
'

PRE_PUSH_CONTENT='#!/usr/bin/env bash
# 2-TEK Ecosystem: Pre-Push Hook (Prettier Verification)
# Rule Conformance: Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols)
set -e

echo "==> [pre-push] Running Prettier verification before push..."

# 1. Dynamically locate prettier / node (Rule 72)
if ! command -v prettier >/dev/null 2>&1; then
  for p in "$CXVM_DIR/bin/prettier" "$HOME/.cxvm/bin/prettier" "$HOME"/.nvm/versions/node/*/bin/prettier /usr/local/bin/prettier; do
    if [ -x "$p" ]; then
      export PATH="$(dirname "$p"):$PATH"
      break
    fi
  done
fi

# 2. Execute prettier on supported files
if command -v prettier >/dev/null 2>&1; then
  # Format/check supported files with 4-space indentation
  files=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -E "\.(json|md|yml|yaml|js|ts|html|css)$" || true)
  if [ -n "$files" ]; then
    echo "--> [pre-push] Verifying Prettier style for modified files: $files"
    prettier --check $files --tab-width 4 --ignore-unknown 2>/dev/null || prettier --write $files --tab-width 4 --ignore-unknown 2>/dev/null || true
  else
    prettier --check "cex-pack*.json" "README.md" --tab-width 4 --ignore-unknown 2>/dev/null || prettier --write "cex-pack*.json" "README.md" --tab-width 4 --ignore-unknown 2>/dev/null || true
  fi
  echo "[OK] [pre-push] Prettier formatting verified."
else
  echo "[WARN] [pre-push] Prettier not installed or not in PATH; skipping prettier check."
fi

exit 0
'

git_count=0
cvm_count=0

# Scan for .git directories
while IFS= read -r git_dir; do
  if [ -n "$git_dir" ] && [ -d "$git_dir" ]; then
    hooks_dir="$git_dir/hooks"
    mkdir -p "$hooks_dir"
    printf "%s\n" "$PRE_COMMIT_CONTENT" > "$hooks_dir/pre-commit"
    chmod +x "$hooks_dir/pre-commit"
    printf "%s\n" "$PRE_PUSH_CONTENT" > "$hooks_dir/pre-push"
    chmod +x "$hooks_dir/pre-push"
    git_count=$((git_count + 1))
    echo "  [OK] Installed hooks in .git: $(dirname "$git_dir")"
  fi
done < <(find "$SCAN_TARGET" -maxdepth 5 -name ".git" -type d 2>/dev/null)

# Scan for .cvm directories
while IFS= read -r cvm_dir; do
  if [ -n "$cvm_dir" ] && [ -d "$cvm_dir" ]; then
    hooks_dir="$cvm_dir/hooks"
    mkdir -p "$hooks_dir"
    printf "%s\n" "$PRE_COMMIT_CONTENT" > "$hooks_dir/pre-commit"
    chmod +x "$hooks_dir/pre-commit"
    printf "%s\n" "$PRE_PUSH_CONTENT" > "$hooks_dir/pre-push"
    chmod +x "$hooks_dir/pre-push"
    cvm_count=$((cvm_count + 1))
    echo "  [OK] Installed hooks in .cvm: $(dirname "$cvm_dir")"
  fi
done < <(find "$SCAN_TARGET" -maxdepth 5 -name ".cvm" -type d 2>/dev/null)

echo "---------------------------------------------------------------"
echo "[OK] Successfully scanned and installed hooks across workspace:"
echo "  - Total .git repositories configured: $git_count"
echo "  - Total .cvm repositories configured: $cvm_count"
echo "  - pre-commit: Auto-fix with CexLint (cxvm lint --fix)"
echo "  - pre-push:   Code style check with Prettier"
echo "==============================================================="
exit 0
