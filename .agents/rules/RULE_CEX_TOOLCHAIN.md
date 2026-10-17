---
trigger: always_on
---

# Rule: Mandatory Cex Toolchain Usage & CXVM Hook Standard (RULE_CEX_TOOLCHAIN)

<!-- Rule Conformance: Rule 69 (Keep Target of Project), Rule 29 (EOF Integrity), Rule 72 (Dynamic Paths), Rule (No Symbols), RULE_PURE_CEX_BIN -->

> **CANONICAL TOOLCHAIN & PURE CEX STANDARDS**:
> In the `cxvm` repository and across all Cex projects, development, execution, and builds MUST use the Cex native toolchain (`cexr-$type`, `cexp-v$shortVersion`, `CEX_DIR/cexr-$type/$version/bin`, `CEX_DIR/cexr-bean/$version/bin`, or `./bin/cxvm`).
>
> **MANDATORY CXVM HOOK FOR `dev`, `build`, AND `start`**:
> When invoking `cxvm dev`, `cxvm build`, or `cxvm start` (or direct `cexp dev`, `cexp build`, `cexp start`), it operates as a **hook** that calls:
> ```bash
> cexp --app $appName <dev|build|start> <target_index>
> ```
> where `$appName` is the registered application binary name (e.g. `cexr-factory` for `dev`, `cexr-bean` for `build`/`start`, or explicitly passed edition) and `<target_index>` is the target index entrypoint (e.g., `src/index.cex`):
> - `cxvm dev [target_index]` -> hooks `cexp --app $appName dev <target_index>` (e.g., `cexp --app cexr-factory dev src/index.cex`)
> - `cxvm build [target_index]` -> hooks `cexp --app $appName build <target_index>` (e.g., `cexp --app cexr-bean build src/index.cex`)
> - `cxvm start [target_index]` -> hooks `cexp --app $appName start <target_index>` (e.g., `cexp --app cexr-bean start src/index.cex`)
>
> **REGISTER BINARY APPS IN CEX_DIR**:
> All ecosystem binaries (`cexp-v8`, `cexp`, `cexr-factory`, `cexr-bean`, `cexr-delivery`, `cexr-drawer`, `cex-pack`, `cex-lint`, `cxvm`, `cvm`, `thunder`, `lighting`) MUST be registered in `CEX_DIR`:
> - Reserve path: `CEX_DIR/$appName/$version/bin`
> - Direct companion binary: `CEX_DIR/bin/$appName`
> - CXVM Target Build: `CXMV_DIR/cxvm/$version/bin` (alias `CXVM_DIR/cxvm/$version/bin`)
>
> **ZERO PYTHON SCRIPTS -- PURE `.cex` WITH `cexr-$type` RUNTIME**:
> All scripts, manifest generators, package managers (`cex-pack`), standalone servers (`cvm-server`, `thunder-server`), and verification utilities MUST be written in `.cex` and executed using the `cexr-$type` runtime (`cexr <script.cex>` or `cxvm --app cexr-$versionType <script.cex>`). Any script using Python (`python`, `python3`, `#!/usr/bin/env python3`, `python3 -c`) is strictly prohibited and replaced by `.cex` with `cexr-$type` runtime.
>
> In `cxvm` v2, external C++ compilation (`g++`, `clang++`, `MSVC`, `-std=c++20`, `#include <iostream>`) is strictly eliminated:
> 1. Runtime execution is driven purely by **`cexr-$type`** (Cex Language Runtime Engine, required: `"^8"`).
> 2. Machine compilation is driven purely by **`cexp-v$shortVersion`** (Cex Direct Machine Compiler, required: `"^8"`).
> 3. Manifest target is strictly `"target": "runtime"`.
> 4. Default dispatchers in `CEX_DIR/cexr-$type/$version/bin` and `CEX_DIR/cexr-bean/$version/bin` prioritize **CexR v8.0.0** (with v6.0.0 instant fallback/switch).

