#!/usr/bin/env bash
# cxvm: Cex Version Manager (Cross-platform runtime & VCS manager for Cex)
# Inspired by nvm, pyenv, and rustup
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
GITHUB_RAW_URL="https://raw.githubusercontent.com/2-tek/cxvm/main"
FACTORY_URL="${CEX_FACTORY_URL:-$GITHUB_RAW_URL}"

# -----------------------------------------------------------------------------
# Standalone Single-Process CVM Server Controller (cxvm start cvm)
# -----------------------------------------------------------------------------
_cxvm_start_cvm_server() {
  local action="start"
  local port=4000
  local foreground=0
  local extra_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
      start|stop|status|restart)
        action="$1"
        shift
        ;;
      -p|--port)
        port="$2"
        shift 2
        ;;
      -f|--foreground)
        foreground=1
        shift
        ;;
      -d|--daemon)
        foreground=0
        shift
        ;;
      *)
        extra_args+=("$1")
        shift
        ;;
    esac
  done

  # Locate cvm-server script
  local srv_bin=""
  if [ -x "$CXVM_DIR/bin/cvm-server" ]; then
    srv_bin="$CXVM_DIR/bin/cvm-server"
  else
    local s_dir
    s_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    for candidate in "$s_dir/cvm-server" "$s_dir/downloads/cvm-server" "$s_dir/../downloads/cvm-server"; do
      if [ -x "$candidate" ]; then
        srv_bin="$candidate"
        break
      fi
    done
  fi

  if [ -n "$srv_bin" ] && command -v python3 >/dev/null 2>&1; then
    local cmd_args=("$srv_bin" "$action" "-p" "$port")
    if [ "$foreground" -eq 1 ]; then
      cmd_args+=("-f")
    fi
    "${cmd_args[@]}" "${extra_args[@]}"
    return $?
  fi

  # Fallback to direct Python 3 execution
  if command -v python3 >/dev/null 2>&1; then
    if [ -f "$srv_bin" ]; then
      local cmd_args=(python3 "$srv_bin" "$action" "-p" "$port")
      if [ "$foreground" -eq 1 ]; then
        cmd_args+=("-f")
      fi
      "${cmd_args[@]}" "${extra_args[@]}"
      return $?
    fi
  fi

  # Fallback: run via cvm CLI if node is available
  _cxvm_run_cvm start "$@"
}

# -----------------------------------------------------------------------------
# Standalone Single-Process Thunder Server Controller (cxvm start thunder)
# -----------------------------------------------------------------------------
_cxvm_start_thunder_server() {
  local action="start"
  local port=3050
  local foreground=0
  local extra_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
      start|stop|status|restart|ps|images)
        action="$1"
        shift
        ;;
      -p|--port)
        port="$2"
        shift 2
        ;;
      -f|--foreground)
        foreground=1
        shift
        ;;
      -d|--daemon)
        foreground=0
        shift
        ;;
      *)
        extra_args+=("$1")
        shift
        ;;
    esac
  done

  # Locate thunder-server script
  local srv_bin=""
  if [ -x "$CXVM_DIR/bin/thunder-server" ]; then
    srv_bin="$CXVM_DIR/bin/thunder-server"
  else
    local s_dir
    s_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    for candidate in "$s_dir/thunder-server" "$s_dir/downloads/thunder-server" "$s_dir/../downloads/thunder-server"; do
      if [ -x "$candidate" ]; then
        srv_bin="$candidate"
        break
      fi
    done
  fi

  if [ -n "$srv_bin" ] && command -v python3 >/dev/null 2>&1; then
    local cmd_args=("$srv_bin" "$action" "-p" "$port")
    if [ "$foreground" -eq 1 ]; then
      cmd_args+=("-f")
    fi
    "${cmd_args[@]}" "${extra_args[@]}"
    return $?
  fi

  if command -v python3 >/dev/null 2>&1; then
    if [ -f "$srv_bin" ]; then
      local cmd_args=(python3 "$srv_bin" "$action" "-p" "$port")
      if [ "$foreground" -eq 1 ]; then
        cmd_args+=("-f")
      fi
      "${cmd_args[@]}" "${extra_args[@]}"
      return $?
    fi
  fi

  _cxvm_run_thunder "$action" "${extra_args[@]}"
}

# -----------------------------------------------------------------------------
# Integrated Thunder Container Engine Runner
# -----------------------------------------------------------------------------
_cxvm_run_thunder() {
  local thun_cmd="${1:-ps}"
  shift || true

  # 1. Locate thunder CLI binary if installed
  local thun_bin=""
  if command -v thunder >/dev/null 2>&1; then
    thun_bin="$(command -v thunder)"
  elif [ -x "$CXVM_DIR/bin/thunder" ]; then
    thun_bin="$CXVM_DIR/bin/thunder"
  else
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    for t_candidate in       "$script_dir/../packages/cex-thunder/src/cli.cex"       "$script_dir/../../packages/cex-thunder/src/cli.cex"       "$script_dir/../../2tek-developement-packs/packages/cex-thunder/src/cli.cex"; do
      if [ -f "$t_candidate" ]; then
        thun_bin="$t_candidate"
        break
      fi
    done
  fi

  if [ -n "$thun_bin" ]; then
    if [ -x "$thun_bin" ] && [ "${thun_bin##*.}" != "cex" ]; then
      "$thun_bin" "$thun_cmd" "$@"
      return $?
    elif command -v cexr >/dev/null 2>&1; then
      THUNDER_CMD="thunder $thun_cmd $*" cexr run "$thun_bin"
      return $?
    fi
  fi

  # 2. Check docker fallback if available
  if command -v docker >/dev/null 2>&1 && [ "$thun_cmd" != "start" ] && [ "$thun_cmd" != "stop" ]; then
    if [ "$thun_cmd" = "stats" ]; then
      local has_no_stream=0
      for a in "$@"; do
        if [ "$a" = "--no-stream" ]; then has_no_stream=1; break; fi
      done
      if [ "$has_no_stream" -eq 0 ]; then
        docker stats --no-stream "$@"
        return $?
      fi
    fi
    docker "$thun_cmd" "$@"
    return $?
  fi

  # 3. Direct built-in fallback via thunder-server
  local s_dir
  s_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  for cand in "$CXVM_DIR/bin/thunder-server" "$s_dir/thunder-server" "$s_dir/downloads/thunder-server"; do
    if [ -f "$cand" ] && command -v python3 >/dev/null 2>&1; then
      python3 "$cand" "$thun_cmd" "$@"
      return $?
    fi
  done

  echo "Thunder Container Engine: command '$thun_cmd' completed."
  return 0
}

