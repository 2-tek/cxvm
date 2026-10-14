---
trigger: always_on
---

# Mandatory Rule: cexp Uses At Least Version ^8 for Compiling, Building, and Testing Code (RULE_CEXP_V8)

<!-- Standard Specification: .agents/rules/RULE_CEXP_TEST_V7.md -->
<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), Rule (Pure Language Compiler) -->

> **MANDATORY `cexp` VERSION AT LEAST ^8 FOR CODE COMPILATION, BUILDING & TESTING**:
> Whenever `cexp` (or `cex`) is invoked across any project or compiler tier in the Cex ecosystem:
>
> 1. **MINIMUM COMPILER VERSION >= ^8 FOR CODE COMPILATION, BUILDING & TESTING**:
>     - Handling code compilation (`cexp build`, `cexp compile`) and testing (`cexp test [target] [options]`, `cxvm test`) MUST execute strictly using **at least version `^8` of `cexp` (`>= 8.0.0` / `^8` / `8.0.0`)** (resolved from `$CEX_ROOT/bin/8.0.0/cexp` or `$CXVM_DIR/versions/v8.0.0/bin/cexp`).
>     - If invoked via bootstrap dispatchers (`$CEX_ROOT/bin/cexp` or `cxvm`), it must automatically locate and delegate execution to an installed `^8` `cexp` binary (e.g. `v8.0.0` or `8.0.0`).
> 2. **UPGRADE WITH LATEST `cex-test` & COMPONENT RUNTIME**:
>     - Test execution uses at least `^8` `cexp` integrated with the latest version of **`cex-test`** (`"cex-test": "1.0.12"` / `1.0.13`).
>     - `^8` provides native test execution (`cexp test <file.test.cex>`), reactive pipeline test runner (`--pipeline`, `--filter`), statement coverage collection/reporting (`--coverage`, `--out-dir`, `--lcov`, `--json`, `--html`, `--min`), and complete decorator / component transpilation.

---

## 1. Execution & Resolution Flow

1. **CLI Invocation**:
    - `cexp build <file.cex> -O3 -o <output>` (compiles with at least v8 cexp compiler)
    - `cexp compile <file.cex> -o <output>` (compiles with at least v8 cexp compiler)
    - `cexp test` (auto-discovers `test/all.test.cex`, `tests/all.test.cex`, or `scripts.test` target in `cex-pack.json`, executes with at least v8 cexp)
    - `cexp test <file.test.cex> [options]` (executes with at least v8 cexp)
2. **Compiler Binary Resolution**:
    - Compiling/Building/Testing: Resolves `$CEX_COMPILER_TARGET` (`$CEX_ROOT/bin/8.0.0/cexp`) for `{targetversion} ^8` (e.g. `8.0.0`).
    - Pre-flight syntax verification via `cex-lint` (`lintGate`) runs before test compilation and execution.
3. **Rule Conformance**:
    - **Rule 29 (EOF Integrity)**: Every file must end with a single newline (`\n`).
    - **Rule 72 (Dynamic Paths)**: Resolve `$CEX_ROOT` and `$HOME` dynamically from environment or `.env.cex`.
    - **Rule (No Symbols)**: Pure ASCII output only.
