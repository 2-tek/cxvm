# Test Specification: Rewrite scripts in cex-pack.json to Invoke Native .cex Toolchains

**Test Suite**: `tests/scripts.test.cex`  
**Target File**: `cex-pack.json`  
**Conformance**: `RULE_BUILD_TESTS_BEFORE_FEATURE`, `RULE_CEX_SCRIPT_ONLY`

---

## 1. Test Matrix

| Test ID | Test Category | Preconditions | Inputs / Target | Expected Assertions |
| :--- | :--- | :--- | :--- | :--- |
| `TC-SCRIPTS-01` | Manifest Presence | `cex-pack.json` exists | `fs.readFile("cex-pack.json")` | File exists and content length > 0 |
| `TC-SCRIPTS-02` | Build Script | `cex-pack.json` | `scripts.build` | Exactly `"cexp-v8-stable build src/index.cex -o .bin"` |
| `TC-SCRIPTS-03` | Dev Script | `cex-pack.json` | `scripts.dev` | Exactly `"cexr-factory src/index.cex"` |
| `TC-SCRIPTS-04` | Start Script | `cex-pack.json` | `scripts.start` | Exactly `"cexr-bean src/index.cex"` |
| `TC-SCRIPTS-05` | Test Script | `cex-pack.json` | `scripts.test` | Starts with `"cext "` and contains `"tests/install.test.cex"` |
| `TC-SCRIPTS-06` | Lint Script | `cex-pack.json` | `scripts.lint` | Exactly `"cex-lint fix ."` |
| `TC-SCRIPTS-07` | Downloads Script | `cex-pack.json` | `scripts.downloads` | Exactly `"cex-pack downloads"` |
| `TC-SCRIPTS-08` | Install Script | `cex-pack.json` | `scripts.install` | Exactly `"cex-pack downloads"` |
| `TC-SCRIPTS-09` | No Legacy Wrapper | `cex-pack.json` | `scripts` block | Zero occurrences of `"cxvm --app"` across all scripts |

---

## 2. Red Phase Verification Plan

- Execute `tests/scripts.test.cex` against the current un-refactored `cex-pack.json`.
- The assertions checking for native commands (`cexp-v8-stable`, `cexr-factory`, `cexr-bean`, `cext`, `cex-lint`) and checking for absence of `cxvm --app` MUST fail (Red Phase).
- Only after failing state is confirmed shall `cex-pack.json` be updated.
