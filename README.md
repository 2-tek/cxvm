# 2-TEK Factory: Cross-Platform Cex Distribution & Version Manager (cxvm v2)

Factory is a fullstack cross-platform toolchain distribution engine and runtime version manager for the C-ext (`.cex`) language, powered by the **Lighting Fullstack MVC Framework**. In v2, cxvm uses a **Pure Cex Toolchain** (`cexr` Runtime + `cexp` Compiler) with **zero C++ dependency**, managing native runtime bundles across Linux, macOS, and Windows.

---

## 1. Architectural Highlights

- **Pure Cex Toolchain (Zero C++ Dependency)**:
  - Powered directly by **`cexr`** (Cex Language Runtime Engine) and **`cexp`** (Cex Language Direct Machine Compiler).
  - No external C++ compilers (`g++`, `clang++`, `MSVC`) or C++20 header dependencies required.
- **Powered by Lighting MVC Framework**:
  - **Model Layer (`src/models/`)**: Active-record schema entities (`PlatformModel`, `VersionModel`, `ArtifactModel`) with validation and JSON serialization.
  - **View Layer (`src/views/`)**: High-throughput SSR template rendering (`FactoryViews`) providing the Web Portal, Downloads Explorer, and interactive `cxvm` Guide.
  - **Controller Layer (`src/controllers/`)**: HTTP dispatchers (`FactoryController`) handling SSR pages, dynamic install scripts (`install.sh`, `install.ps1`), cross-platform distribution downloads (`/downloads/:id`), and REST JSON APIs.
  - **Distribution Engine (`src/builder/` & `scripts/generate_distributions.sh`)**: Cross-platform packaging pipeline that compiles and bundles runtime archives, `cexr` executables, checksums, and manifests into `cxvm/downloads/`.
  - **Cex Version Manager (`src/cxvm/` & `downloads/cxvm*`)**: Cross-platform runtime version manager CLI enabling version switching and `cexr` setup across Linux, macOS, and Windows.
- **Relocated Outside Packages**:
  - Located directly at repository root: `./cxvm`
  - Backward-compatibility symlinks: `packages/cxvm -> ../cxvm` and `bin/cxvm -> ../cxvm/downloads/cxvm`.

---

## 2. Supported Cross-Platform Architecture Matrix

| Platform ID | Operating System | Architecture | Target Triple | Packaging Format | Native Toolchain |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`linux-x86_64`** | Linux | x86_64 (Intel/AMD) | `x86_64-unknown-linux-gnu` | `.tar.gz` | `CexP v8 (Native Direct Compiler)` |
| **`linux-aarch64`** | Linux | aarch64 (ARM64) | `aarch64-unknown-linux-gnu` | `.tar.gz` | `CexP v8 (Native Direct Compiler)` |
| **`darwin-arm64`** | macOS | Apple Silicon (M1-M4) | `aarch64-apple-darwin` | `.tar.gz` | `CexP v8 (Native Direct Compiler)` |
| **`darwin-x86_64`** | macOS | Intel 64-bit | `x86_64-apple-darwin` | `.tar.gz` | `CexP v8 (Native Direct Compiler)` |
| **`windows-x64`** | Windows | x64 (64-bit) | `x86_64-pc-windows-msvc` | `.zip` | `CexP v8 (Native Direct Compiler)` |
| **`windows-arm64`** | Windows | arm64 (ARM64) | `aarch64-pc-windows-msvc` | `.zip` | `CexP v8 (Native Direct Compiler)` |

---

## 3. Quick Start & One-Line Installers to Setup `cexr`

### POSIX Shell (Linux & macOS via GitHub):
```bash
# Bootstrap cxvm and default CexR v8 runtime via GitHub
curl -fsSL https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/install.sh | bash

# Or download standalone cxvm CLI script directly
curl -fsSL https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/cxvm -o ~/.cxvm/bin/cxvm && chmod +x ~/.cxvm/bin/cxvm

# Or run directly from local repository
bash cxvm/downloads/install.sh
```

