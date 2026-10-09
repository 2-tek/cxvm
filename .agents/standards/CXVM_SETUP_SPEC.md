# CXVM Setup Window & Environment Specification

<!-- Standard Specification: .agents/standards/CXVM_SETUP_SPEC.md -->
<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols) -->

## 1. Overview

The `cxvm` setup system provides cross-platform initialization for the Cex environment across Linux, macOS, and Windows. It configures paths, installs default runtimes, and links project dispatchers.

---

## 2. Setup Modalities

### 2.1 Terminal Setup Window (CLI)

- **Entrypoint**: `cxvm setup`, `./bin/cxvm setup`, `bash scripts/setup.sh`, `pwsh scripts/setup.ps1`, or `downloads\setup.cmd`.
- **Display**: ASCII framed application window.
- **Workflow**:
  1. Detect host operating system, architecture, and current shell (`bash`, `zsh`, `fish`, `pwsh`, `cmd`).
  2. Create CXVM root at `$HOME/.cxvm` (POSIX) or `%USERPROFILE%\.cxvm` (Windows).
  3. Ensure directories: `versions/`, `downloads/`, `shims/`, `bin/`.
  4. Write environment configuration to user shell profile (`.bashrc`, `.zshrc`, `config.fish`, or user Windows environment registry).
  5. Install and unpack default runtimes:
     - **v8.0.0** (Default CexR v8 runtime with `.cex_boxes` dist loader).
     - **v6.0.0** (LTS CexR v6 runtime with native JIT).
  6. Point active symlink `$CXVM_DIR/current` -> `$CXVM_DIR/versions/v8.0.0`.
  7. Validate local `./bin/cexr` and `./bin/cex` dispatchers.
  8. Run diagnostic pre-flight checks and report success.

### 2.2 Web Setup Window (Lighting MVC)

- **Route**: `GET /setup` (served via Lighting MVC on port 3080).
- **Interface**:
  - Desktop-style window card featuring macOS/Windows control dots (`[RED] [YELLOW] [GREEN]`).
  - System summary badges: Host OS, architecture, detected shell, active Cex runtime.
  - Tabbed installation guides: Linux / macOS curl installer, Windows PowerShell script, CMD installer.
  - Interactive Runtime Version Switcher: Toggle between **v8.0.0** and **v6.0.0**.
  - Live Doctor Output: Real-time diagnostics preview.

---

## 3. Environment Variables & PATH Configuration

| Variable | Description | Default POSIX | Default Windows |
| :--- | :--- | :--- | :--- |
| `CXVM_DIR` | CXVM installation root | `$HOME/.cxvm` | `%USERPROFILE%\.cxvm` |
| `CEX_HOME` | Cex ecosystem root | `$HOME/.cxvm/current` | `%USERPROFILE%\.cxvm\current` |
| `PATH` | Prepend binary path | `$CXVM_DIR/current/bin:$PATH` | `%CXVM_DIR%\current\bin;%PATH%` |

---

## 4. Project `./bin/` Dispatchers

Project-level `./bin/cexr` and `./bin/cex` scripts:
1. Check for local `$CXVM_DIR/versions/v8.0.0/bin/cexr`.
2. Fall back to system `cexr` in `PATH` if available.
3. Detect version flag arguments (e.g. `./bin/cexr v6 <script>` or `./bin/cex v6 run <script>`) to route to `$CXVM_DIR/versions/v6.0.0/bin/cexr`.
4. Windows companion scripts (`.cmd`, `.ps1`) provide identical functionality without POSIX bash requirements.
