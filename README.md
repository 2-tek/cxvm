# 2-TEK Factory: Cross-Platform Cex Distribution & Version Manager (cxvm v2)

Factory is a fullstack cross-platform toolchain distribution engine and runtime version manager for the C-ext (`.cex`) language, powered by the **Lighting Fullstack MVC Framework**. In v2, cxvm uses a **Pure Cex Toolchain** (`cexr-$type` Runtime + `cexp-v$shortVersion` Compiler) with **zero C++ dependency**, managing native runtime bundles across Linux, macOS, and Windows.

---

## 1. Architectural Highlights

- **Pure Cex Toolchain (Zero C++ Dependency)**:
  - Powered directly by **`cexr-$type`** (Cex Language Runtime Engine) and **`cexp-v$shortVersion`** (Cex Language Direct Machine Compiler).
  - No external C++ compilers (`g++`, `clang++`, `MSVC`) or C++20 header dependencies required.
- **Powered by Lighting MVC Framework**:
  - **Model Layer (`src/models/`)**: Active-record schema entities (`PlatformModel`, `VersionModel`, `ArtifactModel`) with validation and JSON serialization.
  - **View Layer (`src/views/`)**: High-throughput SSR template rendering (`FactoryViews`) providing the Web Portal, Downloads Explorer, and interactive `cxvm` Guide.
  - **Controller Layer (`src/controllers/`)**: HTTP dispatchers (`FactoryController`) handling SSR pages, dynamic install scripts (`install.sh`, `install.ps1`), cross-platform distribution downloads (`/downloads/:id`), and REST JSON APIs.
  - **Distribution Engine (`src/builder/` & `scripts/generate_distributions.sh`)**: Cross-platform packaging pipeline that compiles and bundles runtime archives, `cexr-$type` executables, checksums, and manifests into `cxvm/downloads/`.
  - **Cex Version Manager (`src/cxvm/` & `downloads/cxvm*`)**: Cross-platform runtime version manager CLI enabling version switching and `cexr-$type` setup across Linux, macOS, and Windows.
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

## 3. Quick Start & One-Line Installers to Setup `cexr-$type`

### POSIX Shell (Linux & macOS via GitHub):
```bash
# Bootstrap cxvm and default cexr-$type runtime via GitHub
curl -fsSL https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/install.sh | bash

# Or download standalone cxvm CLI script directly
curl -fsSL https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/cxvm -o ~/.cxvm/bin/cxvm && chmod +x ~/.cxvm/bin/cxvm

# Or run directly from local repository
bash cxvm/downloads/install.sh
```

### Windows PowerShell & CMD (via GitHub):
```powershell
# Bootstrap cxvm and default cexr-$type runtime in PowerShell via GitHub
irm https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/install.ps1 | iex

# Or download PowerShell & CMD scripts directly
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/cxvm.ps1" -OutFile "$HOME\.cxvm\bin\cxvm.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/cxvm.cmd" -OutFile "$HOME\.cxvm\bin\cxvm.cmd"

# Or run directly from local repository
powershell -ExecutionPolicy Bypass -File cxvm/downloads/install.ps1
```

> **Local Factory Server Alternative**: When running the Lighting MVC server locally (`http://127.0.0.1:3080`), you can also use `http://127.0.0.1:3080/install.sh` or `http://127.0.0.1:3080/install.ps1`.


---

## 3. Cross-Platform Setup Window & Reserve Build Target (`CEX_DIR|CEX_HOME.../$name-$quickVersion/$version/bin`)

### Pure Cex Native Setup (`setup.cex`):
Run the setup window using the native Cex runner `cexr setup.cex` to configure environment variables (`CXVM_DIR`, `CEX_HOME`), shell PATH persistence, default runtime versions (`v8.0.0` default and `v6.0.0` LTS), registered apps in `CEX_DIR`, integrated target build directory (`CXVM_DIR/$name-$type/$version/binary`), and project dispatchers:

```bash
# Native Pure Cex Setup Runner (Zero Python, Pure Cex):
cexr setup.cex

# Or via cxvm CLI:
cxvm setup

# Linux / macOS (POSIX wrapper):
bash setup.sh
# Or via curl:
curl -fsSL https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/setup.sh | bash
```

```powershell
# Windows PowerShell
powershell -ExecutionPolicy Bypass -File dist/cxvm.ps1 setup
# Or via CMD batch launcher:
.\downloads\setup.cmd
```

### Web Setup Window (Lighting MVC):
When running the Factory application (`cexr-$type src/index.cex` on port 3080):
- Open **`http://localhost:3080/setup`** in your browser to view the interactive Setup Window.
- Monitor environment variables, PATH persistence, default version status, and live `cxvm doctor` diagnostics.

### Running cxvm with Reserve Target Dispatchers & Integrated Build:
The project toolchain dispatchers resolve via reserve path `CEX_DIR|CEX_HOME.../$name-$quickVersion/$version/bin` using the **exact version of CexR (`1.0.26`)** for `cexr-$type` (`CEX_DIR/cexr-factory/1.0.26/bin`, `CEX_DIR/cexr-bean/1.0.26/bin`) and **v8.0.0** for `cexp-v8` (`CEX_DIR/cexp-v8/8.0.0/bin`):

