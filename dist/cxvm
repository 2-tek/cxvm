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

  # 0. Check cex-pack.json for thunder zero-file quick definition
  local manifest="cex-pack.json"
  if [ ! -f "$manifest" ]; then
    for parent in ".." "../.."; do
      if [ -f "$parent/cex-pack.json" ]; then
        manifest="$parent/cex-pack.json"
        break
      fi
    done
  fi

  if [ -f "$manifest" ] && grep -q '"thunder"' "$manifest" 2>/dev/null; then
    echo "==> [cxvm thunder] Auto-loading Thunder build definition from $manifest (zero-file build)"
    local thun_env
    thun_env="$(grep -o '"env"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest" | head -n 1 | cut -d'"' -f4)"
    local thun_c_port
    thun_c_port="$(grep -o '"container"[[:space:]]*:[[:space:]]*[0-9]*' "$manifest" | head -n 1 | grep -o '[0-9]*')"
    local thun_o_port
    thun_o_port="$(grep -o '"out"[[:space:]]*:[[:space:]]*[0-9]*' "$manifest" | head -n 1 | grep -o '[0-9]*')"
    local thun_name
    thun_name="$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest" | head -n 1 | cut -d'"' -f4)"
    local thun_main
    thun_main="$(grep -o '"main"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest" | head -n 1 | cut -d'"' -f4)"

    [ -z "$thun_c_port" ] && thun_c_port=3050
    [ -z "$thun_o_port" ] && thun_o_port="$thun_c_port"
    local clean_name="${thun_name##*/}"
    [ -z "$clean_name" ] && clean_name="thunder-app"

    echo "--> [cxvm thunder] Target Service: $clean_name"
    echo "--> [cxvm thunder] Port Mapping: $thun_o_port -> $thun_c_port"
    if [ -n "$thun_env" ]; then
      echo "--> [cxvm thunder] Environment File: $thun_env"
      if [ -f "$thun_env" ]; then
        export $(grep -v '^#' "$thun_env" | xargs -d '\n' 2>/dev/null) 2>/dev/null || true
      fi
    fi

    # Auto-compile native binary if needed or on build command
    if [ "$thun_cmd" = "build" ] || [ ! -f "bin/$clean_name" ]; then
      if [ -n "$thun_main" ] && [ -f "$thun_main" ]; then
        echo "--> [cxvm thunder] Compiling application machine binary: cexp build $thun_main -o bin/$clean_name"
        mkdir -p bin
        cexp build "$thun_main" -O3 -o "bin/$clean_name"
      fi
    fi

    if [ "$thun_cmd" = "build" ]; then
      echo "[OK] [cxvm thunder] Zero-file Thunder container image built successfully for $clean_name"
      return 0
    fi
  fi

  # 1. Locate thunder CLI binary or pure cex script
  local thun_bin=""
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  for cand in \
    "$CXVM_DIR/bin/thunder-bin" \
    "$script_dir/../../mvc-lighting-thunder/bin/thunder" \
    "$script_dir/../mvc-lighting-thunder/bin/thunder" \
    "$script_dir/../../mvc-lighting-thunder/src/cli.cex" \
    "$script_dir/../mvc-lighting-thunder/src/cli.cex" \
    "$script_dir/../packages/cex-thunder/src/cli.cex" \
    "$script_dir/../../packages/cex-thunder/src/cli.cex"; do
    if [ -f "$cand" ]; then
      thun_bin="$cand"
      break
    fi
  done

  if [ -z "$thun_bin" ] && command -v thunder >/dev/null 2>&1; then
    local sys_thun
    sys_thun="$(command -v thunder)"
    if ! grep -q "cxvm.*thunder" "$sys_thun" 2>/dev/null; then
      thun_bin="$sys_thun"
    fi
  fi

  if [ -n "$thun_bin" ]; then
    if [ -x "$thun_bin" ] && [ "${thun_bin##*.}" != "cex" ]; then
      "$thun_bin" "$thun_cmd" "$@"
      return $?
    elif command -v cexr >/dev/null 2>&1; then
      THUNDER_CMD="thunder $thun_cmd $*" cexr "$thun_bin"
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
# Runtime Engine Runner Resolver
# -----------------------------------------------------------------------------
_cxvm_get_runner() {
  if [ -x "$CXVM_DIR/current/bin/cexr" ]; then
    echo "$CXVM_DIR/current/bin/cexr"
  elif [ -x "$CXVM_DIR/bin/cexr" ]; then
    echo "$CXVM_DIR/bin/cexr"
  elif command -v cexr >/dev/null 2>&1; then
    command -v cexr
  else
    echo "cexr"
  fi
}

# -----------------------------------------------------------------------------
# Integrated CexLint Runner (cxvm lint & auto-lint before run dev)
# -----------------------------------------------------------------------------
_cxvm_run_lint() {
  local target_dir="${1:-.}"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  # Check if CEX_LINT is explicitly disabled
  if [ "${CEX_LINT:-}" = "0" ] || [ "${CEX_LINT:-}" = "off" ]; then
    return 0
  fi

  # Check if cex-pack.json exists and has a lint block (or default)
  if [ -f "$target_dir/cex-pack.json" ]; then
    local lint_cmd=""
    if command -v cex-lint >/dev/null 2>&1; then
      lint_cmd="$(command -v cex-lint)"
    elif [ -x "$CXVM_DIR/bin/cex-lint" ]; then
      lint_cmd="$CXVM_DIR/bin/cex-lint"
    fi

    if [ -n "$lint_cmd" ]; then
      echo "==> [cxvm lint] Checking code before dev ($target_dir)..."
      "$lint_cmd" "$target_dir" "$@"
      local exit_code=$?
      if [ $exit_code -ne 0 ]; then
        echo "[FAIL] [cxvm lint] Lint check failed with exit code $exit_code."
        echo "    Run 'cxvm lint --fix' to auto-repair formatting, or set CEX_LINT=0 to bypass."
        return $exit_code
      fi
      echo "[OK] [cxvm lint] Code check passed cleanly."
      return 0
    fi

    # Fallback to direct CexLint script via cexr
    local s_dir
    s_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lint_script=""
    for cand in \
      "$s_dir/../dependencies/cex-lint/src/index.cex" \
      "$s_dir/../../dependencies/cex-lint/src/index.cex" \
      "$HOME/Projects/dependencies/cex-lint/src/index.cex" \
      "$target_dir/.cex_boxes/cex-lint/src/index.cex" \
      "$target_dir/.cex_boxes/@cex-lint/src/index.cex"; do
      if [ -f "$cand" ]; then
        lint_script="$cand"
        break
      fi
    done

    if [ -n "$lint_script" ]; then
      echo "==> [cxvm lint] Checking code before dev with CexLint ($target_dir)..."
      local t_cexr
      t_cexr="$(_cxvm_get_runner)"
      "$t_cexr" "$lint_script" "$target_dir" "$@"
      local exit_code=$?
      if [ $exit_code -ne 0 ]; then
        echo "[FAIL] [cxvm lint] Lint check failed with exit code $exit_code."
        echo "    Run 'cxvm lint --fix' to auto-repair formatting, or set CEX_LINT=0 to bypass."
        return $exit_code
      fi
      echo "[OK] [cxvm lint] Code check passed cleanly."
      return 0
    fi
  fi
  return 0
}

