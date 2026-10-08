---
trigger: always_on
---

# Rule 29: End-Of-File (EOF) Integrity Standard

<!-- Rule Conformance: Rule 29 (EOF Integrity) -->

> **MANDATORY INTEGRITY REQUIREMENT**:
> Every file created, modified, or maintained in the `cxvm` repository MUST end with exactly **ONE** newline character (`\n` / byte `0x0A`).

---

## 1. Requirements

1. **Exactly One Trailing Newline**:
   - Files must NOT omit the final newline (preventing `\ No newline at end of file` in git diffs).
   - Files must NOT contain trailing blank lines (multiple consecutive newlines at the end of the file).
2. **Applicable File Types**:
   - Source code (`*.cex`, `*.hpp`, `*.cpp`)
   - Shell & batch scripts (`*.sh`, `*.ps1`, `*.cmd`)
   - Package configurations and JSON (`cex-pack.json`, `package.json`, `manifest.json`, `*.json`)
   - Documentation and agent rules (`*.md`, `*.txt`)
   - Ignore & dotfiles (`.gitignore`, `.env*`)
3. **Verification Command**:
   ```bash
   python3 -c "
   import sys, pathlib
   bad = [f for f in pathlib.Path('.').rglob('*') if f.is_file() and not str(f).startswith('./.git') and not str(f).endswith(('.tar.gz', '.zip')) and (f.read_bytes()[-1:] != b'\n' or f.read_bytes()[-2:] == b'\n\n')]
   if bad: sys.exit(f'Rule 29 violation in: {bad}')
   "
   ```
