# Software Specification Report (SSR): Migrate with Last MVC-Lighting Version & Delete Deprecated Imports

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), Rule 44 (Explicit Types), RULE_BUILD_POSITION, RULE_NO_SYMLINK_BETWEEN_BOXES, RULE_NO_HARD_EDIT_TO_CODE -->

## 1. Objective

Complete the migration of CXVM with the latest version of the **MVC-Lighting** framework (version `6.1.10`, tag `v6.1.10`), register it into the CXVM dependency matrix and package catalog, and purge all remaining deprecated imports and packages across the repository:
1. **Migrate to Last `mvc-lighting` Version (`6.1.10`)**:
   - Update `cex-pack.json` to register `"mvc-lighting": "6.1.10"` under `dependencies`.
   - Update `src/cxvm_engine.cex` and `setup.cex` to dynamically resolve `mvc-lighting` and `lighting` to version `6.1.10`.
   - Synchronize `cex_boxes/mvc-lighting` with the latest v6.1.10 package assets from `projects/mvc-lighting` as a real, self-contained box directory without symlinks (conforming to `RULE_NO_SYMLINK_BETWEEN_BOXES`).
2. **Purge Deprecated Imports & Packages**:
   - Eliminate obsolete `@cex-service` from `dependencies` in `cex-pack.json` and from `setupDeps()` in `src/cxvm_engine.cex` and `setup.cex`.
   - Remove legacy `cex_boxes/cex-service` directory.
   - Refactor test files (`tests/install.test.cex`, `tests/scripts.test.cex`) that used deprecated `import "@cex-test/src/assert.cex"` and `import "@cex-test/src/runner.cex"` to canonical `@cext` imports (`import "@cext/src/assert.cex"`, `import "@cext/src/runner.cex"`).
   - Ensure zero deprecated `@cex-service` or `@cex-test` imports remain in active production and test code.

- **Timestamp**: 2026-10-30T12:10:00+07:00
- **Scope**: `cxvm` (`cex-pack.json`, `src/cxvm_engine.cex`, `setup.cex`, `cex_boxes/`, `tests/`)
- **Target Framework**: `mvc-lighting` v6.1.10 (latest stable release)

---

## 2. Requirements & Scope

1. **Package Manifest Dependency Upgrade**:
   - In `cex-pack.json`:
     - Add `"mvc-lighting": "6.1.10"` to `dependencies`.
     - Remove deprecated `"cex-service": "2.0.0"`.
2. **Engine Version Resolution**:
   - In `src/cxvm_engine.cex`:
     - In `resolveLibVersion(libName)`: Return `"6.1.10"` when `libName == "mvc-lighting" || libName == "lighting"`.
     - In `setupDeps()`: Add `libs->push("mvc-lighting")`, remove `libs->push("cex-service")`.
     - Extend candidate path scanning to include sibling `projects/` repositories (`home + "/Projects/cex/projects/" + lib` and `curPwd + "/../projects/" + lib`).
3. **Environment Setup Runner Sync**:
   - In `setup.cex`:
     - In `resolveVersion(libName)`: Support `mvc-lighting` returning `"6.1.10"`.
     - In `setupDeps()`: Replace `cex-service` with `mvc-lighting`.
4. **Box Store Cleanliness & Isolation**:
   - Conforming to `RULE_NO_SYMLINK_BETWEEN_BOXES`: Ensure `cxvm/cex_boxes/mvc-lighting` contains real files with `cex-pack.json` declaring `version: "6.1.10"`.
   - Remove `cxvm/cex_boxes/cex-service`.
5. **Deprecated Import Elimination**:
   - Replace `@cex-test/src/assert.cex` and `@cex-test/src/runner.cex` in `tests/install.test.cex` and `tests/scripts.test.cex` with canonical `@cext/src/assert.cex` and `@cext/src/runner.cex`.
   - Verify zero occurrences of `@cex-service` in all source and test imports.
6. **Zero Regression Test Verification**:
   - 100% test pass rate across all suites via `cext`.
   - Clean binary compilation with `cexp-v8-stable build src/index.cex -o .bin`.

---

## 3. Architectural Impact & Technical Design

### Ecosystem Component Diagram:
```
+-------------------------------------------------------------+
| cxvm (2-TEK Fullstack Cross-Platform Cex Distribution Engine)|
| - Package Manifest: cex-pack.json                           |
|   ├── dependencies: mvc-lighting: 6.1.10 (DEPRECATED: cex-s)|
|   └── test: cext tests/install.test.cex                     |
+-------------------------------------------------------------+
          |                                  |
          | (resolveLibVersion)              | (import @cext/...)
          v                                  v
+------------------------------------+  +------------------------------------+
| CxvmEngine (src/cxvm_engine.cex)   |  | Canonical Test Harness             |
| - resolveLibVersion("mvc-lighting")|  | (@cext/src/assert.cex)             |
|   -> returns "6.1.10"              |  | - eliminates @cex-test imports     |
| - setupDeps()                      |  | - unified test execution           |
|   -> pulls mvc-lighting 6.1.10     |  +------------------------------------+
+------------------------------------+
          |
          v
+-------------------------------------------------------------+
| cex_boxes/mvc-lighting (Real self-contained box, no symlink) |
| - version: 6.1.10                                           |
| - framework: page_renderer, template_engine, xhtml router   |
+-------------------------------------------------------------+
```

---

## 4. Invariants & Rules

1. **`RULE_BUILD_POSITION`**: No outputs in `dist/` or `tmp/`; outputs must use `.bin` or designated box locations.
2. **`RULE_NO_SYMLINK_BETWEEN_BOXES`**: Packages inside `cex_boxes/` must be isolated real directories, never symlinks.
3. **`Rule 44 (Explicit Types)`**: Every variable declaration must specify explicit types (`string`, `int`, `bool`, etc.), no auto/var.
4. **`Rule 29 (EOF newline)`**: Every file must conclude with exactly one newline.
5. **`Rule 72 (Dynamic Paths)`**: No hardcoded absolute home paths; use dynamic environment variables or relative paths.
