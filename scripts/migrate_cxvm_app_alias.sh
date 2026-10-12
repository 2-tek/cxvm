#!/usr/bin/env bash
# ==============================================================================
# 2-TEK Ecosystem: Migrate cxvm app aliases to 'cxvm --app {appName}'
# Rule Conformance: Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET_DIR="."
FIX_MODE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --fix|-f|--write)
      FIX_MODE=1
      shift
      ;;
    --check|--dry-run)
      FIX_MODE=0
      shift
      ;;
    --path|-p)
      TARGET_DIR="$2"
      shift 2
      ;;
    --path=*)
      TARGET_DIR="${1#--path=}"
      shift
      ;;
    --help|-h)
      echo "Usage: bash scripts/migrate_cxvm_app_alias.sh [options]"
      echo ""
      echo "Options:"
      echo "  --path <dir>     Target directory to scan (default: .)"
      echo "  --fix            Apply migration in-place"
      echo "  --check          Dry-run preview without modifying files (default)"
      echo "  --help           Show this help message"
      exit 0
      ;;
    *)
      if [ -d "$1" ]; then
        TARGET_DIR="$1"
      fi
      shift
      ;;
  esac
done


echo "==============================================================================="
echo "       2-TEK Ecosystem: Migrate cxvm app aliases to 'cxvm --app {appName}'     "
echo "==============================================================================="
echo "  Target Directory: $TARGET_DIR"
if [ $FIX_MODE -eq 1 ]; then
  echo "  Execution Mode:   FIX (In-Place File Updates)"
else
  echo "  Execution Mode:   CHECK (Dry-Run Preview)"
fi
echo "  Target Aliases:   'cxvm thunder', 'cxvm lighting', 'cxvm deepsea', 'cxvm cvm'"
echo "  Replacement:      'cxvm --app {appName}'"
echo "-------------------------------------------------------------------------------"

python3 - <<PYEOF
import os, sys, re

target_dir = "$TARGET_DIR"
fix_mode = ($FIX_MODE == 1)

ignored_dirs = {".git", ".cvm", "node_modules", ".cex_cache", ".cex_boxes", "tmp", "dist", "bin", "downloads"}
text_exts = {".cex", ".json", ".sh", ".ps1", ".cmd", ".md", ".yml", ".yaml"}

scanned = 0
modified = 0
replacements = 0

patterns = [
    (re.compile(r'(?<!\[)(?<!\b--app\s)(?<!\bapp\s)(?<!alias:\s)\bcxvm\s+thunder\b'), 'cxvm --app thunder'),
    (re.compile(r'(?<!\[)(?<!\b--app\s)(?<!\bapp\s)(?<!alias:\s)\bcxvm\s+lighting\b'), 'cxvm --app lighting'),
    (re.compile(r'(?<!\[)(?<!\b--app\s)(?<!\bapp\s)(?<!alias:\s)\bcxvm\s+deepsea\b'), 'cxvm --app deepsea'),
    (re.compile(r'(?<!\[)(?<!\b--app\s)(?<!\bapp\s)(?<!alias:\s)\bcxvm\s+cvm\b'), 'cxvm --app cvm'),
]

for root, dirs, files in os.walk(target_dir):
    dirs[:] = [d for d in dirs if d not in ignored_dirs and not d.startswith(".git") and not d.startswith(".cvm")]
    for fname in files:
        if "migrate_cxvm_app_alias" in fname:
            continue
        ext = os.path.splitext(fname)[1].lower()
        if ext not in text_exts:
            continue
        
        filepath = os.path.join(root, fname)
        scanned += 1
        try:
            with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
        except Exception:
            continue

        file_repls = 0
        new_content = content
        for pat, repl in patterns:
            matches = len(pat.findall(new_content))
            if matches > 0:
                new_content = pat.sub(repl, new_content)
                file_repls += matches

        if file_repls > 0:
            modified += 1
            replacements += file_repls
            if fix_mode:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print(f"  [OK] Migrated: {filepath} ({file_repls} alias occurrence(s) updated)")
            else:
                print(f"  [DRY-RUN] Found: {filepath} ({file_repls} alias occurrence(s) to migrate)")

print("-------------------------------------------------------------------------------")
print("=== Migration Summary ===")
print(f"  Files Scanned:    {scanned}")
print(f"  Files To Migrate: {modified}")
print(f"  Total Aliases:    {replacements}")
if fix_mode:
    print("[OK] All legacy cxvm aliases successfully migrated to 'cxvm --app {appName}'!")
else:
    if modified > 0:
        print(f"[WARN] Dry-run found {modified} file(s) requiring migration. Run with --fix to apply.")
    else:
        print("[OK] All files already conform to 'cxvm --app {appName}'. No changes needed.")
print("===============================================================================")
PYEOF
