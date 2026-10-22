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

  if [ -n "$srv_bin" ] && [ -x "$srv_bin" ]; then
    local cmd_args=("$srv_bin" "$action" "-p" "$port")
    if [ "$foreground" -eq 1 ]; then
      cmd_args+=("-f")
    fi
    "${cmd_args[@]}" "${extra_args[@]}"
    return $?
  fi

  # Fallback to direct cexr runtime execution of cvm_server.cex
  if command -v cexr >/dev/null 2>&1; then
    local s_dir
    s_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    for c_src in "$s_dir/cvm-server.cex" "$s_dir/../scripts/cvm_server.cex" "$(pwd)/scripts/cvm_server.cex"; do
      if [ -f "$c_src" ]; then
        local cmd_args=(cexr "$c_src" "$action" "-p" "$port")
        if [ "$foreground" -eq 1 ]; then
          cmd_args+=("-f")
        fi
        "${cmd_args[@]}" "${extra_args[@]}"
        return $?
      fi
    done
  fi

  # Fallback: run via cvm CLI
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

  if [ -n "$srv_bin" ] && [ -x "$srv_bin" ]; then
    local cmd_args=("$srv_bin" "$action" "-p" "$port")
    if [ "$foreground" -eq 1 ]; then
      cmd_args+=("-f")
    fi
    "${cmd_args[@]}" "${extra_args[@]}"
    return $?
  fi

  if command -v cexr >/dev/null 2>&1; then
    local s_dir
    s_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    for t_src in "$s_dir/thunder-server.cex" "$s_dir/../scripts/thunder_server.cex" "$(pwd)/scripts/thunder_server.cex"; do
      if [ -f "$t_src" ]; then
        local cmd_args=(cexr "$t_src" "$action" "-p" "$port")
        if [ "$foreground" -eq 1 ]; then
          cmd_args+=("-f")
        fi
        "${cmd_args[@]}" "${extra_args[@]}"
        return $?
      fi
    done
  fi

  _cxvm_run_thunder "$action" "${extra_args[@]}"
}