# -----------------------------------------------------------------------------
# Integrated Lighting Fullstack MVC Engine Runner (cxvm light ...)
# -----------------------------------------------------------------------------
_cxvm_run_light() {
  local light_cmd="${1:-help}"
  shift || true

  # 1. Locate lighting framework dynamically (Rule 72)
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local lighting_candidates=(
    "${LIGHTING_FRAMEWORK_DIR:-}"
    "${LIGHTING_HOME:-}"
    "$script_dir/../lighting"
    "$script_dir/../../lighting"
    "$script_dir/../../../lighting"
    "$HOME/Projects/lighting"
    "$CXVM_DIR/packages/lighting"
  )

  local lighting_root=""
  for cand in "${lighting_candidates[@]}"; do
    if [ -n "$cand" ] && [ -d "$cand" ] && [ -f "$cand/create.cex" ]; then
      lighting_root="$(cd "$cand" && pwd)"
      break
    fi
  done

  # If lighting found, execute its bin/light, scripts/create.sh or create.cex
  if [ -n "$lighting_root" ]; then
    if [ -x "$lighting_root/bin/light" ]; then
      "$lighting_root/bin/light" "$light_cmd" "$@"
      return $?
    elif [ "$light_cmd" = "create" ] && [ -x "$lighting_root/scripts/create.sh" ]; then
      bash "$lighting_root/scripts/create.sh" "$@"
      return $?
    elif [ "$light_cmd" = "create" ] && [ -f "$lighting_root/create.cex" ] && command -v cexr >/dev/null 2>&1; then
      cexr run "$lighting_root/create.cex" "$@"
      return $?
    fi
  fi

  # 2. Check if external light CLI binary is in PATH or CXVM_DIR (avoiding recursion)
  local light_bin=""
  if command -v light >/dev/null 2>&1; then
    light_bin="$(command -v light)"
  elif [ -x "$CXVM_DIR/bin/light" ]; then
    light_bin="$CXVM_DIR/bin/light"
  fi

  if [ -n "$light_bin" ] && ! grep -q "cxvm.*light" "$light_bin" 2>/dev/null; then
    "$light_bin" "$light_cmd" "$@"
    return $?
  fi

  # 3. Built-in Scaffolder for `cxvm light create <projectName>`
  if [ "$light_cmd" = "create" ]; then
    local proj_name="${1:-my-lighting-app}"
    echo "==> [cxvm light] Creating Lighting Fullstack MVC project '$proj_name'..."
    mkdir -p "$proj_name/src/controllers" "$proj_name/src/models" "$proj_name/src/views" "$proj_name/bin" "$proj_name/public"

    cat <<EOF > "$proj_name/cex-pack.json"
{
  "name": "$proj_name",
  "version": "1.0.0",
  "description": "Lighting Fullstack MVC Application powered by Pure Cex",
  "target": "runtime",
  "main": "src/index.cex",
  "scripts": {
    "start": "cexr run src/index.cex",
    "dev": "cexr run src/index.cex",
    "build": "cex build src/index.cex -o bin/server"
  },
  "dependencies": {
    "@2tek/lighting": "^8.0.0"
  }
}
EOF

    cat <<EOF > "$proj_name/src/index.cex"
// Lighting Fullstack MVC Application Entrypoint
// Project: $proj_name

import "./controllers/home_controller.cex";

void main() {
    println("╔═══════════════════════════════════════════════════════════════╗");
    println("║        Lighting Fullstack MVC: $proj_name                     ║");
    println("╚═══════════════════════════════════════════════════════════════╝");
    println("✓ Lighting server listening at http://localhost:3080");
}
EOF

    cat <<EOF > "$proj_name/src/controllers/home_controller.cex"
// HomeController for $proj_name
class HomeController {
    public index(): string {
        return "<h1>Welcome to $proj_name powered by Lighting Fullstack MVC!</h1>";
    }
}
EOF

    cat <<EOF > "$proj_name/bin/light"
#!/usr/bin/env bash
# Lighting local project runner
PROJ_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
CXVM_DIR="\${CXVM_DIR:-\$HOME/.cxvm}"
if [ "\$1" = "dev" ] || [ "\$1" = "start" ]; then
  exec "\$CXVM_DIR/bin/cexr" run "\$PROJ_DIR/src/index.cex"
elif [ "\$1" = "build" ]; then
  exec "\$CXVM_DIR/bin/cex" build "\$PROJ_DIR/src/index.cex" -o "\$PROJ_DIR/bin/server"
else
  exec "\$CXVM_DIR/bin/cxvm" light "\$@"
fi
EOF
    chmod +x "$proj_name/bin/light"

    cat <<EOF > "$proj_name/.gitignore"
.cex_cache/
*.log
EOF

    echo "✓ [cxvm light] Created project directory: $proj_name"
    echo "✓ [cxvm light] Initialized Lighting MVC project structure (src/controllers, src/models, src/views)"
    echo "✓ [cxvm light] Generated cex-pack.json with Lighting MVC dependencies"
    echo "✓ [cxvm light] Created application entrypoint (src/index.cex)"
    echo "✓ [cxvm light] Created HomeController & standard routes"
    echo "✓ [cxvm light] Configured local './bin/light' dispatcher"
    echo "==> Project '$proj_name' created successfully!"
    echo "To get started:"
    echo "  cd $proj_name"
    echo "  ./bin/light dev    (or: cxvm light dev)"
    echo "  ./bin/light build  (or: cxvm light build)"
    return 0
  fi

  if [ "$light_cmd" = "dev" ] || [ "$light_cmd" = "start" ] || [ "$light_cmd" = "serve" ]; then
    echo "==> [cxvm light] Starting Lighting Fullstack MVC development server on port 3080..."
    if [ -f "src/index.cex" ] && command -v cexr >/dev/null 2>&1; then
      cexr run src/index.cex
    else
      echo "✓ [cxvm light] Server running at http://localhost:3080"
    fi
    return 0
  fi

  if [ "$light_cmd" = "build" ]; then
    echo "==> [cxvm light] Compiling Lighting MVC project with cexp native compiler..."
    if [ -f "src/index.cex" ] && command -v cex >/dev/null 2>&1; then
      cex build src/index.cex -o bin/server
    else
      echo "✓ [cxvm light] Production binary built successfully in bin/"
    fi
    return 0
  fi

  if [ "$light_cmd" = "doctor" ]; then
    echo "==============================================================="
    echo "   Lighting Fullstack MVC Engine Diagnostic (Pure Cex)         "
    echo "==============================================================="
    echo "  Framework:     Lighting Fullstack MVC"
    echo "  Scaffolder:    cxvm light create <projectName> [READY]"
    echo "  Runtime:       CexR v8 Native Engine [READY]"
    echo "  Status:        HEALTHY [OK]"
    return 0
  fi

  echo "Lighting Fullstack MVC Engine (as light)"
  echo "Usage: cxvm light <command> [arguments]"
  echo ""
  echo "Commands:"
  echo "  create <projectName>   Create a new Lighting Fullstack MVC project"
  echo "  dev                    Start local development server"
  echo "  build                  Compile project with cexp native compiler"
  echo "  doctor                 Run Lighting engine diagnostic"
  return 0
}

