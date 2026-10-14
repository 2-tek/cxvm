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

7. **Integrated Code Linter & Entrypoint Auto-Detection (Start, Dev, Build)**:
    - Integrated native **CexLint** validation engine.
    - Automatically executes before `cxvm dev`, `cxvm start`, `lighting start`, `cxvm light dev`, `cxvm light start` (redirects to `lighting start`), `cxvm build`, and `cxvm load`.
    - Automatically detects the `"main"` entrypoint file from `cex-pack.json` for `cxvm start`, `cxvm dev`, and `cxvm build` (eliminating the need to specify `src/index.cex` manually).
    - Halts execution on lint violations to prevent unvalidated code from running or building.
    - Run `cxvm lint --fix` for automatic formatting repair.

8. **Easy OS Setup & One-Click Cross-Platform Installer**:
    - Instant one-click OS setup for `cxvm`, `cexr`, and `cexp`:
        - POSIX (Linux / macOS): `curl -fsSL http://localhost:3080/one-click.sh | bash`
        - Windows (PowerShell): `irm http://localhost:3080/one-click.ps1 | iex`
        - REST API: `GET` / `POST` `/api/v1/setup/one-click`
        - CLI: `cxvm setup --one-click`
    - Automatically provisions `CXVM_DIR`, configures user shell PATH in `~/.bashrc`, `~/.zshrc`, and Windows User Environment, installs default toolchain in `./bin/`, and activates CexR `v8.0.0` default.

9. **Dynamic App Execution via `cxvm --app $appName` & `./bin/$version/$appName`**:
    - Dispatches and executes installed applications located at `./bin/$version/$appName`, `./bin/v$version/$appName`, or `./bin/$appName`.
    - If the application is not yet compiled, automatically builds and links the binary launcher.
    - REST API: `POST /api/v1/apps/run` (`app`, `cmd`, `args`).
    - Standardized `cxvm dev`: Automatically expands to `cxvm dev = cxvm --app cexr $cex-pack.app-name` (resolving dynamic `"app-name"` from `cex-pack.json`).

10. **One-Command Auto-Repair (`cxvm fix`) & App Downloads (`cxvm downloads`)**:
    - `cxvm fix`: One-command comprehensive repair that restores `./bin/` toolchains, repairs `.cex_boxes` vendor symlinks, ensures manifest apps are built into `./bin/$version/$appName`, runs CexLint auto-repair, and checks OS PATH readiness (`POST /api/v1/fix`).
    - `cxvm downloads`: Downloads and compiles primary applications and runnable dependencies declared in `cex-pack.json` into versioned binary folders `./bin/$version/$appName` (`POST /api/v1/apps/downloads`).
    - Default toolchain in `./bin/`: Integrates `cexr` & `cexp` (`v8` & `v6`) as default in `./bin/` with `.gitkeep` for version control hygiene and build reproducibility.

11. **Integrated App Binary Builds & Routing Transformation (`cxvm $appName = cxvm --app {appName with lastversion} $action ...args`)**:
    - Seamlessly integrates 7 foundational Cex applications as compiled binaries in `./bin/` and `./bin/8.0.0/`:
        - `cex-lint` (`1.0.7`, alias: `lint`)
        - `cex-sql-server` (`1.0.3`, alias: `sql`, `sql-server`)
        - `code-storm` (`1.0.4`, alias: `storm`, `codestorm`)
        - `thunder-lite` (`1.0.8`, alias: `thunder`, `docker`)
        - `cvm` (`1.0.16`, alias: `vcs`, `mvc-code-manager`)
        - `lighting` (`6.0.23`, alias: `light`, `mvc-lighting`)
        - `deepsea` (`1.0.10`, alias: `deep-sea`, `mvp-deepsea`)
    - Removes monolithic/simulated logic inside `src/` and routes all direct app invocations through `cxvm --app $appName` to execute installed binaries.
    - Auto-canonicalizes app names and injects the last known version into console logs: `cxvm $appName = cxvm --app {appName with lastversion} $action ...args`.

---

## 2. Canonical Target & Package Invariants (Rule 69)

| Key                  | Value                  | Specification                                           |
| -------------------- | ---------------------- | ------------------------------------------------------- |
| Package Name         | `@2tek/cxvm`           | Official CXVM Package                                   |
| Version              | `2.0.0`                | Pure Cex Native Engine Standard                         |
| Target               | `"target": "runtime"`  | Strictly Immutable (Rule 69)                            |
| Runtime Requirement  | `"cexr": "^8"`         | CexR v8 .cex_boxes Dist Loader Engine                   |
| Compiler Requirement | `"cexp": "^8"`         | cexp v8 Direct Machine Compiler                         |
| Server Port          | `3080`                 | Factory MVC Default Port                                |
| Primary Store        | `dist/` & `downloads/` | **Keep `dist/` with downloads of cxvm cross platforms** |

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

---

## 12. CXVM Fixed Subsystem Specification

`cxvm fixed` provides an automated workflow to pull the latest cxvm code directly from Git and CVM remotes, retrieve the newest version, and synchronize local toolchains:
- `cxvm fixed`: Pulls from `origin/main` (or active branch), falls back gracefully between Git and CVM.
- `cxvm fixed <remote> <branch>`: Pulls from specified remote and branch.
- Resolves newest version from `cex-pack.json` and VCS release tags.
- Re-executes `integrateBinDefaultToolchain()` and updates `$CXVM_DIR/bin/cxvm`.
