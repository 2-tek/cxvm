---
trigger: always_on
---

# Rule: CXVM Hook for dev, build, start (`cxvm --app cexr $versionType`) & Replace Python Scripts with `.cex` via `cexr` Runtime (RULE_CXVM_HOOK_CEXR_AND_NO_PYTHON)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), RULE_CEX_TOOLCHAIN, RULE_PURE_CEX_BIN -->

> **MANDATORY DIRECTIVE**:
> 1. **CXVM Hook on `dev`, `build`, and `start`**:
>    When using `cxvm dev`, `cxvm build`, or `cxvm start`, it operates as a **hook** that calls:
>    ```bash
>    cxvm --app cexr $versionType <dev|build|start> <target_index>
>    ```
>    where `$versionType` is the CexR runtime edition/version type (for example `$versionType=bean`, `delivery`, `drawer`, `factory`, or `8.0.0`) and `<target_index>` is the target index file (e.g. `src/index.cex`).
> 2. **Replace Python Scripts with `.cex` via `cexr` Runtime**:
>    All scripts that previously used Python (`python`, `python3`, `#!/usr/bin/env python3`, `python3 -c`) MUST be replaced with native `.cex` scripts executed using the `cexr` runtime (`cexr <script.cex>`).

---

## 1. Hook Specification (`cxvm dev`, `cxvm build`, `cxvm start`)

| CXVM Command | Hook Invocation | Example (`$versionType=bean`) |
| :--- | :--- | :--- |
| `cxvm dev [target_index]` | `cxvm --app cexr $versionType dev <target_index>` | `cxvm --app cexr bean dev src/index.cex` |
| `cxvm build [target_index] [out_bin]` | `cxvm --app cexr $versionType build <target_index> [out_bin]` | `cxvm --app cexr bean build src/index.cex` |
| `cxvm start [target_index]` | `cxvm --app cexr $versionType start <target_index>` | `cxvm --app cexr bean start src/index.cex` |

- **Resolution of `$versionType`**:
  1. Explicit `$versionType` argument if provided (`bean`, `delivery`, `drawer`, `factory`, `8.0.0`, `6.0.0`).
  2. Project `cex-pack.json` `"runtime"` field if set to a valid edition (`bean`, `delivery`, `drawer`, `factory`).
  3. Default edition: `bean` (`example=bean`).
- **Resolution of `<target_index>`**:
  1. Explicit `.cex` file argument if provided.
  2. Project `cex-pack.json` `"main"` field (defaulting to `src/index.cex`).

---

## 2. Pure `.cex` Script Replacement via `cexr` Runtime

1. **Zero Python Dependency**:
   - Do NOT use `python` or `python3` in any shell script, batch script, PowerShell script, or verification rule.
   - Replace all Python scripts with `.cex` source files executed by `cexr`:
     - `scripts/cex_pack.cex` (replaces Python `cex-pack` validator and `.cex_boxes` downloader)
     - `scripts/generate_manifest.cex` (replaces inline `python3` manifest generator in `scripts/generate_distributions.sh`)
     - `scripts/verify_eof.cex` (replaces `python3 -c` in `RULE_29_EOF_INTEGRITY.md`)
     - `scripts/cvm_server.cex` (replaces Python `cvm-server`)
     - `scripts/thunder_server.cex` (replaces Python `thunder-server`)
2. **Rule 29 Conformance**:
   - Every `.cex` script and `.md` rule file must end with a single trailing newline (`\n`).