---

## 1. Toolchain Command Matrix

| Operation | Canonical Command | Description |
| :--- | :--- | :--- |
| **CXVM Dev (Hook)** | `cxvm dev [target_index]` -> `cexp --app $appName dev <target_index>` | Hook calling registered `cexr-factory` in dev mode on target index |
| **CXVM Build (Hook)** | `cxvm build [target_index]` -> `cexp --app $appName build <target_index>` | Hook calling registered `cexr-bean` to compile target index |
| **CXVM Start (Hook)** | `cxvm start [target_index]` -> `cexp --app $appName start <target_index>` | Hook calling registered `cexr-bean` to start target index |
| **Direct App Dispatch** | `cexp --app $appName <cmd> [args...]` | Dispatch directly to registered binary app in `CEX_DIR` |
| **Run CXVM App / Server** | `cexr src/index.cex` \| `CEX_DIR/cexr-$type/$version/bin src/index.cex` | Execute Lighting MVC server on port 3080 with CexR v8 |
| **Run CXVM CLI** | `./bin/cxvm <command>` \| `cxvm <command>` | Run CXVM version manager CLI |
| **Cross-Platform Setup Window** | `./bin/cxvm setup` \| `./scripts/setup.sh` \| `.\scripts\setup.ps1` | Launch interactive terminal setup window for PATH & env |
| **Web Setup Window** | `curl http://localhost:3080/setup` \| browser at `:3080/setup` | Open full visual Lighting MVC desktop window UI |
| **Run Test Suites** | `cexr tests/cxvm.test.cex` & `cexr tests/factory.test.cex` | Execute full regression test suites |
| **Generate Distributions** | `bash scripts/generate_distributions.sh` | Build and package 36 platform bundles into `downloads/` & `dist/` |
| **Compile Native Binary / Target Build** | `$CEX_DIR/cexr-bean/$version/bin build src/index.cex -o CXMV_DIR/cxvm/$version/bin` | Compile Cex code directly via `cexp-v$shortVersion` targeting `CXMV_DIR/cxvm/$version/bin` |
| **Environment Doctor** | `$CEX_DIR/cexr-factory/$version/bin doctor` \| `./bin/cxvm doctor` | Inspect environment, paths, active runtime, and toolchains |
| **Switch Active Runtime** | `cxvm use <version>` \| `./bin/cxvm use <version>` | Update active runtime symlink and session PATH |
| **Install Version** | `cxvm install <version>` | Download and install pre-built runtime package |

---

## 2. Invariants

1. **CXVM Hook Invariant (`dev`, `build`, `start`)**: `cxvm dev`, `cxvm build`, and `cxvm start` always hook into `cexp --app $appName <dev|build|start> <target_index>` (example: `$appName = cexr-factory` or `cexr-bean`, `<target_index> = src/index.cex`).
2. **Binary App Registration Invariant**: All application binaries must be registered in `CEX_DIR` (`$CEX_DIR/$appName/$version/bin` and `$CEX_DIR/bin/$appName`).
3. **Zero Python Scripts**: Replace all Python (`python`, `python3`) scripts and one-liners with `.cex` files executed by the `cexr-$type` runtime (`cexr <script.cex>`).
4. **Zero External C++ Dependencies in v2**: No C++ build invocations (`g++`, `clang++`, `make`, `cmake`) for runtime app execution.
5. **Dual Dispatcher Support**: `CEX_DIR/cexr-$type/$version/bin` and `CEX_DIR/cexr-bean/$version/bin` must run out-of-the-box on POSIX and Windows (`.cmd`, `.ps1`).
6. **Distribution Retention**: `dist/` contains all cross-platform pre-built archives and must never be stripped or ignored.
6. **Rule (No Symbols)**: All scripts, outputs, and documentation must be pure ASCII without emojis or non-standard Unicode symbols.