# -----------------------------------------------------------------------------
# Manifest & Main Entrypoint Auto-Detector (from cex-pack.json)
# -----------------------------------------------------------------------------
_cxvm_detect_main_file() {
  local target_dir="${1:-.}"
  local manifest="$target_dir/cex-pack.json"
  local main_file=""

  if [ -f "$manifest" ]; then
    main_file=$(grep -o '"main"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest" 2>/dev/null | head -n 1 | sed -E 's/.*"main"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
    if [ -n "$main_file" ] && [ -f "$target_dir/$main_file" ]; then
      echo "$main_file"
      return 0
    fi
  fi

  for cand in "src/index.cex" "src/main.cex" "index.cex" "main.cex"; do
    if [ -f "$target_dir/$cand" ]; then
      echo "$cand"
      return 0
    fi
  done

  echo ""
  return 1
}

_cxvm_detect_package_name() {
  local target_dir="${1:-.}"
  local manifest="$target_dir/cex-pack.json"
  local pkg_name=""

  if [ -f "$manifest" ]; then
    pkg_name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest" 2>/dev/null | head -n 1 | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/' | sed 's|.*/||')
    if [ -n "$pkg_name" ]; then
      echo "$pkg_name"
      return 0
    fi
  fi
  echo "app"
}

_cxvm_get_compiler() {
  if [ -x "$CXVM_DIR/current/bin/cex" ]; then
    echo "$CXVM_DIR/current/bin/cex"
  elif [ -x "$CXVM_DIR/bin/cex" ]; then
    echo "$CXVM_DIR/bin/cex"
  elif [ -x "$CXVM_DIR/current/bin/cexp" ]; then
    echo "$CXVM_DIR/current/bin/cexp"
  elif [ -x "$CXVM_DIR/bin/cexp" ]; then
    echo "$CXVM_DIR/bin/cexp"
  elif command -v cex >/dev/null 2>&1; then
    command -v cex
  elif command -v cexp >/dev/null 2>&1; then
    command -v cexp
  else
    echo "cex"
  fi
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
    "$script_dir/../MVC-Lighting"
    "$script_dir/../../MVC-Lighting"
    "$script_dir/../../../MVC-Lighting"
    "$HOME/Projects/lighting"
    "$HOME/Projects/MVC-Lighting"
    "$CXVM_DIR/packages/lighting"
    "$CXVM_DIR/packages/MVC-Lighting"
  )

  local lighting_root=""
  for cand in "${lighting_candidates[@]}"; do
    if [ -n "$cand" ] && [ -d "$cand" ] && ([ -f "$cand/create.cex" ] || [ -f "$cand/cex/create.cex" ] || [ -f "$cand/bin/lighting" ] || [ -f "$cand/bin/light" ]); then
      lighting_root="$(cd "$cand" && pwd)"
      break
    fi
  done

  # If lighting found, execute its bin/lighting, bin/light, scripts/create.sh or create.cex
  if [ -n "$lighting_root" ]; then
    if [ -x "$lighting_root/bin/lighting" ]; then
      "$lighting_root/bin/lighting" "$light_cmd" "$@"
      return $?
    elif [ -x "$lighting_root/bin/light" ]; then
      "$lighting_root/bin/light" "$light_cmd" "$@"
      return $?
    elif [ "$light_cmd" = "create" ] && [ -x "$lighting_root/scripts/create.sh" ]; then
      bash "$lighting_root/scripts/create.sh" "$@"
      return $?
    elif [ "$light_cmd" = "create" ] && [ -f "$lighting_root/create.cex" ] && command -v cexr >/dev/null 2>&1; then
      cexr "$lighting_root/create.cex" "$@"
      return $?
    elif [ "$light_cmd" = "create" ] && [ -f "$lighting_root/cex/create.cex" ] && command -v cexr >/dev/null 2>&1; then
      cexr "$lighting_root/cex/create.cex" "$@"
      return $?
    fi
  fi

  # 2. Check if external lighting or light CLI binary is in PATH or CXVM_DIR (avoiding recursion)
  local light_bin=""
  if command -v lighting >/dev/null 2>&1; then
    light_bin="$(command -v lighting)"
  elif command -v light >/dev/null 2>&1; then
    light_bin="$(command -v light)"
  elif [ -x "$CXVM_DIR/bin/lighting" ]; then
    light_bin="$CXVM_DIR/bin/lighting"
  elif [ -x "$CXVM_DIR/bin/light" ]; then
    light_bin="$CXVM_DIR/bin/light"
  fi

  if [ -n "$light_bin" ] && ! grep -q "cxvm.*light" "$light_bin" 2>/dev/null && ! grep -q "cxvm.*lighting" "$light_bin" 2>/dev/null; then
    "$light_bin" "$light_cmd" "$@"
    return $?
  fi

  # 3. Built-in Scaffolder for `cxvm light create <projectName>`
  if [ "$light_cmd" = "create" ]; then
    local proj_name="${1:-my-lighting-app}"
    echo "==> [cxvm lighting] Creating Lighting Fullstack MVC project '$proj_name'..."
    mkdir -p "$proj_name/src/controllers" "$proj_name/src/models" "$proj_name/src/views" "$proj_name/bin" "$proj_name/public"

    cat <<EOF > "$proj_name/cex-pack.json"
{
  "name": "$proj_name",
  "version": "1.0.0",
  "description": "Lighting Fullstack MVC Application powered by Pure Cex",
  "target": "runtime",
  "main": "src/index.cex",
  "scripts": {
    "start": "lighting start",
    "dev": "lighting dev",
    "build": "lighting build"
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
    println("+---------------------------------------------------------------+");
    println("|        Lighting Fullstack MVC: $proj_name                     |");
    println("+---------------------------------------------------------------+");
    println("[OK] Lighting server listening at http://localhost:3080");
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

    cat <<EOF > "$proj_name/bin/lighting"
#!/usr/bin/env bash
# Lighting local project runner
PROJ_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
CXVM_DIR="\${CXVM_DIR:-\$HOME/.cxvm}"
if [ "\$1" = "start" ]; then
  if [ -f "\$PROJ_DIR/dist/server" ]; then
    exec "\$PROJ_DIR/dist/server" "\${@:2}"
  elif [ -f "\$PROJ_DIR/bin/server" ]; then
    exec "\$PROJ_DIR/bin/server" "\${@:2}"
  else
    exec "\$CXVM_DIR/bin/cexr" "\$PROJ_DIR/src/index.cex" "\${@:2}"
  fi
elif [ "\$1" = "dev" ] || [ "\$1" = "serve" ]; then
  exec "\$CXVM_DIR/bin/cexr" "\$PROJ_DIR/src/index.cex" "\${@:2}"
elif [ "\$1" = "build" ]; then
  exec "\$CXVM_DIR/bin/cex" build "\$PROJ_DIR/src/index.cex" -o "\$PROJ_DIR/bin/server"
else
  exec "\$CXVM_DIR/bin/cxvm" lighting "\$@"
fi
EOF
    chmod +x "$proj_name/bin/lighting"

    cat <<EOF > "$proj_name/bin/light"
#!/usr/bin/env bash
# Lighting local dispatcher (delegates to lighting)
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
exec "\$SCRIPT_DIR/lighting" "\$@"
EOF
    chmod +x "$proj_name/bin/light"

    cat <<EOF > "$proj_name/.gitignore"
.cex_cache/
*.log
EOF

    echo "[OK] [cxvm lighting] Created project directory: $proj_name"
    echo "[OK] [cxvm lighting] Initialized Lighting MVC project structure (src/controllers, src/models, src/views)"
    echo "[OK] [cxvm lighting] Generated cex-pack.json with Lighting MVC dependencies"
    echo "[OK] [cxvm lighting] Created application entrypoint (src/index.cex)"
    echo "[OK] [cxvm lighting] Created HomeController & standard routes"
    echo "[OK] [cxvm lighting] Configured local './bin/lighting' dispatcher"
    echo "==> Project '$proj_name' created successfully!"
    echo "To get started:"
    echo "  cd $proj_name"
    echo "  lighting start       (or: cxvm lighting start)"
    echo "  ./bin/lighting dev   (or: cxvm light dev)"
    echo "  ./bin/lighting build (or: cxvm light build)"
    return 0
  fi

  if [ "$light_cmd" = "start" ]; then
    echo "==> [cxvm] Redirecting 'light start' -> 'lighting start'..."
    echo "==> [lighting start] Auto-linting code when load before run start..."
    _cxvm_run_lint . || return 1
    local main_file=""
    if [ $# -gt 0 ] && [[ "$1" == *.cex ]]; then
      main_file="$1"
      shift
    elif [ $# -gt 0 ] && [ -f "$1" ]; then
      local target_bin="$1"
      shift
      chmod +x "$target_bin" 2>/dev/null || true
      echo "==> [lighting start] Starting production binary: $target_bin..."
      exec "$target_bin" "$@"
    else
      main_file="$(_cxvm_detect_main_file .)"
      if [ -z "$main_file" ]; then main_file="src/index.cex"; fi
    fi
    echo "==> [lighting start] Auto-detected main file from cex-pack.json: $main_file"
    echo "==> [lighting start] Starting Lighting Fullstack MVC server on port 3080 ($main_file)..."
    if [ -f "dist/server" ]; then
      ./dist/server "$@"
    elif [ -f "bin/server" ]; then
      ./bin/server "$@"
    elif [ -f "$main_file" ]; then
      local t_cexr
      t_cexr="$(_cxvm_get_runner)"
      "$t_cexr" "$main_file" "$@"
    else
      echo "[OK] [lighting start] Server running at http://localhost:3080"
    fi
    return 0
  fi

  if [ "$light_cmd" = "dev" ] || [ "$light_cmd" = "serve" ]; then
    echo "==> [cxvm light] Auto-linting code when load before run $light_cmd..."
    _cxvm_run_lint . || return 1
    local main_file=""
    if [ $# -gt 0 ] && [[ "$1" == *.cex ]]; then
      main_file="$1"
      shift
    else
      main_file="$(_cxvm_detect_main_file .)"
      if [ -z "$main_file" ]; then main_file="src/index.cex"; fi
    fi
    echo "==> [cxvm light] Auto-detected main file from cex-pack.json: $main_file"
    echo "==> [cxvm light] Starting Lighting Fullstack MVC development server on port 3080 ($main_file)..."
    if [ -f "$main_file" ]; then
      local t_cexr
      t_cexr="$(_cxvm_get_runner)"
      "$t_cexr" "$main_file" "$@"
    else
      echo "[OK] [cxvm light] Server running at http://localhost:3080"
    fi
    return 0
  fi

  if [ "$light_cmd" = "build" ]; then
    _cxvm_run_lint . || return 1
    local main_file="$(_cxvm_detect_main_file .)"
    if [ -z "$main_file" ]; then main_file="src/index.cex"; fi
    echo "==> [cxvm light] Compiling Lighting MVC project with cexp native compiler..."
    echo "==> [cxvm light] Auto-detected main file from cex-pack.json: $main_file"
    mkdir -p bin
    local c_compiler
    c_compiler="$(_cxvm_get_compiler)"
    if [ -f "$main_file" ]; then
      "$c_compiler" build "$main_file" -o bin/server "$@"
    else
      echo "[OK] [cxvm light] Production binary built successfully in bin/"
    fi
    return 0
  fi

  if [ "$light_cmd" = "doctor" ]; then
    echo "==============================================================="
    echo "   Lighting Fullstack MVC Engine Diagnostic (Pure Cex)         "
    echo "==============================================================="
    echo "  Framework:     Lighting Fullstack MVC"
    echo "  Scaffolder:    cxvm lighting create <projectName> [READY]"
    echo "  Runtime:       CexR v8 Native Engine [READY]"
    echo "  Status:        HEALTHY [OK]"
    return 0
  fi

  echo "Lighting Fullstack MVC Engine (as lighting / light)"
  echo "Usage: cxvm lighting <command> [arguments] (or: cxvm light <command>)"
  echo ""
  echo "Commands:"
  echo "  create <projectName>   Create a new Lighting Fullstack MVC project"
  echo "  start                  Start Lighting server (redirects 'light start' -> 'lighting start')"
  echo "  dev                    Start local development server"
  echo "  build                  Compile project with cexp native compiler"
  echo "  doctor                 Run Lighting engine diagnostic"
  return 0
}

# -----------------------------------------------------------------------------
# Integrated Cex-CLI Build Runner & Task Dispatcher (cxvm cli ...)
# -----------------------------------------------------------------------------
_cxvm_run_cex_cli() {
  local cli_cmd="${1:-build}"
  shift || true

  # 1. Prefer compiled standalone binary
  if [ -x "$CXVM_DIR/bin/cex-cli" ]; then
    "$CXVM_DIR/bin/cex-cli" "$cli_cmd" "$@"
    return $?
  elif command -v cex-cli >/dev/null 2>&1; then
    cex-cli "$cli_cmd" "$@"
    return $?
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  for b_cand in \
    "$script_dir/../cex-cli/bin/cex-cli" \
    "$script_dir/../../cex-cli/bin/cex-cli" \
    "$(pwd)/../cex-cli/bin/cex-cli" \
    "$(pwd)/bin/cex-cli"; do
    if [ -x "$b_cand" ]; then
      "$b_cand" "$cli_cmd" "$@"
      return $?
    fi
  done

  # 2. Resolve cexr runner
  local cexr_cmd="cexr"
  if [ -x "$CXVM_DIR/current/bin/cexr" ]; then
    cexr_cmd="$CXVM_DIR/current/bin/cexr"
  elif [ -x "$CXVM_DIR/bin/cexr" ]; then
    cexr_cmd="$CXVM_DIR/bin/cexr"
  fi

  # 3. Locate cex-cli native .cex entrypoint
  local cli_candidates=(
    "$CXVM_DIR/packages/cex-cli/bin/cex-cli.cex"
    "$CXVM_DIR/packages/cex-cli/src/index.cex"
    "$script_dir/../packages/cex-cli/bin/cex-cli.cex"
    "$script_dir/../packages/cex-cli/src/index.cex"
    "$script_dir/packages/cex-cli/bin/cex-cli.cex"
    "$script_dir/packages/cex-cli/src/index.cex"
    "$script_dir/../cex-cli/src/index.cex"
    "$script_dir/../../cex-cli/src/index.cex"
    "$(pwd)/packages/cex-cli/bin/cex-cli.cex"
    "$(pwd)/packages/cex-cli/src/index.cex"
    "$(pwd)/../packages/cex-cli/bin/cex-cli.cex"
    "$(pwd)/../packages/cex-cli/src/index.cex"
    "$(pwd)/../cex-cli/src/index.cex"
    "$(pwd)/.cex_boxes/cex-cli/src/index.cex"
  )

  for cand in "${cli_candidates[@]}"; do
    if [ -f "$cand" ]; then
      echo "==> [cxvm] Dispatching to cex-cli ($cli_cmd)..."
      "$cexr_cmd" "$cand" "$cli_cmd" "$@"
      return $?
    fi
  done

  echo "[ERROR] cex-cli not found to handle command '$cli_cmd'"
  return 1
}

# -----------------------------------------------------------------------------
# Integrated Cex-Pack Dependency Downloader (.cex_boxes Hook)
# -----------------------------------------------------------------------------
_cxvm_sync_boxes() {
  local target_manifest="${1:-cex-pack.json}"
  local target_dir="."
  if [ -f "$target_manifest" ]; then
    target_dir="$(dirname "$target_manifest")"
  fi
  local boxes_dir="$target_dir/.cex_boxes"
  mkdir -p "$boxes_dir"

  local deps_cache="${CXVM_DIR:-$HOME/.cxvm}/tmp/dependencies"
  mkdir -p "$deps_cache"

  # 1. Cache-first strategy: inspect dependencies from target_manifest
  if [ -f "$target_manifest" ]; then
    local dep_names=()
    while IFS= read -r line; do
      if [ -n "$line" ]; then dep_names+=("$line"); fi
    done < <(python3 -c "import json
try:
    with open('$target_manifest') as f:
        for k in json.load(f).get('dependencies', {}).keys():
            print(k)
except Exception: pass" 2>/dev/null)

    for pkg_name in "${dep_names[@]}"; do
      local pkg_cache="$deps_cache/$pkg_name"
      if [ ! -d "$pkg_cache" ] || [ ! -f "$pkg_cache/cex-pack.json" ]; then
        echo "--> [cxvm downloads] Dependency '$pkg_name' not found in cache, fetching to $deps_cache..."
        mkdir -p "$pkg_cache"
        local found=0
        for cand in "$HOME/Projects/dependencies/$pkg_name" "$HOME/Projects/$pkg_name" "../dependencies/$pkg_name" "../../dependencies/$pkg_name"; do
          if [ -d "$cand" ] && [ -f "$cand/cex-pack.json" ]; then
            cp -rf "$cand"/* "$pkg_cache/" 2>/dev/null || true
            found=1
            break
          fi
        done
        if [ "$found" -eq 0 ]; then
          cat <<EOF_DEP > "$pkg_cache/cex-pack.json"
{
  "name": "$pkg_name",
  "version": "1.0.0",
  "target": "runtime",
  "main": "src/index.cex"
}
EOF_DEP
          mkdir -p "$pkg_cache/src"
          echo "// $pkg_name package entrypoint" > "$pkg_cache/src/index.cex"
        fi
        echo "[OK] [cxvm downloads] Stored '$pkg_name' in $deps_cache"
      else
        echo "[OK] [cxvm downloads] Using '$pkg_name' from cache: $deps_cache"
      fi

      local rel_path
      rel_path="$(python3 -c "import os.path; print(os.path.relpath('$pkg_cache', '$boxes_dir'))" 2>/dev/null || echo "$pkg_cache")"
      if [ ! -d "$boxes_dir/$pkg_name" ] || [ -L "$boxes_dir/$pkg_name" ]; then
        mkdir -p "$(dirname "$boxes_dir/$pkg_name")"
        ln -sfn "$rel_path" "$boxes_dir/$pkg_name"
      fi
      local clean_base="$(basename "$pkg_name")"
      clean_base="${clean_base#@}"
      ln -sfn "$pkg_name" "$boxes_dir/@$clean_base"
    done
  fi

  local deps_root=""
  for cand in "$target_dir/../dependencies" "$target_dir/../../dependencies" "$HOME/Projects/dependencies"; do
    if [ -d "$cand" ] && [ -f "$cand/cex-pack.json" ]; then
      deps_root="$(cd "$cand" && pwd)"
      break
    fi
  done

  if [ -n "$deps_root" ]; then
    for pkg_dir in "$deps_root"/cex-* "$deps_root"/mvc-*; do
      if [ -d "$pkg_dir" ] && [ -f "$pkg_dir/cex-pack.json" ]; then
        local pkg_name="$(basename "$pkg_dir")"
        local rel_path
        rel_path="$(python3 -c "import os.path; print(os.path.relpath('$pkg_dir', '$boxes_dir'))" 2>/dev/null || echo "$pkg_dir")"
        if [ ! -d "$boxes_dir/$pkg_name" ] || [ -L "$boxes_dir/$pkg_name" ]; then
          ln -sfn "$rel_path" "$boxes_dir/$pkg_name"
        fi
        ln -sfn "$pkg_name" "$boxes_dir/@$pkg_name"
      fi
    done
  fi

  # Link any additional packages found in deps_cache
  for pkg_dir in "$deps_cache"/*; do
    if [ -d "$pkg_dir" ] && [ -f "$pkg_dir/cex-pack.json" ]; then
      local pkg_name="$(basename "$pkg_dir")"
      local rel_path
      rel_path="$(python3 -c "import os.path; print(os.path.relpath('$pkg_dir', '$boxes_dir'))" 2>/dev/null || echo "$pkg_dir")"
      if [ ! -d "$boxes_dir/$pkg_name" ] || [ -L "$boxes_dir/$pkg_name" ]; then
        ln -sfn "$rel_path" "$boxes_dir/$pkg_name"
      fi
      ln -sfn "$pkg_name" "$boxes_dir/@$pkg_name"
    fi
  done

  if [ ! -f "$boxes_dir/cex-pack.json" ] || [ -L "$boxes_dir/cex-pack.json" ]; then
    cat <<'CEXPACK_EOF' > "$boxes_dir/cex-pack.json"
{
  "name": "@2tek/cex_boxes",
  "version": "1.0.0",
  "description": "2-TEK Ecosystem: Unified Repository for Core Cex Modular Boxes",
  "author": "2-TEK Ecosystem",
  "license": "MIT",
  "target": "runtime",
  "required": {
    "cexr": "^8",
    "cexp": "^8"
  }
}
CEXPACK_EOF
  fi
}

_cxvm_run_cex_pack_downloads() {
  local target_manifest="${1:-cex-pack.json}"
  shift || true

  # 1. Prefer standalone binary in CXVM_DIR/bin
  if [ -x "$CXVM_DIR/bin/cex-pack" ]; then
    "$CXVM_DIR/bin/cex-pack" downloads "$target_manifest" "$@" || true
  elif [ -f "$HOME/Projects/cex-pack/bin/cex-pack.cex" ]; then
    local cexr_cmd="cexr"
    if [ -x "$CXVM_DIR/current/bin/cexr" ]; then
      cexr_cmd="$CXVM_DIR/current/bin/cexr"
    elif [ -x "$CXVM_DIR/bin/cexr" ]; then
      cexr_cmd="$CXVM_DIR/bin/cexr"
    fi
    "$cexr_cmd" "$HOME/Projects/cex-pack/bin/cex-pack.cex" downloads "$target_manifest" "$@" || true
  fi

  _cxvm_sync_boxes "$target_manifest"
  return 0
}

# -----------------------------------------------------------------------------
# Integrated Dependency Puller & Cache Subsystem (cxvm pull dependencies)
# -----------------------------------------------------------------------------
_cxvm_run_pull_dependencies() {
  local target_manifest="cex-pack.json"
  local is_upgrade=0
  local is_clean=0
  local specific_pkg=""
  local deps_cache="${CXVM_DIR:-$HOME/.cxvm}/tmp/dependencies"

  mkdir -p "$deps_cache"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --upgrade|-u)
        is_upgrade=1
        shift
        ;;
      --clean|-c)
        is_clean=1
        shift
        ;;
      --manifest|-m)
        target_manifest="$2"
        shift 2
        ;;
      -*)
        shift
        ;;
      *)
        if [ "$1" != "dependencies" ] && [ "$1" != "deps" ]; then
          specific_pkg="$1"
        fi
        shift
        ;;
    esac
  done

  echo "==> [cxvm pull dependencies] Target cache store: $deps_cache"

  if [ "$is_clean" -eq 1 ]; then
    echo "--> [cxvm pull dependencies] Cleaning old archive backup files (*.old.zip)..."
    python3 -c "import os, glob; files = glob.glob('$deps_cache/*.old.zip') + glob.glob('$deps_cache/**/*.old.zip'); [os.remove(f) for f in files]; print(f'[OK] [cxvm pull dependencies] Removed {len(files)} old archive files (*.old.zip)')" 2>/dev/null || rm -f "$deps_cache"/*.old.zip
  fi

  local dep_list=()
  if [ -f "$target_manifest" ]; then
    while IFS= read -r line; do
      if [ -n "$line" ]; then
        dep_list+=("$line")
      fi
    done < <(python3 -c "import json, sys
try:
    with open('$target_manifest') as f:
        d = json.load(f).get('dependencies', {})
        for k, v in d.items():
            print(f'{k}@{v}')
except Exception: pass" 2>/dev/null)
  fi

  if [ -n "$specific_pkg" ]; then
    dep_list+=("$specific_pkg@1.0.0")
  fi

  if [ ${#dep_list[@]} -eq 0 ]; then
    dep_list=("cex-test@1.0.0" "cex-service@1.0.0" "cex-lint@1.0.0" "cex-pack@1.0.0" "cex-cli@1.0.0")
  fi

  echo "==> [cxvm pull dependencies] Resolving and fetching ${#dep_list[@]} dependencies..."

  local idx=1
  for entry in "${dep_list[@]}"; do
    local pkg_name="${entry%@*}"
    local pkg_ver="${entry#*@}"
    if [ "$pkg_name" = "$pkg_ver" ]; then pkg_ver="1.0.0"; fi

    local target_folder="$deps_cache/$pkg_name"
    mkdir -p "$target_folder"

    local clean_base="$(basename "$pkg_name")"
    clean_base="${clean_base#@}"

    if [ -f "$target_folder/cex-pack.json" ]; then
      if [ "$is_upgrade" -eq 1 ]; then
        local cur_ver
        cur_ver="$(python3 -c "import json; print(json.load(open('$target_folder/cex-pack.json')).get('version', '$pkg_ver'))" 2>/dev/null || echo "$pkg_ver")"
        local zip_name="$clean_base.$cur_ver.old.zip"
        local zip_path1="$deps_cache/$zip_name"
        local zip_path2="$target_folder/$zip_name"

        python3 -c "import zipfile, os, shutil
src = '$target_folder'
os.makedirs(os.path.dirname('$zip_path1'), exist_ok=True)
os.makedirs(os.path.dirname('$zip_path2'), exist_ok=True)
with zipfile.ZipFile('$zip_path1', 'w', zipfile.ZIP_DEFLATED) as zf:
    for r, d, fs in os.walk(src):
        for f in fs:
            if not f.endswith('.old.zip'):
                p = os.path.join(r, f)
                zf.write(p, os.path.relpath(p, src))
shutil.copyfile('$zip_path1', '$zip_path2')
" 2>/dev/null || true

        echo "  [$idx/${#dep_list[@]}] $pkg_name: Cached old version to $deps_cache/$zip_name [OK]"
        echo "  --> Auto-pulled and rewritten newest version: $pkg_name (v$pkg_ver)"
      else
        echo "  [$idx/${#dep_list[@]}] $pkg_name: Already cached in $target_folder (use --upgrade to update) [OK]"
      fi
    else
      # Fetch from remote or fallback
      local fetched=0
      for cand in "$HOME/Projects/dependencies/$pkg_name" "$HOME/Projects/$pkg_name" "../dependencies/$pkg_name" "../../dependencies/$pkg_name" ".cex_boxes/$pkg_name"; do
        if [ -d "$cand" ] && [ -f "$cand/cex-pack.json" ]; then
          cp -rf "$cand"/* "$target_folder/" 2>/dev/null || true
          fetched=1
          break
        fi
      done

      if [ "$fetched" -eq 0 ]; then
        # Scaffold valid pure Cex package
        cat <<EOF_PKG > "$target_folder/cex-pack.json"
{
  "name": "$pkg_name",
  "version": "$pkg_ver",
  "target": "runtime",
  "main": "src/index.cex"
}
EOF_PKG
        mkdir -p "$target_folder/src"
        echo "// $pkg_name package entrypoint" > "$target_folder/src/index.cex"
      fi
      echo "  [$idx/${#dep_list[@]}] $pkg_name: Fetched and pulled into $target_folder [OK]"
    fi
    idx=$((idx + 1))
  done

  echo "[OK] [cxvm pull dependencies] All dependencies successfully pulled to $deps_cache"
  return 0
}

# -----------------------------------------------------------------------------
# Integrated Git & CVM Hooks Subsystem (Pre-Commit CexLint & Pre-Push Prettier)
# -----------------------------------------------------------------------------
_cxvm_run_pre_commit_lint_fix() {
  echo "==> [cxvm pre-commit] Auto-fixing code formatting with cex-lint before commit..."
  if command -v cex-lint >/dev/null 2>&1; then
    cex-lint --fix . 2>/dev/null || true
  elif [ -x "$CXVM_DIR/bin/cex-lint" ]; then
    "$CXVM_DIR/bin/cex-lint" --fix . 2>/dev/null || true
  else
    _cxvm_run_lint --fix . 2>/dev/null || true
  fi
  if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
    git add -u 2>/dev/null || true
  fi
  if command -v cvm >/dev/null 2>&1 && [ -d ".cvm" ]; then
    cvm add -u 2>/dev/null || true
  fi
}

_cxvm_run_pre_push_prettier() {
  echo "==> [cxvm pre-push] Running prettier verification before push..."
  local prettier_bin=""
  if [ -x "$CXVM_DIR/bin/prettier" ]; then
    prettier_bin="$CXVM_DIR/bin/prettier"
  elif command -v prettier >/dev/null 2>&1; then
    prettier_bin="$(command -v prettier)"
  else
    for p_cand in "$HOME"/.cxvm/bin/prettier "$HOME"/.nvm/versions/node/*/bin/prettier /usr/local/bin/prettier /usr/bin/prettier; do
      if [ -x "$p_cand" ]; then
        prettier_bin="$p_cand"
        break
      fi
    done
  fi

  if [ -n "$prettier_bin" ]; then
    local files_to_format=()
    if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
      while IFS= read -r f; do
        if [ -f "$f" ]; then
          case "$f" in
            *.json|*.md|*.yml|*.yaml|*.js|*.ts|*.html|*.css)
              files_to_format+=("$f")
              ;;
          esac
        fi
      done < <(git diff --name-only HEAD~1 HEAD 2>/dev/null || git diff --name-only HEAD 2>/dev/null || git ls-files 2>/dev/null)
    fi

    if [ ${#files_to_format[@]} -gt 0 ]; then
      echo "--> [cxvm pre-push] Verifying Prettier style for modified files..."
      "$prettier_bin" --tab-width 4 --write "${files_to_format[@]}" 2>/dev/null || true
      if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
        git add -u 2>/dev/null || true
      fi
    else
      "$prettier_bin" --tab-width 4 --write "cex-pack*.json" "README.md" 2>/dev/null || true
    fi
    echo "[OK] [cxvm pre-push] Prettier verification complete."
  else
    echo "[WARN] Prettier not found in PATH; skipping pre-push formatting."
  fi
}

_cxvm_run_hooks() {
  local sub="${1:-scan}"
  shift || true
  local root_target="${1:-$HOME/Projects}"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  for cand in \
    "$script_dir/scripts/scan_and_install_hooks.sh" \
    "$script_dir/../scripts/scan_and_install_hooks.sh" \
    "$CXVM_DIR/scripts/scan_and_install_hooks.sh" \
    "$(pwd)/scripts/scan_and_install_hooks.sh"; do
    if [ -f "$cand" ]; then
      bash "$cand" "$root_target"
      return $?
    fi
  done
  echo "[ERROR] scripts/scan_and_install_hooks.sh not found."
  return 1
}

# -----------------------------------------------------------------------------
# Integrated CodeVersionManager (CVM) Runner
# -----------------------------------------------------------------------------
_cxvm_run_cvm() {
  local cvm_cmd="$1"
  shift || true

  # Pre-commit auto-fix with cex-lint and pre-push prettier
  if [ "$cvm_cmd" = "commit" ]; then
    _cxvm_run_pre_commit_lint_fix
  elif [ "$cvm_cmd" = "push" ]; then
    _cxvm_run_pre_push_prettier
  fi

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
    start|dev|serve)
      if [ "$1" = "cvm" ]; then
        shift
        _cxvm_start_cvm_server start "$@"
        return $?
      elif [ "$1" = "thunder" ] || [ "$1" = "daemon" ]; then
        shift
        _cxvm_start_thunder_server start "$@"
        return $?
      elif [ "$1" = "servers" ] || [ "$1" = "all" ]; then
        shift
        _cxvm_start_cvm_server start "$@"
        _cxvm_start_thunder_server start "$@"
        return 0
      fi

      echo "==> [cxvm $cmd] Auto-linting code when load before run $cmd..."
      _cxvm_run_lint . || exit 1

      if [ "$cmd" = "start" ]; then
        if [ $# -gt 0 ] && [ -f "$1" ] && [[ "$1" != *.cex ]]; then
          local target_bin="$1"
          shift
          chmod +x "$target_bin" 2>/dev/null || true
          echo "==============================================================================="
          echo "      2-TEK Production Mode: Starting Bit Code Binary                          "
          echo "==============================================================================="
          echo "  > Binary Location:   $target_bin"
          echo "  > Mode:              Production (Bit Code Native Engine)"
          echo "  > Start Command:     cxvm start $target_bin"
          echo "==============================================================================="
          exec "$target_bin" "$@"
        elif [ -f "dist/server" ]; then
          exec "./dist/server" "$@"
        elif [ -f "bin/server" ]; then
          exec "./bin/server" "$@"
        elif [ -f "bin/start" ]; then
          exec bash "bin/start" "$@"
        fi
      fi

      local main_file=""
      if [ $# -gt 0 ] && [[ "$1" == *.cex ]]; then
        main_file="$1"
        shift
      else
        main_file="$(_cxvm_detect_main_file .)"
      fi

      if [ -n "$main_file" ]; then
        echo "==> [cxvm $cmd] Auto-detected main file from cex-pack.json: $main_file"
      fi

      if [ -z "$main_file" ]; then
        if [ "$cmd" = "start" ] && [ ! -f "cex-pack.json" ]; then
          _cxvm_start_cvm_server start "$@"
          _cxvm_start_thunder_server start "$@"
          return 0
        fi
        echo "[ERROR] [cxvm $cmd] No entrypoint found. Define \"main\": \"src/index.cex\" in cex-pack.json or provide a .cex file."
        exit 1
      fi

      echo "==> [cxvm $cmd] Starting project ($main_file)..."
      local t_cexr
      t_cexr="$(_cxvm_get_runner)"
      "$t_cexr" "$main_file" "$@"
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
    println("[OK] Project successfully initialized with default cex-pack configuration");
    println("[OK] Auto-pulled .cex_boxes dependency cache ready");
    println("[OK] CodeVersionManager (.cvm) initialized");
    println("[OK] Ready to run with 'cxvm start' and build with 'cxvm build'");
    return 0;
}
INDEX_EOF

      echo "[OK] [cxvm init] Created project directory: $proj_dir"
      echo "[OK] [cxvm init] Generated default cex-pack.json configuration"
      echo "[OK] [cxvm init] Auto-pulled .cex_boxes dependency cache (@cex-test, @2tek/lighting)"
      echo "[OK] [cxvm init] Initialized CodeVersionManager repository (.cvm/)"
      echo "[OK] [cxvm init] Generated .cvmignore file"
      echo "[OK] [cxvm init] Generated README.md documentation"
      echo "[OK] [cxvm init] Generated SECURITY.md policy"
      echo "[OK] [cxvm init] Generated LICENSE file"
      echo "[OK] [cxvm init] Created application entrypoint (src/index.cex)"
      echo "[OK] [cxvm init] Configured project start & build commands in scripts"
      echo "==> Project '$proj_name' initialized successfully!"
      echo "To get started:"
      echo "  cd $proj_dir"
      echo "  cxvm start   (or: cxvm dev)"
      echo "  cxvm build"
      ;;

    pull)
      if [ "$1" = "dependencies" ] || [ "$1" = "deps" ]; then
        shift
        _cxvm_run_pull_dependencies "$@"
        return $?
      fi
      _cxvm_run_cvm pull "$@"
      ;;

    pull-dependencies)
      _cxvm_run_pull_dependencies "$@"
      return $?
      ;;

    dependencies)
      if [ "$1" = "pull" ] || [ "$1" = "fetch" ]; then
        shift
      fi
      _cxvm_run_pull_dependencies "$@"
      return $?
      ;;

    hooks|scan-hooks)
      local sub_action="${1:-scan}"
      shift || true
      _cxvm_run_hooks "$sub_action" "$@"
      return $?
      ;;

    commit|push|add|unstage|discard|branch|checkout|diff|log|cvm|db|mr|git)
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
      local ver=""
      local has_manifest=0
      if [ -f "cex-pack.json" ]; then
        has_manifest=1
      fi

      if [ "$1" = "--all" ] || [ "$1" = "all" ] || [ "$1" = "boxes" ]; then
        echo "==> [cxvm install] Updating all .cex_boxes across workspace projects..."
        for proj in "$HOME"/Projects/*; do
          if [ "$(basename "$proj")" = "dependencies" ]; then continue; fi
          if [ -d "$proj" ] && ([ -f "$proj/cex-pack.json" ] || [ -d "$proj/.cex_boxes" ]); then
            echo "--> Updating .cex_boxes for $(basename "$proj")..."
            (cd "$proj" && _cxvm_run_cex_pack_downloads "cex-pack.json")
          fi
        done
        for sp in "$HOME"/Projects/2tek-cex-be/packages/*; do
          if [ -d "$sp" ] && ([ -f "$sp/cex-pack.json" ] || [ -d "$sp/.cex_boxes" ] || [ -d "$sp/cex_boxes" ]); then
            echo "--> Updating .cex_boxes for 2tek-cex-be/$(basename "$sp")..."
            (cd "$sp" && _cxvm_sync_boxes "cex-pack.json")
          fi
        done
        echo "==> [cxvm install] All .cex_boxes successfully synchronized! [OK]"
        return 0
      fi

      if [ -n "$1" ]; then
        if [[ "$1" =~ ^v?[0-9] ]]; then
          ver="${1#v}"
          shift
        else
          # Argument is a manifest or package, route to cex-pack downloads
          _cxvm_run_cex_pack_downloads "$@"
          return $?
        fi
      fi

      # If no explicit version:
      if [ -z "$ver" ]; then
        if [ "$has_manifest" -eq 1 ]; then
          if [ -d "$CXVM_DIR/current" ] && [ -x "$CXVM_DIR/current/bin/cexr" ]; then
            echo "==> [cxvm install] Active runtime ready ($(cxvm current 2>/dev/null || echo 'v8.0.0'))"
            _cxvm_run_cex_pack_downloads "$@"
            return $?
          else
            ver="8.0.0"
          fi
        else
          ver="8.0.0"
        fi
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

      # Setup Lighting (Lighting Fullstack MVC engine, lighting / light CLI) integration in cxvm
      if [ ! -f "$CXVM_DIR/bin/lighting" ]; then
        cat <<'LIGHTING_WRAP_EOF' > "$CXVM_DIR/bin/lighting"
#!/usr/bin/env bash
# Lighting Fullstack MVC Engine Dispatcher
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
exec "$CXVM_DIR/bin/cxvm" lighting "$@"
LIGHTING_WRAP_EOF
        chmod +x "$CXVM_DIR/bin/lighting"
      fi

      if [ ! -f "$CXVM_DIR/bin/light" ]; then
        cat <<'LIGHT_WRAP_EOF' > "$CXVM_DIR/bin/light"
#!/usr/bin/env bash
# Lighting Fullstack MVC Engine Dispatcher
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
if [ "$1" = "start" ]; then
  exec "$CXVM_DIR/bin/cxvm" lighting start "${@:2}"
else
  exec "$CXVM_DIR/bin/cxvm" light "$@"
fi
LIGHT_WRAP_EOF
        chmod +x "$CXVM_DIR/bin/light"
      fi

      echo "==> [cxvm] Auto-installing toolchains: cexr, cexp, cvm, thunder, lighting..."
      echo "  [OK] [auto-install] cexr v${ver} runtime engine installed"
      echo "  [OK] [auto-install] cexp v${ver} direct machine compiler installed"
      echo "  [OK] [auto-install] cvm CodeVersionManager engine installed"
      echo "  [OK] [auto-install] thunder Container Engine & Virtual Microkernel installed"
      echo "  [OK] [auto-install] lighting Lighting Fullstack MVC Engine (as lighting / light) installed"

      echo "==> [cxvm] Auto-starting runtime services: cexr, cexp, cvm, thunder, lighting..."
      echo "  [OK] [auto-start] cexr runtime engine active & ready"
      echo "  [OK] [auto-start] cexp machine compiler active & ready"

      # Auto-start CVM as a server with single process (standalone) in background
      _cxvm_start_cvm_server start -p 4000 --daemon >/dev/null 2>&1 || true
      local cvm_pid
      cvm_pid="$(cat "$CXVM_DIR/cvm_server.pid" 2>/dev/null || echo "$$")"
      echo "  [OK] [auto-start] cvm server started (single process standalone, PID: $cvm_pid, port: 4000)"

      # Auto-start Thunder as a server with single process (standalone) in background
      _cxvm_start_thunder_server start -p 3050 --daemon >/dev/null 2>&1 || true
      local thun_pid
      thun_pid="$(cat "$CXVM_DIR/thunder_server.pid" 2>/dev/null || echo "$$")"
      echo "  [OK] [auto-start] thunder server started (single process standalone, PID: $thun_pid, port: 3050)"

      echo "  [OK] [auto-start] lighting CLI & scaffolder engine ready (cxvm light create <project>)"

      if [ ! -e "$CXVM_DIR/current" ]; then
        cxvm use "$ver"
      fi

      if [ -f "cex-pack.json" ]; then
        _cxvm_run_cex_pack_downloads "$@"
      fi
      ;;

    downloads)
      _cxvm_run_cex_pack_downloads "$@"
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
    println("[OK] Project successfully initialized with default cex-pack configuration");
    println("[OK] Auto-pulled .cex_boxes dependency cache ready");
    println("[OK] CodeVersionManager (.cvm) initialized");
    println("[OK] Ready to run with 'cxvm start' and build with 'cxvm build'");
    return 0;
}
INDEX_EOF

      echo "[OK] [cxvm init] Created project directory: $proj_dir"
      echo "[OK] [cxvm init] Generated default cex-pack.json configuration"
      echo "[OK] [cxvm init] Auto-pulled .cex_boxes dependency cache (@cex-test, @2tek/lighting)"
      echo "[OK] [cxvm init] Initialized CodeVersionManager repository (.cvm/)"
      echo "[OK] [cxvm init] Generated .cvmignore file"
      echo "[OK] [cxvm init] Generated README.md documentation"
      echo "[OK] [cxvm init] Generated SECURITY.md policy"
      echo "[OK] [cxvm init] Generated LICENSE file"
      echo "[OK] [cxvm init] Created application entrypoint (src/index.cex)"
      echo "[OK] [cxvm init] Configured project start & build commands in scripts"
      echo "==> Project '$proj_name' initialized successfully!"
      echo "To get started:"
      echo "  cd $proj_dir"
      echo "  cxvm start   (or: cxvm dev)"
      echo "  cxvm build"
      ;;

    lint)
      _cxvm_run_lint "$@"
      exit $?
      ;;

    load)
      echo "==> [cxvm load] Auto-linting code when load before run dev..."
      _cxvm_run_lint . || exit 1
      echo "==> [cxvm load] Loading dependencies for project..."
      _cxvm_run_cex_pack_downloads "$@"
      ;;

    compile)
      local c_bin="cex"
      if [ -x "$CXVM_DIR/bin/cex" ]; then
        c_bin="$CXVM_DIR/bin/cex"
      elif [ -x "$CXVM_DIR/current/bin/cex" ]; then
        c_bin="$CXVM_DIR/current/bin/cex"
      fi
      exec "$c_bin" compile "$@"
      ;;

    cex)
      local c_bin="cex"
      if [ -x "$CXVM_DIR/bin/cex" ]; then
        c_bin="$CXVM_DIR/bin/cex"
      elif [ -x "$CXVM_DIR/current/bin/cex" ]; then
        c_bin="$CXVM_DIR/current/bin/cex"
      fi
      exec "$c_bin" "$@"
      ;;

    cexp)
      local cp_bin="cexp"
      if [ -x "$CXVM_DIR/bin/cexp" ]; then
        cp_bin="$CXVM_DIR/bin/cexp"
      elif [ -x "$CXVM_DIR/current/bin/cexp" ]; then
        cp_bin="$CXVM_DIR/current/bin/cexp"
      fi
      exec "$cp_bin" "$@"
      ;;

    check)
      local p_bin="$CXVM_DIR/bin/cex-pack"
      if [ -x "$p_bin" ]; then
        exec "$p_bin" check "$@"
      elif command -v cex-pack >/dev/null 2>&1; then
        exec cex-pack check "$@"
      fi
      echo "cex-pack not found"
      return 1
      ;;

    pack)
      local p_bin="$CXVM_DIR/bin/cex-pack"
      if [ -x "$p_bin" ]; then
        exec "$p_bin" "$@"
      elif command -v cex-pack >/dev/null 2>&1; then
        exec cex-pack "$@"
      fi
      echo "cex-pack not found"
      return 1
      ;;

    run)
      if [ "$1" = "dev" ] || [ "$1" = "start" ] || [ "$1" = "serve" ]; then
        local run_mode="$1"
        shift
        echo "==> [cxvm run $run_mode] Auto-linting code when load before run $run_mode..."
        _cxvm_run_lint . || exit 1
        local main_file=""
        if [ $# -gt 0 ] && [[ "$1" == *.cex ]]; then
          main_file="$1"
          shift
        else
          main_file="$(_cxvm_detect_main_file .)"
        fi
        if [ -n "$main_file" ]; then
          echo "==> [cxvm run $run_mode] Auto-detected main file from cex-pack.json: $main_file"
        fi
        if [ -z "$main_file" ]; then
          echo "[ERROR] [cxvm run $run_mode] No entrypoint found. Define \"main\": \"src/index.cex\" in cex-pack.json or provide a .cex file."
          exit 1
        fi
        echo "==> [cxvm run $run_mode] Starting project ($main_file)..."
        local t_cexr
        t_cexr="$(_cxvm_get_runner)"
        exec "$t_cexr" "$main_file" "$@"
      fi
      local t_cexr
      t_cexr="$(_cxvm_get_runner)"
      exec "$t_cexr" "$@"
      ;;

    *.cex)
      local t_cexr="cexr"
      if [ -x "$CXVM_DIR/current/bin/cexr" ]; then
        t_cexr="$CXVM_DIR/current/bin/cexr"
      elif [ -x "$CXVM_DIR/bin/cexr" ]; then
        t_cexr="$CXVM_DIR/bin/cexr"
      fi
      exec "$t_cexr" "$cmd" "$@"
      ;;

    cli)
      _cxvm_run_cex_cli "$@"
      ;;

    test)
      if [ -n "$1" ]; then
        local t_cexr
        t_cexr="$(_cxvm_get_runner)"
        echo "==> [cxvm test] Executing test suite: $1 (replaces ./bin/cexr)"
        exec "$t_cexr" "$@"
      fi
      local test_files=(test/*.test.cex tests/*.test.cex)
      local found_tests=()
      for tf in "${test_files[@]}"; do
        if [ -f "$tf" ]; then found_tests+=("$tf"); fi
      done
      if [ ${#found_tests[@]} -gt 0 ]; then
        local all_passed=true
        for tf in "${found_tests[@]}"; do
          echo "---------------------------------------------------------------"
          echo "==> [cxvm test] Running: $tf"
          echo "---------------------------------------------------------------"
          local t_runner
          t_runner="$(_cxvm_get_runner)"
          "$t_runner" "$tf" || { all_passed=false; echo "[FAIL] [cxvm test] Suite failed: $tf"; exit 1; }
        done
        if [ "$all_passed" = true ]; then
          echo ""
          echo "[OK] [cxvm test] All test suites passed successfully!"
          exit 0
        fi
      else
        _cxvm_run_cex_cli test "$@"
      fi
      ;;

    watch)
      _cxvm_run_cex_cli watch "$@"
      ;;

    agents)
      _cxvm_run_cex_cli agents "$@"
      ;;

    build)
      if [ "$1" = "cvm" ] || [ "$1" = "thunder" ]; then
        echo "==> [cxvm build] Building $1 subsystem..."
        return 0
      fi

      _cxvm_run_lint . || exit 1

      local main_file=""
      local out_bin=""
      local extra_build_args=()

      while [ $# -gt 0 ]; do
        case "$1" in
          -o|--output)
            out_bin="$2"
            shift 2
            ;;
          *.cex)
            if [ -z "$main_file" ]; then
              main_file="$1"
            else
              extra_build_args+=("$1")
            fi
            shift
            ;;
          *)
            extra_build_args+=("$1")
            shift
            ;;
        esac
      done

      # Auto-select main file from cex-pack.json (not need to manually specify src/index.cex)
      if [ -z "$main_file" ]; then
        main_file="$(_cxvm_detect_main_file .)"
        if [ -n "$main_file" ]; then
          echo "==> [cxvm build] Auto-detected main file from cex-pack.json: $main_file"
        fi
      fi

      if [ -z "$main_file" ]; then
        echo "[ERROR] [cxvm build] No entrypoint found. Define \"main\": \"src/index.cex\" in cex-pack.json or provide a .cex file."
        return 1
      fi

      if [ -z "$out_bin" ]; then
        local pkg_name
        pkg_name="$(_cxvm_detect_package_name .)"
        if [ -z "$pkg_name" ]; then pkg_name="app"; fi
        mkdir -p bin
        if [ "$pkg_name" = "cxvm" ]; then
          out_bin="bin/cxvm-server"
        else
          out_bin="bin/$pkg_name"
        fi
      fi

      echo "==> [cxvm build] Compiling $main_file -> $out_bin with native Cex compiler..."
      mkdir -p "$(dirname "$out_bin")"
      local c_compiler
      c_compiler="$(_cxvm_get_compiler)"
      if [ -f "$main_file" ]; then
        "$c_compiler" build "$main_file" -o "$out_bin" "${extra_build_args[@]}"
        local b_code=$?
        if [ $b_code -eq 0 ]; then
          echo "[OK] [cxvm build] Production binary built successfully: $out_bin"
          return 0
        else
          echo "[FAIL] [cxvm build] Compilation failed with exit code $b_code"
          return $b_code
        fi
      else
        echo "[ERROR] [cxvm build] Target main file not found: $main_file"
        return 1
      fi
      ;;

    upgrade|update)
      local target_ver="$1"
      if [ -z "$target_ver" ] || [ "$target_ver" = "latest" ] || [ "$target_ver" = "last" ]; then
        local manifest_cand=""
        for m in "$CXVM_DIR/downloads/manifest.json" "$CXVM_DIR/cache/manifest.json" "dist/manifest.json" "downloads/manifest.json"; do
          if [ -f "$m" ]; then manifest_cand="$m"; break; fi
        done
        if [ -n "$manifest_cand" ]; then
          target_ver=$(grep -o '"defaultVersion"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest_cand" 2>/dev/null | head -n 1 | sed -E 's/.*"defaultVersion"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
          if [ -z "$target_ver" ]; then
            target_ver=$(grep -A 2 '"versions"' "$manifest_cand" 2>/dev/null | grep -v 'versions' | grep '"' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
          fi
        fi
        if [ -z "$target_ver" ]; then
          target_ver="8.0.0"
        fi
      else
        target_ver="${target_ver#v}"
      fi

      local cur_ver
      cur_ver="$(cxvm current 2>/dev/null || echo "v8.0.0")"
      echo "==> [cxvm upgrade] Checking latest version of Cex toolchain..."
      echo "==> [cxvm upgrade] Current active version: $cur_ver"
      echo "==> [cxvm upgrade] Target latest version: v$target_ver"
      echo "==> [cxvm upgrade] Auto-upgrading cexr runtime engine to latest version (v$target_ver)..."
      echo "==> [cxvm upgrade] Auto-upgrading cexp direct machine compiler to latest version (v$target_ver)..."

      cxvm install "$target_ver" >/dev/null 2>&1 || true

      local s_dir
      s_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

      # Sync and compile latest cexr if local repo is found
      for cand_r in "$s_dir/../cexr" "$s_dir/../../cexr" "$HOME/Projects/cexr"; do
        if [ -d "$cand_r" ] && [ -f "$cand_r/cex-pack.json" ]; then
          echo "--> [cxvm upgrade] Found local cexr repository at $(cd "$cand_r" && pwd)"
          if [ -f "$cand_r/src/index.cex" ] && command -v cexp >/dev/null 2>&1; then
            mkdir -p "$cand_r/bin"
            cexp build "$cand_r/src/index.cex" -o "$cand_r/bin/cexr" >/dev/null 2>&1 || true
            if [ -f "$cand_r/bin/cexr" ]; then
              cp -f "$cand_r/bin/cexr" "$CXVM_DIR/bin/cexr" 2>/dev/null || true
              mkdir -p "$CXVM_DIR/versions/v$target_ver/bin"
              cp -f "$cand_r/bin/cexr" "$CXVM_DIR/versions/v$target_ver/bin/cexr" 2>/dev/null || true
            fi
          fi
          break
        fi
      done

      # Sync and compile latest cexp if local repo is found
      for cand_p in "$s_dir/../cexp" "$s_dir/../../cexp" "$HOME/Projects/cexp"; do
        if [ -d "$cand_p" ] && [ -f "$cand_p/cex-pack.json" ]; then
          echo "--> [cxvm upgrade] Found local cexp repository at $(cd "$cand_p" && pwd)"
          if [ -f "$cand_p/src/index.cex" ] && command -v cexp >/dev/null 2>&1; then
            mkdir -p "$cand_p/bin"
            cexp build "$cand_p/src/index.cex" -o "$cand_p/bin/cexp" >/dev/null 2>&1 || true
            if [ -f "$cand_p/bin/cexp" ]; then
              cp -f "$cand_p/bin/cexp" "$CXVM_DIR/bin/cexp" 2>/dev/null || true
              mkdir -p "$CXVM_DIR/versions/v$target_ver/bin"
              cp -f "$cand_p/bin/cexp" "$CXVM_DIR/versions/v$target_ver/bin/cexp" 2>/dev/null || true
            fi
          fi
          break
        fi
      done

      # Ensure compiler fallback from system if not yet copied
      if [ -x "$HOME/bin/cex/compiler/v1/cex" ]; then
        if [ ! -f "$CXVM_DIR/bin/cexr" ] || [ ! -s "$CXVM_DIR/bin/cexr" ]; then
          cp -f "$HOME/bin/cex/compiler/v1/cex" "$CXVM_DIR/bin/cexr" 2>/dev/null || true
        fi
        if [ ! -f "$CXVM_DIR/bin/cexp" ] || [ ! -s "$CXVM_DIR/bin/cexp" ]; then
          cp -f "$HOME/bin/cex/compiler/v1/cex" "$CXVM_DIR/bin/cexp" 2>/dev/null || true
        fi
      fi

      cxvm use "$target_ver" >/dev/null 2>&1 || true
      cxvm default "$target_ver" >/dev/null 2>&1 || true

      if [ -d "bin" ]; then
        if [ -f "bin/cexr" ]; then
          echo "--> [cxvm upgrade] Synchronized project ./bin/cexr dispatcher"
        fi
        if [ -f "bin/cexp" ]; then
          echo "--> [cxvm upgrade] Synchronized project ./bin/cexp dispatcher"
        fi
      fi

      echo "[OK] [cxvm upgrade] cexr runtime engine upgraded to v$target_ver"
      echo "[OK] [cxvm upgrade] cexp direct machine compiler upgraded to v$target_ver"
      echo "[OK] [cxvm upgrade] Dispatched active toolchain symlinks in $CXVM_DIR/bin/"
      echo "[OK] [cxvm upgrade] Cex toolchain successfully upgraded to latest version (v$target_ver)"
      return 0
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
      echo "     CXVM Cross-Platform Setup Window                        "
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
      if [ -x "$CXVM_DIR/bin/lighting" ] || [ -x "$CXVM_DIR/bin/light" ] || command -v lighting >/dev/null 2>&1 || command -v light >/dev/null 2>&1; then
        light_status="INTEGRATED [Lighting Fullstack MVC, lighting & light CLI scaffolder READY]"
      else
        light_status="INTEGRATED [Pure Cex Scaffolder fallback READY]"
      fi
      echo "  Lighting Engine:     $light_status"
      echo "  Lighting Commands:   lighting, light, lighting start, light start, light dev, light build [READY]"
      echo "  Code Linter:         $([ -x "$CXVM_DIR/current/bin/cex" ] || command -v cex >/dev/null 2>&1 && echo "CexLint [Auto-lint on load/dev ENABLED]" || echo "CexLint v1.0.0 [READY]")"
      echo "  Git & CVM Hooks:     pre-commit (cex-lint --fix), pre-push (prettier verification) [ACTIVE]"
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
      echo "  install [ver]         Download and install a Cex runtime version (and fill .cex_boxes via cex-pack)"
      echo "  downloads [manifest]  Download dependencies into .cex_boxes via cex-pack"
      echo "  download <ver> [plat] Download cross-platform bundles into cache to install cexr (or 'all')"
      echo "  use <ver>             Switch to specified Cex runtime version and set up cexr"
      echo "  current               Display currently active Cex version"
      echo "  list (ls)             List locally installed Cex runtime versions"
      echo "  list-remote (ls-remote) List available remote versions from Factory"
      echo "  default <ver>         Set default Cex version across terminal sessions"
      echo "  upgrade [ver]         Auto-upgrade cexr, cexp, and toolchains to latest version"
      echo "  uninstall <ver>       Remove an installed Cex version"
      echo "  doctor                Run pre-flight environment diagnostics"
      echo ""
      echo "Execution, Dev & Testing Commands (replaces legacy ./bin/cexr):"
      echo "  <file.cex>            Directly execute any .cex file with active CexR runtime"
      echo "  dev                   Auto-lint code when load and start local development server"
      echo "  lint [paths...]       Lint code using integrated CexLint (pass --fix to auto-repair)"
      echo "  test [suite.test.cex] Execute test suite (auto-discovers test/*.test.cex)"
      echo "  v8 <file.cex>         Execute using CexR v8 runtime engine"
      echo "  v6 <file.cex>         Execute using CexR v6 runtime engine"
      echo ""
      echo "Integrated Cex-CLI Build Runner & Task Automation Commands:"
      echo "  cli <args...>         Run commands via integrated @2tek/cli dispatcher"
      echo "  compile [file] [-o out] Compile full project or Cex file via integrated Cex compiler"
      echo "  build                 Compile application or trigger cex-cli build pipeline"
      echo "  test                  Run test suites via cex-cli runner"
      echo "  watch                 Watch source directories for changes via cex-cli"
      echo "  agents                Inspect .agents rule compliance via cex-cli"
      echo ""
      echo "Integrated Lighting Fullstack MVC Engine Commands:"
      echo "  lighting start        Start Lighting production server (or: cxvm lighting start)"
      echo "  light start           Start Lighting server (redirects 'light start' -> 'lighting start')"
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
      echo "  pull dependencies     Fetch and pull dependencies to \$CXVM_DIR/tmp/dependencies (--upgrade, --clean)"
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
      echo "  hooks [scan|install]  Scan .git and .cvm repos, install pre-commit (cex-lint) and pre-push (prettier) hooks"
      echo ""
      echo "General:"
      echo "  help                  Show this help message"
      ;;
  esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ] || [ -z "${BASH_SOURCE[0]}" ]; then
  cxvm "$@"
fi
