# Expectation Criteria: Migrate with Last MVC-Lighting Version & Delete Deprecated Imports

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 44 (Explicit Types), RULE_BUILD_TESTS_BEFORE_FEATURE -->

## 1. Expected Behaviors & Contracts

1. **Manifest Dependency Contract**:
   - `cex-pack.json` specifies `"mvc-lighting": "6.1.10"` under `dependencies`.
   - Deprecated `"cex-service"` is completely absent from `dependencies`.
   - Manifest remains valid JSON conforming to all schema requirements.

2. **Engine Version Resolution Contract**:
   - `cxvm->resolveLibVersion("mvc-lighting")` returns `"6.1.10"`.
   - `cxvm->resolveLibVersion("lighting")` returns `"6.1.10"`.
   - `cxvm->setupDeps()` queues `mvc-lighting` and no longer requests `cex-service`.

3. **Box Package Storage Contract**:
   - `cex_boxes/mvc-lighting` exists as a real directory (not a symlink, satisfying `RULE_NO_SYMLINK_BETWEEN_BOXES`).
   - `cex_boxes/mvc-lighting/cex-pack.json` specifies version `"6.1.10"`.
   - `cex_boxes/cex-service` is deleted.

4. **Zero Deprecated Imports Contract**:
   - All tests in `tests/` (`tests/install.test.cex`, `tests/scripts.test.cex`, etc.) import from canonical `@cext/src/assert.cex` and `@cext/src/runner.cex`.
   - No `.cex` file in `src/` or `tests/` imports from `@cex-service` or `@cex-test`.

5. **Compiler & Quality Gates**:
   - Static compilation succeeds: `cexp-v8-stable build src/index.cex -o .bin` exit code 0.
   - 100% test pass rate across all suites via `cext`.
