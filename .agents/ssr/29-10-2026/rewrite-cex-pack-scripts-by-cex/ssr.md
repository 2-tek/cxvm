# Software Specification Report (SSR): Rewrite scripts in cex-pack.json to Invoke Native .cex Toolchains

**SSR ID**: `SSR-20261029-CXVM-SCRIPTS-01`  
**Date**: 29-10-2026  
**Status**: DRAFT  
**Target Project**: `cxvm` (`@2tek/cxvm`)  
**Conformance**: `RULE_GENERATE_SSR_BEFORE_AGENT_FIX`, `RULE_BUILD_TESTS_BEFORE_FEATURE`, `RULE_CEX_SCRIPT_ONLY`, `RULE_BUILD_TO_BIN_BEFORE_COMMIT_AND_PUSH`

---

## 1. Objective

Refactor the `"scripts"` declaration block in `cex-pack.json` of `@2tek/cxvm` from indirect `cxvm --app` dispatches to direct native `.cex` toolchains (`cexp-v8-stable`, `cexr-factory`, `cexr-bean`, `cext`, `cex-lint`, `cex-pack`). This enforces `RULE_CEX_SCRIPT_ONLY`, streamlines build and test execution pipelines, and eliminates redundant process hopping layers.

---

## 2. Requirements & Scope

1. **Manifest Scripts Alignment**:
   - In `cex-pack.json`:
     - `"build"`: Direct machine compilation to project `.bin`: `"cexp-v8-stable build src/index.cex -o .bin"`
     - `"dev"`: Direct native execution via Factory runtime: `"cexr-factory src/index.cex"`
     - `"start"`: Direct native execution via Bean runtime: `"cexr-bean src/index.cex"`
     - `"test"`: Direct test execution via CexT: `"cext tests/install.test.cex"`
     - `"lint"`: Direct lint execution via CexLint: `"cex-lint fix ."`
     - `"downloads"`: Direct dependency download via CexPack: `"cex-pack downloads"`
     - `"install"`: Direct dependency installation via CexPack: `"cex-pack downloads"`
2. **Purge Indirect Wrappers**:
   - Eliminate all references to `cxvm --app` inside `cex-pack.json` `scripts`.
3. **Unit Test Creation Prior to Code Changes**:
   - Author `tests/scripts.test.cex` asserting that each script entry exists and conforms to native `.cex` toolchain execution rules without legacy `cxvm --app` wrappers.
4. **Zero Tolerated Regressions**:
   - Verify that all scripts and test suites pass 100%.

---

## 3. Architectural Impact

- **Direct Execution**: Calling `cexp-v8-stable`, `cexr-factory`, `cexr-bean`, `cext`, and `cex-lint` directly avoids spawning an intermediate `cxvm` CLI dispatcher process which previously resolved `--app <target>` before forwarding arguments.
- **Specification Compliance**: Fully aligns `cxvm` with other ecosystem repositories (`documents`, `code-storm`, `mvc-lighting`, `cex-pack`) that use direct toolchain commands in `cex-pack.json`.

---

## 4. Technical Design & Invariants

### 4.1 Invariants
- **Invariant 1 (`RULE_CEX_SCRIPT_ONLY`)**: All build and runner targets must be native Cex toolchain binaries or `.cex` source files.
- **Invariant 2 (`RULE_BUILD_TO_BIN_BEFORE_COMMIT_AND_PUSH`)**: The `build` script must compile to `{rootProjectPath}/.bin`.
- **Invariant 3 (`RULE_NO_INDIRECT_WRAPPER`)**: Scripts must invoke canonical toolchain binaries directly instead of wrapping through `cxvm --app`.

### 4.2 Script Mapping Specification

| Script Key | Legacy Value | New Native Value |
| :--- | :--- | :--- |
| `build` | `cxvm --app cexr-bean src/index.cex` | `cexp-v8-stable build src/index.cex -o .bin` |
| `dev` | `cxvm --app cexr-factory src/index.cex` | `cexr-factory src/index.cex` |
| `start` | `cxvm --app cexr-bean src/index.cex` | `cexr-bean src/index.cex` |
| `test` | `cxvm --app cext run tests/install.test.cex` | `cext tests/install.test.cex` |
| `lint` | `cxvm --app cex-lint fix .` | `cex-lint fix .` |
| `downloads` | `cex-pack downloads` | `cex-pack downloads` |
| `install` | `cex-pack downloads` | `cex-pack downloads` |
