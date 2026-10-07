# 2-TEK Factory: Cross-Platform Cex Distribution & Version Manager (cxvm)

Factory is a fullstack cross-platform toolchain distribution engine and runtime version manager for the C-ext (`.cex`) language, powered by the **Lighting Fullstack MVC Framework**. It builds and serves native compiler bundles and installers to `Factory/downloads/` and provides `cxvm`—the Cex Version Manager (the `nvm` of the Cex ecosystem).

---

## 1. Architectural Highlights

- **Powered by Lighting MVC Framework**:
  - **Model Layer (`src/models/`)**: Active-record schema entities (`PlatformModel`, `VersionModel`, `ArtifactModel`) with validation and JSON serialization.
  - **View Layer (`src/views/`)**: High-throughput SSR template rendering (`FactoryViews`) providing the Web Portal, Downloads Explorer, and interactive `cxvm` Guide.
  - **Controller Layer (`src/controllers/`)**: HTTP dispatchers (`FactoryController`) handling SSR pages, dynamic install scripts (`install.sh`, `install.ps1`), distribution downloads, and REST JSON APIs.
  - **Distribution Engine (`src/builder/`)**: Cross-platform packaging pipeline that compiles and bundles runtime archives, checksums, and manifests into `Factory/downloads/`.
  - **Cex Version Manager (`src/cxvm/` & `downloads/cxvm`)**: Cross-platform runtime version manager CLI enabling version switching and installation across platforms.

---

## 2. Supported Cross-Platform Architecture Matrix

| Platform ID | Operating System | Architecture | Target Triple | Packaging Format | Compiler Toolchain |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`linux-x86_64`** | Linux | x86_64 (Intel/AMD) | `x86_64-unknown-linux-gnu` | `.tar.gz` | `g++-12 / clang++-16` |
| **`linux-aarch64`** | Linux | aarch64 (ARM64) | `aarch64-unknown-linux-gnu` | `.tar.gz` | `g++-12 (aarch64)` |
| **`darwin-arm64`** | macOS | Apple Silicon (M1-M4) | `aarch64-apple-darwin` | `.tar.gz` | `clang++-16 (Apple Silicon)` |
| **`darwin-x86_64`** | macOS | Intel 64-bit | `x86_64-apple-darwin` | `.tar.gz` | `clang++-16 (Intel x86_64)` |
| **`windows-x64`** | Windows | x64 (64-bit) | `x86_64-pc-windows-msvc` | `.zip` | `MSVC 2022 / clang-cl` |
| **`windows-arm64`** | Windows | arm64 (ARM64) | `aarch64-pc-windows-msvc` | `.zip` | `MSVC 2022 ARM64` |

---

## 3. Quick Start & One-Line Installers

### POSIX Shell (Linux & macOS):
```bash
# Bootstrap cxvm and default Cex runtime
curl -fsSL http://127.0.0.1:3080/install.sh | bash

# Or run directly from local repository
bash packages/Factory/downloads/install.sh
```

### Windows PowerShell:
```powershell
# Bootstrap cxvm and default Cex runtime
irm http://127.0.0.1:3080/install.ps1 | iex

# Or run directly from local repository
powershell -ExecutionPolicy Bypass -File packages/Factory/downloads/install.ps1
```

---

## 4. Cex Version Manager (`cxvm`) CLI (like `nvm`)

| Command | Node.js (`nvm`) Equivalent | Action |
| :--- | :--- | :--- |
| `cxvm install 1.0.0` | `nvm install 18` | Downloads and unpacks runtime tarball/zip |
| `cxvm use 1.0.0` | `nvm use 18` | Switches active version via symlink & PATH |
| `cxvm list` | `nvm ls` | Lists locally installed Cex runtimes and active one |
| `cxvm list-remote` | `nvm ls-remote` | Queries Factory catalog for available upstream releases |
| `cxvm current` | `nvm current` | Prints active Cex runtime version |
| `cxvm default 1.0.0` | `nvm alias default 18` | Configures default Cex version for new shells |
| `cxvm uninstall 1.0.0` | `nvm uninstall 18` | Removes an installed version |
| `cxvm doctor` | — | Runs pre-flight diagnostics for C++20 and runtime environment |

---

## 5. Pre-Built Distribution Artifacts (`Factory/downloads/`)

The following distribution archives and tools are generated into `Factory/downloads/`:

- `cex-v1.0.0-linux-x86_64.tar.gz`
- `cex-v1.0.0-linux-aarch64.tar.gz`
- `cex-v1.0.0-darwin-arm64.tar.gz`
- `cex-v1.0.0-darwin-x86_64.tar.gz`
- `cex-v1.0.0-windows-x64.zip`
- `cex-v1.0.0-windows-arm64.zip`
- `cex-v1.1.0-linux-x86_64.tar.gz`
- `cex-v1.1.0-linux-aarch64.tar.gz`
- `cex-v1.1.0-darwin-arm64.tar.gz`
- `cex-v1.1.0-darwin-x86_64.tar.gz`
- `cex-v1.1.0-windows-x64.zip`
- `cex-v1.1.0-windows-arm64.zip`
- `install.sh` (POSIX curl | bash installer)
- `install.ps1` (PowerShell installer)
- `cxvm` / `cxvm.sh` (POSIX version manager CLI)
- `cxvm.ps1` (Windows PowerShell version manager CLI)
- `manifest.json` (Distribution catalog & cryptographic hashes)
- `SHA256SUMS` (Standard SHA-256 checksums file)

---

## 6. Execution & Testing

```bash
# Run Factory Demonstration & Server Engine
./bin/cex run packages/Factory/src/index.cex

# Run Factory Verification Test Suite
./bin/cex run packages/Factory/tests/factory.test.cex
```
