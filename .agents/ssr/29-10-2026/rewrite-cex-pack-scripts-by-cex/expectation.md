# Expectation Criteria: Rewrite scripts in cex-pack.json to Invoke Native .cex Toolchains

**Target**: `cex-pack.json` & `tests/scripts.test.cex`  
**Status**: SPECIFIED  

---

## 1. Expected Behaviors & Contracts

1. **`cex-pack.json` Script Mapping Contract**:
   ```json
   "scripts": {
       "install": "cex-pack downloads",
       "downloads": "cex-pack downloads",
       "dev": "cexr-factory src/index.cex",
       "start": "cexr-bean src/index.cex",
       "build": "cexp-v8-stable build src/index.cex -o .bin",
       "lint": "cex-lint fix .",
       "test": "cext tests/install.test.cex"
   }
   ```
2. **Behavior Verification**:
   - `scripts.build`: Calls `cexp-v8-stable` to build native binary directly to `.bin` per `RULE_BUILD_TO_BIN_BEFORE_COMMIT_AND_PUSH`.
   - `scripts.dev`: Runs application entry `src/index.cex` directly in Factory runtime (`cexr-factory`).
   - `scripts.start`: Runs application entry `src/index.cex` in Bean runtime (`cexr-bean`).
   - `scripts.test`: Directly invokes `cext` on `tests/install.test.cex`.
   - `scripts.lint`: Directly invokes `cex-lint fix .`.
   - `scripts.install` & `scripts.downloads`: Directly invokes `cex-pack downloads`.
3. **Purity Contract**:
   - Zero occurrences of `cxvm --app` in `scripts`.
   - Formatting preserves valid JSON with 4-space indentation per project standards.
4. **Pass Criteria (Green Phase)**:
   - 100% pass rate in `tests/scripts.test.cex`.
   - Zero test failures, zero regressions across test runners.
