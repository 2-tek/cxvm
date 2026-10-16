---
trigger: always_on
---

# Rule: Cross-Platform CXVM Setup Window & Dispatcher Standards (RULE_CEX_SETUP)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols) -->

> **SETUP WINDOW & RUNTIME DISPATCHER DIRECTIVE**:
> `cxvm` must provide an interactive setup window (both terminal and web-based) that configures environment variables, user shell PATHs, default runtime versions, and project dispatchers across Linux, macOS, and Windows.

---

## 1. Setup Window Specifications

1. **Terminal Setup Window (`cxvm setup`)**:
   - Must be cross-platform: `scripts/setup.sh` (POSIX bash/zsh), `scripts/setup.ps1` (PowerShell Core / Windows PowerShell), and `downloads/setup.cmd` (Windows CMD).
   - Renders an ASCII framed setup window displaying:
     - Header: `2-TEK CXVM Cross-Platform Setup Window`
     - Step 1: Detect Host OS, Architecture, and Shell.
     - Step 2: Initialize `CXVM_DIR` (`~/.cxvm` or `%USERPROFILE%\.cxvm`).
     - Step 3: Configure environment variables (`CXVM_DIR`, `CEX_HOME`, `PATH`).
     - Step 4: Install/link default runtimes: **v8.0.0** (Default) and **v6.0.0** (LTS), setting default `cexr` runtime to **`cexr-factory`** (`factory`) and default build to **`cexr-bean`** (`bean`).
     - Step 5: Verify project `./bin/cexr` and `./bin/cex` dispatchers and run `cexr -v` to display all editions (`cexr-factory`, `cexr-bean`, `cexr-delivery`, `cexr-drawer`, `cexp`, `cex-pack`).
     - Step 6: Run `cxvm doctor` and report readiness.
2. **Web Setup Window (`/setup`)**:
   - Delivered via Lighting Fullstack MVC at route `/setup`.
   - Displays a desktop application window UI with OS titlebar controls (`[RED] [YELLOW] [GREEN]`), platform selection tabs, installer snippets, interactive version selector, `cexr-factory` / `cexr-bean` edition indicators, and live status diagnostics.

---

## 2. Dispatcher Standards (`./bin/cexr` & `./bin/cex`)

1. **Default Version (v8.0.0) & Default Editions (`cexr-factory` & `cexr-bean`)**:
   - `./bin/cexr` and `./bin/cex` default to CexR v8.0.0 (`~/.cxvm/versions/v8.0.0/bin/cexr` or active CexR v8 binary).
   - Default runtime edition (`run`, `dev`, `start`): **`cexr-factory`** (`CEXR_VERSION_TYPE=factory`).
   - Default build edition (`build`, `compile`): **`cexr-bean`** (`CEXR_BUILD_VERSION_TYPE=bean`).
   - Running `cexr -v` displays all integrated editions (`cexr-factory`, `cexr-bean`, `cexr-delivery`, `cexr-drawer`, `cexp`, and `cex-pack`).
2. **Instant Version Switch (v6.0.0)**:
   - Must support direct version invocation: `./bin/cexr v6 <file.cex>` or `./bin/cex v6 run <file.cex>` targeting CexR v6.0.0 without permanently altering global default.
3. **Cross-Platform Companions**:
   - `bin/cexr`, `bin/cex`, `bin/cxvm` (POSIX bash)
   - `bin/cexr.cmd`, `bin/cex.cmd`, `bin/cxvm.cmd` (Windows CMD)
   - `bin/cexr.ps1`, `bin/cex.ps1`, `bin/cxvm.ps1` (Windows PowerShell)