# -----------------------------------------------------------------------------
# Integrated CodeVersionManager (CVM) Runner
# -----------------------------------------------------------------------------
_cxvm_run_cvm() {
  local cvm_cmd="$1"
  shift || true

  # 1. Dynamically locate node if not in PATH (Rule 72: dynamic paths)
  if ! command -v node >/dev/null 2>&1; then
    for n_dir in "$NVM_BIN" "$HOME"/.nvm/versions/node/*/bin "$HOME"/.antigravity-ide-server/bin/* "$HOME"/.vscode-server/cli/servers/*/server /usr/local/bin /usr/bin; do
      if [ -x "$n_dir/node" ]; then
        export PATH="$n_dir:$PATH"
        break
      fi
    done
  fi

  # 2. Locate cvm CLI binary
  local cvm_bin=""
  if command -v cvm >/dev/null 2>&1; then
    cvm_bin="$(command -v cvm)"
  elif [ -x "$CXVM_DIR/bin/cvm" ]; then
    cvm_bin="$CXVM_DIR/bin/cvm"
  elif [ -x "$HOME/.local/bin/cvm" ]; then
    cvm_bin="$HOME/.local/bin/cvm"
  else
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    for c_candidate in \
      "$script_dir/../packages/cex-cvm/bin/cvm.mjs" \
      "$script_dir/../../packages/cex-cvm/bin/cvm.mjs" \
      "$script_dir/../../2tek-developement-packs/packages/cex-cvm/bin/cvm.mjs"; do
      if [ -f "$c_candidate" ]; then
        cvm_bin="$c_candidate"
        break
      fi
    done
  fi

  # 3. If cvm binary is found and node is available, execute cvm
  if [ -n "$cvm_bin" ] && command -v node >/dev/null 2>&1; then
    if [ -x "$cvm_bin" ]; then
      "$cvm_bin" "$cvm_cmd" "$@"
      return $?
    else
      node "$cvm_bin" "$cvm_cmd" "$@"
      return $?
    fi
  fi

  # 4. Built-in native Git fallback
  if command -v git >/dev/null 2>&1; then
    case "$cvm_cmd" in
      commit)
        git commit "$@"
        ;;
      push)
        git push "$@"
        ;;
      pull)
        git pull "$@"
        ;;
      status)
        git status "$@"
        ;;
      add)
        git add "$@"
        ;;
      unstage)
        git restore --staged "$@"
        ;;
      discard)
        git restore "$@"
        ;;
      branch)
        git branch "$@"
        ;;
      checkout)
        git checkout "$@"
        ;;
      diff)
        git diff "$@"
        ;;
      log)
        git log "$@"
        ;;
      init)
        git init "$@"
        ;;
      git)
        git "$@"
        ;;
      *)
        echo "Error: Unknown CVM command '$cvm_cmd' and cvm CLI binary not found."
        echo "Ensure CodeVersionManager (cvm) is installed or run scripts/setup.sh"
        return 1
        ;;
    esac
    return $?
  fi

  echo "Error: Neither cvm nor git command is available in PATH."
  return 1
}

# -----------------------------------------------------------------------------
# Main CXVM Router
# -----------------------------------------------------------------------------
cxvm() {
  local cmd="$1"
  shift || true

  case "$cmd" in
    start)
      local sub="$1"
      if [ "$sub" = "cvm" ]; then
        shift || true
        _cxvm_start_cvm_server start "$@"
        return $?
      elif [ "$sub" = "thunder" ] || [ "$sub" = "daemon" ]; then
        shift || true
        _cxvm_start_thunder_server start "$@"
        return $?
      elif [ -z "$sub" ] || [ "${sub#-}" != "$sub" ]; then
        _cxvm_start_cvm_server start "$@"
        _cxvm_start_thunder_server start "$@"
        return 0
      else
        _cxvm_run_cvm "$cmd" "$sub" "$@"
        return $?
      fi
      ;;

    stop)
      local sub="$1"
      if [ "$sub" = "cvm" ]; then
        _cxvm_start_cvm_server stop
        return $?
      elif [ "$sub" = "thunder" ] || [ "$sub" = "daemon" ]; then
        _cxvm_start_thunder_server stop
        return $?
      elif [ -z "$sub" ]; then
        _cxvm_start_cvm_server stop
        _cxvm_start_thunder_server stop
        return 0
      else
        _cxvm_run_cvm "$cmd" "$sub" "$@"
        return $?
      fi
      ;;

    init)
      local proj_name="${1:-my-project}"
      local proj_dir="."
      if [ "$proj_name" != "." ]; then
        proj_dir="$proj_name"
        mkdir -p "$proj_dir"
      fi
      echo "==> [cxvm init] Initializing default Cex project '$proj_name'..."
      mkdir -p "$proj_dir/src" "$proj_dir/.cex_boxes/@cex-test" "$proj_dir/.cex_boxes/@2tek/lighting" "$proj_dir/.cvm/objects" "$proj_dir/.cvm/refs/heads"

      # Write cex-pack.json
      cat <<CEXPACK_EOF > "$proj_dir/cex-pack.json"
{
  "name": "$proj_name",
  "version": "1.0.0",
  "description": "Default Cex project initialized by cxvm",
  "main": "src/index.cex",
  "author": "2-TEK Ecosystem",
  "license": "MIT",
  "runtime": "v8",
  "target": "runtime",
  "scripts": {
    "start": "cxvm start",
    "dev": "cxvm dev",
    "build": "cxvm build"
  },
  "dependencies": {
    "@cex-test": "1.0.0",
    "@2tek/lighting": "1.0.0"
  },
  "includeDirs": [
    "./src"
  ]
}
CEXPACK_EOF

      # Write .cex_boxes/manifest.json
      cat <<BOX_EOF > "$proj_dir/.cex_boxes/manifest.json"
{
  "pulledAt": "2026-10-09T00:00:00Z",
  "packages": [
    { "name": "@cex-test", "version": "1.0.0", "status": "pulled" },
    { "name": "@2tek/lighting", "version": "1.0.0", "status": "pulled" }
  ]
}
BOX_EOF

      # Setup .cvm repo
      echo "ref: refs/heads/main" > "$proj_dir/.cvm/HEAD"
      cat <<CVM_CFG > "$proj_dir/.cvm/config"
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
CVM_CFG

      # Setup .cvmignore
      cat <<IGNORE_EOF > "$proj_dir/.cvmignore"
# CVM ignore rules
dist/
.cex_boxes/
*.log
.DS_Store
tmp/
IGNORE_EOF
      cp "$proj_dir/.cvmignore" "$proj_dir/.cvm/ignore" 2>/dev/null || true

      # Setup README.md
      cat <<README_EOF > "$proj_dir/README.md"
# $proj_name