### Windows PowerShell & CMD (via GitHub):
```powershell
# Bootstrap cxvm and default CexR v8 runtime in PowerShell via GitHub
irm https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/install.ps1 | iex

# Or download PowerShell & CMD scripts directly
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/cxvm.ps1" -OutFile "$HOME\.cxvm\bin\cxvm.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/cxvm.cmd" -OutFile "$HOME\.cxvm\bin\cxvm.cmd"

# Or run directly from local repository
powershell -ExecutionPolicy Bypass -File cxvm/downloads/install.ps1
```

> **Local Factory Server Alternative**: When running the Lighting MVC server locally (`http://127.0.0.1:3080`), you can also use `http://127.0.0.1:3080/install.sh` or `http://127.0.0.1:3080/install.ps1`.


---

## 3. Cross-Platform Setup Window & `./bin` Toolchain Configuration

### Terminal Setup Window (Cross-Platform CLI):
Run the setup window to configure environment variables (`CXVM_DIR`, `CEX_HOME`), shell PATH persistence, default runtime versions (`v8.0.0` default and `v6.0.0` LTS), and project dispatchers (`./bin/cexr` and `./bin/cex`):

```bash
# Linux / macOS (POSIX)
curl -fsSL https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/setup.sh | bash
# Or run locally:
bash scripts/setup.sh
# Or via cxvm CLI:
cxvm setup
```

```powershell
# Windows PowerShell
irm https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/setup.ps1 | iex
# Or run locally:
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
# Or via CMD batch launcher:
.\downloads\setup.cmd
```

### Web Setup Window (Lighting MVC):
When running the Factory application (`cexr run src/index.cex` on port 3080):
- Open **`http://localhost:3080/setup`** in your browser to view the interactive Setup Window.
- Monitor environment variables, PATH persistence, default version status, and live `cxvm doctor` diagnostics.

### Running cxvm with Default `./bin/cexr` and `./bin/cex`:
The project `./bin/` dispatchers are preconfigured to run cxvm using **v8.0.0** by default, with instant support for **v6.0.0**:

```bash
# Run using default v8 runtime:
./bin/cexr run src/index.cex
./bin/cex run src/index.cex

# Run using v6 runtime:
./bin/cexr v6 run src/index.cex
./bin/cex v6 run src/index.cex

# Switch active version across sessions:
cxvm use 8.0.0
cxvm use 6.0.0
```

---

## 4. Cex Version Manager (`cxvm`) CLI (like `nvm`)

| Command | Node.js (`nvm`) Equivalent | Action |
| :--- | :--- | :--- |
| `cxvm setup` | — | Displays cross-platform setup window, configures PATH & env, and links `./bin/cexr` & `./bin/cex` (v8 & v6) |
| `cxvm install 8.0.0` | `nvm install 18` | Downloads platform archive and sets up native `cexr` runner |
| `cxvm download 8.0.0 [plat]` | — | Downloads cross-platform bundle into cache for offline `cexr` setup |
| `cxvm download 8.0.0 all` | — | Downloads all 6 cross-platform targets (`linux`, `darwin`, `windows`) into cache to install `cexr` |
| `cxvm use 8.0.0` | `nvm use 18` | Switches active version via symlink & activates `cexr` in PATH |
| `cxvm list` | `nvm ls` | Lists locally installed Cex runtimes and active one |
| `cxvm list-remote` | `nvm ls-remote` | Queries Factory catalog for available upstream releases |
| `cxvm current` | `nvm current` | Prints active Cex runtime version (e.g. `v8.0.0`) |
| `cxvm default 8.0.0` | `nvm alias default 18` | Configures default Cex version for new shells |
| `cxvm uninstall 2.0.0` | `nvm uninstall 18` | Removes an installed version |
| `cxvm doctor` | — | Runs pre-flight diagnostics for native `cexr`, `cexp`, `cvm`, `thunder`, `light`, and host environment (zero C++ dependency) |
| `cxvm light create <name>` | `nest new` | Hooks project creation logic in MVC-Lighting to scaffold new Fullstack MVC project |
| `cxvm light dev` | `npm run dev` | Starts local Lighting MVC development server on port 3080 |
| `cxvm light build` | `npm run build` | Compiles Lighting project with `cexp` direct machine compiler |
| `cxvm light doctor` | — | Runs Lighting engine diagnostic and verification |
| `cxvm thunder <cmd>` | Docker CLI (`docker`) | Run Thunder container operations (`ps`, `run`, `stop`, `images`, `stats`) |
| `cxvm docker <cmd>` | Docker CLI (`docker`) | Docker compatibility alias for Thunder |
| `cxvm start thunder [-p <port>]` | — | Starts Thunder container engine daemon with single process (standalone) |
| `cxvm status thunder` | — | Inspects status of standalone Thunder server |
| `cxvm stop thunder` | — | Stops background standalone Thunder server |

