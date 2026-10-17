---
trigger: always_on
---

# Rule: Hook using App with `cexp --app $appName action` (Short Command) & Register Binary App in CEX_DIR (RULE_CXVM_HOOK_CEXR_AND_NO_PYTHON)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), RULE_CEX_TOOLCHAIN, RULE_PURE_CEX_BIN -->

> **MANDATORY DIRECTIVE**:
> 1. **Hook using App with `cexp --app $appName action` (Short Command)**:
>    When invoking short commands (`cxvm dev`, `cxvm build`, `cxvm start`, or direct `cexp dev`, `cexp build`, `cexp start`), it operates as a **hook** that calls:
>    ```bash
>    cexp --app $appName $action <target_index>
>    ```
>    where `$appName` is the registered application binary name (e.g. `cexr-factory` for `dev`, `cexr-bean` for `build`/`start`, or explicitly passed edition) and `$action` is the short command action (`dev`, `build`, `start`).
> 2. **Register Binary App in `CEX_DIR`, Target Build in `CXMV_DIR`, & Integrated Build in `CXVM_DIR`**:
>    All toolchain binaries (`cexp-v8`, `cexp`, `cexr-factory`, `cexr-bean`, `cexr-delivery`, `cexr-drawer`, `cex-pack`, `cex-lint`, `cxvm`, `cvm`, `thunder`, `lighting`) MUST be registered in `CEX_DIR`:
>    - Reserve path: `CEX_DIR/$appName/$version/bin`
>    - Direct companion binary: `CEX_DIR/bin/$appName`
>    - CXVM Target Build: `CXMV_DIR/cxvm/$version/bin` (alias `CXVM_DIR/cxvm/$version/bin`)
>    - Integrated Build Target: `CXVM_DIR/$name-$type/$version/binary` (e.g. `CXVM_DIR/cxvm-bean/2.0.0/binary`)
> 3. **Replace setup.sh with setup.cex & Zero Python via `cexr-$type` Runtime**:
>    Setup is implemented in pure Cex (`setup.cex`) and executed natively via `cexr setup.cex`.
>    All scripts that previously used Python (`python`, `python3`, `#!/usr/bin/env python3`, `python3 -c`) MUST be replaced with native `.cex` scripts executed using the `cexr-$type` runtime (`cexr <script.cex>`).

---

## 1. Hook Specification (`cexp --app $appName action`)

| CXVM Short Command | Hook Invocation | Default Target Index | Example |
| :--- | :--- | :--- | :--- |
| `cxvm dev [target_index]` | `cexp --app $appName dev <target_index>` | `src/index.cex` | `cexp --app cexr-factory dev src/index.cex` |
| `cxvm build [target_index]` | `cexp --app $appName build <target_index>` | `src/index.cex` | `cexp --app cexr-bean build src/index.cex` |
| `cxvm start [target_index]` | `cexp --app $appName start <target_index>` | `src/index.cex` | `cexp --app cexr-bean start src/index.cex` |

- **Resolution of `$appName`**:
  1. Default for `dev`: `cexr-factory`.
  2. Default for `build` and `start`: `cexr-bean`.
  3. Explicit edition argument if provided (`bean` -> `cexr-bean`, `factory` -> `cexr-factory`, etc.).
  4. Project `cex-pack.json` `"runtime"` field if configured.
- **Resolution of `<target_index>`**:
  1. Explicit `.cex` file argument if provided.
  2. Project `cex-pack.json` `"main"` field (defaulting to `src/index.cex`).

---

## 2. Pure `.cex` Script Replacement via `cexr-$type` Runtime

1. **Zero Python Dependency**:
   - Do NOT use `python` or `python3` in any shell script, batch script, PowerShell script, or verification rule.
   - Replace all Python scripts with `.cex` source files executed by `cexr-$type`:
     - `scripts/cex_pack.cex` (replaces Python `cex-pack` validator and `.cex_boxes` downloader)
     - `scripts/generate_manifest.cex` (replaces inline `python3` manifest generator in `scripts/generate_distributions.sh`)
     - `scripts/verify_eof.cex` (replaces `python3 -c` in `RULE_29_EOF_INTEGRITY.md`)
     - `scripts/cvm_server.cex` (replaces Python `cvm-server`)
     - `scripts/thunder_server.cex` (replaces Python `thunder-server`)
2. **Rule 29 Conformance**:
   - Every `.cex` script and `.md` rule file must end with a single trailing newline (`\n`).
