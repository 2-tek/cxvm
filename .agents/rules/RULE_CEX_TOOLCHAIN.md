---
trigger: always_on
---

# Rule: Mandatory Cex Toolchain Usage & CXVM Hook Standard (RULE_CEX_TOOLCHAIN)

<!-- Rule Conformance: Rule 69 (Keep Target of Project), Rule 29 (EOF Integrity), Rule 72 (Dynamic Paths), Rule (No Symbols), RULE_PURE_CEX_BIN -->

> **CANONICAL TOOLCHAIN & PURE CEX STANDARDS**:
> In the `cxvm` repository and across all Cex projects, development, execution, and builds MUST use the Cex native toolchain (`cexr`, `cexp`, `./bin/cexr`, `./bin/cex`, or `./bin/cxvm`).
>
> **MANDATORY CXVM HOOK FOR `dev`, `build`, AND `start`**:
> When invoking `cxvm dev`, `cxvm build`, or `cxvm start`, it operates as a **hook** that calls:
> ```bash
> cxvm --app cexr $versionType <dev|build|start> <target_index>
> ```
> where `$versionType` is the CexR runtime edition/version type (`example=bean`, or `delivery`, `drawer`, `factory`, `8.0.0`) and `<target_index>` is the target index entrypoint (e.g., `src/index.cex`):
> - `cxvm dev [target_index]` -> hooks `cxvm --app cexr $versionType dev <target_index>` (e.g., `cxvm --app cexr bean dev src/index.cex`)
> - `cxvm build [target_index] [out_bin]` -> hooks `cxvm --app cexr $versionType build <target_index> [out_bin]` (e.g., `cxvm --app cexr bean build src/index.cex`)
> - `cxvm start [target_index]` -> hooks `cxvm --app cexr $versionType start <target_index>` (e.g., `cxvm --app cexr bean start src/index.cex`)
>
> **ZERO PYTHON SCRIPTS -- PURE `.cex` WITH `cexr` RUNTIME**:
> All scripts, manifest generators, package managers (`cex-pack`), standalone servers (`cvm-server`, `thunder-server`), and verification utilities MUST be written in `.cex` and executed using the `cexr` runtime (`cexr <script.cex>` or `cxvm --app cexr $versionType <script.cex>`). Any script using Python (`python`, `python3`, `#!/usr/bin/env python3`, `python3 -c`) is strictly prohibited and replaced by `.cex` with `cexr` runtime.
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
| **CXVM Dev (Hook)** | `cxvm dev [target_index]` -> `cxvm --app cexr $versionType dev <target_index>` | Hook calling `cexr` `$versionType` (e.g. `bean` / `factory`) in dev mode on target index |
| **CXVM Build (Hook)** | `cxvm build [target_index]` -> `cxvm --app cexr $versionType build <target_index>` | Hook calling `cexr` `$versionType` (e.g. `bean`) to compile target index |
| **CXVM Start (Hook)** | `cxvm start [target_index]` -> `cxvm --app cexr $versionType start <target_index>` | Hook calling `cexr` `$versionType` (e.g. `bean`) to start target index |
| **Direct App Dispatch** | `cxvm --app cexr $versionType <cmd> <target_index>` | Dispatch directly to `cexr` `$versionType` (`bean`, `delivery`, `drawer`, `factory`) |
| **Run CXVM App / Server** | `cexr src/index.cex` \| `./bin/cexr src/index.cex` | Execute Lighting MVC server on port 3080 with CexR v8 |
| **Run CXVM CLI** | `./bin/cxvm <command>` \| `cxvm <command>` | Run CXVM version manager CLI |
| **Cross-Platform Setup Window** | `./bin/cxvm setup` \| `./scripts/setup.sh` \| `.\scripts\setup.ps1` | Launch interactive terminal setup window for PATH & env |
| **Web Setup Window** | `curl http://localhost:3080/setup` \| browser at `:3080/setup` | Open full visual Lighting MVC desktop window UI |
| **Run Test Suites** | `cexr tests/cxvm.test.cex` & `cexr tests/factory.test.cex` | Execute full regression test suites |
| **Generate Distributions** | `bash scripts/generate_distributions.sh` | Build and package 36 platform bundles into `downloads/` & `dist/` |
| **Compile Native Binary** | `./bin/cex build src/index.cex -o bin/cxvm-server` | Compile Cex code directly via `cexp` |
| **Environment Doctor** | `./bin/cex doctor` \| `./bin/cxvm doctor` | Inspect environment, paths, active runtime, and toolchains |
| **Switch Active Runtime** | `cxvm use <version>` \| `./bin/cxvm use <version>` | Update active runtime symlink and session PATH |
| **Install Version** | `cxvm install <version>` | Download and install pre-built runtime package |

---

## 2. Invariants

1. **CXVM Hook Invariant (`dev`, `build`, `start`)**: `cxvm dev`, `cxvm build`, and `cxvm start` always hook into `cxvm --app cexr $versionType <dev|build|start> <target_index>` (example: `$versionType = bean`, `<target_index> = src/index.cex`).
2. **Zero Python Scripts**: Replace all Python (`python`, `python3`) scripts and one-liners with `.cex` files executed by the `cexr` runtime (`cexr <file.cex>`).
3. **Zero External C++ Dependencies in v2**: No C++ build invocations (`g++`, `clang++`, `make`, `cmake`) for runtime app execution.
4. **Dual Dispatcher Support**: `./bin/cexr` and `./bin/cex` must run out-of-the-box on POSIX and Windows (`.cmd`, `.ps1`).
5. **Distribution Retention**: `dist/` contains all cross-platform pre-built archives and must never be stripped or ignored.
6. **Rule (No Symbols)**: All scripts, outputs, and documentation must be pure ASCII without emojis or non-standard Unicode symbols.