---

## 5. Integrated CodeVersionManager (CVM) Commands (like `git` & `cvm`)

`cxvm` features an integrated **CodeVersionManager (CVM)** engine built natively in pure C-ext (`src/cvm/`). All VCS operations can be executed directly via `cxvm`:

| Command | Action | Example |
| :--- | :--- | :--- |
| `cxvm status` | Inspect branch, working tree, and untracked/staged files | `cxvm status` |
| `cxvm add <files...>` | Stage file modifications into index | `cxvm add src/app.cex` \| `cxvm add .` |
| `cxvm commit -m <msg>` | Commit staged changes to local DAG graph with SHA hash | `cxvm commit -m "feat(cxvm): integrate cvm into cxvm"` |
| `cxvm push [remote] [branch]` | Push committed changes to upstream remote repository | `cxvm push` \| `cxvm push origin main` |
| `cxvm pull [remote] [branch]` | Fetch and integrate changes from upstream remote | `cxvm pull` \| `cxvm pull origin main` |
| `cxvm branch [name]` | List existing branches or create a new branch | `cxvm branch` \| `cxvm branch feature/my-feature` |
| `cxvm checkout <branch>` | Switch active HEAD to target branch | `cxvm checkout main` |
| `cxvm diff [file]` | Display unified diff of modified files | `cxvm diff` |
| `cxvm log [--oneline]` | Display commit log history with hashes and authors | `cxvm log` |
| `cxvm unstage <files...>` | Unstage files from index without discarding changes | `cxvm unstage src/index.cex` |
| `cxvm discard <files...>` | Discard changes in working directory | `cxvm discard src/index.cex` |
| `cxvm init [dir] [--git]` | Initialize new repository with object store | `cxvm init` |
| `cxvm git <args...>` | Direct pass-through to native git toolchain | `cxvm git log -n 5` |
| `cxvm start cvm [-p <port>]` | Start CVM as a server with single process (standalone) in background | `cxvm start cvm` \| `cxvm start cvm -p 4000` |
| `cxvm status cvm` | Check single-process standalone CVM server status | `cxvm status cvm` |
| `cxvm stop cvm` | Stop background standalone CVM server | `cxvm stop cvm` |

### Standalone Single-Process CVM Server (`cxvm start cvm`):

`cxvm` provides a lightweight, **single-process standalone CVM server** that runs without heavy multi-process frameworks (e.g. Next.js multi-process `npx next dev`).
- **Single OS Process**: Zero multi-process overhead, instant launch, and minimal memory footprint.
- **Web Studio UI**: Visual dashboard accessible at `http://localhost:4000` for managing commits, branches, and diffs.
- **REST Endpoints**:
  - `GET /health` & `GET /api/v1/health`: Server health check and process PID report.
  - `GET /api/v1/cvm/status`: Current git/CVM repository working tree status.
  - `POST /api/v1/cvm/commit`: Commit staged files.
  - `POST /api/v1/cvm/push`: Push to upstream repository.
  - `POST /api/v1/cvm/pull`: Pull latest changes.
  - `GET /api/v1/cvm/log`: Commit history log.
  - `GET /api/v1/cvm/diff`: Working tree diff.
- **Lifecycle Management**:
  ```bash
  cxvm start cvm              # Start standalone server on port 4000 (daemon background)
  cxvm start cvm -p 5000      # Custom port
  cxvm start cvm --foreground # Run in foreground
  cxvm status cvm             # Inspect PID and active port
  cxvm stop cvm               # Stop server
  ```

