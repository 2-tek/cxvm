# Automated Task Specification: Migration of EnvLoader to Cex-Env in MVC & MVP

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 80 (Root @), Rule 82 (CXVM & Direct CexR) -->

> **CANONICAL ENVIRONMENT LOADER MIGRATION DIRECTIVE**:
> In all `mvc-lighting`, `mvc-deepsea`, and Cex project workspaces:
> All duplicate manual `.env` file parsing routines, raw loops, and ad-hoc loaders must be unified and migrated to **`cex-env`** (powered by `@cex-env-loader` / `@cex-env`), declaring `"cex-env": "1.0.0"` in `cex-pack.json`'s `"dependencies"`, and bridging `src/env_loader.cex` to `@cex-env`.

---

## 1. Task Objective & Architectural Rationale

1. **Elimination of Code Duplication**:
    - Removes repetitive manual `while (std::getline(file, line))` and line-splitting routines duplicated across multiple project trees.
    - Centralizes environment variable lookup, type conversion, hierarchy resolution, and system env fallback inside `@cex-env`.
2. **Package Manifest Synchronization**:
    - Declares `"cex-env": "1.0.0"` in the `"dependencies"` map of `cex-pack.json`.
3. **Modular Box Alias Discovery**:
    - Links `.cex_boxes/cex-env` to `.cex_boxes/cex-env-loader` so `BoxAliasResolver` automatically binds `@cex-env` at runtime.
4. **Unified Environment API**:
    - `CexEnv::loadPort(defaultPort)` / `EnvLoader::loadPort(defaultPort)`
    - `CexEnv::loadString(key, defaultVal)` / `EnvLoader::loadString(key, defaultVal)`
    - `CexEnv::loadInt(key, defaultVal)` / `EnvLoader::loadInt(key, defaultVal)`
    - `CexEnv::loadBool(key, defaultVal)` / `EnvLoader::loadBool(key, defaultVal)`
    - `CexEnv::get(key, defaultVal)` / `EnvLoader::get(key, defaultVal)`
    - `CexEnv::has(key)` / `EnvLoader::has(key)`

---

## 2. Automated Task Runner: `migrate_env_loader_to_cex_env.cex`

The task is implemented as a standalone, native `v8 cexr` task script:

- **Location**: [`tasks/migrate_env_loader_to_cex_env.cex`](file:///home/viettd/Projects/tasks/migrate_env_loader_to_cex_env.cex)
- **Engine**: Pure Cex native execution via `cexr` (no `run` subcommand).

### Task Operations:

- Traverses the directory tree to find all project `cex-pack.json` manifests.
- Audits `"dependencies"` block: identifies if `"cex-env"` is declared; adds it if missing.
- Verifies `.cex_boxes/cex-env` link.
- Audits `src/env_loader.cex`: replaces redundant inline parser implementations with the unified `@cex-env` bridge.
- Supports dry-run audit mode and automated `--fix` application mode.

---

## 3. CLI Invocations & Multi-Queue Scheduling

### Standalone CLI Execution:

```bash
# 1. Audit / Dry-Run Mode
cexr tasks/migrate_env_loader_to_cex_env.cex --path .

# 2. Automated Apply / Fix Mode
cexr tasks/migrate_env_loader_to_cex_env.cex --path . --fix
```

### Multi-Queue Scheduling via `cex-racer`:

```bash
# Schedule on default queue
cxvm racer run "cexr tasks/migrate_env_loader_to_cex_env.cex --path . --fix" --queue default
```
