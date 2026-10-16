---
trigger: always_on
---

# Rule: Pure Cex Binaries & Scripts in bin/ and scripts/ (RULE_PURE_CEX_BIN)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), RULE_CEX_TOOLCHAIN -->

> **Severity: MANDATORY / STRICT**

## 1. Requirement
Across `cxvm` and all packages, any `bin/` directory and executable tool scripts must use native `.cex` files (e.g., `bin/cex-pack.cex`, `scripts/cex_pack.cex`, `scripts/generate_manifest.cex`, `scripts/verify_eof.cex`, `scripts/cvm_server.cex`, `scripts/thunder_server.cex`) executed by the `cexr` runtime.
Under no circumstances are Python scripts (`python`, `python3`, `#!/usr/bin/env python3`, `.py`), JavaScript files (`.js`), or Node.js scripts (`#!/usr/bin/env node`) permitted.

When invoking `cxvm dev`, `cxvm build`, or `cxvm start`, `cxvm` hooks and calls:
```bash
cxvm --app cexr $versionType <dev|build|start> <target_index>
```
(for example `$versionType=bean`, e.g., `cxvm --app cexr bean build src/index.cex`).

## 2. Invariants
1. **Pure .cex Execution**: All executable entrypoints, generators, validators, and tools must be written in the Cex native language (`.cex`) and run with the `cexr` runtime (`cexr <script.cex>`).
2. **Runtime Hook Invocation**: `cxvm dev`, `cxvm build`, and `cxvm start` act as hooks calling `cxvm --app cexr $versionType ... <target_index>`.
3. **Zero Python or JavaScript**: No `python`/`python3`/`.py` or `.js`/Node.js scripts are allowed in `bin/`, `scripts/`, or `dist/`.
4. **Rule 29 Conformance**: Every file must end with a single trailing newline.
