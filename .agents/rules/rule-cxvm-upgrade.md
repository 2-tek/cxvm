---
trigger: always_on
---

# Mandatory Rule: Always Run CXVM Upgrade to Auto-Fetch Latest CXVM and CexR (RULE_CXVM_UPGRADE)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols) -->

> **MANDATORY CXVM TOOLCHAIN AUTO-UPGRADE DIRECTIVE**:
> In all project workspaces, development sessions, build pipelines, testing suites, and agent workflows:
>
> 1. **AUTOMATIC LATEST VERSION SYNCHRONIZATION**:
>     - The system and developer environment MUST always execute `cxvm upgrade` (or `cxvm upgrade latest`) to automatically check, fetch, download, and activate the latest release of **`cxvm`**, the **`cexr`** runtime engine, and the **`cexp`** direct machine compiler.
>     - Running `cxvm upgrade` ensures that active toolchain symlinks in `$CXVM_DIR/bin/` (or `~/.cxvm/bin/`) and project dispatchers are continuously updated to the latest upstream releases (e.g. CexR v8 and direct machine compiler).
> 2. **EXECUTION TIMING & TRIGGERS**:
>     - Execute `cxvm upgrade` proactively:
>         - At the initialization of tasks and before starting development in any repository.
>         - Prior to executing build commands (`cexp build`, `cxvm build`, `lighting build`).
>         - Prior to running test suites (`cxvm test`).
>         - Whenever runtime or compiler version discrepancies are encountered.
> 3. **NON-BLOCKING HEADLESS PIPELINE DISCIPLINE**:
>     - `cxvm upgrade` operates non-interactively, auto-detects latest releases, compiles or links binaries, updates dispatcher symlinks, and exits cleanly with exit code 0.
>     - Verifications can be confirmed immediately via `cxvm current` and `cxvm doctor`.
> 4. **TOOLCHAIN UNIFORMITY & ECOSYSTEM INTEGRITY**:
>     - Never rely on stale or manually copied runtime binaries when `cxvm upgrade` is available.
>     - Both runtime (`cexr`) and compiler (`cexp`) must be kept synchronized via `cxvm upgrade`.