### Auto-Install & Auto-Start on CXVM Install:

When installing `cxvm` via `cxvm install <version>`, `install.sh`, `setup.sh`, or `setup.ps1`:
1. **Auto-Install Toolchains**: Automatically installs and configures:
   - `cexr` (Cex Language Runtime Engine)
   - `cexp` (Cex Direct Machine Compiler)
   - `cvm` (CodeVersionManager Engine & standalone server)
2. **Auto-Start Runtime Services**:
   - Initializes active `cexr` runtime engine
   - Pre-warms `cexp` machine compiler
   - Auto-starts `cvm` server with a single process (standalone) in the background on port 4000.

### Lighting MVC HTTP REST API for CVM:

When the Factory application runs on port 3080:
- **`GET /api/v1/cvm/status`**: Returns JSON object representing current repository status, active branch, and cleanliness.
- **`POST /api/v1/cvm/commit`**: Commits staged files with provided message payload, returning commit hash.
- **`POST /api/v1/cvm/push`**: Pushes local branch commits to upstream remote.
- **`POST /api/v1/cvm/server/start`**: Programmatically starts the standalone CVM server.
- **`GET /api/v1/cvm/server/status`**: Queries standalone CVM server PID and port status.
- **`POST /api/v1/cvm/server/stop`**: Programmatically stops the standalone CVM server.

---

## 6. Integrated Thunder Container Engine & Virtual Linux Microkernel

`cxvm` features native integration with **Thunder** (`@2tek/thunder`), a high-performance Pure Cex Container Engine, Virtual Linux 6.8 Microkernel, and Lighting MVC Control Daemon.

Thunder enables building, isolating, executing, and orchestrating native container workloads with Docker syntax compatibility and single-process standalone daemon execution.

### Thunder CLI Commands:

| Command | Action | Example |
| :--- | :--- | :--- |
| `cxvm thunder ps` / `cxvm docker ps` | List running containers with IDs, names, images, ports, and status | `cxvm thunder ps` |
| `cxvm thunder run <image>` | Run container workload inside virtual microkernel isolation | `cxvm thunder run @2tek/cxvm:latest` |
| `cxvm thunder stop <id>` | Gracefully stop running container instance | `cxvm thunder stop cxt-1a8f9` |
| `cxvm thunder images` / `cxvm docker images` | List local OCI container images in cache | `cxvm thunder images` |
| `cxvm thunder stats` | Inspect real-time virtual CPU, memory, vFS, and network metrics | `cxvm thunder stats` |
| `cxvm start thunder [-p <port>]` | Start Thunder as a single-process standalone daemon in background | `cxvm start thunder` \| `cxvm start thunder -p 3050` |
| `cxvm status thunder` | Check status of single-process standalone Thunder daemon | `cxvm status thunder` |
| `cxvm stop thunder` | Stop background standalone Thunder daemon | `cxvm stop thunder` |

### Standalone Single-Process Thunder Daemon (`cxvm start thunder`):

`cxvm` provisions Thunder as a lightweight, single-process standalone service:
- **Virtual Linux 6.8 Microkernel**: Pure user-space kernel simulation providing virtual processes, namespaces (PID, Mount, Net), vFS overlays (`overlayfs`, `procfs`, `sysfs`), and cgroups v2 resource limits.
- **Web Dashboard UI**: Real-time container control panel accessible at `http://localhost:3050`.
- **REST APIs**:
  - `GET /health` & `GET /api/v1/health`: Thunder health check.
  - `GET /api/v1/thunder/status`: Microkernel and daemon status report.
  - `GET /api/v1/thunder/containers`: Active containers list.
  - `POST /api/v1/thunder/containers/run`: Spawn container.
  - `POST /api/v1/thunder/containers/stop`: Terminate container.
  - `GET /api/v1/thunder/images`: Cached images list.
  - `GET /api/v1/thunder/stats`: Real-time performance telemetry.