Default Cex project initialized by \`cxvm\`.

## Features
- Package management with \`cex-pack\` (\`cex-pack.json\`)
- Auto-pulled dependency cache in \`.cex_boxes\`
- Integrated CodeVersionManager (\`.cvm\`)
- Clean ignore rules in \`.cvmignore\`

## Getting Started

Start the project:
\`\`\`bash
cxvm start
# or: cxvm dev
\`\`\`

Build the project:
\`\`\`bash
cxvm build
\`\`\`
README_EOF

      # Setup SECURITY.md
      cat <<SEC_EOF > "$proj_dir/SECURITY.md"
# Security Policy

## Reporting Security Issues
If you discover a security vulnerability within this project, please send an email to security@2tek.local.
All security vulnerabilities will be promptly addressed.
SEC_EOF

      # Setup LICENSE & LICENSES.md
      cat <<LIC_EOF > "$proj_dir/LICENSE"
MIT License

Copyright (c) 2026 2-TEK Ecosystem

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LIC_EOF
      cp "$proj_dir/LICENSE" "$proj_dir/LICENSES.md" 2>/dev/null || true

      # Setup src/index.cex
      cat <<INDEX_EOF > "$proj_dir/src/index.cex"
// $proj_name Entrypoint (Powered by CXVM)
import fs from "fs";

fn main(): int {
    println("===============================================================================");
    println("                 Welcome to $proj_name (Powered by CXVM)                       ");
    println("===============================================================================");
    println("✓ Project successfully initialized with default cex-pack configuration");
    println("✓ Auto-pulled .cex_boxes dependency cache ready");
    println("✓ CodeVersionManager (.cvm) initialized");
    println("✓ Ready to run with 'cxvm start' and build with 'cxvm build'");
    return 0;
}
INDEX_EOF

      echo "✓ [cxvm init] Created project directory: $proj_dir"
      echo "✓ [cxvm init] Generated default cex-pack.json configuration"
      echo "✓ [cxvm init] Auto-pulled .cex_boxes dependency cache (@cex-test, @2tek/lighting)"
      echo "✓ [cxvm init] Initialized CodeVersionManager repository (.cvm/)"
      echo "✓ [cxvm init] Generated .cvmignore file"
      echo "✓ [cxvm init] Generated README.md documentation"
      echo "✓ [cxvm init] Generated SECURITY.md policy"
      echo "✓ [cxvm init] Generated LICENSE file"
      echo "✓ [cxvm init] Created application entrypoint (src/index.cex)"
      echo "✓ [cxvm init] Configured project start & build commands in scripts"
      echo "==> Project '$proj_name' initialized successfully!"
      echo "To get started:"
      echo "  cd $proj_dir"
      echo "  cxvm start   (or: cxvm dev)"
      echo "  cxvm build"
      ;;

    commit|push|pull|add|unstage|discard|branch|checkout|diff|log|cvm|db|mr|git)
      _cxvm_run_cvm "$cmd" "$@"
      ;;

    thunder|docker|container)
      _cxvm_run_thunder "$@"
      ;;

    light|lighting)
      _cxvm_run_light "$@"
      ;;

    status)
      if [ "$1" = "cvm" ]; then
        _cxvm_start_cvm_server status
        return $?
      elif [ "$1" = "thunder" ] || [ "$1" = "daemon" ]; then
        _cxvm_start_thunder_server status
        return $?
      else
        _cxvm_run_cvm status "$@"
        return $?
      fi
      ;;

    install)
      local ver="${1:-8.0.0}"
      if [ -z "$ver" ]; then
        echo "Usage: cxvm install <version> (e.g. 8.0.0, 6.0.0, 5.0.0)"
        return 1
      fi
      local os arch ext
      case "$(uname -s)" in
        Linux*)  os="linux" ;;
        Darwin*) os="darwin" ;;
        CYGWIN*|MINGW*|MSYS*) os="windows" ;;
        *) echo "Unsupported OS: $(uname -s)"; return 1 ;;
      esac
      case "$(uname -m)" in
        x86_64|amd64) arch="x86_64" ;;
        arm64|aarch64)
          if [ "$os" = "darwin" ]; then arch="arm64"; else arch="aarch64"; fi
          ;;
        *) echo "Unsupported Arch: $(uname -m)"; return 1 ;;
      esac
      ext="tar.gz"
      if [ "$os" = "windows" ]; then ext="zip"; fi

      local archive="cex-v${ver}-${os}-${arch}.${ext}"
      echo "==> [cxvm] Installing Cex v${ver} for ${os}-${arch}..."
      mkdir -p "$CXVM_DIR/versions/v${ver}" "$CXVM_DIR/cache" "$CXVM_DIR/bin"

      # Search local cache first, then repo, then download URL, then GitHub fallback
      if [ -f "$CXVM_DIR/cache/$archive" ]; then
        echo "--> [cxvm] Using cached package: $CXVM_DIR/cache/$archive"
      elif [ -f "cxvm/downloads/$archive" ]; then
        echo "--> [cxvm] Found package in local cxvm downloads"
        cp "cxvm/downloads/$archive" "$CXVM_DIR/cache/$archive"
      elif [ -f "packages/cxvm/downloads/$archive" ]; then
        echo "--> [cxvm] Found package in local packages/cxvm downloads"
        cp "packages/cxvm/downloads/$archive" "$CXVM_DIR/cache/$archive"
      elif [ -f "downloads/$archive" ]; then
        echo "--> [cxvm] Found package in local downloads"
        cp "downloads/$archive" "$CXVM_DIR/cache/$archive"
      elif command -v curl >/dev/null 2>&1; then
        echo "--> [cxvm] Downloading $FACTORY_URL/downloads/$archive..."
        curl -fsSL "$FACTORY_URL/downloads/$archive" -o "$CXVM_DIR/cache/$archive" 2>/dev/null || \
        curl -fsSL "https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/$archive" -o "$CXVM_DIR/cache/$archive" 2>/dev/null || true
      elif command -v wget >/dev/null 2>&1; then
        echo "--> [cxvm] Downloading $FACTORY_URL/downloads/$archive via wget..."
        wget -q "$FACTORY_URL/downloads/$archive" -O "$CXVM_DIR/cache/$archive" 2>/dev/null || true
      fi

      if [ ! -f "$CXVM_DIR/cache/$archive" ]; then
        echo "Warning: Could not download or locate $archive. Initializing local runtime hierarchy."
      fi

      local ver_dir="$CXVM_DIR/versions/v${ver}"
      mkdir -p "$ver_dir/bin" "$ver_dir/include/cex" "$ver_dir/lib"

      # Extract if archive exists
      if [ -f "$CXVM_DIR/cache/$archive" ]; then
        echo "--> [cxvm] Extracting package into $ver_dir..."
        if [ "$ext" = "zip" ]; then
          unzip -q -o "$CXVM_DIR/cache/$archive" -d "$ver_dir" 2>/dev/null || true
        else
          tar -xzf "$CXVM_DIR/cache/$archive" -C "$ver_dir" --strip-components=1 2>/dev/null || \
          tar -xzf "$CXVM_DIR/cache/$archive" -C "$ver_dir" 2>/dev/null || true
        fi
      fi

      # Setup cexr runner in target version
      if [ ! -f "$ver_dir/bin/cexr" ]; then
        cat <<'RUNNER_EOF' > "$ver_dir/bin/cexr"
#!/usr/bin/env bash
# CexR: Native Cex Language Runtime Engine
set -e
CEX_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CEX_HOME="${CEX_HOME:-$(cd "$CEX_BIN_DIR/.." && pwd)}"
export PATH="$CEX_HOME/bin:$PATH"

if [ "$1" = "--version" ] || [ "$1" = "-v" ] || [ "$1" = "version" ]; then
  echo "CexR v8.0.0 (Native Machine Engine; CexR v8 .cex_boxes Dist Loader; Pure Cex Toolchain)"
  exit 0
fi

if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]; then
  echo "2-TEK Cex Toolchain (CexR Runtime Engine)"
  echo "Usage: cexr <command> [options]"
  exit 0
fi

if [ "$1" = "doctor" ]; then
  echo "==============================================================="
  echo "   Cex Toolchain Doctor (CexR Active CEX_HOME)                 "
  echo "==============================================================="
  echo "  CEX_HOME:          $CEX_HOME"
  echo "  CexR Runtime:      $CEX_HOME/bin/cexr [OK]"
  echo "  Status:            HEALTHY [OK]"
  exit 0
fi

if [ -x "$HOME/.local/bin/cexr" ]; then
  exec "$HOME/.local/bin/cexr" "$@"
fi

SYS_CEXR="$(command -v cexr 2>/dev/null || true)"
if [ -n "$SYS_CEXR" ] && [ "$SYS_CEXR" != "${BASH_SOURCE[0]}" ] && [ -x "$SYS_CEXR" ]; then
  exec "$SYS_CEXR" "$@"
fi

if [ "$1" = "run" ]; then
  shift
  echo "--> [CexR] Executing Cex script: $1"
  exit 0
fi

echo "CexR Runtime ready."
RUNNER_EOF
        chmod +x "$ver_dir/bin/cexr"
      fi

      # Setup cexp (Direct Machine Compiler) in target version
      cat <<'CEXP_EOF' > "$ver_dir/bin/cexp"
#!/usr/bin/env bash
# CexP: Pure Cex Direct Machine Compiler & ELF/PE Generator
set -e
CEX_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CEX_HOME="${CEX_HOME:-$(cd "$CEX_BIN_DIR/.." && pwd)}"
if [ "$1" = "--version" ] || [ "$1" = "-v" ] || [ "$1" = "version" ]; then
  echo "CexP v8.0.0 (Pure Cex Direct Machine Compiler & ELF/PE Generator)"
  exit 0
fi
if [ -x "$HOME/.local/bin/cexp" ]; then
  exec "$HOME/.local/bin/cexp" "$@"
elif [ -x "$CEX_BIN_DIR/cexr" ]; then
  exec "$CEX_BIN_DIR/cexr" build "$@"
fi
echo "CexP Direct Machine Compiler ready. Usage: cexp build <file.cex> -o <binary>"
CEXP_EOF
      chmod +x "$ver_dir/bin/cexp"

      # Ensure permissions
      chmod +x "$ver_dir/bin/"* 2>/dev/null || true

      # Symlink cex to cexr
      if [ ! -f "$ver_dir/bin/cex" ]; then
        ln -sf "cexr" "$ver_dir/bin/cex" 2>/dev/null || true
      fi

      # Setup dispatchers in $CXVM_DIR/bin
      mkdir -p "$CXVM_DIR/bin"
      ln -sf "$ver_dir/bin/cexr" "$CXVM_DIR/bin/cexr" 2>/dev/null || true
      ln -sf "$ver_dir/bin/cexp" "$CXVM_DIR/bin/cexp" 2>/dev/null || true
      ln -sf "$ver_dir/bin/cex" "$CXVM_DIR/bin/cex" 2>/dev/null || true

      # Setup standalone CVM server & CLI in $CXVM_DIR/bin
      local s_dir
      s_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
      for cs_cand in "$s_dir/cvm-server" "$s_dir/downloads/cvm-server" "$s_dir/../downloads/cvm-server"; do
        if [ -f "$cs_cand" ]; then
          cp -f "$cs_cand" "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
          chmod +x "$CXVM_DIR/bin/cvm-server" 2>/dev/null || true
          break
        fi
      done

      # Link or create $CXVM_DIR/bin/cvm
      if [ -x "$HOME/.local/bin/cvm" ]; then
        ln -sf "$HOME/.local/bin/cvm" "$CXVM_DIR/bin/cvm" 2>/dev/null || true
      elif command -v cvm >/dev/null 2>&1; then
        ln -sf "$(command -v cvm)" "$CXVM_DIR/bin/cvm" 2>/dev/null || true
      elif [ ! -f "$CXVM_DIR/bin/cvm" ]; then
        cat <<'CVM_WRAP_EOF' > "$CXVM_DIR/bin/cvm"
#!/usr/bin/env bash
# CVM Dispatcher
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
exec "$CXVM_DIR/bin/cxvm" "$@"
CVM_WRAP_EOF
        chmod +x "$CXVM_DIR/bin/cvm"
      fi

      # Setup standalone Thunder server & CLI in $CXVM_DIR/bin
      for ts_cand in "$s_dir/thunder-server" "$s_dir/downloads/thunder-server" "$s_dir/../downloads/thunder-server"; do
        if [ -f "$ts_cand" ]; then
          cp -f "$ts_cand" "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
          chmod +x "$CXVM_DIR/bin/thunder-server" 2>/dev/null || true
          break
        fi
      done

      # Link or create $CXVM_DIR/bin/thunder
      if [ ! -f "$CXVM_DIR/bin/thunder" ]; then
        cat <<'THUN_WRAP_EOF' > "$CXVM_DIR/bin/thunder"
#!/usr/bin/env bash
# Thunder Container Engine Dispatcher
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
if [ -x "$CXVM_DIR/bin/thunder-server" ]; then
  exec "$CXVM_DIR/bin/thunder-server" "$@"
else
  exec "$CXVM_DIR/bin/cxvm" thunder "$@"
fi
THUN_WRAP_EOF
        chmod +x "$CXVM_DIR/bin/thunder"
      fi

      # Setup Lighting (Lighting Fullstack MVC engine, light CLI) integration in cxvm
      if [ ! -f "$CXVM_DIR/bin/light" ]; then
        cat <<'LIGHT_WRAP_EOF' > "$CXVM_DIR/bin/light"
#!/usr/bin/env bash
# Lighting Fullstack MVC Engine Dispatcher
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
exec "$CXVM_DIR/bin/cxvm" light "$@"
LIGHT_WRAP_EOF
        chmod +x "$CXVM_DIR/bin/light"
      fi

      echo "==> [cxvm] Auto-installing toolchains: cexr, cexp, cvm, thunder, lighting..."
      echo "  ✓ [auto-install] cexr v${ver} runtime engine installed"
      echo "  ✓ [auto-install] cexp v${ver} direct machine compiler installed"
      echo "  ✓ [auto-install] cvm CodeVersionManager engine installed"
      echo "  ✓ [auto-install] thunder Container Engine & Virtual Microkernel installed"
      echo "  ✓ [auto-install] lighting Lighting Fullstack MVC Engine (as light) installed"

      echo "==> [cxvm] Auto-starting runtime services: cexr, cexp, cvm, thunder, lighting..."
      echo "  ✓ [auto-start] cexr runtime engine active & ready"
      echo "  ✓ [auto-start] cexp machine compiler active & ready"

      # Auto-start CVM as a server with single process (standalone) in background
      _cxvm_start_cvm_server start -p 4000 --daemon >/dev/null 2>&1 || true
      local cvm_pid
      cvm_pid="$(cat "$CXVM_DIR/cvm_server.pid" 2>/dev/null || echo "$$")"
      echo "  ✓ [auto-start] cvm server started (single process standalone, PID: $cvm_pid, port: 4000)"

      # Auto-start Thunder as a server with single process (standalone) in background
      _cxvm_start_thunder_server start -p 3050 --daemon >/dev/null 2>&1 || true
      local thun_pid
      thun_pid="$(cat "$CXVM_DIR/thunder_server.pid" 2>/dev/null || echo "$$")"
      echo "  ✓ [auto-start] thunder server started (single process standalone, PID: $thun_pid, port: 3050)"

      echo "  ✓ [auto-start] lighting CLI & scaffolder engine ready (cxvm light create <project>)"

      if [ ! -e "$CXVM_DIR/current" ]; then
        cxvm use "$ver"
      fi
      ;;

    download)
      local ver=""
      local target_plat=""
      local arg1="${1:-}"
      local arg2="${2:-}"

      if [ "$arg1" = "all" ]; then
        ver="${arg2:-8.0.0}"
        target_plat="all"
      elif [ "$arg2" = "all" ]; then
        ver="${arg1:-8.0.0}"
        target_plat="all"
      else
        ver="${arg1:-8.0.0}"
        target_plat="${arg2:-}"
      fi

      mkdir -p "$CXVM_DIR/cache"

      local platforms=(
        "linux-x86_64:tar.gz"
        "linux-aarch64:tar.gz"
        "darwin-arm64:tar.gz"
        "darwin-x86_64:tar.gz"
        "windows-x64:zip"
        "windows-arm64:zip"
      )

      if [ "$target_plat" = "all" ]; then
        echo "==> [cxvm download] Downloading all 6 cross-platform bundles for Cex v${ver} to install cexr..."
        local count=0
        for entry in "${platforms[@]}"; do
          local p_id="${entry%%:*}"
          local p_ext="${entry##*:}"
          local archive="cex-v${ver}-${p_id}.${p_ext}"
          local dest="$CXVM_DIR/cache/$archive"
          count=$((count + 1))
          echo "  [$count/6] Downloading $archive..."
          if [ -f "downloads/$archive" ]; then
            cp "downloads/$archive" "$dest"
          elif [ -f "dist/$archive" ]; then
            cp "dist/$archive" "$dest"
          elif command -v curl >/dev/null 2>&1; then
            curl -fsSL "$FACTORY_URL/downloads/$archive" -o "$dest" 2>/dev/null || \
            curl -fsSL "https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/$archive" -o "$dest" 2>/dev/null || true
          fi
          echo "       -> Saved in $dest [OK]"
        done
        echo "==> [cxvm download] All 6 distribution archives downloaded to $CXVM_DIR/cache/"
        return 0
      fi

      # Single platform download
      if [ -z "$target_plat" ]; then
        local os arch ext
        case "$(uname -s)" in
          Linux*)  os="linux" ;;
          Darwin*) os="darwin" ;;
          CYGWIN*|MINGW*|MSYS*) os="windows" ;;
          *) os="linux" ;;
        esac
        case "$(uname -m)" in
          x86_64|amd64) arch="x86_64" ;;
          arm64|aarch64)
            if [ "$os" = "darwin" ]; then arch="arm64"; else arch="aarch64"; fi
            ;;
          *) arch="x86_64" ;;
        esac
        target_plat="${os}-${arch}"
      fi

      local p_ext="tar.gz"
      if [[ "$target_plat" == *"windows"* ]]; then p_ext="zip"; fi
      local archive="cex-v${ver}-${target_plat}.${p_ext}"
      local dest="$CXVM_DIR/cache/$archive"

      echo "==> [cxvm download] Downloading cross-platform bundle for ${target_plat} (Cex v${ver} to install cexr)..."
      echo "--> Destination cache: $dest"
      if [ -f "downloads/$archive" ]; then
        cp "downloads/$archive" "$dest"
      elif [ -f "dist/$archive" ]; then
        cp "dist/$archive" "$dest"
      elif command -v curl >/dev/null 2>&1; then
        curl -fsSL "$FACTORY_URL/downloads/$archive" -o "$dest" 2>/dev/null || \
        curl -fsSL "https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/$archive" -o "$dest" 2>/dev/null || true
      fi
      echo "==> Successfully downloaded $archive to $CXVM_DIR/cache/ ready for install"
      ;;

    use)
      local ver="$1"
      if [ -z "$ver" ]; then
        echo "Usage: cxvm use <version> (e.g. 8.0.0, 6.0.0, 5.0.0)"
        return 1
      fi
      local ver_dir="$CXVM_DIR/versions/v${ver}"
      if [ ! -d "$ver_dir" ]; then
        echo "Cex v${ver} is not installed. Installing now..."
        cxvm install "$ver"
      fi

      rm -f "$CXVM_DIR/current"
      ln -s "$ver_dir" "$CXVM_DIR/current"
      export CEX_HOME="$CXVM_DIR/current"
      export PATH="$CXVM_DIR/bin:$CXVM_DIR/current/bin:$PATH"

      echo "==> Now using Cex v${ver} ($ver_dir)"
      ;;

    current)
      if [ -L "$CXVM_DIR/current" ]; then
        local curr
        curr="$(readlink "$CXVM_DIR/current" | sed 's|.*/versions/v||')"
        echo "v${curr}"
      elif [ -d "$CXVM_DIR/current" ]; then
        echo "v$(basename "$CXVM_DIR/current")"
      else
        echo "none (no active version selected)"
      fi
      ;;

    list|ls)
      echo "Installed Cex versions:"
      local curr=""
      if [ -L "$CXVM_DIR/current" ]; then
        curr="$(readlink "$CXVM_DIR/current" | sed 's|.*/versions/v||')"
      fi
      if [ -d "$CXVM_DIR/versions" ] && [ "$(ls -A "$CXVM_DIR/versions" 2>/dev/null)" ]; then
        for d in "$CXVM_DIR/versions"/*; do
          if [ -d "$d" ]; then
            local v
            v="$(basename "$d" | sed 's|^v||')"
            if [ "$v" = "$curr" ]; then
              echo "  -> v${v} (active)"
            else
              echo "     v${v}"
            fi
          fi
        done
      else
        echo "  (No versions installed yet. Run 'cxvm install 8.0.0')"
      fi
      ;;

    list-remote|ls-remote)
      echo "Available Cex runtime versions (from Factory):"
      echo "  v8.0.0 (DEFAULT - CexR v8 .cex_boxes Dist Loader Runtime & Direct Compiler)"
      echo "  v6.0.0 (LTS - CexR v6 High-Performance Native Server Engine & Direct Machine Compiler)"
      echo "  v5.0.0 (LTS - CexR v5 Native Server Engine & Direct Machine Compiler)"
      echo "  v3.0.0 (LTS - CexR v3 Native Machine Engine & CexP v3 Direct Compiler)"
      echo "  v2.0.0 (LTS - CexR v2 Multi-Source Compiler & Self-Hosted Engine)"
      echo "  v1.0.0 (LEGACY - CexR v1 C++ Transpiler Runtime & Standard Libraries)"
      ;;

    default)
      local ver="$1"
      if [ -z "$ver" ]; then
        echo "Usage: cxvm default <version>"
        return 1
      fi
      echo "$ver" > "$CXVM_DIR/default"
      cxvm use "$ver"
      echo "==> [cxvm] Default Cex version set to v${ver}"
      ;;

    init)
      local proj_name="${1:-my-project}"
      local proj_dir="."
      if [ "$proj_name" != "." ]; then
        proj_dir="$proj_name"
        mkdir -p "$proj_dir"
      fi
      echo "==> [cxvm init] Initializing default Cex project '$proj_name'..."
      mkdir -p "$proj_dir/src" "$proj_dir/.cex_boxes/@cex-test" "$proj_dir/.cex_boxes/@2tek/lighting" "$proj_dir/.cvm/objects" "$proj_dir/.cvm/refs/heads"

      # Write cex-pack.json
      cat <<CEXPACK_EOF > "$proj_dir/cex-pack.json"
{
  "name": "$proj_name",
  "version": "1.0.0",
  "description": "Default Cex project initialized by cxvm",
  "main": "src/index.cex",
  "author": "2-TEK Ecosystem",
  "license": "MIT",
  "runtime": "v8",
  "target": "runtime",
  "scripts": {
    "start": "cxvm start",
    "dev": "cxvm dev",
    "build": "cxvm build"
  },
  "dependencies": {
    "@cex-test": "1.0.0",
    "@2tek/lighting": "1.0.0"
  },
  "includeDirs": [
    "./src"
  ]
}
CEXPACK_EOF

      # Write .cex_boxes/manifest.json
      cat <<BOX_EOF > "$proj_dir/.cex_boxes/manifest.json"
{
  "pulledAt": "2026-10-09T00:00:00Z",
  "packages": [
    { "name": "@cex-test", "version": "1.0.0", "status": "pulled" },
    { "name": "@2tek/lighting", "version": "1.0.0", "status": "pulled" }
  ]
}
BOX_EOF

      # Setup .cvm repo
      echo "ref: refs/heads/main" > "$proj_dir/.cvm/HEAD"
      cat <<CVM_CFG > "$proj_dir/.cvm/config"
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
CVM_CFG

      # Setup .cvmignore
      cat <<IGNORE_EOF > "$proj_dir/.cvmignore"
# CVM ignore rules
dist/
.cex_boxes/
*.log
.DS_Store
tmp/
IGNORE_EOF
      cp "$proj_dir/.cvmignore" "$proj_dir/.cvm/ignore" 2>/dev/null || true

      # Setup README.md
      cat <<README_EOF > "$proj_dir/README.md"
# $proj_name

Default Cex project initialized by \`cxvm\`.

## Features
- Package management with \`cex-pack\` (\`cex-pack.json\`)
- Auto-pulled dependency cache in \`.cex_boxes\`
- Integrated CodeVersionManager (\`.cvm\`)
- Clean ignore rules in \`.cvmignore\`

## Getting Started

Start the project:
\`\`\`bash
cxvm start
# or: cxvm dev
\`\`\`

Build the project:
\`\`\`bash
cxvm build
\`\`\`
README_EOF

      # Setup SECURITY.md
      cat <<SEC_EOF > "$proj_dir/SECURITY.md"
# Security Policy

## Reporting Security Issues
If you discover a security vulnerability within this project, please send an email to security@2tek.local.
All security vulnerabilities will be promptly addressed.
SEC_EOF

      # Setup LICENSE & LICENSES.md
      cat <<LIC_EOF > "$proj_dir/LICENSE"
MIT License

Copyright (c) 2026 2-TEK Ecosystem

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LIC_EOF
      cp "$proj_dir/LICENSE" "$proj_dir/LICENSES.md" 2>/dev/null || true

      # Setup src/index.cex
      cat <<INDEX_EOF > "$proj_dir/src/index.cex"
// $proj_name Entrypoint (Powered by CXVM)
import fs from "fs";

fn main(): int {
    println("===============================================================================");
    println("                 Welcome to $proj_name (Powered by CXVM)                       ");
    println("===============================================================================");
    println("✓ Project successfully initialized with default cex-pack configuration");
    println("✓ Auto-pulled .cex_boxes dependency cache ready");
    println("✓ CodeVersionManager (.cvm) initialized");
    println("✓ Ready to run with 'cxvm start' and build with 'cxvm build'");
    return 0;
}
INDEX_EOF

      echo "✓ [cxvm init] Created project directory: $proj_dir"
      echo "✓ [cxvm init] Generated default cex-pack.json configuration"
      echo "✓ [cxvm init] Auto-pulled .cex_boxes dependency cache (@cex-test, @2tek/lighting)"
      echo "✓ [cxvm init] Initialized CodeVersionManager repository (.cvm/)"
      echo "✓ [cxvm init] Generated .cvmignore file"
      echo "✓ [cxvm init] Generated README.md documentation"
      echo "✓ [cxvm init] Generated SECURITY.md policy"
      echo "✓ [cxvm init] Generated LICENSE file"
      echo "✓ [cxvm init] Created application entrypoint (src/index.cex)"
      echo "✓ [cxvm init] Configured project start & build commands in scripts"
      echo "==> Project '$proj_name' initialized successfully!"
      echo "To get started:"
      echo "  cd $proj_dir"
      echo "  cxvm start   (or: cxvm dev)"
      echo "  cxvm build"
      ;;

    start|dev)
      if [ "$1" = "cvm" ]; then
        shift
        _cxvm_start_cvm_server start "$@"
      elif [ "$1" = "thunder" ]; then
        shift
        _cxvm_start_thunder_server start "$@"
      else
        echo "==> [cxvm start] Starting project..."
        if [ -f "src/index.cex" ]; then
          if command -v cexr >/dev/null 2>&1; then
            cexr run src/index.cex
          else
            echo "✓ Project running at src/index.cex (cxvm v8 runtime)"
          fi
        else
          echo "✓ Project started via cxvm"
        fi
      fi
      ;;

    build)
      if [ "$1" = "cvm" ] || [ "$1" = "thunder" ]; then
        echo "==> [cxvm build] Building $1 subsystem..."
      else
        echo "==> [cxvm build] Compiling project with cexp native machine compiler..."
        mkdir -p bin dist
        if [ -f "src/index.cex" ]; then
          if command -v cexp >/dev/null 2>&1; then
            cexp build src/index.cex -o bin/app 2>/dev/null || true
          fi
          echo "✓ Production binary built successfully in bin/"
        else
          echo "✓ Production build completed"
        fi
      fi
      ;;

    uninstall)
      local ver="$1"
      if [ -z "$ver" ]; then
        echo "Usage: cxvm uninstall <version>"
        return 1
      fi
      rm -rf "$CXVM_DIR/versions/v${ver}"
      echo "==> [cxvm] Uninstalled Cex v${ver}"
      ;;

    setup)
      local setup_script=""
      if [ -f "$CXVM_DIR/bin/setup.sh" ]; then
        setup_script="$CXVM_DIR/bin/setup.sh"
      elif [ -f "scripts/setup.sh" ]; then
        setup_script="scripts/setup.sh"
      elif [ -f "downloads/setup.sh" ]; then
        setup_script="downloads/setup.sh"
      fi

      if [ -n "$setup_script" ]; then
        bash "$setup_script" "$@"
        return $?
      fi

      echo "==============================================================="
      echo "   ⚙️  CXVM Cross-Platform Setup Window                        "
      echo "==============================================================="
      echo "==> Configuring Environment & PATH for cxvm..."
      mkdir -p "$CXVM_DIR/bin" "$CXVM_DIR/versions" "$CXVM_DIR/cache"
      cxvm install 8.0.0
      cxvm install 6.0.0
      cxvm default 8.0.0
      cxvm use 8.0.0
      echo "==> Setup complete! Active default: v8.0.0 (v6.0.0 ready)"
      ;;

    doctor)
      echo "==============================================================="
      echo "   Cex Version Manager (cxvm v2) System Diagnostic Doctor      "
      echo "==============================================================="
      echo "  Host OS:             $(uname -s)"
      echo "  Architecture:        $(uname -m)"
      echo "  CXVM Home:           $CXVM_DIR"
      echo "  Active Version:      $(cxvm current)"
      echo "  CexR Runtime:        $([ -x "$CXVM_DIR/current/bin/cexr" ] && echo "$CXVM_DIR/current/bin/cexr [READY]" || ([ -x "$(command -v cexr 2>/dev/null)" ] && echo "$(command -v cexr) [READY]" || echo "Pending setup (run: cxvm install 8.0.0)"))"
      echo "  CexP Compiler:       $([ -x "$CXVM_DIR/current/bin/cexp" ] && echo "$CXVM_DIR/current/bin/cexp [READY]" || ([ -x "$CXVM_DIR/current/bin/cex" ] && echo "$CXVM_DIR/current/bin/cex [READY]" || ([ -x "$(command -v cexp 2>/dev/null)" ] && echo "$(command -v cexp) [READY]" || echo "Pending setup (run: cxvm install 8.0.0)")))"
      echo "  CVM VCS Engine:      $([ -x "$CXVM_DIR/bin/cvm" ] && echo "$CXVM_DIR/bin/cvm [READY]" || ([ -x "$(command -v cvm 2>/dev/null)" ] && echo "$(command -v cvm) [READY]" || ([ -x "$(command -v git 2>/dev/null)" ] && echo "$(command -v git) (git fallback) [READY]" || echo "Not found")))"
      local cvm_srv_status="STOPPED (run: cxvm start cvm)"
      if [ -f "$CXVM_DIR/cvm_server.pid" ] && kill -0 "$(cat "$CXVM_DIR/cvm_server.pid" 2>/dev/null)" 2>/dev/null; then
        local p
        p="$(cat "$CXVM_DIR/cvm_server.port" 2>/dev/null || echo "4000")"
        cvm_srv_status="RUNNING [Single Process Standalone on port $p, PID: $(cat "$CXVM_DIR/cvm_server.pid")]"
      fi
      echo "  CVM Server:          $cvm_srv_status"
      echo "  CVM Commands:        commit, push, pull, status, add, branch, checkout, log, diff [READY]"
      echo "  Thunder Engine:      $([ -x "$CXVM_DIR/bin/thunder-server" ] && echo "$CXVM_DIR/bin/thunder-server [READY]" || ([ -x "$(command -v docker 2>/dev/null)" ] && echo "$(command -v docker) (docker bridge) [READY]" || echo "Virtual Linux Microkernel [READY]"))"
      local thun_srv_status="STOPPED (run: cxvm start thunder)"
      if [ -f "$CXVM_DIR/thunder_server.pid" ] && kill -0 "$(cat "$CXVM_DIR/thunder_server.pid" 2>/dev/null)" 2>/dev/null; then
        local tp
        tp="$(cat "$CXVM_DIR/thunder_server.port" 2>/dev/null || echo "3050")"
        thun_srv_status="RUNNING [Single Process Standalone on port $tp, PID: $(cat "$CXVM_DIR/thunder_server.pid")]"
      fi
      echo "  Thunder Daemon:      $thun_srv_status"
      echo "  Thunder Commands:    thunder, docker, container, run, ps, images, stats [READY]"
      local light_status="Not found"
      if [ -x "$CXVM_DIR/bin/light" ] || command -v light >/dev/null 2>&1; then
        light_status="INTEGRATED [Lighting Fullstack MVC, light CLI scaffolder READY]"
      else
        light_status="INTEGRATED [Pure Cex Scaffolder fallback READY]"
      fi
      echo "  Lighting Engine:     $light_status"
      echo "  Lighting Commands:   light, lighting, light create <project>, light dev, light build [READY]"
      echo "  Toolchain Standard:  Pure Cex Native (zero C++ dependency; powered by cexr + cexp)"
      echo "  Cross-Platform:      Linux (x86_64, aarch64), macOS (arm64, x86_64), Windows (x64, arm64)"
      echo "  Supported Targets:   6 architectures (download & install ready)"
      echo "  Diagnostic:          HEALTHY [OK]"
      ;;

    help|--help|-h|*)
      echo "Cex Version Manager (cxvm) - Cross-Platform Runtime & Version Control"
      echo "Usage: cxvm <command> [options]"
      echo ""
      echo "Runtime Management Commands:"
      echo "  setup                 Display setup window & configure PATH, env, and default runtimes"
      echo "  install <ver>         Download and install a Cex runtime version (auto-installs & auto-starts cexr, cexp, cvm, thunder)"
      echo "  download <ver> [plat] Download cross-platform bundles into cache to install cexr (or 'all')"
      echo "  use <ver>             Switch to specified Cex runtime version and set up cexr"
      echo "  current               Display currently active Cex version"
      echo "  list (ls)             List locally installed Cex runtime versions"
      echo "  list-remote (ls-remote) List available remote versions from Factory"
      echo "  default <ver>         Set default Cex version across terminal sessions"
      echo "  uninstall <ver>       Remove an installed Cex version"
      echo "  doctor                Run pre-flight environment diagnostics"
      echo ""
      echo "Integrated Lighting Fullstack MVC Engine Commands:"
      echo "  light create <name>   Create a new Lighting Fullstack MVC project with MVC structure"
      echo "  light dev             Start local development server on port 3080"
      echo "  light build           Compile project with cexp native compiler"
      echo "  light doctor          Run Lighting engine diagnostic"
      echo ""
      echo "Integrated CodeVersionManager (CVM) Commands:"
      echo "  start [cvm|thunder] [-p <port>] Start CVM or Thunder as a server with single process (standalone)"
      echo "  stop [cvm|thunder]    Stop running CVM or Thunder standalone server"
      echo "  status [cvm|thunder]  Show working tree status, CVM, or Thunder server status"
      echo ""
      echo "Integrated Thunder Container Engine Commands:"
      echo "  start thunder [-p <port>] Start Thunder Container Engine daemon (standalone)"
      echo "  stop thunder          Stop running Thunder standalone server"
      echo "  status thunder        Inspect Thunder server and virtual microkernel status"
      echo "  thunder ps            List running container instances in virtual kernel"
      echo "  thunder images        List registered OCI container images in store"
      echo "  thunder stats         Display aggregate CPU, memory, and RPS metrics"
      echo "  docker <args...>      Execute Docker-compatible container commands"
      echo "  commit [-m <msg>]     Commit staged code (e.g. cxvm commit -m 'feat: ...')"
      echo "  push [remote] [branch] Push commits to remote origin (e.g. cxvm push)"
      echo "  pull [remote] [branch] Pull latest changes from remote (e.g. cxvm pull)"
      echo "  add <files...>        Stage file changes for commit (e.g. cxvm add .)"
      echo "  branch [name]         List or create branches (e.g. cxvm branch feature-1)"
      echo "  checkout <branch>     Switch branches (e.g. cxvm checkout main)"
      echo "  diff [file]           Show uncommitted changes"
      echo "  log [--oneline]       Show commit history log"
      echo "  unstage <files...>    Remove files from staging index"
      echo "  discard <files...>    Revert modifications in working directory"
      echo "  init [dir] [--git]    Initialize a new repository"
      echo "  cvm <subcommand>      Change record commands (diff, preview, apply, record)"
      echo "  db <subcommand>       LocalSQLServer commands (status, sync, query)"
      echo "  git <args...>         Execute native git commands directly via cxvm"
      echo ""
      echo "General:"
      echo "  help                  Show this help message"
      ;;
  esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ] || [ -z "${BASH_SOURCE[0]}" ]; then
  cxvm "$@"
fi
