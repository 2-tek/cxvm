# Test Cases: Migrate with Last MVC-Lighting Version & Delete Deprecated Imports

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 44 (Explicit Types), RULE_BUILD_TESTS_BEFORE_FEATURE -->

## Test Matrix Overview

| Test ID | Test Target | Preconditions | Input / Operation | Expected Assertion | Boundary / Edge Cases |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-MIG-01** | `cex-pack.json` Dependency Matrix | Manifest exists | Read `cex-pack.json` and parse `dependencies` | `mvc-lighting` equals `"6.1.10"`; `cex-service` does NOT exist | Extra spaces, valid JSON syntax |
| **TC-MIG-02** | `CxvmEngine::resolveLibVersion` | `CxvmEngine` instance | `cxvm->resolveLibVersion("mvc-lighting")` & `("lighting")` | Both return `"6.1.10"` | Fallback when box is missing or version query changes |
| **TC-MIG-03** | Box Store Integrity | `cex_boxes/` exists | Check `cex_boxes/mvc-lighting` and `cex_boxes/cex-service` | `mvc-lighting/cex-pack.json` version is `"6.1.10"`; not a symlink; `cex_boxes/cex-service` is deleted | Conformance to `RULE_NO_SYMLINK_BETWEEN_BOXES` |
| **TC-MIG-04** | Deprecated Import Audit | Repository source & tests | Scan all `.cex` files in `src/` and `tests/` for deprecated `@cex-service` and `@cex-test` imports | Zero occurrences of `@cex-service` and `@cex-test` imports | Comments vs actual import statements |
| **TC-MIG-05** | Setup Runner Configuration | `setup.cex` exists | Check `SetupRunner::resolveVersion("mvc-lighting")` and dependency list | Resolves to `"6.1.10"`; `cex-service` removed from dependency queue | Default fallback behavior |
| **TC-MIG-06** | Full Suite Pass Rate | Toolchain runtime active | Run all test suites using `cext` | 100% tests pass, zero regressions | Exit code 0 across all 17 test suites |
