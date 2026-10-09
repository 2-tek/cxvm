---
trigger: always_on
---

# Rule: Pure Cex Binaries in bin/ (RULE_PURE_CEX_BIN)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols) -->

> **Severity: MANDATORY / STRICT**

## 1. Requirement
Across `cxvm` and all packages under `packages/`, any package `bin/` directory must contain exclusively native `.cex` files (e.g., `bin/cex-pack.cex`, `bin/cex-log.cex`).
Under no circumstances are JavaScript files (`.js`), Node.js scripts (`#!/usr/bin/env node`), or non-`.cex` interpreted scripts permitted in package `bin/` directories.

## 2. Invariants
1. **Pure .cex Execution**: All executable entrypoints and tools in package `bin/` must be written in the Cex native language (`.cex`).
2. **Runtime Invocation**: Scripts and binaries in `bin/` are driven strictly by the native Cex toolchain (`cexr run bin/<tool>.cex` or direct machine compilation via `cexp`).
3. **Zero JavaScript in bin/**: No `.js` files or wrappers are allowed in package `bin/`.
4. **Rule 29 Conformance**: Every file must end with a single trailing newline.
