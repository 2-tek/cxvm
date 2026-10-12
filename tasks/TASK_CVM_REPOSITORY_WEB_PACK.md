# Automated Task Specification: CVM Repository & Multi-Manifest Routing in cex-pack

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 80 (Root @), Rule 82 (CXVM & Direct CexR), RULE_CVM_REPOSITORY_IN_CEX_PACK -->

> **CANONICAL CVM REPOSITORY & MANIFEST ROUTING DIRECTIVE**:
> In accordance with **`RULE_CVM_REPOSITORY_IN_CEX_PACK`**:
> Projects may declare `"cvm_repository"` inside `cex-pack.json` with an optional `"path"` pointing to an alternate manifest (such as `web-pack.json`). This enables streamlined multi-manifest dependency downloads, staging, commits, and pushes directly through CodeVersionManager (`cvm`) and `cex-pack`.

---

## 1. Task Objective & Architectural Rationale

1. **Dual / Multi-Manifest Architecture**:
    - Modern fullstack Cex applications often separate server/backend runtime configurations (`cex-pack.json`) from client-side / Virtual DOM bundle manifests (`web-pack.json`).
    - By declaring `"path": "web-pack.json"` inside `"cvm_repository"`, tools and background agents can seamlessly recognize, validate, and synchronize both package definitions without duplicating repositories.
2. **Streamlined CVM Operations**:
    - **Download**: `cex-pack downloads --path web-pack.json` resolves and installs web dependencies into `.cex_boxes/`. Running `cex-pack downloads` automatically discovers and resolves dependencies from both `cex-pack.json` and `web-pack.json` if configured.
    - **Commit**: `cex-pack commit -m "<message>" --path web-pack.json` stages the specific manifest and records changes in CVM.
    - **Push**: `cex-pack push --path web-pack.json` syncs commits to the designated CVM repository URL.
3. **Security & Boundary Enforcement**:
    - The manifest path must stay within the project root directory. Path traversals (`..`) are strictly rejected with `RULE_CVM_REPO_PATH_TRAVERSAL`.

---

## 2. Manifest Schema Specification

Inside `cex-pack.json`:

```json
{
    "name": "@2tek/my-application",
    "version": "1.0.0",
    "main": "src/index.cex",
    "target": "runtime",
    "cvm_repository": {
        "type": "cvm",
        "url": "cvm://localhost:3110/repo/my-application",
        "path": "web-pack.json",
        "branch": "main"
    },
    "dependencies": {
        "cex-cli": "1.0.0"
    }
}
```

Or string URL shorthand:

```json
"cvm_repository": "cvm://localhost:3110/repo/my-application"
```

---

## 3. Automated Task Runner: `task_cvm_repository_web_pack.cex`

The task is implemented as a standalone, native `v8 cexr` task script:

- **Location**: [`tasks/task_cvm_repository_web_pack.cex`](file:///home/viettd/Projects/tasks/task_cvm_repository_web_pack.cex)
- **Engine**: Pure Cex native execution via `cexr` (no `run` subcommand).

### CLI Invocations:

```bash
# 1. Audit / Read-Only Mode (scans for cvm_repository configuration)
cexr tasks/task_cvm_repository_web_pack.cex --path . --check

# 2. Automated Apply / Configure Mode (configures cvm_repository pointing to web-pack.json)
cexr tasks/task_cvm_repository_web_pack.cex --path . --fix

# 3. Custom Manifest Target Name
cexr tasks/task_cvm_repository_web_pack.cex --path . --custom client-pack.json --fix
```

---

## 4. Test Suite Verification

Run the automated test suite via `cxvm`:

```bash
cxvm test tasks/test/cvm_repository_web_pack.test.cex
```

All testcases verify:

- Package name slug normalization.
- Detection of missing, string-based, and object-based `cvm_repository`.
- Custom manifest path resolution (`web-pack.json`).
- Path traversal detection and rejection (`RULE_CVM_REPO_PATH_TRAVERSAL`).
- Clean injection and formatting preservation.
