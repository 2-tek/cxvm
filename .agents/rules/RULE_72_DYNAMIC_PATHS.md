---
trigger: always_on
---

# Rule 72: Dynamic Path Resolution Standard

<!-- Rule Conformance: Rule 72 (Dynamic Paths) -->

> **ZERO HARDCODED PATHS**:
> All paths in scripts, tools, code, documentation, and agent rules MUST resolve dynamically relative to the execution context or standard environment variables.
> **HARDCODED ABSOLUTE USER PATHS (e.g. `/home/username/...` or `C:\Users\username\...`) ARE STRICTLY FORBIDDEN.**

---

## 1. Requirements

1. **Environment-Driven Roots**:
   - Use `$HOME`, `$CXVM_DIR`, `$CEX_HOME`, `$XDG_DATA_HOME`, or standard platform locations (`%USERPROFILE%`, `$env:USERPROFILE`).
   - Shell scripts: resolve script directory dynamically via `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`.
   - PowerShell scripts: resolve dynamically via `$PSScriptRoot`.
   - Batch scripts: resolve dynamically via `%~dp0`.
2. **Cex Source Resolution**:
   - Use relative paths from project root or look up active runtime via `fs.exists("dist") ? "dist" : (fs.exists("downloads") ? "downloads" : ...)`.
   - Never embed specific developer home directory strings inside committed assets.
3. **Verification Command**:
   ```bash
   grep -rn "/home/[a-zA-Z0-9_-]\+" .agents/ src/ bin/ scripts/ tests/
   ```
