# 2-TEK cxvm: Cross-Platform Cex Distribution Engine & Runtime Version Manager Specification

<!-- Standard Specification: .agents/PRODUCT_TARGET.md -->
<!-- Rule Conformance: Rule 69 (Keep Target of Project), Rule 29 (EOF Integrity), Rule 72 (Dynamic Paths), Rule (No Symbols) -->

> **Canonical Target of cxvm (`@2tek/cxvm`)**:
> **`cxvm` is the canonical cross-platform Cex distribution builder and runtime version manager engine, powered natively by Lighting Fullstack MVC.**
> **Toolchain Standard**: Pure Cex Native Engine (`cexr` runtime engine + `cexp` direct machine compiler; zero C++ toolchain dependency).
> **Target Definition**: `"target": "runtime"` in `cex-pack.json`.
> **Distribution Standard (Rule 69)**: In CexR v8 of `.cex_boxes`; when loaded, dependencies load from the dist file of `.cex_boxes/{dependencyName}` to runtime, with `cex-pack.json`. If target is runtime, do not use `.gitignore` for dist bundle file. **Always keep `dist/` containing all cross-platform distribution downloads of cxvm.**

---

## 1. High-Level Vision & Scope

The `cxvm` repository defines the official distribution hub and version management infrastructure for the entire 2-TEK Cex ecosystem:

1. **Pure Cex Native Engine (v2 Standard)**:
   - Eliminates all external C++ compiler dependencies (`g++`, `clang++`, `MSVC`, `-std=c++20`, `#include <iostream>`).
   - Powered purely by **`cexr`** (Cex Language Runtime Engine) and **`cexp`** (Cex Direct Machine Compiler).
   - Package manifest strictly requires:
     ```json
     "target": "runtime",
     "required": {
       "cexr": "^8",
       "cexp": "^8"
     }
     ```

2. **Cross-Platform Distribution Builder (`DistBuilder`)**:
   - Manages and generates **36 native distribution bundles** (6 release versions across 6 target platforms) into both **`downloads/`** and **`dist/`**.
   - Maintains full cross-platform compatibility:
     - **Linux x86_64** (`.tar.gz`, `x86_64-unknown-linux-gnu`)
     - **Linux aarch64** (`.tar.gz`, `aarch64-unknown-linux-gnu`)
     - **macOS Apple Silicon** (`.tar.gz`, `aarch64-apple-darwin`)
     - **macOS Intel 64-bit** (`.tar.gz`, `x86_64-apple-darwin`)
     - **Windows x64** (`.zip`, `x86_64-pc-windows-msvc`)
     - **Windows ARM64** (`.zip`, `aarch64-pc-windows-msvc`)
   - Pre-computed `SHA256SUMS` verification hashes and auto-generated `manifest.json`.

3. **Cex Version Manager (`cxvm`) CLI (like `nvm`)**:
   - Standalone multi-platform management CLI (`cxvm` for POSIX bash, `cxvm.ps1` for Windows PowerShell, and `cxvm.cmd` for Windows Command Prompt).
   - Manages runtime installations into `~/.cxvm/versions/v<version>`, creates symlinks to `~/.cxvm/current`, and manages the active `cexr` binary runner.
   - Core commands:
     - `cxvm setup`: Cross-platform interactive setup window configuring environment, PATH, and `./bin/` dispatchers.
     - `cxvm install <ver>`: Installs target version package into `~/.cxvm/versions/`.
     - `cxvm download <ver> [plat|all]`: Downloads bundles into cache for offline setup.
     - `cxvm use <ver>`: Switches active runtime and updates PATH in the current session.
     - `cxvm list` / `cxvm current` / `cxvm default <ver>`: Inspects and manages version selection.
     - `cxvm doctor`: System diagnostic doctor verifying host OS, architecture, `cexr` runtime, `cexp` compiler, and Pure Cex toolchain status.

