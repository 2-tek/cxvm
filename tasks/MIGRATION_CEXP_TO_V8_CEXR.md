# Migration Task Suite: Migrating Codebases from CexP to CexR v8 Syntax & Toolchain

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 81 (Native Syntax), Rule 82 (CXVM & Direct CexR), Rule 83 (Import cpp/c Replace #include), Rule 84 (No C++ in v8), RULE_AGENTS_MVC_MVP_V8_CEXR_TASKS -->

> **CANONICAL MIGRATION DIRECTIVE**:
> This task suite defines the systematic, automated procedure to migrate all repositories, agent workflows, manifests, and `.cex` source files from legacy `cexp` compiler patterns to the unified **`CexR v8`** runtime engine and architecture standard.

---

## 1. Executive Summary & Rationale

| Dimension | Legacy CexP Standard | Canonical CexR v8 Standard | Migration Action |
| :--- | :--- | :--- | :--- |
| **Runtime Engine** | Direct `cexp` / `cexp v3` compiler invocations | Unified `v8 cexr` with native GC & JIT tiering | Replace `cexp` invocations with `cexr` |
| **Command Syntax** | `cexr run <file.cex>` / `cexp run <file.cex>` | `cexr <file.cex>` (**NO `run` SUBCOMMAND**) | Strip `run` subcommand across all commands |
| **Test Execution** | `./bin/cexr <test.cex>` or `cexr test/...` | `cxvm test <test.cex>` or `cxvm test` | Use `cxvm test` exclusively |
| **Compiler Flags** | `"cFlags": ["-std=c++20", "-O3", ...]` in manifest | Native compiler built-ins (automatic C++20 `-O3`) | Remove `"cFlags"` from `cex-pack.json` |
| **Header Inclusions**| Raw `#include <...>` or `#include "..."` | Rule 83 `import "cpp/..."` and `import "c/..."` | Migrate to standard Cex `import` syntax |
| **Class Inheritance**| C++ syntax `class Child : public Parent` | Rule 81/82 `class Child extends Parent` | Replace `: public` with `extends` |
| **v8 Directory Rule**| Mixed `.cpp` / `.hpp` source files | Rule 84 pure `.cex` only (zero `.cpp`/`.hpp`) | Rewrite to pure `.cex` using Rule 83 imports |
| **Agent Architecture**| Ad-hoc scripts and loose tasks | Strict **MVC** or **MVP** with `v8 cexr` tasks | Conform to `RULE_AGENTS_MVC_MVP_V8_CEXR_TASKS` |

---

## 2. Migration Task Matrix & Detailed Work Breakdown

### Task 1: Toolchain CLI Command Migration (`cexp` -> `cexr`)
- **Objective**: Eliminate legacy `cexp` script invocations and deprecate the `run` subcommand.
- **Rules Enforced**: `RULE_CEX_TOOLCHAIN`, `RULE_ANTIGRAVITY_DAEMON_ON_EDIT_CEX`.
- **Search Patterns**:
  - `cexp run ` -> `cexr `
  - `cexp build ` -> `cxvm build ` (or `lighting build `)
  - `cexr run ` -> `cexr `
  - `./bin/cexr run ` -> `cexr `
- **Validation**:
  - Run `grep -rn "cexr run " .` -> 0 matches.
  - Run `grep -rn "cexp run " .` -> 0 matches.

### Task 2: Automated Test Execution Migration (`cxvm test`)
- **Objective**: Standardize all verification workflows through `cxvm test`.
- **Rules Enforced**: `RULE_CEX_TOOLCHAIN` Section 2.
- **Search Patterns**:
  - `./bin/cexr test/` -> `cxvm test test/`
  - `./bin/cexr <path>.test.cex` -> `cxvm test <path>.test.cex`
  - `cexr test/` -> `cxvm test test/`
- **Validation**:
  - All CI/CD scripts and test suites execute via `cxvm test`.

### Task 3: Package Manifest (`cex-pack.json`) Deprecation & Upgrade
- **Objective**: Cleanse `cex-pack.json` manifests of deprecated compiler flags and pin v8 runtime.
- **Rules Enforced**: `RULE_CEX_TOOLCHAIN` Section 5.
- **Actions**:
  - Remove `"cFlags": [...]` block entirely from all `cex-pack.json` files.
  - Update required dependencies:
    ```json
    "required": {
        "cexr": ">= v8",
        "cxvm": ">= v1"
    }
    ```
  - Ensure `"target": "runtime"`.
- **Validation**:
  - `grep -rn "\"cFlags\"" .` -> 0 matches.

### Task 4: Module Import Modernization (Rule 83 Standard)
- **Objective**: Eliminate raw C/C++ preprocessor `#include` directives in `.cex` source files.
- **Rules Enforced**: `RULE_IMPORT_CPP_C_REPLACE_INCLUDE` (Rule 83).
- **Transformations**:
  - `#include <iostream>` -> `import "cpp/iostream";`
  - `#include <vector>` -> `import "cpp/vector";`
  - `#include <string>` -> `import "cpp/string";`
  - `#include <algorithm>` -> `import "cpp/algorithm";`
  - `#include <chrono>` -> `import "cpp/chrono";`
  - `#include <unistd.h>` -> `import "c/unistd.h";`
  - `#include <stdio.h>` -> `import "c/stdio.h";`
  - `#include <sys/socket.h>` -> `import "c/sys/socket.h";`
  - `#include <arpa/inet.h>` -> `import "c/arpa/inet.h";`
- **Validation**:
  - `cex-lint` rule `no-raw-include` passes with 0 diagnostics.

### Task 5: Preprocessor & Define Directives Migration
- **Objective**: Standardize macro and constant declarations with native `CexR v8` syntax.
- **Rules Enforced**: CexR v8 Allow Define standard.
- **Transformations**:
  - C-style `#define CONSTANT value` -> native Cex `#define` or `define CONSTANT value`.
  - Ensure macros with parameters use `#define MACRO(a, b) ((a) * (b))`.

### Task 6: Object-Oriented Syntax Migration (`extends` & `this->`)
- **Objective**: Enforce modern Cex OOP semantics and eliminate raw C++ syntax in `.cex` files.
- **Rules Enforced**: `Rule 81` (Native Engine Syntax), `Rule 82` (Public by Extends).
- **Transformations**:
  - `class Derived : public Base` -> `class Derived extends Base`
  - `class Derived : public IView` -> `class Derived extends IView`
  - Ensure all member accesses inside class methods use `this->` prefix.
  - Ensure engine contexts use `ctx->view` rather than `ctx::view`.

### Task 7: Architecture Alignment (Strict MVC or MVP)
- **Objective**: Structure code and agent tasks into MVC (`MVC-Lighting`) or MVP (`MVP-DeepSea`).
- **Rules Enforced**: `RULE_AGENTS_MVC_MVP_V8_CEXR_TASKS`.
- **Requirements**:
  - Web & SSR applications conform to **MVC**: Models (`src/models/`), Views (`src/views/`), Controllers (`src/controllers/`).
  - Microservices & REST APIs conform to **MVP**: Models (`src/models/`), Passive Views (`src/views/`), Presenters (`src/presenters/`).

### Task 8: Task Dispatch via `cex-racer` / `cxvm racer`
- **Objective**: Automate the execution of migration tasks as managed background queues.
- **Commands**:
  ```bash
  # Execute migration task on default queue
  cxvm racer run "cexr tasks/migrate_cexp_to_v8_cexr.cex" --queue default

  # Schedule recurring audit task every 1 hour
  cxvm racer schedule cexp-migration-audit --cmd "cexr tasks/migrate_cexp_to_v8_cexr.cex" --interval 1h --queue background
  ```

---

## 3. Automated Migration Script Usage

The native `v8 cexr` task runner script is provided at `tasks/migrate_cexp_to_v8_cexr.cex`:

```bash
# 1. Audit / Dry-Run Mode (scans and reports all legacy patterns)
cexr tasks/migrate_cexp_to_v8_cexr.cex --path .

# 2. Automated Apply / Fix Mode (migrates files in-place)
cexr tasks/migrate_cexp_to_v8_cexr.cex --path . --fix

# 3. Verify Migration via CXVM Test Suite
cxvm test tasks/test/migration_task.test.cex
```
