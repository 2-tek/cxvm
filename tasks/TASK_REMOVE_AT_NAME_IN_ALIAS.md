# Automated Task Specification: Removal of Package (@name) Aliases in cex-pack.json

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 80 (Root @), Rule 82 (CXVM & Direct CexR), RULE_NO_PACKAGE_AT_NAME_IN_ALIAS -->

> **CANONICAL MANIFEST ALIAS PURGE DIRECTIVE**:
> In accordance with **`RULE_NO_PACKAGE_AT_NAME_IN_ALIAS`** and **`RULE_ROOT_DIR_AT_ALIAS`**:
> The `"alias"` section in `cex-pack.json` is reserved exclusively for the current project root (`"@": "."`) and its source directory (`"@/src": "./src"`). All package aliases starting with `@` (e.g. `@cex-cli`, `@cex-lint`, `@mvp-deepsea`, `@cex-sql`, etc.) must be removed from the manifest.

---

## 1. Task Objective & Architectural Rationale

1. **Namespace Isolation**:
    - In CexR v8, the `@` symbol in import statements refers strictly to the project root (`@/src/...`).
    - Declaring package aliases like `@cex-cli` inside the project manifest creates namespace collisions, inconsistent resolutions across sub-packages, and redundant path mappings.
2. **Automated Box Discovery**:
    - Modular packages residing in `.cex_boxes/` are automatically discovered, registered, and resolved by `BoxAliasResolver` and `box_loader.cex`.
    - Explicit package aliases in `cex-pack.json` are completely redundant and bypass native container distribution loading.
3. **Canonical Manifest Standard**:
   Every `cex-pack.json` should conform to:
    ```json
    "alias": {
        "@": ".",
        "@/src": "./src"
    }
    ```

---

## 2. Automated Task Runner: `migrate_remove_at_name_in_alias.cex`

The task is implemented as a standalone, native `v8 cexr` task script:

- **Location**: [`tasks/migrate_remove_at_name_in_alias.cex`](file:///home/viettd/Projects/tasks/migrate_remove_at_name_in_alias.cex)
- **Engine**: Pure Cex native execution via `cexr` (no `run` subcommand).

### Task Operations:

- Traverses the directory tree to find all `cex-pack.json` manifests.
- Reads and parses the JSON manifest.
- Audits the `"alias"` block: identifies any key other than `"@"` and `"@/src"`.
- If `--fix` is passed:
    - Purges all package `@name` keys from the `"alias"` block.
    - Rewrites `cex-pack.json` with clean indentation (preserving format) and Rule 29 trailing newline.
    - Reports all purged aliases and modified files.

---

## 3. CLI Invocations & Multi-Queue Scheduling

### Standalone CLI Execution:

```bash
# 1. Audit / Dry-Run Mode
cexr tasks/migrate_remove_at_name_in_alias.cex --path .

# 2. Automated Apply / Fix Mode
cexr tasks/migrate_remove_at_name_in_alias.cex --path . --fix
```

### Multi-Queue Scheduling via `cex-racer`:

```bash
# Execute immediately on default queue
cxvm racer run "cexr tasks/migrate_remove_at_name_in_alias.cex --path . --fix" --queue default

# Schedule recurring manifest audit task
cxvm racer schedule audit-manifest-aliases --cmd "cexr tasks/migrate_remove_at_name_in_alias.cex --path ." --interval 2h --queue background
```

---

## 4. Verification Test Suite

The task includes an automated test suite verifying manifest cleaning:

```bash
cxvm test tasks/test/remove_at_name_in_alias.test.cex
```
