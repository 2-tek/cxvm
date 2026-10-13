---
trigger: always_on
---

# Mandatory Rule 72: Dynamic Path Resolution & Load Paths from .env Standard (RULE_72_DYNAMIC_PATHS)

<!-- Standard Specification: .agents/rules/RULE_72_DYNAMIC_PATHS.md -->
<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths) -->

> **ZERO HARDCODED PATHS — IF USING A PATH, LOAD FROM `.env`**:
> All paths in scripts, tools, source code, documentation, and agent rules MUST resolve dynamically from `.env`, the execution context, or standard environment variables.
> **HARDCODED ABSOLUTE USER PATHS (e.g. `/home/username/...` or `C:\Users\username\...`) AND HARDCODED STORAGE/RUNTIME PATHS ARE STRICTLY FORBIDDEN.**

---

## 1. Requirements

1. **Mandatory `.env` Path Loading (`RULE_NO_HARDCODE_PATH_FROM_ENV`)**:
    - Do NOT use hardcoded paths in application or service code (`./src`, `./bin`, `./builder`).
    - Whenever a file path, directory path, database path, upload directory, certificate path, or storage location is used, load it from `.env` via `@cex-env` (`CexEnv::loadString("KEY", "./default")`, `EnvLoader::loadString("KEY", "./default")`), `getenv()`, or `process.env`.
    - Fallback defaults must strictly be relative to the project root or current working directory and only used when the `.env` variable is unset.
2. **Environment-Driven System Roots**:
    - Use `$HOME`, `$CXVM_DIR`, `$CEX_HOME`, `$XDG_DATA_HOME`, or standard platform locations (`%USERPROFILE%`, `$env:USERPROFILE`).
    - Shell scripts: resolve script directory dynamically via `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`.
    - PowerShell scripts: resolve dynamically via `$PSScriptRoot`.
    - Batch scripts: resolve dynamically via `%~dp0`.
3. **Cex Source Resolution**:
    - Load runtime configurable paths from `.env` (`import "@cex-env/src/env_loader.cex";`).
    - Never embed specific developer home directory strings inside committed assets.
4. **Verification Command**:
    ```bash
    grep -rn "/home/[a-zA-Z0-9_-]\+" .agents/ src/ bin/ scripts/ test/ tests/
    ```