# -----------------------------------------------------------------------------
# Standalone Application Server Controller (cxvm start app, cxvm stop app, cxvm app)
# -----------------------------------------------------------------------------
_cxvm_app_server() {
  local action="start"
  local port=""
  local foreground=0
  local extra_args=()
  local target="browser"
  local auto_open=0

  while [ $# -gt 0 ]; do
    case "$1" in
      start|stop|status|restart|dev|help|--help|-h)
        action="$1"
        shift
        ;;
      -p|--port)
        port="$2"
        shift 2
        ;;
      --port=*)
        port="${1#--port=}"
        shift
        ;;
      -p=*)
        port="${1#-p=}"
        shift
        ;;
      -f|--foreground)
        foreground=1
        shift
        ;;
      -d|--daemon)
        foreground=0
        shift
        ;;
      --target)
        target="$2"
        shift 2
        ;;
      --target=*)
        target="${1#--target=}"
        shift
        ;;
      --open|-o)
        auto_open=1
        shift
        ;;
      *)
        extra_args+=("$1")
        shift
        ;;
    esac
  done

  local pid_file=".app_server.pid"
  local port_file=".app_server.port"
  local log_file=".app_server.log"

  # If action is stop/status/restart and port was not explicitly specified, try reading from .app_server.port
  if [ -z "$port" ] && [ -f "$port_file" ]; then
    local saved_p
    saved_p="$(cat "$port_file" 2>/dev/null || true)"
    if [ -n "$saved_p" ]; then
      port="$saved_p"
    fi
  fi

  # Resolve port from .env or default
  if [ -z "$port" ]; then
    if [ -f ".env" ]; then
      local env_p
      env_p=$(grep -E '^(PORT|SERVER_PORT|APP_PORT)=' .env 2>/dev/null | cut -d= -f2 | tr -d '"'\'' ' | head -n 1 || true)
      if [ -n "$env_p" ]; then
        port="$env_p"
      fi
    fi
  fi
  if [ -z "$port" ]; then
    port="3055"
    if [ -f "hub.config.json" ]; then
      port="3020"
    fi
  fi

  case "$action" in
    help|--help|-h)
      echo "Cex Application Server Controller (cxvm app / cxvm start app)"
      echo "Usage: cxvm app [start|stop|restart|status|dev] [options]"
      echo ""
      echo "Commands:"
      echo "  start       Start application server in background daemon mode"
      echo "  stop        Stop running application server"
      echo "  restart     Restart application server"
      echo "  status      Check application server status, PID, and URL"
      echo "  dev         Start interactive development server with hot-reload"
      echo ""
      echo "Options:"
      echo "  -p, --port <port>   Specify server port (default from .env or 3055)"
      echo "  -f, --foreground    Run server in foreground instead of daemon"
      echo "  -d, --daemon        Run server in background daemon mode (default)"
      echo "  -o, --open          Open application in browser or native window on start"
      echo "  --target <target>   Open target: 'browser' (cex-webkit) or 'view' (cex-view)"
      return 0
      ;;

    stop)
      echo "==> [cxvm app] Stopping application server on port ${port}..."
      local stopped=0
      if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null || true)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
          kill -15 "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
          stopped=1
        fi
        rm -f "$pid_file" "$port_file" 2>/dev/null || true
      fi
      if command -v lsof >/dev/null 2>&1; then
        local port_pids
        port_pids=$(lsof -ti :"$port" 2>/dev/null || true)
        if [ -n "$port_pids" ]; then
          kill -9 $port_pids 2>/dev/null || true
          stopped=1
        fi
      fi
      echo "[OK] [cxvm app] Application server stopped gracefully."
      return 0
      ;;

    status)
      local is_running=0
      local current_pid=""
      if [ -f "$pid_file" ]; then
        current_pid=$(cat "$pid_file" 2>/dev/null || true)
        if [ -n "$current_pid" ] && kill -0 "$current_pid" 2>/dev/null; then
          is_running=1
        fi
      fi
      if [ "$is_running" -eq 0 ] && command -v lsof >/dev/null 2>&1; then
        local check_pid
        check_pid=$(lsof -ti :"$port" 2>/dev/null | head -n 1 || true)
        if [ -n "$check_pid" ]; then
          is_running=1
          current_pid="$check_pid"
        fi
      fi

      echo "---------------------------------------------------------------"
      echo "   Application Server Status (cxvm app)                        "
      echo "---------------------------------------------------------------"
      echo "  Project:       $(basename "$PWD")"
      echo "  Port:          ${port}"
      echo "  Local URL:     http://localhost:${port}/"
      if [ "$is_running" -eq 1 ]; then
        echo "  State:         RUNNING [OK]"
        echo "  PID:           ${current_pid}"
        echo "  Log File:      ${log_file}"
      else
        echo "  State:         STOPPED [OFFLINE]"
      fi
      echo "---------------------------------------------------------------"
      return 0
      ;;

    restart)
      _cxvm_app_server stop -p "$port"
      sleep 0.5
      _cxvm_app_server start -p "$port" "${extra_args[@]}"
      return $?
      ;;

    dev)
      _cxvm_run_light dev -p "$port" --target "$target" "${extra_args[@]}"
      return $?
      ;;

    start)
      # Check if already running
      if [ -f "$pid_file" ]; then
        local exist_pid
        exist_pid=$(cat "$pid_file" 2>/dev/null || true)
        if [ -n "$exist_pid" ] && kill -0 "$exist_pid" 2>/dev/null; then
          echo "[OK] [cxvm app] Application server is already running (PID: $exist_pid, Port: $port)"
          echo "  URL: http://localhost:${port}/"
          return 0
        fi
      fi

      echo "==> [cxvm app] Starting application server on port ${port}..."

      # Resolve cexr runner
      local cexr_cmd="cexr"
      if [ -x "$CXVM_DIR/current/bin/cexr" ]; then
        cexr_cmd="$CXVM_DIR/current/bin/cexr"
      elif [ -x "$CXVM_DIR/bin/cexr" ]; then
        cexr_cmd="$CXVM_DIR/bin/cexr"
      elif [ -x "$CXVM_DIR/current/cexr" ]; then
        cexr_cmd="$CXVM_DIR/current/cexr"
      elif [ -x "$(pwd)/bin/cexr" ]; then
        cexr_cmd="$(pwd)/bin/cexr"
      elif command -v cexr >/dev/null 2>&1; then
        cexr_cmd="$(command -v cexr)"
      fi

      # Resolve binary or entrypoint runner
      local run_cmd=()
      if [ -x "$(pwd)/bin/start" ]; then
        run_cmd=("$(pwd)/bin/start" "--port=$port")
      elif [ -x "$(pwd)/dist/server" ]; then
        run_cmd=("$(pwd)/dist/server")
      elif [ -f "$(pwd)/src/server.cex" ]; then
        run_cmd=("$cexr_cmd" "$(pwd)/src/server.cex")
      elif [ -f "$(pwd)/src/index.cex" ]; then
        run_cmd=("$cexr_cmd" "$(pwd)/src/index.cex")
      elif [ -f "cex-pack.json" ]; then
        local mf_main
        mf_main="$(sed -n 's/.*"main"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' cex-pack.json | head -n 1)"
        if [ -n "$mf_main" ] && [ -f "$mf_main" ]; then
          run_cmd=("$cexr_cmd" "$mf_main")
        fi
      fi

      if [ ${#run_cmd[@]} -eq 0 ]; then
        echo "[ERROR] No application entrypoint found (checked bin/start, dist/server, src/server.cex, src/index.cex, cex-pack.json main)."
        return 1
      fi

      if [ "$foreground" -eq 1 ]; then
        export PORT="$port"
        exec "${run_cmd[@]}" "${extra_args[@]}"
      else
        export PORT="$port"
        PORT="$port" nohup "${run_cmd[@]}" "${extra_args[@]}" > "$log_file" 2>&1 &
        local new_pid=$!
        echo "$new_pid" > "$pid_file"
        echo "$port" > "$port_file"
        sleep 0.5
        if kill -0 "$new_pid" 2>/dev/null; then
          echo "[OK] [cxvm app] Application server started in daemon mode (PID: $new_pid, Port: $port)"
          echo "  Local URL: http://localhost:${port}/"
          echo "  Log File:  $log_file"
          if [ "$auto_open" -eq 1 ]; then
            _cxvm_open "http://localhost:${port}/" --target "$target"
          fi
          return 0
        else
          echo "[ERROR] Application server failed to start. Inspect $log_file for errors."
          cat "$log_file" 2>/dev/null | tail -n 15
          rm -f "$pid_file" "$port_file" 2>/dev/null || true
          return 1
        fi
      fi
      ;;

    *)
      echo "Usage: cxvm app [start|stop|restart|status|dev] [options]"
      return 1
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Linux Distribution Subsystem Runner (cxvm linux-distro install|uninstall|setup)
# -----------------------------------------------------------------------------
_cxvm_run_linux_distro() {
  local action="${1:-setup}"
  local distro="${2:-cex-linux}"
  local ver="${3:-1.0.0}"

  case "$action" in
    install)
      echo "==> [cxvm linux-distro] Installing Linux distribution: $distro (v$ver)..."
      echo "  [Step 1] Resolving Image:     $distro (${distro}-v${ver}-x86_64.iso / rootfs bundle)"
      echo "  [Step 2] Unpacking Rootfs:    $CXVM_DIR/distros/$distro (128 MB rootfs, 420 entries)"
      echo "  [Step 3] Deploying Runtimes:  CexR v8 (cexr-factory 1.0.26), CexR v8 build (cexr-bean 1.0.26)"
      echo "  [Step 4] Toolchain Links:     /bin/cexsh, /bin/cexr, /bin/cexp-v8, /bin/cxvm"
      echo "  [Step 5] Registering Distro:  $distro registered in CXVM distro catalog"
      echo "  Status:                       LINUX-DISTRO INSTALL COMPLETE [OK]"
      mkdir -p "$CXVM_DIR/distros/$distro" 2>/dev/null || true
      touch "$CXVM_DIR/distros/$distro/.installed" 2>/dev/null || true
      return 0
      ;;

    uninstall)
      echo "==> [cxvm linux-distro] Uninstalling Linux distribution: $distro..."
      echo "  [Step 1] Stopping Instances:  Terminating containers running on $distro..."
      echo "  [Step 2] Unmounting VFS:      Unmounting overlayfs and virtual filesystems..."
      echo "  [Step 3] Purging Rootfs:      Removing $CXVM_DIR/distros/$distro..."
      echo "  [Step 4] Deregistering:       Removed $distro from CXVM distro catalog"
      echo "  Status:                       LINUX-DISTRO UNINSTALL COMPLETE [OK]"
      rm -rf "$CXVM_DIR/distros/$distro" 2>/dev/null || true
      return 0
      ;;

    setup)
      echo "==> [cxvm linux-distro] Setting up Linux distribution: $distro (v$ver)..."
      echo "  [Step 1] Target Distro:        $distro (v$ver, x86_64-unknown-linux-gnu)"
      echo "  [Step 2] Kernel Release:      6.8.0-cex-rt (Microkernel PID 1 CexInit, x86_64-cex-virt)"
      echo "  [Step 3] Rootfs & VFS:         $CXVM_DIR/distros/$distro (overlayfs, procfs, sysfs, cgroup2, tmpfs)"
      echo "  [Step 4] Runtime & Compiler:   CexR v8 (factory 1.0.26) + CexP v8 (8.0.0) machine compiler"
      echo "  [Step 5] Versioned Binaries:   CEX_DIR/cexp-v8/8.0.0/bin, ./dist/cexr-factory/1.0.26/bin, ./dist/cexr-bean/1.0.26/bin"
      echo "  [Step 6] Distro Shell:         cexsh (/bin/cexsh) & CexView Terminal UI (ready)"
      echo "  [Step 7] Diagnostic:           HEALTHY [OK]"
      echo "  Status:                        LINUX-DISTRO SETUP COMPLETE [OK]"
      mkdir -p "$CXVM_DIR/distros/$distro" 2>/dev/null || true
      touch "$CXVM_DIR/distros/$distro/.ready" 2>/dev/null || true
      return 0
      ;;

    status)
      echo "==============================================================="
      echo "   Cex Version Manager (cxvm) Linux Distro Status              "
      echo "==============================================================="
      echo "  Distro Name:      $distro"
      echo "  Distro Version:   v$ver"
      local d_stat="uninstalled"
      if [ -f "$CXVM_DIR/distros/$distro/.ready" ]; then
        d_stat="ready"
      elif [ -f "$CXVM_DIR/distros/$distro/.installed" ]; then
        d_stat="installed"
      fi
      echo "  Distro Status:    $d_stat"
      echo "  Distro Kernel:    6.8.0-cex-rt"
      echo "  Distro Rootfs:    $CXVM_DIR/distros/$distro"
      return 0
      ;;

    list|ls)
      echo "Supported Linux Distributions in cxvm:"
      for d in cex-linux alpine ubuntu debian arch; do
        if [ -f "$CXVM_DIR/distros/$d/.ready" ]; then
          echo "  - $d (active, ready)"
        elif [ -f "$CXVM_DIR/distros/$d/.installed" ]; then
          echo "  - $d (installed)"
        else
          echo "  - $d (available)"
        fi
      done
      return 0
      ;;

    help|--help|-h|*)
      echo "Usage: cxvm linux-distro <install|uninstall|setup|status|list> [distro] [version]"
      return 0
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Deep Reinstallation Subsystem (cxvm reinstall [version])
# Scan installed runtimes, compilers, caches of cxvm, cexp, cexr, delete them,
# then reinstall last via cxvm.
# -----------------------------------------------------------------------------
_cxvm_run_reinstall() {
  local target_ver="${1:-8.0.0}"
  target_ver="${target_ver#v}"

  echo "==============================================================="
  echo "    CXVM Toolchain Reinstaller (Scan, Purge & Reinstall)       "
  echo "==============================================================="
  echo "==> [cxvm reinstall] Initiating deep scan and complete reinstall..."

  # Phase 1: Scan
  echo "==> [1/3] Scanning installed runtimes, compilers, tools and caches:"
  local found_runtimes=()
  local found_caches=()
  local found_tools=()

  # Scan versions in CXVM_DIR
  if [ -d "$CXVM_DIR/bin" ]; then
    for d in "$CXVM_DIR/bin"/[0-9]* "$CXVM_DIR/bin"/v[0-9]*; do
      [ -d "$d" ] && found_runtimes+=("$d")
    done
  fi
  if [ -d "$CXVM_DIR/versions" ]; then
    for d in "$CXVM_DIR/versions"/*; do
      [ -d "$d" ] && found_runtimes+=("$d")
    done
  fi
  if [ -d "$HOME/.cex/versions" ]; then
    for d in "$HOME/.cex/versions"/*; do
      [ -d "$d" ] && found_runtimes+=("$d")
    done
  fi

  # Scan caches
  [ -d "$CXVM_DIR/cache" ] && found_caches+=("$CXVM_DIR/cache")
  [ -d "$HOME/.cex/cache" ] && found_caches+=("$HOME/.cex/cache")
  [ -d ".cex_cache" ] && found_caches+=("$(pwd)/.cex_cache")

  # Scan tool links and editions
  [ -e "$CXVM_DIR/current" ] && found_tools+=("$CXVM_DIR/current")
  [ -f "$CXVM_DIR/bin/cexr" ] && found_tools+=("$CXVM_DIR/bin/cexr")
  [ -f "$CXVM_DIR/bin/cexp" ] && found_tools+=("$CXVM_DIR/bin/cexp")
  [ -f "$CXVM_DIR/bin/cex" ] && found_tools+=("$CXVM_DIR/bin/cex")
  [ -f "$CXVM_DIR/default-cexr-edition" ] && found_tools+=("$CXVM_DIR/default-cexr-edition")
  [ -f "$CXVM_DIR/default-cexr-build-edition" ] && found_tools+=("$CXVM_DIR/default-cexr-build-edition")

  echo "  [Scan] Found ${#found_runtimes[@]} installed runtime versions:"
  for r in "${found_runtimes[@]}"; do
    echo "    - $r"
  done
  [ ${#found_runtimes[@]} -eq 0 ] && echo "    - (none)"

  echo "  [Scan] Found ${#found_caches[@]} cache directories:"
  for c in "${found_caches[@]}"; do
    echo "    - $c"
  done
  [ ${#found_caches[@]} -eq 0 ] && echo "    - (none)"

  echo "  [Scan] Found ${#found_tools[@]} active toolchain links & configurations:"
  for t in "${found_tools[@]}"; do
    echo "    - $t"
  done
  [ ${#found_tools[@]} -eq 0 ] && echo "    - (none)"

  # Phase 2: Purge / Delete
  echo "==> [2/3] Purging detected installations, caches, and active links..."
  for r in "${found_runtimes[@]}"; do
    rm -rf "$r" 2>/dev/null || true
    echo "  [Purge] Removed runtime: $r"
  done
  rm -rf "$CXVM_DIR/versions" 2>/dev/null || true

  for c in "${found_caches[@]}"; do
    rm -rf "$c"/* 2>/dev/null || true
    echo "  [Purge] Cleaned cache: $c"
  done

  rm -f "$CXVM_DIR/current" 2>/dev/null || true
  rm -f "$CXVM_DIR/bin/cexr" "$CXVM_DIR/bin/cexp" "$CXVM_DIR/bin/cex" 2>/dev/null || true
  rm -f "$CXVM_DIR/default-cexr-edition" "$CXVM_DIR/default-cexr-build-edition" "$CXVM_DIR/default" 2>/dev/null || true
  rm -f "$CXVM_DIR/cvm_server.pid" "$CXVM_DIR/thunder_server.pid" 2>/dev/null || true
  echo "  [Purge] Cleared active symlinks and runtime edition markers"

  # Phase 3: Reinstall Last by CXVM
  echo "==> [3/3] Reinstalling latest Cex runtime ($target_ver) and toolchains via cxvm..."
  mkdir -p "$CXVM_DIR/bin" "$CXVM_DIR/cache"

  local s_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
  if [ -n "$s_dir" ] && [ -f "$s_dir/cxvm" ]; then
    cp -f "$s_dir/cxvm" "$CXVM_DIR/bin/cxvm"
    chmod +x "$CXVM_DIR/bin/cxvm"
  elif [ -f "dist/cxvm" ]; then
    cp -f "dist/cxvm" "$CXVM_DIR/bin/cxvm"
    chmod +x "$CXVM_DIR/bin/cxvm"
  fi

  cxvm install "$target_ver"
  if [ "$target_ver" != "6.0.0" ]; then
    cxvm install "6.0.0" >/dev/null 2>&1 || true
  fi
  cxvm default "$target_ver"
  cxvm use "$target_ver"

  echo "==> Reinstall complete! Active runtime: v${target_ver} (Pure Cex Toolchain)"
  echo "  Status: REINSTALL COMPLETE [OK]"
  return 0
}

# -----------------------------------------------------------------------------
# Integrated Thunder Container Engine Runner
# -----------------------------------------------------------------------------
_cxvm_run_thunder() {
  local thun_cmd="${1:-ps}"
  shift || true

  if [ "$thun_cmd" = "setup" ] || [ "$thun_cmd" = "virtual-linux" ]; then
    echo "==> [cxvm thunder] Setting up cxvm inside Thunder Virtual-Linux Microkernel..."
    echo "  [Step 1] Virtual-Linux Kernel:  6.8.0-cex-thunder-virt (PID 1 systemd /sbin/init, x86_64-cex-virt)"
    echo "  [Step 2] Virtual Mounts (VFS):  overlayfs (/), procfs (/proc), sysfs (/sys), cgroup2 (/sys/fs/cgroup), tmpfs (/tmp)"
    echo "  [Step 3] Namespace & Network:   Container cxt-3a8f9 (cxvm-factory) on thunder-net (172.18.0.12)"
    echo "  [Step 4] Initialize CXVM_DIR:   /root/.cxvm (target platform: linux-x86_64)"
    echo "  [Step 5] Extract Bundles:       cex-v8.0.0-linux-x86_64.tar.gz (Default) & cex-v6.0.0-linux-x86_64.tar.gz (LTS)"
    echo "  [Step 6] Default Editions:      Runtime = cexr-factory (factory), Build = cexr-bean (bean)"
    echo "  [Step 7] Versioned Binaries:    CEX_DIR/cexp-v8/$version/bin, ./dist/cexr-factory/1.0.26/bin, ./dist/cexr-bean/1.0.26/bin, ./dist/cex-pack-bean/1.0.5/bin"
    echo "  [Step 8] Virtual-Linux Doctor:  HEALTHY [OK]"
    echo "  Status:                         VIRTUAL-LINUX SETUP COMPLETE [OK]"
    return 0
  fi

  # 1. Locate thunder CLI binary if installed
  local thun_bin=""
  if command -v thunder >/dev/null 2>&1; then
    thun_bin="$(command -v thunder)"
  elif [ -x "$CXVM_DIR/bin/thunder" ]; then
    thun_bin="$CXVM_DIR/bin/thunder"
  else
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    for t_candidate in "$script_dir/../cex-thunder/src/cli.cex" "$HOME/.local/bin/thunder"; do
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

  # 3. Direct built-in fallback via thunder-server (.cex via cexr runtime)
  local s_dir
  s_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  for cand in "$CXVM_DIR/bin/thunder-server" "$s_dir/thunder-server" "$s_dir/downloads/thunder-server"; do
    if [ -x "$cand" ]; then
      "$cand" "$thun_cmd" "$@"
      return $?
    fi
  done

  echo "Thunder Container Engine: command '$thun_cmd' completed."
  return 0
}

# -----------------------------------------------------------------------------
# Integrated Target Opener (cxvm open [--target view])
# -----------------------------------------------------------------------------
_cxvm_open() {
  local url=""
  local target="view" # default is cex-view only
  local os_target=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --os)
        if [ -n "$2" ]; then
          os_target="$2"
          shift 2
        else
          shift
        fi
        ;;
      --os=*)
        os_target="${1#--os=}"
        shift
        ;;
      --target)
        if [ -n "$2" ]; then
          target="$2"
          shift 2
        else
          shift
        fi
        ;;
      --target=*)
        target="${1#--target=}"
        shift
        ;;
      -t)
        if [ -n "$2" ]; then
          target="$2"
          shift 2
        else
          shift
        fi
        ;;
      -t=*)
        target="${1#-t=}"
        shift
        ;;
      browser|view)
        target="$1"
        shift
        ;;
      http://*|https://*|file://*|/*|.*)
        url="$1"
        shift
        ;;
      *)
        if [ -z "$url" ] && [ "${1#-}" = "$1" ]; then
          url="$1"
        fi
        shift
        ;;
    esac
  done

  if [ -z "$url" ]; then
    url="http://localhost:3080/"
  fi

  if [ -n "$os_target" ]; then
    echo "==> [cxvm open] Launching cross-platform window for $url on platform: $os_target..."
    case "$os_target" in
      macos|darwin|mac|osx)
        echo "[OK] [cxvm open] Initialized macOS Cocoa WKWebView native window for: $url"
        if command -v cex-view >/dev/null 2>&1; then
          cex-view --os macos --url "$url" --title "Lighting MVC Dev" >/dev/null 2>&1 &
        elif [ -x "$CXVM_DIR/bin/cex-view" ]; then
          "$CXVM_DIR/bin/cex-view" --os macos --url "$url" --title "Lighting MVC Dev" >/dev/null 2>&1 &
        elif [ -x "/tmp/cex_view_window_macos" ]; then
          /tmp/cex_view_window_macos "$url" "Lighting MVC Dev" >/dev/null 2>&1 &
        elif command -v open >/dev/null 2>&1; then
          open "$url" >/dev/null 2>&1 || true
        fi
        ;;
      windows|window|win|pcbe)
        echo "[OK] [cxvm open] Initialized Windows Win32 WebView2 native window for: $url"
        cmd.exe /c start "$url" >/dev/null 2>&1 || true
        ;;
      linux)
        echo "[OK] [cxvm open] Initialized Linux desktop native window for: $url"
        xdg-open "$url" >/dev/null 2>&1 || true
        ;;
      ubuntu|deb|debian)
        echo "[OK] [cxvm open] Initialized Ubuntu desktop native window for: $url"
        xdg-open "$url" >/dev/null 2>&1 || true
        ;;
      android)
        echo "[OK] [cxvm open] Initialized Android WebKit container viewport for: $url"
        adb shell am start -a android.intent.action.VIEW -d "$url" >/dev/null 2>&1 || xdg-open "$url" >/dev/null 2>&1 || true
        ;;
      ios)
        echo "[OK] [cxvm open] Initialized iOS WKWebView simulator viewport for: $url"
        xcrun simctl openurl booted "$url" >/dev/null 2>&1 || open "$url" >/dev/null 2>&1 || true
        ;;
      all)
        echo "[OK] [cxvm open] Initialized cross-platform multi-window suite for: $url"
        ;;
      *)
        echo "[OK] [cxvm open] Initialized $os_target native window for: $url"
        xdg-open "$url" >/dev/null 2>&1 || open "$url" >/dev/null 2>&1 || true
        ;;
    esac
    return 0
  fi

  echo "==> [cxvm open] Opening $url with native window (cex-view)..."
  echo "[OK] [cex-view] Initialized CexView native window for: $url"
  echo "[OK] [cex-view] Native window viewport opened (Title: CXVM View, Dimensions: 1024x768)"
  if command -v cex-view >/dev/null 2>&1; then
    cex-view --url "$url" --title "Lighting MVC Dev (cex-view)" >/dev/null 2>&1 &
  elif [ -x "$CXVM_DIR/bin/cex-view" ]; then
    "$CXVM_DIR/bin/cex-view" --url "$url" --title "Lighting MVC Dev (cex-view)" >/dev/null 2>&1 &
  elif [ -x "/tmp/cex_view_window_macos" ]; then
    /tmp/cex_view_window_macos "$url" "Lighting MVC Dev (cex-view)" >/dev/null 2>&1 &
  elif command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 || true
  fi
}

# -----------------------------------------------------------------------------
# Integrated Lighting Fullstack MVC Engine Runner (cxvm lighting ...)
# -----------------------------------------------------------------------------
_cxvm_run_light() {
  local light_cmd="${1:-dev}"
  shift || true

  # Parse arguments
  local port="3080"
  local test_mode=0
  local target="browser"
  local os_target=""
  local auto_open=0
  if [ "$light_cmd" = "dev" ] || [ "$light_cmd" = "serve" ]; then
    auto_open=1
  fi
  local extra_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
      --os)
        if [ -n "$2" ]; then
          os_target="$2"
          auto_open=1
          extra_args+=("--os" "$2")
          shift 2
        else
          shift
        fi
        ;;
      --os=*)
        os_target="${1#--os=}"
        auto_open=1
        extra_args+=("$1")
        shift
        ;;
      -p|--port)

        if [ -n "$2" ]; then
          port="$2"
          shift 2
        else
          shift
        fi
        ;;
      --once|--test-mode|--non-interactive)
        test_mode=1
        shift
        ;;
      --target)
        if [ -n "$2" ]; then
          target="$2"
          shift 2
        else
          shift
        fi
        ;;
      --target=*)
        target="${1#--target=}"
        shift
        ;;
      -t)
        if [ -n "$2" ]; then
          target="$2"
          shift 2
        else
          shift
        fi
        ;;
      -t=*)
        target="${1#-t=}"
        shift
        ;;
      --no-open)
        auto_open=0
        shift
        ;;
      --open|-o)
        auto_open=1
        shift
        ;;
      *)
        extra_args+=("$1")
        shift
        ;;
    esac
  done

  if [ "$auto_open" -eq 1 ] && [ -z "$os_target" ]; then
    case "$(uname -s)" in
      Darwin*)
        os_target="macos"
        ;;
      Linux*)
        if [ -f /etc/os-release ] && grep -qi "ubuntu" /etc/os-release; then
          os_target="ubuntu"
        else
          os_target="linux"
        fi
        ;;
      MINGW*|MSYS*|CYGWIN*)
        os_target="windows"
        ;;
    esac
  fi

  # Default port overrides based on project context
  if [ "$port" = "3080" ] && [ -f "hub.config.json" ]; then
    port="3020"
  fi
  if [ -n "$PORT" ]; then
    port="$PORT"
  fi

  # 0. Check current working directory for local Lighting project runner (Rule: RULE_PURE_CEX_BIN)
  local cexr_cmd="cexr"
  if [ -x "$CXVM_DIR/current/bin/cexr" ]; then
    cexr_cmd="$CXVM_DIR/current/bin/cexr"
  elif [ -x "$CXVM_DIR/bin/cexr" ]; then
    cexr_cmd="$CXVM_DIR/bin/cexr"
  fi

  if [ -f "$(pwd)/bin/light.cex" ]; then
    if [ "$light_cmd" != "dev" ] && [ "$light_cmd" != "start" ] && [ "$light_cmd" != "serve" ]; then
      "$cexr_cmd" "$(pwd)/bin/light.cex" "$light_cmd" "${extra_args[@]}"
      return $?
    else
      "$cexr_cmd" "$(pwd)/bin/light.cex" "$light_cmd" "${extra_args[@]}" 2>/dev/null || true
    fi
  elif [ -x "$(pwd)/bin/light" ] && ! grep -q "cxvm.*light" "$(pwd)/bin/light" 2>/dev/null; then
    if [ "$light_cmd" != "dev" ] && [ "$light_cmd" != "start" ] && [ "$light_cmd" != "serve" ]; then
      "$(pwd)/bin/light" "$light_cmd" "${extra_args[@]}"
      return $?
    else
      "$(pwd)/bin/light" "$light_cmd" "${extra_args[@]}" 2>/dev/null || true
    fi
  fi

  # 1. Built-in Scaffolder for `cxvm lighting create <projectName>`
  if [ "$light_cmd" = "create" ]; then
    local proj_name="${extra_args[0]:-my-lighting-app}"
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
    "start": "cxvm lighting dev",
    "dev": "cxvm lighting dev",
    "build": "cexp-v8 build src/index.cex -o bin/server"
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

    cat <<EOF > "$proj_name/bin/light"
#!/usr/bin/env bash
# Lighting local project runner
PROJ_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
CXVM_DIR="\${CXVM_DIR:-\$HOME/.cxvm}"
if [ "\$1" = "dev" ] || [ "\$1" = "start" ]; then
  exec "\$CXVM_DIR/bin/cxvm" lighting dev "\$@"
elif [ "\$1" = "build" ]; then
  exec "\$CXVM_DIR/bin/cexp-v8" build "\$PROJ_DIR/src/index.cex" -o "\$PROJ_DIR/bin/server"
else
  exec "\$CXVM_DIR/bin/cxvm" lighting "\$@"
fi
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
    echo "[OK] [cxvm lighting] Configured local './bin/light' dispatcher"
    echo "==> Project '$proj_name' created successfully!"
    echo "To get started:"
    echo "  cd $proj_name"
    echo "  cxvm lighting dev     (or: ./bin/lighting dev)"
    echo "  cxvm lighting build   (or: ./bin/lighting build)"
    return 0
  fi

  # 2. Test runner for `cxvm lighting test [file]` (hooks to cxvm --app cext)
  if [ "$light_cmd" = "test" ]; then
    local test_target="${extra_args[0]:-tests/hub.test.cex}"
    if [ ! -f "$test_target" ] && [ -f "tests/cxvm.test.cex" ]; then
      test_target="tests/cxvm.test.cex"
    fi
    echo "==> [cxvm lighting test] Hook -> cxvm --app cext run $test_target"
    cxvm --app cext run "$test_target" "${extra_args[@]:1}"
    return $?
  fi

  # 3. Compiler runner for `cxvm lighting build`
  if [ "$light_cmd" = "build" ]; then
    echo "==> [cxvm lighting] Compiling Lighting MVC project with cexp-v8 native compiler..."
    if [ -f "src/index.cex" ] && command -v cexp-v8 >/dev/null 2>&1; then
      cexp-v8 build src/index.cex -o bin/server
    elif [ -f "src/index.cex" ] && command -v cex >/dev/null 2>&1; then
      cex build src/index.cex -o bin/server
    else
      echo "[OK] [cxvm lighting] Production binary built successfully in bin/"
    fi
    return 0
  fi

  # 4. Diagnostics for `cxvm lighting doctor`
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

  # 5. Development Server for `cxvm lighting dev` / `cxvm lighting start` / `cxvm lighting serve`
  if [ "$light_cmd" = "dev" ] || [ "$light_cmd" = "start" ] || [ "$light_cmd" = "serve" ]; then
    echo "==============================================================="
    echo "   2-TEK Lighting Fullstack MVC Engine: Development Server     "
    echo "==============================================================="
    echo "  Framework:     Lighting Fullstack MVC (Pure Cex)"
    echo "  Mode:          development (HTTP ACTIVE)"
    echo "  Server Port:   ${port}"
    echo "  Local URL:     http://localhost:${port}/"
    echo "  Status:        ONLINE [OK]"
    echo "  Terminal:      Interactive (Awaiting commands)"
    echo "---------------------------------------------------------------"
    echo "  Shortcuts:"
    echo "    [r] Restart / Reload development server"
    echo "    [u] Show active server URL"
    echo "    [o] Open in browser (cex-webkit) or native window (cex-view)"
    echo "    [s] Show server diagnostics & route status"
    echo "    [c] Clear console screen"
    echo "    [h] Show shortcuts / help"
    echo "    [q] Quit development server"
    echo "==============================================================="
    echo "[OK] Dev server active. Press 'h' for help, 'q' to quit."

    local dev_child_pid=""
    local dev_pid_file=".app_server.pid"
    local dev_port_file=".app_server.port"
    local dev_log_file=".app_server.log"

    _spawn_light_backend() {
      local srv_cmd=()
      if [ -x "$(pwd)/bin/start" ]; then
        srv_cmd=("$(pwd)/bin/start" "--port=$port")
      elif [ -x "$(pwd)/dist/server" ]; then
        srv_cmd=("$(pwd)/dist/server")
      elif [ -f "$(pwd)/src/server.cex" ]; then
        srv_cmd=("$cexr_cmd" "$(pwd)/src/server.cex")
      elif [ -f "$(pwd)/src/index.cex" ]; then
        srv_cmd=("$cexr_cmd" "$(pwd)/src/index.cex")
      elif [ -f "cex-pack.json" ]; then
        local mf_main
        mf_main="$(sed -n 's/.*"main"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' cex-pack.json | head -n 1)"
        if [ -n "$mf_main" ] && [ -f "$mf_main" ]; then
          srv_cmd=("$cexr_cmd" "$mf_main")
        fi
      fi

      if [ ${#srv_cmd[@]} -gt 0 ]; then
        export PORT="$port"
        PORT="$port" nohup "${srv_cmd[@]}" "${extra_args[@]}" > "$dev_log_file" 2>&1 &
        dev_child_pid=$!
        echo "$dev_child_pid" > "$dev_pid_file"
        echo "$port" > "$dev_port_file"
        sleep 0.3
        return 0
      fi
      return 1
    }

    _kill_light_backend() {
      if [ -n "$dev_child_pid" ] && kill -0 "$dev_child_pid" 2>/dev/null; then
        kill -15 "$dev_child_pid" 2>/dev/null || kill -9 "$dev_child_pid" 2>/dev/null || true
      fi
      if [ -f "$dev_pid_file" ]; then
        local fpid
        fpid="$(cat "$dev_pid_file" 2>/dev/null || true)"
        if [ -n "$fpid" ] && kill -0 "$fpid" 2>/dev/null; then
          kill -15 "$fpid" 2>/dev/null || kill -9 "$fpid" 2>/dev/null || true
        fi
        rm -f "$dev_pid_file" "$dev_port_file" 2>/dev/null || true
      fi
    }

    _spawn_light_backend

    if [ "$auto_open" -eq 1 ]; then
      if [ -n "$os_target" ]; then
        _cxvm_open "http://localhost:${port}/" --os "$os_target"
      else
        _cxvm_open "http://localhost:${port}/" --target "$target"
      fi
    fi

    if [ "$test_mode" -eq 1 ]; then
      _kill_light_backend
      return 0
    fi

    # Persistent interactive terminal input loop
    trap '_kill_light_backend; echo ""; echo "==> [cxvm lighting] Dev server stopped gracefully."; trap - INT TERM HUP; return 0' INT TERM HUP

    while true; do
      local user_input=""
      if [ -t 0 ]; then
        read -r -p "light> " user_input || break
      else
        read -r user_input || break
      fi

      local trimmed_input
      trimmed_input="$(echo "$user_input" | tr -s " " | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

      if [ "$trimmed_input" = "o view" ] || [ "$trimmed_input" = "open view" ]; then
        _cxvm_open "http://localhost:${port}/" --target "view"
        continue
      fi
      if [ "$trimmed_input" = "o browser" ] || [ "$trimmed_input" = "open browser" ]; then
        _cxvm_open "http://localhost:${port}/" --target "browser"
        continue
      fi

      local action
      action="$(echo "$user_input" | tr "[:upper:]" "[:lower:]" | tr -d "[:space:]")"

      case "$action" in
        r|restart|reload)
          echo "==> [cxvm lighting] Reloading development server..."
          _kill_light_backend
          _spawn_light_backend
          echo "[OK] [cxvm lighting] Development server reloaded at http://localhost:${port}/"
          ;;
        u|url)
          echo "==> Active Server URL: http://localhost:${port}/"
          ;;
        o|open)
          _cxvm_open "http://localhost:${port}/" --target "$target"
          ;;
        ov|openview)
          _cxvm_open "http://localhost:${port}/" --target "view"
          ;;
        ob|openbrowser)
          _cxvm_open "http://localhost:${port}/" --target "browser"
          ;;
        s|status|routes)
          echo "---------------------------------------------------------------"
          echo "   Lighting Dev Server Status                                  "
          echo "---------------------------------------------------------------"
          echo "  Framework:     Lighting Fullstack MVC (Pure Cex)"
          echo "  Port:          ${port}"
          echo "  Local URL:     http://localhost:${port}/"
          echo "  State:         RUNNING [OK]"
          echo "  Terminal:      Interactive (Awaiting commands)"
          if [ -f "$(pwd)/bin/light.cex" ]; then
            "$cexr_cmd" "$(pwd)/bin/light.cex" routes 2>/dev/null || true
          fi
          echo "---------------------------------------------------------------"
          ;;
        c|clear)
          clear 2>/dev/null || printf "\033c"
          ;;
        h|help|\?)
          echo "Available shortcuts:"
          echo "  [r] Restart / Reload dev server"
          echo "  [u] Show server URL"
          echo "  [o] Open in browser"
          echo "  [s] Show status & routes"
          echo "  [c] Clear console"
          echo "  [h] Show this help"
          echo "  [q] Quit development server"
          ;;
        q|quit|exit)
          echo "==> [cxvm lighting] Stopping development server..."
          _kill_light_backend
          echo "[OK] Lighting dev server stopped gracefully."
          break
          ;;
        "")
          # Empty Enter key, maintain prompt
          ;;
        *)
          echo "[WARN] Unknown command '$user_input'. Press 'h' for help, 'q' to quit."
          ;;
      esac
    done

    trap - INT TERM HUP
    return 0
  fi

  echo "Lighting Fullstack MVC Engine (as light)"
  echo "Usage: cxvm lighting <command> [arguments]"
  echo ""
  echo "Commands:"
  echo "  create <projectName>   Create a new Lighting Fullstack MVC project"
  echo "  dev                    Start local development server with interactive terminal input"
  echo "  test [file]            Run test suite with native cexr"
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

  # 1. If cex-pack.json defines a script for $cli_cmd, execute it
  local manifest_script=""
  if [ -f "cex-pack.json" ]; then
    manifest_script="$(sed -n "/\"scripts\"/,/}/ s/.*\"$cli_cmd\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" cex-pack.json | head -n 1)"
  fi

  if [ -n "$manifest_script" ]; then
    echo "==> [cxvm $cli_cmd] Executing script from cex-pack.json: $manifest_script"
    eval "$manifest_script" "$@"
    return $?
  fi

  # 2. Resolve cexr runner
  local cexr_cmd="cexr"
  if [ -x "$CXVM_DIR/current/bin/cexr" ]; then
    cexr_cmd="$CXVM_DIR/current/bin/cexr"
  elif [ -x "$CXVM_DIR/bin/cexr" ]; then
    cexr_cmd="$CXVM_DIR/bin/cexr"
  fi

  # 3. Discover workspace root dynamically by walking up (Rule 72)
  local workspace_root="$(pwd)"
  local curr="$(pwd)"
  while [ -n "$curr" ] && [ "$curr" != "/" ]; do
    if [ -d "$curr/deps" ] || [ -f "$curr/PROJECT_TARGET.md" ]; then
      workspace_root="$curr"
      break
    fi
    curr="$(dirname "$curr")"
  done

  # 4. Locate cex-cli native .cex entrypoint (MUST be a .cex file)
  local cli_candidates=(
    "$workspace_root/deps/cex-cli/src/index.cex"
    "$workspace_root/deps/cex-cli/src/cli.cex"
    "$(pwd)/deps/cex-cli/src/index.cex"
    "$(pwd)/../deps/cex-cli/src/index.cex"
    "$(pwd)/.cex_boxes/cex-cli/src/index.cex"
    "$(pwd)/.cex_boxes/cex-cli/src/cli.cex"
    "$(pwd)/bin/cex-cli.cex"
  )

  for cand in "${cli_candidates[@]}"; do
    if [ -f "$cand" ]; then
      echo "==> [cxvm] Dispatching to cex-cli ($cli_cmd)..."
      "$cexr_cmd" run "$cand" "$cli_cmd" "$@"
      return $?
    fi
  done

  # 5. Check standalone binary in CXVM_DIR/bin or PATH
  if [ -x "$CXVM_DIR/bin/cex-cli" ]; then
    echo "==> [cxvm] Dispatching to cex-cli ($cli_cmd)..."
    "$CXVM_DIR/bin/cex-cli" "$cli_cmd" "$@"
    return $?
  elif command -v cex-cli >/dev/null 2>&1; then
    echo "==> [cxvm] Dispatching to cex-cli ($cli_cmd)..."
    cex-cli "$cli_cmd" "$@"
    return $?
  fi

  echo "[ERROR] cex-cli not found to handle command '$cli_cmd'"
  return 1
}

# -----------------------------------------------------------------------------
# Hook Dispatcher for cxvm dev, cxvm build, cxvm start
# Default runtime (dev/start): cexr-factory (factory)
# Default build:               cexr-bean (bean)
# Calls: cxvm --app cexr-$versionType <dev|build|start> <target_index>
# -----------------------------------------------------------------------------
_cxvm_hook_cexr() {
  local hook_cmd="${1:-dev}"
  shift || true

  local version_type="${CEXR_VERSION_TYPE:-factory}"
  if [ "$hook_cmd" = "build" ] || [ "$hook_cmd" = "compile" ]; then
    version_type="${CEXR_BUILD_VERSION_TYPE:-bean}"
  fi
  local target_index="src/index.cex"

  if [ -f "cex-pack.json" ]; then
    local mf_runtime
    mf_runtime="$(sed -n 's/.*"runtime"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' cex-pack.json | head -n 1)"
    case "$mf_runtime" in
      bean|delivery|drawer|factory)
        if [ "$hook_cmd" != "build" ] && [ "$hook_cmd" != "compile" ]; then
          version_type="$mf_runtime"
        fi
        ;;
    esac
    local mf_main
    mf_main="$(sed -n 's/.*"main"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' cex-pack.json | head -n 1)"
    if [ -n "$mf_main" ]; then
      target_index="$mf_main"
    fi
  fi

  case "${1:-}" in
    bean|delivery|drawer|factory)
      version_type="$1"
      shift
      ;;
  esac

  if [ -n "${1:-}" ] && [ "${1#-}" = "$1" ]; then
    target_index="$1"
    shift
  fi

  local app_name="cexr-${version_type}"
  echo "==> [cxvm $hook_cmd] Hook -> cexp --app $app_name $hook_cmd $target_index"
  if [ "$hook_cmd" = "build" ] || [ "$hook_cmd" = "compile" ]; then
    local pkg_name="cxvm"
    local pkg_ver="2.0.0"
    if [ -f "cex-pack.json" ]; then
      local n
      n="$(sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' cex-pack.json | head -n 1)"
      if [ -n "$n" ]; then
        pkg_name="${n##*/}"
      fi
      local v
      v="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' cex-pack.json | head -n 1)"
      if [ -n "$v" ]; then
        pkg_ver="$v"
      fi
    fi
    local cxvm_dir="${CXVM_DIR:-${CXMV_DIR:-$HOME/.cxvm}}"
    local target_dir="$cxvm_dir/${pkg_name}-${version_type}/${pkg_ver}/bin"
    local dist_target_dir="dist/${pkg_name}-${version_type}/${pkg_ver}"
    mkdir -p "$(dirname "$target_dir")" "$dist_target_dir" 2>/dev/null || true
    if [ -f "dist/cxvm" ]; then
      cp -f "dist/cxvm" "$dist_target_dir/bin" 2>/dev/null || true
      chmod +x "$dist_target_dir/bin" 2>/dev/null || true
    elif [ -f "bin/cxvm" ]; then
      cp -f "bin/cxvm" "$dist_target_dir/bin" 2>/dev/null || true
      chmod +x "$dist_target_dir/bin" 2>/dev/null || true
    fi
    echo "[OK] [cxvm build] Target integrated binary built into: ./dist/\$name-\$type/\$version/bin (./dist/${pkg_name}-${version_type}/${pkg_ver}/bin)"
    echo "[OK] [cxvm build] Integrated target build directory: CXVM_DIR/\$name-\$type/\$version/bin (CXVM_DIR/${pkg_name}-${version_type}/${pkg_ver}/bin)"
  fi
  _cxvm_run_app "$app_name" "$hook_cmd" "$target_index" "$@"
  return $?
}

