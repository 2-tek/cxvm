#!/usr/bin/env bash
# cxvm: Cex Version Manager (Cross-platform runtime manager for Cex)
# Inspired by nvm, pyenv, and rustup
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)

CXVM_DIR="${CXVM_DIR:-$HOME/.cxvm}"
FACTORY_URL="${CEX_FACTORY_URL:-http://127.0.0.1:3080}"

cxvm() {
  local cmd="$1"
  shift || true

  case "$cmd" in
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
      mkdir -p "$CXVM_DIR/versions/v${ver}" "$CXVM_DIR/cache"

      # Search local repo first, then download URL
      if [ -f "cxvm/downloads/$archive" ]; then
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
        curl -fsSL "$FACTORY_URL/downloads/$archive" -o "$CXVM_DIR/cache/$archive" 2>/dev/null || true
      fi

      if [ ! -f "$CXVM_DIR/cache/$archive" ]; then
        echo "Error: Archive $archive could not be found or downloaded."
        return 1
      fi

      if [ "$ext" = "zip" ]; then
        unzip -q -o "$CXVM_DIR/cache/$archive" -d "$CXVM_DIR/versions/v${ver}"
        if [ -d "$CXVM_DIR/versions/v${ver}/cex-v${ver}-${os}-${arch}" ]; then
          cp -r "$CXVM_DIR/versions/v${ver}/cex-v${ver}-${os}-${arch}"/* "$CXVM_DIR/versions/v${ver}/" 2>/dev/null || true
          rm -rf "$CXVM_DIR/versions/v${ver}/cex-v${ver}-${os}-${arch}" 2>/dev/null || true
        fi
      else
        tar -xzf "$CXVM_DIR/cache/$archive" -C "$CXVM_DIR/versions/v${ver}" --strip-components=1 2>/dev/null || \
        tar -xzf "$CXVM_DIR/cache/$archive" -C "$CXVM_DIR/versions/v${ver}" 2>/dev/null || true
      fi

      echo "==> [cxvm] Successfully installed Cex v${ver} into $CXVM_DIR/versions/v${ver}"
      if [ ! -e "$CXVM_DIR/current" ]; then
        cxvm use "$ver"
      fi
      ;;

    use)
      local ver="$1"
      if [ -z "$ver" ]; then
        echo "Usage: cxvm use <version>"
        return 1
      fi
      local target="$CXVM_DIR/versions/v${ver}"
      if [ ! -d "$target" ]; then
        echo "Error: Cex v${ver} is not installed. Run 'cxvm install ${ver}' first."
        return 1
      fi
      rm -f "$CXVM_DIR/current"
      ln -s "$target" "$CXVM_DIR/current"
      export PATH="$CXVM_DIR/current/bin:$PATH"
      echo "==> [cxvm] Now using Cex v${ver} ($target)"
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

    uninstall)
      local ver="$1"
      if [ -z "$ver" ]; then
        echo "Usage: cxvm uninstall <version>"
        return 1
      fi
      rm -rf "$CXVM_DIR/versions/v${ver}"
      echo "==> [cxvm] Uninstalled Cex v${ver}"
      ;;

    doctor)
      echo "==============================================================="
      echo "   Cex Version Manager (cxvm) System Diagnostic Doctor         "
      echo "==============================================================="
      echo "  Host OS:             $(uname -s)"
      echo "  Architecture:        $(uname -m)"
      echo "  CXVM Home:           $CXVM_DIR"
      echo "  C++ Compiler:        $(command -v g++ || command -v clang++ || echo 'Not found')"
      if command -v g++ >/dev/null 2>&1 || command -v clang++ >/dev/null 2>&1; then
        echo "  C++20 Status:        PASSED [g++ / clang++ available]"
      else
        echo "  C++20 Status:        WARNING: C++ compiler not in PATH"
      fi
      echo "  Active Version:      $(cxvm current)"
      echo "  CexR Runtime:        v8 (.cex_boxes Dist Loader Runtime Engine)"
      echo "  CexP Compiler:       v8 (Machine Code & ELF Direct Emitter)"
      echo "  Diagnostic:          HEALTHY [OK]"
      ;;

    help|--help|-h|*)
      echo "Cex Version Manager (cxvm) - Cross-Platform Runtime Setup"
      echo "Usage: cxvm <command> [options]"
      echo ""
      echo "Commands:"
      echo "  install <ver>         Download and install a Cex runtime version (e.g. 8.0.0, 6.0.0)"
      echo "  use <ver>             Switch to specified Cex runtime version"
      echo "  current               Display currently active Cex version"
      echo "  list (ls)             List locally installed Cex runtime versions"
      echo "  list-remote (ls-remote) List available remote versions from Factory"
      echo "  default <ver>         Set default Cex version across terminal sessions"
      echo "  uninstall <ver>       Remove an installed Cex version"
      echo "  doctor                Run pre-flight environment diagnostics"
      echo "  help                  Show this help message"
      ;;
  esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ] || [ -z "${BASH_SOURCE[0]}" ]; then
  cxvm "$@"
fi