4. **Cross-Platform Setup Window**:
   - **Terminal Setup Window (CLI)**: Visual ASCII framed application window (`cxvm setup`, `scripts/setup.sh`, `scripts/setup.ps1`, `downloads/setup.cmd`) providing automated directory initialization, shell profile configuration, default runtime installation (`v8.0.0` default and `v6.0.0` LTS), and project `./bin/` integration.
   - **Web Setup Window (Lighting MVC)**: Full-featured desktop application window UI on route `/setup` with macOS/Windows titlebar controls (`[RED] [YELLOW] [GREEN]`), tabbed OS quick installers, environment status cards, runtime selector, and live `cxvm doctor` console.

5. **Project `./bin/` Toolchain Dispatchers**:
   - `./bin/cexr`: Smart runtime dispatcher defaulting to **CexR v8.0.0** with instant version switching to **v6.0.0** (`./bin/cexr v6 ...`).
   - `./bin/cex`: Toolchain runner with support for `run`, `build`, `doctor`, `setup`, and version switches.
   - Cross-platform Windows companions: `cexr.cmd`, `cex.cmd`, `cxvm.cmd`, `cexr.ps1`, `cex.ps1`, `cxvm.ps1`.

6. **Lighting Fullstack MVC Server (Port 3080)**:
   - Embedded web portal providing downloads catalog, setup window, documentation guide, REST JSON endpoints (`/api/v1/status`, `/api/v1/versions`, `/api/v1/platforms`, `/api/v1/downloads`, `/api/v1/manifest`, `/api/v1/setup`), and artifact streaming.

---

## 2. Canonical Target & Package Invariants (Rule 69)

| Key | Value | Specification |
|---|---|---|
| Package Name | `@2tek/cxvm` | Official CXVM Package |
| Version | `2.0.0` | Pure Cex Native Engine Standard |
| Target | `"target": "runtime"` | Strictly Immutable (Rule 69) |
| Runtime Requirement | `"cexr": "^8"` | CexR v8 .cex_boxes Dist Loader Engine |
| Compiler Requirement | `"cexp": "^8"` | CexP v8 Direct Machine Compiler |
| Server Port | `3080` | Factory MVC Default Port |
| Primary Store | `dist/` & `downloads/` | **Keep `dist/` with downloads of cxvm cross platforms** |

---

## 3. Directory Invariants

```text
cxvm/
+-- .agents/                      # Agent specifications, targets, and rules
|   +-- PRODUCT_TARGET.md         # Canonical target specification
|   +-- rules/                    # Enforced coding & architectural rules
|   +-- standards/                # Architectural & setup standards
+-- bin/                          # Project toolchain dispatchers (cexr, cex, cxvm, .cmd, .ps1)
+-- dist/                         # Cross-platform distribution bundles (Rule 69: NOT ignored)
+-- downloads/                    # Cross-platform distribution download store
+-- scripts/                      # Build pipeline & setup automation scripts
|   +-- generate_distributions.sh # Multi-platform package builder & dist sync
|   +-- setup.sh                  # POSIX cross-platform setup window script
|   +-- setup.ps1                 # Windows PowerShell setup window script
+-- src/                          # Lighting MVC fullstack application kernel
|   +-- app.cex                   # Application kernel & route registry
|   +-- builder/                  # Distribution builder logic
|   +-- controllers/              # MVC controllers (FactoryController)
|   +-- cxvm/                     # CXVM version manager engine core
|   +-- models/                   # Validated entities (Platform, Version, Artifact)
|   +-- views/                    # SSR HTML views & Setup Window (FactoryViews)
|   +-- index.cex                 # Package entrypoint & live verification
|   +-- lighting_mvc.cex          # Lighting MVC framework integration
+-- tests/                        # Comprehensive test suites
|   +-- cxvm.test.cex             # CXVM engine & endpoint verification
|   +-- factory.test.cex          # Factory architecture & model validation
+-- cex-pack.json                 # Package manifest (target: runtime, cexp: ^8, cexr: ^8)
+-- README.md                     # Complete cross-platform documentation
```