```bash
# Run using default v8 runtime (cexr-factory, exact version 1.0.26):
$CEX_DIR/cexr-factory/1.0.26/bin src/index.cex

# Build compiles to integrated target build directory: CXVM_DIR/$name-$type/$version/binary
# Target build of cxvm output: CXMV_DIR/cxvm/$version/bin
cxvm build src/index.cex
$CEX_DIR/cexr-bean/1.0.26/bin build src/index.cex -o CXMV_DIR/cxvm/$version/bin

# Run using v6 runtime:
$CEX_DIR/cexr-factory/1.0.26/bin v6 run src/index.cex

# Switch active version across sessions:
cxvm use 8.0.0
cxvm use 6.0.0
```

---

## 4. Cex Version Manager (`cxvm`) CLI (like `nvm`)

| Command | Node.js (`nvm`) Equivalent | Action |
| :--- | :--- | :--- |
| `cxvm setup` | - | Displays cross-platform setup window, configures PATH & env, and links `CEX_DIR/cexr-factory/1.0.26/bin` & `CEX_DIR/cexr-bean/1.0.26/bin` (v8 & v6) |
| `cxvm init [name\|.]` | `npm init` | Initializes default Cex project (`my-project`, custom name, or `.` for current folder) using `cex-pack` (`cex-pack.json`), auto-pulled `.cex_boxes`, `.cvm`, `.cvmignore`, `README.md`, `SECURITY.md`, `LICENSE`, and entrypoint (`src/index.cex`) |
| `cxvm install 8.0.0` | `nvm install 18` | Downloads platform archive and sets up native `cexr-$type` runner |
| `cxvm download 8.0.0 [plat]` | - | Downloads cross-platform bundle into cache for offline `cexr-$type` setup |
| `cxvm download 8.0.0 all` | - | Downloads all 6 cross-platform targets (`linux`, `darwin`, `windows`) into cache to install `cexr-$type` |
| `cxvm use 8.0.0` | `nvm use 18` | Switches active version via symlink & activates `cexr-$type` in PATH |
| `cxvm list` | `nvm ls` | Lists locally installed Cex runtimes and active one |
| `cxvm list-remote` | `nvm ls-remote` | Queries Factory catalog for available upstream releases |
| `cxvm current` | `nvm current` | Prints active Cex runtime version (e.g. `v8.0.0`) |
| `cxvm default 8.0.0` | Configures default Cex version for new shells |
| `cxvm uninstall 2.0.0` | Removes an installed version |
| `cxvm doctor` | - | Runs pre-flight diagnostics for native `cexr-$type`, `cexp-v$shortVersion`, `cvm`, `thunder`, `light`, and host environment (zero C++ dependency) |
| `cxvm dev [target]` | `npm run dev` | Hook calling `cexp --app cexr-factory dev <target>` (short command) |
| `cxvm build [target]` | `npm run build` | Hook calling `cexp --app cexr-bean build <target>` (target build: `CXMV_DIR/cxvm/$version/bin`) |
| `cxvm start [target]` | `npm start` | Hook calling `cexp --app cexr-bean start <target>` (short command) |
| `cexp --app <app> <action>` | - | Direct app dispatcher executing registered binary apps in `CEX_DIR` |
| `cxvm --app lighting create <name>` | `nest new` | Hooks project creation logic in lighting to scaffold new Fullstack MVC project |
| `cxvm --app lighting dev` | `npm run dev` | Starts local Lighting MVC development server on port 3080 |
| `cxvm --app lighting dev --target view` | - | Starts Lighting MVC dev server and opens CexView native window |
| `cxvm --app lighting build` | `npm run build` | Compiles Lighting project with `cexp-v$shortVersion` direct machine compiler |
| `cxvm --app lighting doctor` | - | Runs Lighting engine diagnostic and verification |
| `cxvm open [url] [--target <browser\|view>]` | - | Opens application or URL using CexWebKit browser (default) or CexView native window |
| `cxvm --app thunder <cmd>` | Docker CLI (`docker`) | Run Thunder container operations (`ps`, `run`, `stop`, `images`, `stats`) |
| `cxvm docker <cmd>` | Docker CLI (`docker`) | Docker compatibility alias for Thunder |
| `cxvm start thunder [-p <port>]` | - | Starts Thunder container engine daemon with single process (standalone) |
| `cxvm status thunder` | - | Inspects status of standalone Thunder server |
| `cxvm stop thunder` | - | Stops background standalone Thunder server |

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
   - `cexr-$type` (Cex Language Runtime Engine)
   - `cexp-v$shortVersion` (Cex Direct Machine Compiler)
   - `cvm` (CodeVersionManager Engine & standalone server)