- **Lifecycle Management**:
  ```bash
  cxvm start thunder              # Start standalone daemon on default port 3050 (background)
  cxvm start thunder -p 3055      # Custom port
  cxvm start thunder --foreground # Run in foreground
  cxvm status thunder             # Inspect PID and active port
  cxvm stop thunder               # Stop daemon
  ```

### Auto-Install & Auto-Start on CXVM Setup & Run:

When setting up `cxvm` via `scripts/setup.sh`, `scripts/setup.ps1`, `install.sh`, `install.ps1`, or running `cxvm install <version>`:
1. **Auto-Install Toolchains**: Installs and configures:
   - `cexr` (Cex Language Runtime Engine)
   - `cexp` (Cex Direct Machine Compiler)
   - `cvm` (CodeVersionManager Engine)
   - `thunder` (Thunder Container Engine & Virtual Linux Microkernel)
2. **Auto-Start Runtime Services**:
   - `cexr` runtime engine initialized
   - `cexp` direct compiler pre-warmed
   - `cvm-server` auto-started as standalone single process on port 4000
   - `thunder-server` auto-started as standalone single process on port 3050

### Lighting MVC HTTP REST API for Thunder:

When the Factory application runs on port 3080:
- **`GET /api/v1/thunder/status`**: Returns health, microkernel version, container counts, and engine status.
- **`POST /api/v1/thunder/server/start`**: Programmatically starts the standalone Thunder server.
- **`GET /api/v1/thunder/server/status`**: Queries standalone Thunder server PID and port status.
- **`POST /api/v1/thunder/server/stop`**: Programmatically stops the standalone Thunder server.
- **`GET /api/v1/thunder/containers`**: Lists all active container instances with ports and status.
- **`GET /api/v1/thunder/images`**: Lists cached OCI container images with SHA hashes.

---

## 7. Integrated Lighting Fullstack MVC Engine & Scaffolder (`cxvm light`)

`cxvm` natively integrates **Lighting Fullstack MVC** (`@2tek/lighting`), allowing developers to immediately scaffold, develop, build, and deploy high-performance web applications using Pure Cex.

### Scaffolding New Projects with `cxvm light create {projectName}`:
To create a new project powered by Lighting Fullstack MVC:
```bash
cxvm light create my-awesome-app
# Or using the alias:
cxvm lighting create my-awesome-app
```

`cxvm` hooks directly into the logic scripts of `MVC-Lighting` (`bin/light`, `scripts/create.sh`, `create.cex`):
1. **Directory Structure**:
   - `src/controllers/`: MVC controllers (e.g. `HomeController`, `FactoryController`).
   - `src/models/`: Strongly-typed schema models with validation.
   - `src/views/`: Server-rendered templates and HTML views.
   - `public/`: Static assets and styling.
   - `bin/light`: Project runner dispatcher.
2. **Package Configuration (`cex-pack.json`)**: Configured with `"target": "runtime"` and dependency `@2tek/lighting: "^8.0.0"`.
3. **Application Entrypoint (`src/index.cex`)**: High-throughput Lighting HTTP server pre-configured.

### Running & Building Lighting Applications:
```bash
cd my-awesome-app
cxvm light dev    # Or ./bin/light dev (starts server on port 3080)
cxvm light build  # Or ./bin/light build (compiles native binary via cexp)
cxvm light doctor # Runs diagnostic health check
```

### Lighting MVC REST Endpoints:
- **`GET /api/v1/light/status`**: Returns Lighting engine readiness, framework version, and available commands.
- **`POST /api/v1/light/create`**: Programmatically triggers project scaffolding via JSON payload `{"projectName": "app-name"}`.

---

## 8. Pre-Built Distribution Artifacts (`cxvm/downloads/`)

The following distribution archives (36 bundles: 6 versions x 6 platforms) and tools are generated into `cxvm/downloads/`:

- **v8.0.0 (CexR v8 .cex_boxes Dist Loader Runtime & Direct Compiler - Default)**:
  - `cex-v8.0.0-linux-x86_64.tar.gz`
  - `cex-v8.0.0-linux-aarch64.tar.gz`
  - `cex-v8.0.0-darwin-arm64.tar.gz`
  - `cex-v8.0.0-darwin-x86_64.tar.gz`
  - `cex-v8.0.0-windows-x64.zip`
  - `cex-v8.0.0-windows-arm64.zip`
