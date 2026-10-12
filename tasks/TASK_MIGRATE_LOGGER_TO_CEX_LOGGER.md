# Automated Task Specification: Migration of Loggers to Cex-Logger in MVC & MVP

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 80 (Root @), Rule 82 (CXVM & Direct CexR) -->

> **CANONICAL LOGGER MIGRATION DIRECTIVE**:
> In all `mvc-lighting`, `mvp-deepsea`, and Cex project workspaces:
> All ad-hoc, unformatted, or manual console print loggers must be unified and migrated to **`cex-logger`** (powered by `@cex-log` / `@cex-logger`), declaring `"cex-logger": "1.0.0"` in `cex-pack.json`'s `"dependencies"`, bridging `src/log.cex` to `@cex-logger`, and updating HTTP request logging to `CexLogger::info(...)`.

---

## 1. Task Objective & Architectural Rationale

1. **Standardized High-Resolution Logging**:
    - Replaces unstructured `print("  [Lighting MVC Logger] "); print(req->method); ...` with structured `CexLogger::info(...)`.
    - Leverages high-resolution nanosecond timestamps, latency profiling (`Stopwatch`), and formatted delay strings.
2. **Package Manifest Synchronization**:
    - Ensures `"cex-logger": "1.0.0"` is declared in the `"dependencies"` map of `cex-pack.json`.
3. **Modular Box Alias Discovery**:
    - Links `.cex_boxes/cex-logger` to `.cex_boxes/cex-log` so `BoxAliasResolver` automatically binds `@cex-logger` at runtime.
4. **Unified Logging API**:
    - `CexLogger::info(msg)`
    - `CexLogger::debug(msg)`
    - `CexLogger::warn(msg)`
    - `CexLogger::error(msg)`
    - `CexLogger::start(label)`
    - `CexLogger::delayWithStatus(label, durationMs, statusCode)`

---

## 2. Automated Task Runner: `migrate_logger_to_cex_logger.cex`

The task is implemented as a standalone, native `v8 cexr` task script:

- **Location**: [`tasks/migrate_logger_to_cex_logger.cex`](file:///home/viettd/Projects/tasks/migrate_logger_to_cex_logger.cex)
- **Engine**: Pure Cex native execution via `cexr` (no `run` subcommand).

### Task Operations:

- Traverses the directory tree to find all project `cex-pack.json` manifests.
- Audits the `"dependencies"` block: identifies if `"cex-logger"` is registered; adds it if missing.
- Verifies `.cex_boxes/cex-logger` link.
- Audits `src/log.cex`: ensures `@cex-logger` bridge import.
- Audits `src/middleware.cex`: upgrades `runLogger` implementation to `CexLogger::info`.
- Supports dry-run audit mode and automated `--fix` application mode.

---

## 3. CLI Invocations & Multi-Queue Scheduling

### Standalone CLI Execution:

```bash
# 1. Audit / Dry-Run Mode
cexr tasks/migrate_logger_to_cex_logger.cex --path .

# 2. Automated Apply / Fix Mode
cexr tasks/migrate_logger_to_cex_logger.cex --path . --fix
```

### Multi-Queue Scheduling via `cex-racer`:

```bash
# Schedule on default queue
cxvm racer run "cexr tasks/migrate_logger_to_cex_logger.cex --path . --fix" --queue default
```