2. **Auto-Start Runtime Services**:
   - Initializes active `cexr-$type` runtime engine
   - Pre-warms `cexp-v$shortVersion` machine compiler
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
| `cxvm --app thunder ps` / `cxvm docker ps` | List running containers with IDs, names, images, ports, and status | `cxvm --app thunder ps` |
| `cxvm --app thunder run <image>` | Run container workload inside virtual microkernel isolation | `cxvm --app thunder run @2tek/cxvm:latest` |
| `cxvm --app thunder stop <id>` | Gracefully stop running container instance | `cxvm --app thunder stop cxt-1a8f9` |
| `cxvm --app thunder images` / `cxvm docker images` | List local OCI container images in cache | `cxvm --app thunder images` |
| `cxvm --app thunder stats` | Inspect real-time virtual CPU, memory, vFS, and network metrics | `cxvm --app thunder stats` |
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
   - `cexr-$type` (Cex Language Runtime Engine)
   - `cexp-v$shortVersion` (Cex Direct Machine Compiler)
   - `cvm` (CodeVersionManager Engine)
   - `thunder` (Thunder Container Engine & Virtual Linux Microkernel)
2. **Auto-Start Runtime Services**:
   - `cexr-$type` runtime engine initialized
   - `cexp-v$shortVersion` direct compiler pre-warmed
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

### Scaffolding New Projects with `cxvm --app lighting create {projectName}`:
To create a new project powered by Lighting Fullstack MVC:
```bash
cxvm --app lighting create my-awesome-app
# Or using the alias:
cxvm --app lighting create my-awesome-app
```

`cxvm` hooks directly into the logic scripts of `lighting` (`bin/light`, `scripts/create.sh`, `create.cex`):
1. **Directory Structure**:

2. **Package Configuration (`cex-pack.json`)**: Configured with `"target": "runtime"` and dependency `@2tek/lighting: "^8.0.0"`.
3. **Application Entrypoint (`src/index.cex`)**: High-throughput Lighting HTTP server pre-configured.

### Running & Building Lighting Applications:
```bash
cd my-awesome-app
cxvm --app lighting dev    # Or ./bin/lighting dev (starts server on port 3080)
cxvm --app lighting build  # Or ./bin/lighting build (compiles native binary via cexp)
cxvm --app lighting doctor # Runs diagnostic health check
```

### Lighting MVC REST Endpoints:
- **`GET /api/v1/light/status`**: Returns Lighting engine readiness, framework version, and available commands.
- **`POST /api/v1/light/create`**: Programmatically triggers project scaffolding via JSON payload `{"projectName": "app-name"}`.

---

## 8. Integrated Target Opener & Window Engine (`cxvm open --target browser||view`)

`cxvm` features built-in target dispatching to open applications or URLs either in a browser viewport or inside a native desktop window:

| Target Option | Engine | Description | Default |
| :--- | :--- | :--- | :--- |
| `--target browser` (`-t browser`) | **CexWebKit** | Standard Cex browser engine rendering web viewports | **Yes (Default)** |
| `--target view` (`-t view`) | **CexView** | Native desktop OS window engine (`800x600`) | No |

### Usage Examples:
```bash
# Open using default CexWebKit browser:
cxvm open
cxvm open http://localhost:3080
cxvm open http://localhost:3080 --target browser

# Open using CexView native desktop window:
cxvm open http://localhost:3080 --target view
cxvm open http://localhost:3080 -t view

# Target aliases in Lighting MVC runners:
cxvm --app lighting dev --target view
cxvm --app lighting dev --target browser
cxvm dev -t view
```

### Interactive Keyboard Shortcuts:
During `cxvm dev` / `cxvm --app lighting dev`
- Press `[o]` or type `open` to open in browser (`cex-webkit`).
- Type `o view` to open in native desktop window (`cex-view`).
- Type `o browser` to switch back to browser.

### REST Endpoints:
- `POST /api/v1/open`: JSON body `{"url": "...", "target": "browser|view"}`.
- `GET /api/v1/target`: Returns supported opener engines (`cex-webkit`, `cex-view`) and default target.

---

## 9. Pre-Built Distribution Artifacts (`cxvm/downloads/`)

The following distribution archives (36 bundles: 6 versions x 6 platforms) and tools are generated into `cxvm/downloads/`:

## 10. Execution & Testing with cexr-$type

```bash
# 1. Switch to cexr-$type Runtime via cxvm
cxvm use 8.0.0
# Or activate cexr-$type via toolchain
cexr-$type use v8

# 2. Run cxvm Demonstration & Server Engine via cexr-$type
cexr-$type src/index.cex
# Or execute canonically via cexr-$type toolchain runner
$CEX_DIR/cexr-factory/$version/bin src/index.cex
# Or load and execute via cexr-$type .cex_boxes dist loader
cexr-$type run cxvm

# 3. Run cxvm Verification Test Suites with cexr-$type
cexr-$type tests/cxvm.test.cex
cexr-$type tests/factory.test.cex
```

---

## 11. Repository & Upstream Git Origin

- **GitHub Repository**: [`https://github.com/2-tek/cxvm`](https://github.com/2-tek/cxvm)
- **Clone Repository**:
  ```bash
  git clone https://github.com/2-tek/cxvm.git
  ```