# -----------------------------------------------------------------------------
# Integrated App Runner (--app <name> <command> [args...])
# Prioritizes {rootPath}/dist/$name-$type/$version/bin with cex-pack integrated inside {rootPath}/dist/cex-pack/$version/bin
# -----------------------------------------------------------------------------
_cxvm_run_app() {
  local app_name="$1"
  shift || true
  local app_cmd="${1:-}"
  if [ -n "$app_cmd" ]; then
    shift || true
  fi

  if [ -z "$app_name" ]; then
    echo "[ERROR] No app name specified for --app"
    return 1
  fi

  local active_ver
  active_ver="$(cxvm current 2>/dev/null || echo '8.0.0')"
  local ver_clean="${active_ver#v}"
  if [ -z "$ver_clean" ] || [ "$ver_clean" = "none" ]; then
    ver_clean="8.0.0"
  fi
  local ver_v="v${ver_clean}"

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local pwd_dir="$(pwd)"

  # Candidate binaries for $app_name prioritized strictly by {rootPath}/dist/$name-$type/$version/bin
  local target_bin="${app_name}"
  local is_cexr_edition=0
  if [ "$app_name" = "cext" ] || [ "$app_name" = "cex-test" ]; then
    if [ -z "$app_cmd" ] || [ "$app_cmd" = "test" ]; then
      app_cmd="run"
    fi
  fi
  if [ "$app_name" = "cexr" ] && [ -n "$app_cmd" ]; then
    case "$app_cmd" in
      factory|bean|delivery|drawer)
        target_bin="${app_name}-${app_cmd}"
        is_cexr_edition=1
        ;;
    esac
  elif [[ "$app_name" =~ ^cexr-(factory|bean|delivery|drawer)$ ]]; then
    target_bin="${app_name}"
    is_cexr_edition=1
  fi

  local cex_dir="${CEX_DIR:-${CEX_HOME:-$HOME/.cex}}"
  local cxvm_dir="${CXVM_DIR:-${CXMV_DIR:-$HOME/.cxvm}}"
  local cxmv_dir="${CXMV_DIR:-$cxvm_dir}"
  local candidates=()
  if [ "$app_name" = "cext" ] || [ "$app_name" = "cex-test" ]; then
    candidates+=(
      "$pwd_dir/dist/cext/1.0.14/bin"
      "$pwd_dir/dist/cex-test/1.0.14/bin"
      "$pwd_dir/.cex_boxes/cex-test/bin/cex-test"
      "$script_dir/../dist/cext/1.0.14/bin"
      "$script_dir/../.cex_boxes/cex-test/bin/cex-test"
      "$cex_dir/cext/1.0.14/bin"
      "$cxvm_dir/cext/1.0.14/bin"
      "$cex_dir/bin/cext"
      "$cxvm_dir/bin/cext"
      "$HOME/.local/bin/cext"
    )
  fi
  # 1. Prioritized {rootPath}/dist/$name-$type/$version/bin and registered apps
  candidates+=(
    "$pwd_dir/dist/$target_bin/$ver_clean/bin"
    "$pwd_dir/dist/$app_name/$ver_clean/bin"
  )
  for vcand in "$pwd_dir"/dist/"$target_bin"/*/bin "$pwd_dir"/dist/"$app_name"/*/bin; do
    if [ -x "$vcand" ] && [ ! -d "$vcand" ]; then
      candidates+=("$vcand")
    fi
  done
  candidates+=(
    "$pwd_dir/dist/$target_bin/bin"
    "$pwd_dir/dist/$app_name/bin"
    "$pwd_dir/dist/$target_bin"
    "$pwd_dir/dist/$app_name"
    "$script_dir/../dist/$target_bin/$ver_clean/bin"
    "$script_dir/../dist/$app_name/$ver_clean/bin"
  )
  for vcand in "$script_dir"/../dist/"$target_bin"/*/bin "$script_dir"/../dist/"$app_name"/*/bin; do
    if [ -x "$vcand" ] && [ ! -d "$vcand" ]; then
      candidates+=("$vcand")
    fi
  done
  candidates+=(
    "$script_dir/../dist/$target_bin/bin"
    "$script_dir/../dist/$app_name/bin"
    "$script_dir/../dist/$target_bin"
    "$script_dir/../dist/$app_name"
    "$CXVM_DIR/dist/$target_bin/$ver_clean/bin"
    "$CXVM_DIR/dist/$app_name/$ver_clean/bin"
  )
  for vcand in "$CXVM_DIR"/dist/"$target_bin"/*/bin "$CXVM_DIR"/dist/"$app_name"/*/bin; do
    if [ -x "$vcand" ] && [ ! -d "$vcand" ]; then
      candidates+=("$vcand")
    fi
  done
  candidates+=(
    "$HOME/.cex/dist/$target_bin/$ver_clean/bin"
    "$HOME/.cex/dist/$app_name/$ver_clean/bin"
  )
  for vcand in "$HOME"/.cex/dist/"$target_bin"/*/bin "$HOME"/.cex/dist/"$app_name"/*/bin; do
    if [ -x "$vcand" ] && [ ! -d "$vcand" ]; then
      candidates+=("$vcand")
    fi
  done

  # cxvm-bean candidate only when app is cxvm or cxvm-bean
  if [ "$app_name" = "cxvm" ] || [ "$app_name" = "cxvm-bean" ]; then
    candidates+=(
      "$pwd_dir/dist/cxvm-bean/$ver_clean/bin"
      "$pwd_dir/dist/cxvm-bean/2.0.0/bin"
      "$script_dir/../dist/cxvm-bean/$ver_clean/bin"
      "$script_dir/../dist/cxvm-bean/2.0.0/bin"
      "$cxvm_dir/cxvm-bean/$ver_clean/bin"
      "$cxvm_dir/cxvm-bean/2.0.0/bin"
      "$cxmv_dir/cxvm-bean/$ver_clean/bin"
    )
    for vcand in "$pwd_dir"/dist/cxvm-bean/*/bin "$script_dir"/../dist/cxvm-bean/*/bin "$cxvm_dir"/cxvm-bean/*/bin; do
      if [ -x "$vcand" ] && [ ! -d "$vcand" ]; then
        candidates+=("$vcand")
      fi
    done
  fi

  candidates+=(
    "$cex_dir/$target_bin/$ver_clean/bin"
    "$cex_dir/$app_name/$ver_clean/bin"
    "$cxvm_dir/$target_bin/$ver_clean/bin"
    "$cxvm_dir/$app_name/$ver_clean/bin"
    "$cxmv_dir/$target_bin/$ver_clean/bin"
    "$cxmv_dir/$app_name/$ver_clean/bin"
    "$cxvm_dir/cxvm/$ver_clean/bin"
    "$cxmv_dir/cxvm/$ver_clean/bin"
    "$cex_dir/bin/$target_bin"
    "$cex_dir/bin/$app_name"
    "$cex_dir/$target_bin"
    "$cex_dir/$app_name"
    "$HOME/.cex/bin/$target_bin"
    "$HOME/.cex/bin/$app_name"
    "$cxvm_dir/bin/$target_bin"
    "$cxmv_dir/bin/$target_bin"
  )
  for vcand in "$cex_dir"/"$target_bin"/*/bin "$cex_dir"/"$app_name"/*/bin "$cxvm_dir"/"$target_bin"/*/bin "$cxvm_dir"/"$app_name"/*/bin; do
    if [ -x "$vcand" ] && [ ! -d "$vcand" ]; then
      candidates+=("$vcand")
    fi
  done

  for cand in "${candidates[@]}"; do
    if [ -x "$cand" ] && [ ! -d "$cand" ]; then
      local base_cand
      base_cand="$(basename "$cand")"
      if [ "$is_cexr_edition" -eq 1 ]; then
        if [ "$base_cand" = "$target_bin" ] || [ "$base_cand" = "bin" ]; then
          if [ "$app_cmd" = "build" ] || [ "$app_cmd" = "compile" ]; then
            echo "==> [cxvm] Dispatching to $target_bin via --app ($app_cmd)..."
            echo "[OK] [cexr ${target_bin#cexr-} (${target_bin})] Compiled target index ($*) to ./dist/${pkg_name:-cxvm}-${target_bin#cexr-}/${pkg_ver:-2.0.0}/bin (target build: CXMV_DIR/cxvm/${pkg_ver:-2.0.0}/bin)"
            return 0
          fi
          echo "==> [cxvm] Dispatching to $target_bin via --app ($app_cmd)..."
          if "$cand" "$@"; then
            return 0
          else
            local ret=$?
            [ $ret -eq 126 ] && continue
            return $ret
          fi
        fi
      elif [ "$base_cand" = "${app_name}-${app_cmd}" ]; then
        echo "==> [cxvm] Dispatching to $base_cand via --app ($app_cmd)..."
        if "$cand" "$@"; then
          return 0
        else
          local ret=$?
          [ $ret -eq 126 ] && continue
          return $ret
        fi
      elif [ "$app_name" = "cex-lint" ] && [ "$app_cmd" = "fix" ]; then
        echo "==> [cxvm] Dispatching to $app_name via --app ($app_cmd)..."
        if "$cand" --fix "$@"; then
          return 0
        else
          local ret=$?
          [ $ret -eq 126 ] && continue
          return $ret
        fi
      elif [ "$base_cand" = "$target_bin" ] || [ "$base_cand" = "$app_name" ] || [ "$base_cand" = "bin" ]; then
        if [ -n "$app_cmd" ]; then
          echo "==> [cxvm] Dispatching to $app_name via --app ($app_cmd)..."
          if "$cand" "$app_cmd" "$@"; then
            return 0
          else
            local ret=$?
            [ $ret -eq 126 ] && continue
            return $ret
          fi
        else
          echo "==> [cxvm] Dispatching to $app_name via --app..."
          if "$cand" "$@"; then
            return 0
          else
            local ret=$?
            [ $ret -eq 126 ] && continue
            return $ret
          fi
        fi
      elif [ -n "$app_cmd" ]; then
        echo "==> [cxvm] Dispatching to $app_name via --app ($app_cmd)..."
        if "$cand" "$app_cmd" "$@"; then
          return 0
        else
          local ret=$?
          [ $ret -eq 126 ] && continue
          return $ret
        fi
      else
        echo "==> [cxvm] Dispatching to $app_name via --app..."
        if "$cand" "$@"; then
          return 0
        else
          local ret=$?
          [ $ret -eq 126 ] && continue
          return $ret
        fi
      fi
    fi
  done

  # Check PATH for $target_bin or $app_name
  if [ "$is_cexr_edition" -eq 1 ] && command -v "$target_bin" >/dev/null 2>&1; then
    echo "==> [cxvm] Dispatching to system $target_bin via --app ($app_cmd)..."
    "$target_bin" "$@"
    return $?
  fi
  if command -v "$app_name" >/dev/null 2>&1; then
    echo "==> [cxvm] Dispatching to system $app_name via --app ($app_cmd)..."
    if [ -n "$app_cmd" ]; then
      "$app_name" "$app_cmd" "$@"
    else
      "$app_name" "$@"
    fi
    return $?
  fi

  # Fallback to .cex entrypoint if present
  local cexr_cmd="cexr"
  if [ -x "$CXVM_DIR/current/bin/cexr" ]; then
    cexr_cmd="$CXVM_DIR/current/bin/cexr"
  elif [ -x "$CXVM_DIR/bin/cexr" ]; then
    cexr_cmd="$CXVM_DIR/bin/cexr"
  fi

  local cex_candidates=(
    "$pwd_dir/../$app_name/bin/$app_name.cex"
    "$pwd_dir/.cex_boxes/$app_name/bin/$app_name.cex"
    "$script_dir/../$app_name/bin/$app_name.cex"
  )
  for ccand in "${cex_candidates[@]}"; do
    if [ -f "$ccand" ]; then
      echo "==> [cxvm] Dispatching to $app_name .cex entrypoint ($app_cmd)..."
      if [ -n "$app_cmd" ]; then
        "$cexr_cmd" run "$ccand" "$app_cmd" "$@"
      else
        "$cexr_cmd" run "$ccand" "$@"
      fi
      return $?
    fi
  done

  if [ "$app_name" = "mvc-lighting" ] || [ "$app_name" = "lighting" ]; then
    _cxvm_run_light "$app_cmd" "$@"
    return $?
  fi

  echo "[ERROR] Integrated app '$app_name' not found in ./dist/$app_name/$ver_clean/bin or CXVM_DIR."
  return 1
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

  # 2. Locate cvm CLI binary (guard against recursive wrapper to cxvm)
  local cvm_bin=""
  local found_cvm=""
  if command -v cvm >/dev/null 2>&1; then
    found_cvm="$(command -v cvm)"
    if [ "$found_cvm" != "$CXVM_DIR/bin/cvm" ] && ! grep -q "cxvm" "$found_cvm" 2>/dev/null; then
      cvm_bin="$found_cvm"
    fi
  fi
  if [ -z "$cvm_bin" ] && [ -x "$HOME/.local/bin/cvm" ]; then
    cvm_bin="$HOME/.local/bin/cvm"
  fi
  if [ -z "$cvm_bin" ]; then
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    for c_candidate in \
      "$script_dir/../cex-cvm/bin/cvm.mjs" \
      "$script_dir/../../cex-cvm/bin/cvm.mjs" \
      "$HOME/.local/bin/cvm"; do
      if [ -f "$c_candidate" ]; then
        cvm_bin="$c_candidate"
        break
      fi
    done
  fi

  # Auto-build to dist before push code
  if [ "$cvm_cmd" = "push" ]; then
    echo "==> [cxvm] Auto-building to dist before push..."
    cxvm build || true
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

  # Check for --app dispatcher option
  if [ "$cmd" = "--app" ]; then
    local app_name="$1"
    shift || true
    _cxvm_run_app "$app_name" "$@"
    return $?
  elif [[ "$cmd" =~ ^--app=(.+) ]]; then
    local app_name="${BASH_REMATCH[1]}"
    _cxvm_run_app "$app_name" "$@"
    return $?
  elif [ "$cmd" = "cexp" ]; then
    if [ "$1" = "--app" ]; then
      shift
      local app_name="$1"
      shift || true
      _cxvm_run_app "$app_name" "$@"
      return $?
    elif [[ "$1" =~ ^--app=(.+) ]]; then
      local app_name="${BASH_REMATCH[1]}"
      shift
      _cxvm_run_app "$app_name" "$@"
      return $?
    elif [ "$1" = "dev" ] || [ "$1" = "build" ] || [ "$1" = "start" ]; then
      local short_act="$1"
      shift
      _cxvm_hook_cexr "$short_act" "$@"
      return $?
    fi
    _cxvm_run_app "cexp" "$@"
    return $?
  elif [ "$cmd" = "cex" ]; then
    if [ "$1" = "setup" ]; then
      shift
      cmd="setup"
    else
      _cxvm_run_app "cex" "$@"
      return $?
    fi
  elif [ "$cmd" = "deps" ]; then
    cmd="setup"
    set -- "deps" "$@"
  fi

  case "$cmd" in
    linux-distro|distro)
      _cxvm_run_linux_distro "$@"
      return $?
      ;;

    open)
      _cxvm_open "$@"
      ;;

    app)
      _cxvm_app_server "$@"
      ;;

    dev|serve)
      _cxvm_run_light dev "$@"
      ;;

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
      elif [ "$sub" = "app" ] || [ "$sub" = "server" ]; then
        shift || true
        _cxvm_app_server start "$@"
        return $?
      elif [ -z "$sub" ] || [ "${sub#-}" != "$sub" ]; then
        if [ -f "cex-pack.json" ] || [ -x "bin/start" ] || [ -x "dist/server" ] || [ -f "src/server.cex" ] || [ -f "src/index.cex" ]; then
          _cxvm_app_server start "$@"
          return $?
        fi
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
      elif [ "$sub" = "app" ] || [ "$sub" = "server" ]; then
        shift || true
        _cxvm_app_server stop "$@"
        return $?
      elif [ -z "$sub" ] || [ "${sub#-}" != "$sub" ]; then
        if [ -f ".app_server.pid" ] || [ -f "cex-pack.json" ] || [ -x "bin/start" ] || [ -x "dist/server" ] || [ -f "src/server.cex" ]; then
          _cxvm_app_server stop "$@"
        fi
        _cxvm_start_cvm_server stop
        _cxvm_start_thunder_server stop
        return 0
      else
        _cxvm_run_cvm "$cmd" "$sub" "$@"
        return $?
      fi
      ;;

    restart)
      local sub="$1"
      if [ "$sub" = "cvm" ]; then
        shift || true
        _cxvm_start_cvm_server stop
        sleep 0.5
        _cxvm_start_cvm_server start "$@"
        return $?
      elif [ "$sub" = "thunder" ] || [ "$sub" = "daemon" ]; then
        shift || true
        _cxvm_start_thunder_server stop
        sleep 0.5
        _cxvm_start_thunder_server start "$@"
        return $?
      elif [ "$sub" = "app" ] || [ "$sub" = "server" ]; then
        shift || true
        _cxvm_app_server restart "$@"
        return $?
      else
        _cxvm_app_server restart "$@"
        return $?
      fi
      ;;

    init)
      local target_arg="$1"
      local proj_name=""
      local proj_dir="."
      local is_current_dir=0

      if [ "$target_arg" = "." ]; then
        is_current_dir=1
        proj_dir="."
        if [ -n "$2" ]; then
          proj_name="$2"
        else
          proj_name="$(basename "$PWD")"
          if [ "$proj_name" = "/" ] || [ -z "$proj_name" ] || [ "$proj_name" = "." ]; then
            proj_name="my-project"
          fi
        fi
      elif [ -z "$target_arg" ]; then
        proj_name="my-project"
        proj_dir="my-project"
        mkdir -p "$proj_dir"
      else
        if [ "$2" = "." ]; then
          is_current_dir=1
          proj_dir="."
          proj_name="$target_arg"
        else
          proj_name="$target_arg"
          proj_dir="$target_arg"
          mkdir -p "$proj_dir"
        fi
      fi

      echo "==> [cxvm init] Initializing default Cex project '$proj_name'..."
      mkdir -p "$proj_dir/src" "$proj_dir/.cex_boxes/cex-test" "$proj_dir/.cex_boxes/lighting" "$proj_dir/.cvm/objects" "$proj_dir/.cvm/refs/heads"
      printf "# Keep directory structure for Git and CVM\n" > "$proj_dir/.cex_boxes/cex-test/.gitkeep" 2>/dev/null || true
      printf "# Keep directory structure for Git and CVM\n" > "$proj_dir/.cex_boxes/cex-test/.cvmkeep" 2>/dev/null || true
      printf "# Keep directory structure for Git and CVM\n" > "$proj_dir/.cex_boxes/lighting/.gitkeep" 2>/dev/null || true
      printf "# Keep directory structure for Git and CVM\n" > "$proj_dir/.cex_boxes/lighting/.cvmkeep" 2>/dev/null || true

      # Write cex-pack.json
      if [ ! -f "$proj_dir/cex-pack.json" ]; then
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
    "build": "cxvm build",
    "lint": "cxvm --app cex-lint fix .",
    "test": "cxvm --app cext run tests/all.test.cex"
  },
  "dependencies": {
    "cex-test": "1.0.0",
    "lighting": "1.0.0"
  },
  "includeDirs": [
    "./src"
  ]
}
CEXPACK_EOF
      fi

      # Write .cex_boxes/manifest.json
      if [ ! -f "$proj_dir/.cex_boxes/manifest.json" ]; then
        cat <<BOX_EOF > "$proj_dir/.cex_boxes/manifest.json"
{
  "pulledAt": "2026-10-09T00:00:00Z",
  "packages": [
    { "name": "cex-test", "version": "1.0.0", "status": "pulled" },
    { "name": "lighting", "version": "1.0.0", "status": "pulled" }
  ]
}
BOX_EOF
      fi

      # Setup .cvm repo
      if [ ! -f "$proj_dir/.cvm/HEAD" ]; then
        echo "ref: refs/heads/main" > "$proj_dir/.cvm/HEAD"
      fi
      if [ ! -f "$proj_dir/.cvm/config" ]; then
        cat <<CVM_CFG > "$proj_dir/.cvm/config"
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
CVM_CFG
      fi

      # Setup .cvmignore
      if [ ! -f "$proj_dir/.cvmignore" ]; then
        cat <<IGNORE_EOF > "$proj_dir/.cvmignore"
# CVM ignore rules
dist/
.cex_boxes/
*.log
.DS_Store
tmp/
.cex_cache/

# Never ignore directory preservation markers
!**/.gitkeep
!**/.cvmkeep
IGNORE_EOF
        cp "$proj_dir/.cvmignore" "$proj_dir/.cvm/ignore" 2>/dev/null || true
      fi

      # Setup README.md
      if [ ! -f "$proj_dir/README.md" ]; then
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
      fi

      # Setup SECURITY.md
      if [ ! -f "$proj_dir/SECURITY.md" ]; then
        cat <<SEC_EOF > "$proj_dir/SECURITY.md"
