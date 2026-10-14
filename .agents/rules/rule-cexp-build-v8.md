---
trigger: always_on
---

# Mandatory Rule: cexp Requires At Least ^8 for Compiling, Building, and Testing Code .cex (RULE_CEXP_BUILD_V8)

<!-- Standard Specification: .agents/rules/RULE_CEXP_BUILD_V8.md -->
<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), Rule (Pure Language Compiler) -->

> **MANDATORY AT LEAST `^8` FOR `cexp` TO COMPILE, BUILD, AND TEST CODE `.cex`**:
> Whenever `cexp` is invoked to compile, build, or test `.cex` source files across any project in the Cex ecosystem:
>
> 1. **MINIMUM COMPILER VERSION >= ^8 FOR COMPILE, BUILD & TEST**:
>     - Compiling (`cexp compile`), building (`cexp build`), and testing (`cexp test [target] [options]`) `.cex` code MUST strictly and exclusively execute using **at least version `^8` of `cexp` (`^8.0.0`, version 8 series: `>= 8.0.0`)** (resolved from `$CEX_ROOT/bin/8.0.0/cexp` or `$CXVM_DIR/versions/v8.0.0/bin/cexp`).
>     - If invoked via bootstrap dispatchers (`$CEX_ROOT/bin/cexp` or `cxvm`), it must automatically locate and delegate execution to an installed `^8` `cexp` binary (e.g. `v8.0.0` or `8.0.0`).
>     - All project manifests (`cex-pack.json`) specifying compiler requirements for compiling, building, or testing code must specify `"cexp": "^8"`.
> 2. **TESTING DISCIPLINE WITH ^8 AND LATEST `cex-test`**:
>     - Native test execution (`cexp test <file.test.cex>`, `cxvm test`) uses at least `^8` `cexp` integrated with the latest `cex-test` runtime (`1.0.12` / `1.0.13`).
>     - Full test pipeline runner (`--pipeline`, `--filter`), statement coverage reporting (`--coverage`), and decorator/component transpilation are executed under the `^8` toolchain.

---

## 1. Execution & Resolution Flow

1. **CLI Invocation**:
    - `cexp build <file.cex> -O3 -o <output>` (compiles with at least v8 cexp compiler)
    - `cexp compile <file.cex> -o <output>` (compiles with at least v8 cexp compiler)
    - `cexp test` (auto-discovers `test/all.test.cex`, `tests/all.test.cex`, or `scripts.test` target in `cex-pack.json`, executes with at least v8 cexp)
    - `cexp test <file.test.cex> [options]` (executes with at least v8 cexp)
2. **Compiler Binary Resolution (`^8` / `8.0.0`)**:
    - Resolves `$CEX_COMPILER_TARGET` (`$CEX_ROOT/bin/8.0.0/cexp`) for `{targetversion} ^8` (e.g. `8.0.0`).
    - Pre-flight syntax verification via `cex-lint` (`lintGate`) runs before compilation, build, and test execution.
3. **Rule Conformance**:
    - **Rule 29 (EOF Integrity)**: Every file must end with a single newline (`\n`).
    - **Rule 72 (Dynamic Paths)**: Resolve `$CEX_ROOT` and `$HOME` dynamically from environment or `.env.cex`.
    - **Rule (No Symbols)**: Pure ASCII output only.