- **v6.0.0 (CexR v6 High-Performance Native Server Engine & Direct Machine Compiler - LTS)**:
  - `cex-v6.0.0-linux-x86_64.tar.gz`
  - `cex-v6.0.0-linux-aarch64.tar.gz`
  - `cex-v6.0.0-darwin-arm64.tar.gz`
  - `cex-v6.0.0-darwin-x86_64.tar.gz`
  - `cex-v6.0.0-windows-x64.zip`
  - `cex-v6.0.0-windows-arm64.zip`
- **v5.0.0 (CexR v5 Native Server Engine & Direct Machine Compiler - LTS)**:
  - `cex-v5.0.0-linux-x86_64.tar.gz`
  - `cex-v5.0.0-linux-aarch64.tar.gz`
  - `cex-v5.0.0-darwin-arm64.tar.gz`
  - `cex-v5.0.0-darwin-x86_64.tar.gz`
  - `cex-v5.0.0-windows-x64.zip`
  - `cex-v5.0.0-windows-arm64.zip`
- **v3.0.0 (CexR v3 Native Machine Engine & CexP v3 Direct Compiler - LTS)**:
  - `cex-v3.0.0-linux-x86_64.tar.gz`
  - `cex-v3.0.0-linux-aarch64.tar.gz`
  - `cex-v3.0.0-darwin-arm64.tar.gz`
  - `cex-v3.0.0-darwin-x86_64.tar.gz`
  - `cex-v3.0.0-windows-x64.zip`
  - `cex-v3.0.0-windows-arm64.zip`
- **v2.0.0 (CexR v2 Multi-Source Compiler & Self-Hosted Engine - LTS)**:
  - `cex-v2.0.0-linux-x86_64.tar.gz`
  - `cex-v2.0.0-linux-aarch64.tar.gz`
  - `cex-v2.0.0-darwin-arm64.tar.gz`
  - `cex-v2.0.0-darwin-x86_64.tar.gz`
  - `cex-v2.0.0-windows-x64.zip`
  - `cex-v2.0.0-windows-arm64.zip`
- **v1.0.0 (CexR v1 C++ Transpiler Runtime & Standard Libraries - LEGACY)**:
  - `cex-v1.0.0-linux-x86_64.tar.gz`
  - `cex-v1.0.0-linux-aarch64.tar.gz`
  - `cex-v1.0.0-darwin-arm64.tar.gz`
  - `cex-v1.0.0-darwin-x86_64.tar.gz`
  - `cex-v1.0.0-windows-x64.zip`
  - `cex-v1.0.0-windows-arm64.zip`
- **Installers & Manager CLI**:
  - `install.sh` (POSIX curl | bash installer)
  - `install.ps1` (PowerShell installer)
  - `cxvm` / `cxvm.sh` (POSIX version manager CLI)
  - `cxvm.ps1` (Windows PowerShell version manager CLI)
  - `cxvm.cmd` (Windows Command Prompt launcher)
  - `manifest.json` (Distribution catalog & cryptographic hashes)
  - `SHA256SUMS` (Standard SHA-256 checksums file)

---

## 9. Execution & Testing with CexR v8

```bash
# 1. Switch to CexR v8 Runtime via cxvm
cxvm use 8.0.0
# Or activate CexR v8 via toolchain
cexr use v8

# 2. Run cxvm Demonstration & Server Engine via CexR v8
cexr run src/index.cex
# Or execute canonically via CexR v8 toolchain runner
./bin/cex run src/index.cex
# Or load and execute via CexR v8 .cex_boxes dist loader
cexr v8 run cxvm

# 3. Run cxvm Verification Test Suites with CexR v8
cexr run tests/cxvm.test.cex
cexr run tests/factory.test.cex
```

---

## 10. Repository & Upstream Git Origin

- **GitHub Repository**: [`https://github.com/2-tek/cxvm`](https://github.com/2-tek/cxvm)
- **Clone Repository**:
  ```bash
  git clone https://github.com/2-tek/cxvm.git
  ```