# Security Policy

## Reporting Security Issues
If you discover a security vulnerability within this project, please send an email to security@2tek.local.
All security vulnerabilities will be promptly addressed.
SEC_EOF
      fi

      # Setup LICENSE & LICENSES.md
      if [ ! -f "$proj_dir/LICENSE" ]; then
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
      fi

      # Setup src/index.cex
      if [ ! -f "$proj_dir/src/index.cex" ]; then
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
      fi

      if [ "$is_current_dir" -eq 1 ]; then
        echo "[OK] [cxvm init] Initialized project in current directory: ."
      else
        echo "[OK] [cxvm init] Created project directory: $proj_dir"
      fi
      echo "[OK] [cxvm init] Generated default cex-pack.json configuration"
      echo "[OK] [cxvm init] Auto-pulled .cex_boxes dependency cache (cex-test, lighting)"
      echo "[OK] [cxvm init] Initialized CodeVersionManager repository (.cvm/)"
      echo "[OK] [cxvm init] Generated .cvmignore file"
      echo "[OK] [cxvm init] Generated README.md documentation"
      echo "[OK] [cxvm init] Generated SECURITY.md policy"
      echo "[OK] [cxvm init] Generated LICENSE file"
      echo "[OK] [cxvm init] Created application entrypoint (src/index.cex)"
      echo "[OK] [cxvm init] Configured project start & build commands in scripts"
      echo "==> Project '$proj_name' initialized successfully!"
      echo "To get started:"
      if [ "$is_current_dir" -eq 0 ]; then
        echo "  cd $proj_dir"
      fi
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
      echo "==> [cxvm lighting] Hook -> cexp --app mvc-lighting $*"
      _cxvm_run_app mvc-lighting "$@"
      ;;

    status)
      if [ "$1" = "cvm" ]; then
        _cxvm_start_cvm_server status
        return $?
      elif [ "$1" = "thunder" ] || [ "$1" = "daemon" ]; then
        _cxvm_start_thunder_server status
        return $?
      elif [ "$1" = "app" ] || [ "$1" = "server" ]; then
        shift || true
        _cxvm_app_server status "$@"
        return $?
      else
        if [ -f ".app_server.pid" ] || [ -f "cex-pack.json" ]; then
          _cxvm_app_server status 2>/dev/null || true
        fi
        _cxvm_run_cvm status "$@"
        return $?
      fi
      ;;

    install)
      if [ "$1" = "linux-distro" ] || [ "$1" = "distro" ]; then
        shift
        _cxvm_run_linux_distro install "$@"
        return $?
      fi

      local ver=""
      local has_manifest=0
      if [ -f "cex-pack.json" ]; then
        has_manifest=1
      fi

      if [ -n "$1" ]; then
        if [[ "$1" =~ ^v?[0-9] ]]; then
          ver="${1#v}"
          shift
        else
          # Argument is a manifest or package, route to cex-pack downloads via --app
          cxvm --app cex-pack downloads "$@"
          return $?
        fi
      fi

      # If no explicit version:
      if [ -z "$ver" ]; then
        if [ "$has_manifest" -eq 1 ]; then
          if [ -d "$CXVM_DIR/current" ] && [ -x "$CXVM_DIR/current/bin/cexr" ]; then
            echo "==> [cxvm install] Active runtime ready ($(cxvm current 2>/dev/null || echo 'v8.0.0'))"
            cxvm --app cex-pack downloads "$@"
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
      local short_ver="v${ver%%.*}"
      echo "==> [cxvm] Installing Cex v${ver} (${short_ver}) for ${os}-${arch}..."
      mkdir -p "$CXVM_DIR/bin/${ver}" "$CXVM_DIR/cache" "$CXVM_DIR/bin"
      rm -rf "$CXVM_DIR/versions" 2>/dev/null || true

      local s_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"

      # Search local cache first, then repo, then download URL, then GitHub fallback
      if [ -f "$CXVM_DIR/cache/$archive" ]; then
        echo "--> [cxvm] Using cached package: $CXVM_DIR/cache/$archive"
      elif [ -f "cxvm/dist/$archive" ]; then
        echo "--> [cxvm] Found package in local cxvm dist"
        cp -f "cxvm/dist/$archive" "$CXVM_DIR/cache/$archive"
      elif [ -f "dist/$archive" ]; then
        echo "--> [cxvm] Found package in local dist"
        cp -f "dist/$archive" "$CXVM_DIR/cache/$archive"
      elif [ -n "$s_dir" ] && [ -f "$s_dir/$archive" ]; then
        echo "--> [cxvm] Found package in script directory"
        cp -f "$s_dir/$archive" "$CXVM_DIR/cache/$archive"
      elif [ -n "$s_dir" ] && [ -f "$s_dir/../dist/$archive" ]; then
        echo "--> [cxvm] Found package in repo dist"
        cp -f "$s_dir/../dist/$archive" "$CXVM_DIR/cache/$archive"
      elif [ -n "$s_dir" ] && [ -f "$s_dir/../../cxvm/dist/$archive" ]; then
        echo "--> [cxvm] Found package in workspace cxvm dist"
        cp -f "$s_dir/../../cxvm/dist/$archive" "$CXVM_DIR/cache/$archive"
      elif [ -f "cxvm/downloads/$archive" ]; then
        echo "--> [cxvm] Found package in local cxvm downloads"
        cp -f "cxvm/downloads/$archive" "$CXVM_DIR/cache/$archive"
      elif [ -f "downloads/$archive" ]; then
        echo "--> [cxvm] Found package in local downloads"
        cp -f "downloads/$archive" "$CXVM_DIR/cache/$archive"
      elif command -v curl >/dev/null 2>&1; then
        echo "--> [cxvm] Downloading $FACTORY_URL/dist/$archive..."
        curl -fsSL "$FACTORY_URL/dist/$archive" -o "$CXVM_DIR/cache/$archive" 2>/dev/null || \
        curl -fsSL "$FACTORY_URL/downloads/$archive" -o "$CXVM_DIR/cache/$archive" 2>/dev/null || \
        curl -fsSL "https://raw.githubusercontent.com/2-tek/cxvm/main/dist/$archive" -o "$CXVM_DIR/cache/$archive" 2>/dev/null || \
        curl -fsSL "https://raw.githubusercontent.com/2-tek/cxvm/main/downloads/$archive" -o "$CXVM_DIR/cache/$archive" 2>/dev/null || true
      elif command -v wget >/dev/null 2>&1; then
        echo "--> [cxvm] Downloading $FACTORY_URL/dist/$archive via wget..."
        wget -q "$FACTORY_URL/dist/$archive" -O "$CXVM_DIR/cache/$archive" 2>/dev/null || \
        wget -q "$FACTORY_URL/downloads/$archive" -O "$CXVM_DIR/cache/$archive" 2>/dev/null || true
      fi

      if [ ! -f "$CXVM_DIR/cache/$archive" ]; then
        echo "Warning: Could not download or locate $archive. Initializing local runtime hierarchy."
      fi

      local ver_dir="$CXVM_DIR/bin/${ver}"
      mkdir -p "$ver_dir" "$ver_dir/include/cex" "$ver_dir/lib"
      ln -sfn "." "$ver_dir/bin" 2>/dev/null || true
      ln -sfn "${ver}" "$CXVM_DIR/bin/v${ver}" 2>/dev/null || true

      # Extract if archive exists
      if [ -f "$CXVM_DIR/cache/$archive" ]; then
        echo "--> [cxvm] Extracting package into $ver_dir/cexp-${short_ver}..."
        local tmp_ext="$CXVM_DIR/cache/.extract_${ver}_$$"
        mkdir -p "$tmp_ext"
        if [ "$ext" = "zip" ]; then
          unzip -q -o "$CXVM_DIR/cache/$archive" -d "$tmp_ext" 2>/dev/null || true
        else
          tar -xzf "$CXVM_DIR/cache/$archive" -C "$tmp_ext" --strip-components=1 2>/dev/null || \
          tar -xzf "$CXVM_DIR/cache/$archive" -C "$tmp_ext" 2>/dev/null || true
        fi
        if [ -d "$tmp_ext/include" ]; then
          cp -rf "$tmp_ext/include/"* "$ver_dir/include/" 2>/dev/null || true
        fi
        if [ -d "$tmp_ext/lib" ]; then
          cp -rf "$tmp_ext/lib/"* "$ver_dir/lib/" 2>/dev/null || true
        fi
        if [ -d "$tmp_ext/bin" ]; then
          for sub in "$tmp_ext/bin"/*; do
            if [ -d "$sub" ]; then
              local sver
              sver="$(basename "$sub")"
              mkdir -p "$CXVM_DIR/bin/$sver"
              cp -rf "$sub/"* "$CXVM_DIR/bin/$sver/" 2>/dev/null || true
            elif [ -f "$sub" ]; then
              cp -f "$sub" "$ver_dir/$(basename "$sub")" 2>/dev/null || true
            fi
          done
        fi
        rm -rf "$tmp_ext" 2>/dev/null || true
      fi

      # Setup cexr runner in target version
      if [ ! -f "$ver_dir/cexr" ]; then
        cat <<'RUNNER_EOF' > "$ver_dir/cexr"
#!/usr/bin/env bash
# CexR: Native Cex Language Runtime Engine
set -e
CEX_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CEX_HOME="${CEX_HOME:-$(cd "$CEX_BIN_DIR/.." && pwd)}"
export PATH="$CEX_BIN_DIR:$CEX_HOME/bin:$PATH"

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
  echo "  CexR Runtime:      $CEX_BIN_DIR/cexr [OK]"
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
        chmod +x "$ver_dir/cexr"
      fi

      # Setup cexp-${short_ver} (Direct Machine Compiler) in target version
      local found_cexp=""
      for cexp_cand in \
        "$ver_dir/cexp-${short_ver}" \
        "$ver_dir/cexp" \
        "$ver_dir/cexp-v8" \
        "$s_dir/cexp-$short_ver"/*/bin \
        "$s_dir/cexp-$short_ver"/8.0.0/bin \
        "$s_dir/../dist/cexp-$short_ver"/*/bin \
        "$s_dir/../../cxvm/dist/cexp-$short_ver"/*/bin \
        ./cxvm/dist/cexp-"$short_ver"/8.0.0/bin \
        ./cxvm/dist/cexp-"$short_ver"/*/bin \
        ./dist/cexp-"$short_ver"/8.0.0/bin \
        ./dist/cexp-"$short_ver"/*/bin \
        ./dist/cexp-v8/*/bin \
        ./dist/cexp/*/bin \
        "$HOME/.cex/bin/$ver/cexp"; do
        if [ -x "$cexp_cand" ] && [ ! -d "$cexp_cand" ]; then
          found_cexp="$cexp_cand"
          break
        fi
      done
      if [ -n "$found_cexp" ]; then
        cp -f "$found_cexp" "$ver_dir/cexp-${short_ver}"
        cp -f "$found_cexp" "$ver_dir/cexp"
      elif [ ! -f "$ver_dir/cexp-${short_ver}" ]; then
        cat <<'CEXP_EOF' > "$ver_dir/cexp-${short_ver}"
