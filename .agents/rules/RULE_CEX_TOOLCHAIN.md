---
trigger: always_on
---

# Rule: Mandatory Cex Toolchain Usage (RULE_CEX_TOOLCHAIN)

<!-- Rule Conformance: Rule 69 (Keep Target of Project), Rule 29 (EOF Integrity), Rule 72 (Dynamic Paths), Rule (No Symbols) -->

> **CANONICAL TOOLCHAIN & PURE CEX STANDARDS**:
> In the `cxvm` repository and across all Cex projects, development, execution, and builds MUST use the Cex native toolchain (`cexr`, `cexp`, `./bin/cexr`, `./bin/cex`, or `./bin/cxvm`).
>
> In `cxvm` v2, external C++ compilation (`g++`, `clang++`, `MSVC`, `-std=c++20`, `#include <iostream>`) is strictly eliminated:
> 1. Runtime execution is driven purely by **`cexr`** (Cex Language Runtime Engine, required: `"^8"`).
> 2. Machine compilation is driven purely by **`cexp`** (Cex Direct Machine Compiler, required: `"^8"`).
> 3. Manifest target is strictly `"target": "runtime"`.
> 4. Default dispatchers in `./bin/cexr` and `./bin/cex` prioritize **CexR v8.0.0** (with v6.0.0 instant fallback/switch).

---

## 1. Toolchain Command Matrix

| Operation | Canonical Command | Description |
| :--- | :--- | :--- |
| **Run CXVM App / Server** | `cexr run src/index.cex` \| `./bin/cexr run src/index.cex` | Execute Lighting MVC server on port 3080 with CexR v8 |
| **Run CXVM CLI** | `./bin/cxvm <command>` \| `cxvm <command>` | Run CXVM version manager CLI |
| **Cross-Platform Setup Window** | `./bin/cxvm setup` \| `./scripts/setup.sh` \| `.\scripts\setup.ps1` | Launch interactive terminal setup window for PATH & env |
| **Web Setup Window** | `curl http://localhost:3080/setup` \| browser at `:3080/setup` | Open full visual Lighting MVC desktop window UI |
| **Run Test Suites** | `cexr run tests/cxvm.test.cex` & `cexr run tests/factory.test.cex` | Execute full regression test suites |
| **Generate Distributions** | `bash scripts/generate_distributions.sh` | Build and package 36 platform bundles into `downloads/` & `dist/` |
| **Compile Native Binary** | `./bin/cex build src/index.cex -o bin/cxvm-server` | Compile Cex code directly via `cexp` |
| **Environment Doctor** | `./bin/cex doctor` \| `./bin/cxvm doctor` | Inspect environment, paths, active runtime, and toolchains |
| **Switch Active Runtime** | `cxvm use <version>` \| `./bin/cxvm use <version>` | Update active runtime symlink and session PATH |
| **Install Version** | `cxvm install <version>` | Download and install pre-built runtime package |

---

## 2. Invariants

1. **Zero External C++ Dependencies in v2**: No C++ build invocations (`g++`, `clang++`, `make`, `cmake`) for runtime app execution.
2. **Dual Dispatcher Support**: `./bin/cexr` and `./bin/cex` must run out-of-the-box on POSIX and Windows (`.cmd`, `.ps1`).
3. **Distribution Retention**: `dist/` contains all cross-platform pre-built archives and must never be stripped or ignored.
4. **Rule (No Symbols)**: All scripts, outputs, and documentation must be pure ASCII without emojis or non-standard Unicode symbols.