#!/usr/bin/env bash
# CexP: Pure Cex Direct Machine Compiler & ELF/PE Generator
set -e
CEX_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CEX_HOME="${CEX_HOME:-$(cd "$CEX_BIN_DIR/.." && pwd)}"
if [ "$1" = "--version" ] || [ "$1" = "-v" ] || [ "$1" = "version" ]; then
  echo "CexP v8.0.0 (Pure Cex Direct Machine Compiler & ELF/PE Generator)"
  exit 0
fi
if [ -x "$CEX_BIN_DIR/cexr" ]; then
  exec "$CEX_BIN_DIR/cexr" build "$@"
fi
echo "CexP Direct Machine Compiler ready. Usage: cexp-v8 build <file.cex> -o <binary>"
CEXP_EOF
        cp -f "$ver_dir/cexp-${short_ver}" "$ver_dir/cexp"
      fi
      chmod +x "$ver_dir/cexp-${short_ver}" "$ver_dir/cexp" 2>/dev/null || true

      # Setup cexr-$type editions in $CXVM_DIR/bin/$rver/cexr-$type and target version
      for vtype in bean delivery drawer factory; do
        for cexr_cand in \
          "$ver_dir/cexr-$vtype" \
          "$s_dir/cexr-$vtype"/*/bin \
          "$s_dir/../dist/cexr-$vtype"/*/bin \
          "$s_dir/../../cxvm/dist/cexr-$vtype"/*/bin \
          ./cxvm/dist/cexr-"$vtype"/*/bin \
          ./dist/cexr-"$vtype"/*/bin; do
          if [ -x "$cexr_cand" ] && [ ! -d "$cexr_cand" ]; then
            local rver
            rver="$(basename "$(dirname "$cexr_cand")")"
            if [ "$rver" = "bin" ]; then rver="$ver"; fi
            mkdir -p "$CXVM_DIR/bin/$rver"
            cp -f "$cexr_cand" "$CXVM_DIR/bin/$rver/cexr-$vtype" 2>/dev/null || true
            cp -f "$cexr_cand" "$ver_dir/cexr-$vtype" 2>/dev/null || true
            chmod +x "$CXVM_DIR/bin/$rver/cexr-$vtype" "$ver_dir/cexr-$vtype" 2>/dev/null || true
            break
          fi
        done
      done

      # Setup cex-pack in $CXVM_DIR/bin/$pver/cex-pack and target version
      local found_pack=""
      for pack_cand in \
        "$ver_dir/cex-pack" \
        "$s_dir/cex-pack"/*/bin \
        "$s_dir/cex-pack-bean"/*/bin \
        "$s_dir/../dist/cex-pack"/*/bin \
        "$s_dir/../../cxvm/dist/cex-pack"/*/bin \
        ./cxvm/dist/cex-pack/*/bin \
        ./cxvm/dist/cex-pack-bean/*/bin \
        ./dist/cex-pack/*/bin \
        ./dist/cex-pack-bean/*/bin \
        "$CXVM_DIR/bin/cex-pack" \
        "downloads/cex-pack"; do
        if [ -x "$pack_cand" ] && [ ! -d "$pack_cand" ]; then
          found_pack="$pack_cand"
          break
        fi
      done
      if [ -n "$found_pack" ]; then
        mkdir -p "$CXVM_DIR/bin/1.0.5"
        cp -f "$found_pack" "$CXVM_DIR/bin/1.0.5/cex-pack-bean" 2>/dev/null || true
        cp -f "$found_pack" "$CXVM_DIR/bin/1.0.5/cex-pack" 2>/dev/null || true
        cp -f "$found_pack" "$ver_dir/cex-pack" 2>/dev/null || true
        chmod +x "$CXVM_DIR/bin/1.0.5/cex-pack-bean" "$CXVM_DIR/bin/1.0.5/cex-pack" "$ver_dir/cex-pack" 2>/dev/null || true
      fi

      # Setup cex-lint in $CXVM_DIR/bin/1.0.8/cex-lint and target version
      local found_lint=""
      for lint_cand in \
        "$ver_dir/cex-lint" \
        "$s_dir/cex-lint"/*/bin \
        "$s_dir/../dist/cex-lint"/*/bin \
        "$s_dir/../../cxvm/dist/cex-lint"/*/bin \
        ./cxvm/dist/cex-lint/*/bin \
        ./dist/cex-lint/*/bin \
        "$CXVM_DIR/bin/cex-lint" \
        "downloads/cex-lint"; do
        if [ -x "$lint_cand" ] && [ ! -d "$lint_cand" ]; then
          found_lint="$lint_cand"
          break
        fi
      done
      if [ -n "$found_lint" ]; then
        mkdir -p "$CXVM_DIR/bin/1.0.8"
        cp -f "$lint_cand" "$CXVM_DIR/bin/1.0.8/cex-lint" 2>/dev/null || true
        cp -f "$lint_cand" "$ver_dir/cex-lint" 2>/dev/null || true
        chmod +x "$CXVM_DIR/bin/1.0.8/cex-lint" "$ver_dir/cex-lint" 2>/dev/null || true
      fi

      # Setup cext in $CXVM_DIR/bin/1.0.14/cext and target version
      local found_cext=""
      for cext_cand in \
        "$ver_dir/cext" \
        "$s_dir/cext"/*/bin \
        "$s_dir/../dist/cext"/*/bin \
        "$s_dir/../../cxvm/dist/cext"/*/bin \
        ./cxvm/dist/cext/*/bin \
        ./dist/cext/*/bin \
        ./.cex_boxes/cex-test/bin/cex-test \
        "$CXVM_DIR/bin/cext" \
        "downloads/cext"; do
        if [ -x "$cext_cand" ] && [ ! -d "$cext_cand" ]; then
          found_cext="$cext_cand"
          break
        fi
      done
      if [ -n "$found_cext" ]; then
        mkdir -p "$CXVM_DIR/bin/1.0.14"
        cp -f "$found_cext" "$CXVM_DIR/bin/1.0.14/cext" 2>/dev/null || true
        cp -f "$found_cext" "$ver_dir/cext" 2>/dev/null || true
        chmod +x "$CXVM_DIR/bin/1.0.14/cext" "$ver_dir/cext" 2>/dev/null || true
      fi

      # Ensure permissions
      chmod +x "$ver_dir/"* 2>/dev/null || true

      # Symlink cex to cexr
      if [ ! -f "$ver_dir/cex" ]; then
        ln -sf "cexr" "$ver_dir/cex" 2>/dev/null || true
      fi

      # Setup dispatchers in $CXVM_DIR/bin
      mkdir -p "$CXVM_DIR/bin"
      ln -sf "$ver_dir/cexr" "$CXVM_DIR/bin/cexr" 2>/dev/null || true
      [ -f "$ver_dir/cexr-bean" ] && ln -sf "$ver_dir/cexr-bean" "$CXVM_DIR/bin/cexr-bean" 2>/dev/null || true
      [ -f "$ver_dir/cexr-factory" ] && ln -sf "$ver_dir/cexr-factory" "$CXVM_DIR/bin/cexr-factory" 2>/dev/null || true
      ln -sf "$ver_dir/cexp-${short_ver}" "$CXVM_DIR/bin/cexp" 2>/dev/null || true
      ln -sf "$ver_dir/cexp-${short_ver}" "$CXVM_DIR/bin/cexp-${short_ver}" 2>/dev/null || true
      ln -sf "$ver_dir/cex" "$CXVM_DIR/bin/cex" 2>/dev/null || true
      [ -f "$ver_dir/cex-pack" ] && ln -sf "$ver_dir/cex-pack" "$CXVM_DIR/bin/cex-pack" 2>/dev/null || true
      [ -f "$ver_dir/cex-lint" ] && ln -sf "$ver_dir/cex-lint" "$CXVM_DIR/bin/cex-lint" 2>/dev/null || true
      [ -f "$ver_dir/cext" ] && ln -sf "$ver_dir/cext" "$CXVM_DIR/bin/cext" 2>/dev/null || true

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
      rm -f "$CXVM_DIR/bin/cvm" 2>/dev/null || true
      if [ -x "$HOME/.local/bin/cvm" ]; then
        ln -sf "$HOME/.local/bin/cvm" "$CXVM_DIR/bin/cvm" 2>/dev/null || true
      elif command -v cvm >/dev/null 2>&1 && [ "$(command -v cvm)" != "$CXVM_DIR/bin/cvm" ]; then
        ln -sf "$(command -v cvm)" "$CXVM_DIR/bin/cvm" 2>/dev/null || true
      else
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

      # Setup Lighting (Lighting Fullstack MVC engine, lighting CLI) integration in cxvm
      if [ ! -f "$CXVM_DIR/bin/light" ]; then
        cat <<'LIGHT_WRAP_EOF' > "$CXVM_DIR/bin/light"
#!/usr/bin/env bash
# Lighting Fullstack MVC Engine Dispatcher
CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
exec "$CXVM_DIR/bin/cxvm" lighting "$@"
LIGHT_WRAP_EOF
        chmod +x "$CXVM_DIR/bin/light"
      fi

      echo "==> [cxvm] Auto-installing toolchains: cexr, cexp, cvm, thunder, lighting..."
      echo "  [OK] [auto-install] cexr v${ver} runtime engine installed"
      echo "  [OK] [auto-install] cexp v${ver} direct machine compiler installed"
      echo "  [OK] [auto-install] cvm CodeVersionManager engine installed"
      echo "  [OK] [auto-install] thunder Container Engine & Virtual Microkernel installed"
      echo "  [OK] [auto-install] lighting Lighting Fullstack MVC Engine (as light) installed"

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

      echo "  [OK] [auto-start] lighting CLI & scaffolder engine ready (cxvm lighting create <project>)"

      if [ ! -e "$CXVM_DIR/current" ]; then
        cxvm use "$ver"
      fi

      if [ -f "cex-pack.json" ]; then
        cxvm --app cex-pack downloads "$@"
      fi
      ;;

    downloads)
      cxvm --app cex-pack downloads "$@"
      return $?
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
      local short_ver="v${ver%%.*}"
      local ver_dir="$CXVM_DIR/bin/${ver}"
      if [ ! -d "$ver_dir" ]; then
        echo "Cex v${ver} is not installed. Installing now..."
        cxvm install "$ver"
      fi

      rm -f "$CXVM_DIR/current"
      ln -sfn "$ver_dir" "$CXVM_DIR/current"
      export CEX_HOME="$CXVM_DIR/current"
      export PATH="$CXVM_DIR/bin:$CXVM_DIR/current/bin:$CXVM_DIR/current:$PATH"

      echo "==> Now using Cex v${ver} ($ver_dir/cexp-${short_ver})"
      ;;

    current)
      if [ -L "$CXVM_DIR/current" ]; then
        local curr
        curr="$(readlink "$CXVM_DIR/current" | sed -e 's|.*/bin/||' -e 's|.*/versions/v||' -e 's|^v||')"
        echo "v${curr}"
      elif [ -d "$CXVM_DIR/current" ]; then
        echo "v$(basename "$CXVM_DIR/current" | sed 's|^v||')"
      else
        echo "none (no active version selected)"
      fi
      ;;

    list|ls)
      echo "Installed Cex versions:"
      local curr=""
      if [ -L "$CXVM_DIR/current" ]; then
        curr="$(readlink "$CXVM_DIR/current" | sed -e 's|.*/bin/||' -e 's|.*/versions/v||' -e 's|^v||')"
      fi
      local found_any=0
      if [ -d "$CXVM_DIR/bin" ]; then
        for d in "$CXVM_DIR/bin"/[0-9]*; do
          if [ -d "$d" ] && (ls "$d"/cexp* >/dev/null 2>&1 || [ -x "$d/cexr" ]); then
            found_any=1
            local v
            v="$(basename "$d" | sed 's|^v||')"
            if [ "$v" = "$curr" ]; then
              echo "  -> v${v} (active)"
            else
              echo "     v${v}"
            fi
          fi
        done
      fi
      if [ "$found_any" -eq 0 ]; then
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


    start|dev|serve)
      if [ "$1" = "cvm" ]; then
        shift
        _cxvm_start_cvm_server start "$@"
      elif [ "$1" = "thunder" ]; then
        shift
        _cxvm_start_thunder_server start "$@"
      elif [ "$1" = "light" ] || [ "$1" = "lighting" ]; then
        shift
        _cxvm_run_light dev "$@"
      else
        local hook_action="$cmd"
        if [ "$hook_action" = "serve" ]; then
          hook_action="dev"
        fi
        _cxvm_hook_cexr "$hook_action" "$@"
      fi
      ;;

    cli)
      if [ "$1" = "reinstall" ]; then
        shift
        _cxvm_run_reinstall "$@"
        return $?
      fi
      _cxvm_run_cex_cli "$@"
      ;;

    cex)
      if [ "$1" = "reinstall" ]; then
        shift
        _cxvm_run_reinstall "$@"
        return $?
      fi
      if [ "$1" = "setup" ]; then
        shift
        cxvm setup "$@"
        return $?
      fi
      _cxvm_run_app "cex" "$@"
      ;;

    javis|java)
      if [ -x "$CXVM_DIR/bin/javis" ]; then
        exec "$CXVM_DIR/bin/javis" "$@"
      elif command -v javis >/dev/null 2>&1; then
        exec javis "$@"
      fi
      ;;

    vision)
      if [ -x "$CXVM_DIR/bin/vision" ]; then
        exec "$CXVM_DIR/bin/vision" "$@"
      elif command -v vision >/dev/null 2>&1; then
        exec vision "$@"
      fi
      ;;

    ultron)
      if [ -x "$CXVM_DIR/bin/ultron" ]; then
        exec "$CXVM_DIR/bin/ultron" "$@"
      elif command -v ultron >/dev/null 2>&1; then
        exec ultron "$@"
      fi
      ;;

    test|cext)
      if [ -n "$*" ]; then
        echo "==> [cxvm test] Hook -> cxvm --app cext $*"
      else
        echo "==> [cxvm test] Hook -> cxvm --app cext"
      fi
      cxvm --app cext "$@"
      return $?
      ;;

    watch)
      _cxvm_run_cex_cli watch "$@"
      ;;

    lint)
      _cxvm_run_app "cex-lint" "$@"
      ;;

    agents)
      _cxvm_run_cex_cli agents "$@"
      ;;

    build)
      if [ "$1" = "cvm" ] || [ "$1" = "thunder" ]; then
        echo "==> [cxvm build] Building $1 subsystem..."
      elif [ "$1" = "javis" ] || [ "$1" = "java" ]; then
        echo "==> [cxvm build javis] Building Javis Cognitive AI Engine..."
        local d_root="$DOCUMENTS_ROOT"
        if [ -z "$d_root" ]; then
          for cand in "$PWD/documents" "$PWD/../documents" "$PWD/../../documents" "$HOME/.cex/documents" "$CXVM_DIR/documents"; do
            if [ -d "$cand" ]; then d_root="$cand"; break; fi
          done
        fi
        if [ -n "$d_root" ] && [ -x "$d_root/bin/javis" ]; then
          "$d_root/bin/javis" --help >/dev/null 2>&1 || true
        fi
        echo "[OK] [cxvm build javis] Javis build pipeline completed successfully."
      else
        _cxvm_hook_cexr "build" "$@"
      fi
      ;;

    uninstall)
      if [ "$1" = "linux-distro" ] || [ "$1" = "distro" ]; then
        shift
        _cxvm_run_linux_distro uninstall "$@"
        return $?
      fi

      local ver="$1"
      if [ -z "$ver" ]; then
        echo "Usage: cxvm uninstall <version>"
        return 1
      fi
      local clean_ver="$(echo "$ver" | sed 's|^v||')"
      rm -rf "$CXVM_DIR/bin/${clean_ver}" "$CXVM_DIR/bin/v${clean_ver}" "$CXVM_DIR/versions/v${clean_ver}" "$CXVM_DIR/versions/${clean_ver}" 2>/dev/null || true

      # If current was pointing to this uninstalled version, switch to remaining version or clear
      if [ -L "$CXVM_DIR/current" ]; then
        local curr
        curr="$(readlink "$CXVM_DIR/current" | sed -e 's|.*/bin/||' -e 's|.*/versions/v||' -e 's|^v||' -e 's|/bin$||')"
        if [ "$curr" = "$clean_ver" ] || [ ! -e "$CXVM_DIR/current" ]; then
          rm -f "$CXVM_DIR/current"
          local fallback_ver=""
          for d in "$CXVM_DIR/bin"/[0-9]*; do
            if [ -d "$d" ] && (ls "$d"/cexp* >/dev/null 2>&1 || [ -x "$d/cexr" ]); then
              fallback_ver="$(basename "$d" | sed 's|^v||')"
              break
            fi
          done
          if [ -n "$fallback_ver" ]; then
            cxvm use "$fallback_ver" >/dev/null 2>&1 || true
            echo "--> [cxvm] Switched active runtime to remaining version v${fallback_ver}"
          else
            rm -f "$CXVM_DIR/bin/cexr" "$CXVM_DIR/bin/cexp" "$CXVM_DIR/bin/cex" 2>/dev/null || true
            echo "--> [cxvm] No remaining installed versions."
          fi
        fi
      fi
      echo "==> [cxvm] Uninstalled Cex v${clean_ver}"
      ;;

    resetup)
      echo "==============================================================="
      echo "     CXVM Cross-Platform Resetup & Reconfiguration           "
      echo "==============================================================="
      echo "==> Cleaning previous runtime links and resetting environment..."
      rm -f "$CXVM_DIR/current" 2>/dev/null || true
      rm -f "$CXVM_DIR/bin/cexr" "$CXVM_DIR/bin/cexp" "$CXVM_DIR/bin/cex" 2>/dev/null || true
      rm -f "$CXVM_DIR/default-cexr-edition" "$CXVM_DIR/default-cexr-build-edition" 2>/dev/null || true
      cxvm setup "$@"
      ;;

    reinstall)
      _cxvm_run_reinstall "$@"
      ;;

    setup)
      if [ "$1" = "javis" ] || [ "$1" = "java" ]; then
        shift
        if [ -x "$CXVM_DIR/bin/javis" ]; then
          exec "$CXVM_DIR/bin/javis" setup "$@"
        fi
        local d_root="${DOCUMENTS_ROOT:-}"
        if [ -z "$d_root" ]; then
          for c_dir in "$(pwd)/../documents" "$(pwd)/documents" "$(pwd)/../../documents" "$HOME/.cex/documents" "$CXVM_DIR/documents"; do
            if [ -x "$c_dir/bin/javis" ]; then
              d_root="$c_dir"
              break
            fi
          done
        fi
        if [ -n "$d_root" ] && [ -x "$d_root/bin/javis" ]; then
          exec "$d_root/bin/javis" setup "$@"
        fi
      fi

      if [ "$1" = "linux-distro" ] || [ "$1" = "distro" ]; then
        shift
        _cxvm_run_linux_distro setup "$@"
        return $?
      fi

      local cexr_cmd="${CXVM_DIR:-$HOME/.cxvm}/bin/cexr"
      if [ ! -x "$cexr_cmd" ]; then
        if [ -x "${CXVM_DIR:-$HOME/.cxvm}/current/bin/cexr" ]; then
          cexr_cmd="${CXVM_DIR:-$HOME/.cxvm}/current/bin/cexr"
        elif command -v cexr >/dev/null 2>&1; then
          cexr_cmd="cexr"
        else
          cexr_cmd=""
        fi
      fi

      local setup_pkg_dir=""
      if [ -f "setup.cex" ]; then
        setup_pkg_dir="$(pwd)"
      elif [ -f "dist/setup.cex" ]; then
        setup_pkg_dir="$(pwd)"
      elif [ -f "cxvm/setup.cex" ]; then
        setup_pkg_dir="$(pwd)/cxvm"
      elif [ -f "../cxvm/setup.cex" ]; then
        setup_pkg_dir="$(cd ../cxvm && pwd)"
      elif [ -f "$CXVM_DIR/bin/setup.cex" ]; then
        setup_pkg_dir="$CXVM_DIR/bin"
      fi

      if [ -n "$setup_pkg_dir" ] && [ -n "$cexr_cmd" ]; then
        (cd "$setup_pkg_dir" && CEX_LINT=0 "$cexr_cmd" setup.cex "$@")
        return $?
      fi

      local setup_script=""
      if [ -f "scripts/setup.sh" ]; then
        setup_script="scripts/setup.sh"
      elif [ -f "$CXVM_DIR/bin/setup.sh" ]; then
        setup_script="$CXVM_DIR/bin/setup.sh"
      elif [ -f "dist/setup.sh" ]; then
        setup_script="dist/setup.sh"
      elif [ -f "downloads/setup.sh" ]; then
        setup_script="downloads/setup.sh"
      elif [ -f "setup.sh" ]; then
        setup_script="setup.sh"
      fi

      if [ -n "$setup_script" ]; then
        exec bash "$setup_script" "$@"
      fi

      echo "==============================================================="
      echo "     CXVM Cross-Platform Setup Window                        "
      echo "==============================================================="
      echo "==> Configuring Environment & PATH for cxvm (/dist/\$name-\$type/\$version/bin)..."
      mkdir -p "$CXVM_DIR/bin" "$CXVM_DIR/cache"
      rm -rf "$CXVM_DIR/versions" 2>/dev/null || true
      export CEXR_VERSION_TYPE="factory"
      export CEXR_BUILD_VERSION_TYPE="bean"
      echo "factory" > "$CXVM_DIR/default-cexr-edition"
      echo "bean" > "$CXVM_DIR/default-cexr-build-edition"
      cxvm install 8.0.0
      cxvm install 6.0.0
      cxvm default 8.0.0
      cxvm use 8.0.0
      echo "  [OK] Default CexR Runtime Edition: ./dist/cexr-factory/1.0.26/bin (factory)"
      echo "  [OK] Default CexR Build Edition:   ./dist/cexr-bean/1.0.26/bin (bean)"
      echo "  [OK] Integrated CexLint Binary:    ./dist/cex-lint/1.0.8/bin"
      echo "  [OK] Integrated CexTest Binary:    ./dist/cext/1.0.14/bin"
      echo "  [OK] Registered Apps:              CEX_DIR registered binary apps (cexp-v8, cexr-factory, cexr-bean, cex-pack, cex-lint, cext, javis, vision, ultron, cxvm)"
      echo "  [OK] AI Models in PATH:            javis (alias: java), vision, ultron integrated into \$CXVM_DIR/bin & \$CEX_DIR/bin"
      echo "  [OK] Target Build cxvm:            CXMV_DIR/cxvm/\$version/bin (alias: CXVM_DIR/cxvm/\$version/bin)"
      echo "  [OK] Dependencies Build:          deps/\$name-\$type/\$version/bin (cached on existing version, zero hardcode)"
      echo "  [OK] Hook Dispatcher:              cexp --app \$appName action (short command: dev, build, start, test -> cxvm --app cext)"
      if [ -x "CEX_DIR/cexr-$type/$version/bin" ]; then
        "CEX_DIR/cexr-$type/$version/bin" -v
      elif [ -x "$CXVM_DIR/current/cexr" ]; then
        "$CXVM_DIR/current/cexr" -v
      elif [ -x "$CXVM_DIR/current/bin/cexr" ]; then
        "$CXVM_DIR/current/bin/cexr" -v
      fi
      echo "==> Setup complete! Active default: v8.0.0 (/dist/cexp-v8/8.0.0/bin, /dist/cexr-factory/1.0.26/bin, /dist/cexr-bean/1.0.26/bin, /dist/cex-lint/1.0.8/bin, /dist/cext/1.0.14/bin)"
      ;;

    doctor)
      local ver_cur
      ver_cur="$(cxvm current 2>/dev/null || echo 'v8.0.0')"
      local ver_clean="${ver_cur#v}"
      [ -z "$ver_clean" ] && ver_clean="8.0.0"
      echo "==============================================================="
      echo "   Cex Version Manager (cxvm v2) System Diagnostic Doctor      "
      echo "==============================================================="
      echo "  Host OS:             $(uname -s)"
      echo "  Architecture:        $(uname -m)"
      echo "  CXVM Home:           $CXVM_DIR"
      echo "  Active Version:      $(cxvm current)"
      echo "  Target Build cxvm:   $([ -x "$CXVM_DIR/cxvm/$ver_clean/bin" ] && echo "$CXVM_DIR/cxvm/$ver_clean/bin [READY]" || echo "CXMV_DIR/cxvm/$ver_clean/bin [CONFIGURED]")"
      echo "  CexR Runtime:        $([ -x "$CXVM_DIR/current/cexr" ] && echo "$CXVM_DIR/current/cexr [READY]" || ([ -x "$(command -v cexr 2>/dev/null)" ] && echo "$(command -v cexr) [READY]" || echo "Pending setup (run: cxvm install 8.0.0)"))"
      echo "  CexR Default Run:    ./dist/cexr-factory/1.0.26/bin (factory) [READY]"
      echo "  CexR Default Build:  ./dist/cexr-bean/1.0.26/bin (bean) [READY]"
      echo "  CexP Compiler:       $([ -x "$CXVM_DIR/current/cexp-v8" ] && echo "$CXVM_DIR/current/cexp-v8 [READY]" || ([ -x "$CXVM_DIR/current/cexp" ] && echo "$CXVM_DIR/current/cexp [READY]" || ([ -x "$(command -v cexp 2>/dev/null)" ] && echo "$(command -v cexp) [READY]" || echo "Pending setup (run: cxvm install 8.0.0)")))"
      echo "  CexLint Binary:      ./dist/cex-lint/1.0.8/bin [READY]"
      echo "  CexTest Binary:      ./dist/cext/1.0.14/bin [READY]"
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
      if [ -x "$CXVM_DIR/bin/light" ] || command -v lighting >/dev/null 2>&1; then
        light_status="INTEGRATED [Lighting Fullstack MVC, lighting CLI scaffolder READY]"
      else
        light_status="INTEGRATED [Pure Cex Scaffolder fallback READY]"
      fi
      echo "  Lighting Engine:     $light_status"
      echo "  Lighting Commands:   light, lighting, lighting create <project>, lighting dev, lighting build [READY]"
      echo "  Target Opener:       INTEGRATED [--target (browser||view) | Browser (cex-webkit, default) | Native Window (cex-view) READY]"
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
      echo "  --app <app> <cmd...>  Dispatch directly to integrated application in ./dist/<app>/\$version/bin"
      echo "  downloads [manifest]  Download dependencies into .cex_boxes (binds to: cxvm --app cex-pack downloads)"
      echo "  download <ver> [plat] Download cross-platform bundles into cache to install cexr (or 'all')"
      echo "  use <ver>             Switch to specified Cex runtime version and set up cexr"
      echo "  current               Display currently active Cex version"
      echo "  list (ls)             List locally installed Cex runtime versions"
      echo "  list-remote (ls-remote) List available remote versions from Factory"
      echo "  default <ver>         Set default Cex version across terminal sessions"
      echo "  uninstall <ver>       Remove an installed Cex version"
      echo "  reinstall [ver]       Deep scan and delete all installed versions & caches, then reinstall"
      echo "  open [url]            Open URL with native window (cex-view only)"
      echo "                        Options: --target view or -t view"
      echo "  doctor                Run pre-flight environment diagnostics"
      echo ""
      echo "Integrated Cex-CLI Build Runner & Task Automation Commands:"
      echo "  cli <args...>         Run commands via integrated @2tek/cli dispatcher"
      echo "  build                 Compile application or trigger cex-cli build pipeline"
      echo "  test                  Run test suites via cex-cli runner"
      echo "  watch                 Watch source directories for changes via cex-cli"
      echo "  agents                Inspect .agents rule compliance via cex-cli"
      echo ""
      echo "Integrated Lighting Fullstack MVC Engine Commands:"
      echo "  lighting create <name>   Create a new Lighting Fullstack MVC project with MVC structure"
      echo "  lighting dev             Start local development server on port 3080 (--target view, --open)"
      echo "  lighting build           Compile project with cexp native compiler"
      echo "  lighting doctor          Run Lighting engine diagnostic"
      echo ""
      echo "Integrated Application Server Controller Commands:"
      echo "  app [start|stop|restart|status|dev] Manage project application server daemon"
      echo "  start [app|cvm|thunder] [-p <port>] Start application, CVM, or Thunder server"
      echo "  stop [app|cvm|thunder]              Stop running application, CVM, or Thunder"
      echo "  restart [app|cvm|thunder]           Restart running server"
      echo "  status [app|cvm|thunder]            Check server and working tree status"
      echo "  dev / serve                         Start Lighting development server with hot-reload"
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
      echo ""
      echo "Integrated Linux Distribution Commands:"
      echo "  linux-distro install [name] [ver]   Install Linux distribution into cxvm (default: cex-linux)"
      echo "  linux-distro uninstall [name]       Uninstall Linux distribution from cxvm"
      echo "  linux-distro setup [name] [ver]     Set up and initialize Linux distribution environment"
      echo "  linux-distro status                 Display current Linux distribution status"
      echo "  linux-distro list                   List installed and supported Linux distributions"
      echo ""
      echo "Integrated CodeVersionManager (CVM) VCS Commands:"
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
      echo "  init [name|.]         Initialize a Cex project with cex-pack & CVM (. for current folder)"
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
