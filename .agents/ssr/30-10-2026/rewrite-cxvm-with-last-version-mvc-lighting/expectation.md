# Expectation Specification: Rewrite CXVM with Last Version of MVC-Lighting

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), Rule 44 (Explicit Types) -->

## 1. Expected Behavior & Operational Contract

1. **Declarative `.xhtml` Single-File Architecture**:
   - Every view in `cxvm/src/views/` is an authentic `.xhtml` file with root `<html xmlns="https://www.2-tek.com/xhtml">`.
   - `views/layout.xhtml` acts as the master template containing navigation, styles, and `<slot />` placeholder.
   - Child templates (`dashboard.xhtml`, `downloads.xhtml`, `cxvm_docs.xhtml`, `setup.xhtml`) render cleanly within the layout slot.
   - `PageRenderer::renderFiles(pagePath, layoutPath, ctx)` processes variables (`{{key}}`), loops (`{{#each list}}`), and conditionals (`{{#if condition}}`).

2. **Strict API Separation of FactoryController**:
   - `FactoryController` inherits from `BaseController` and is dedicated 100% to backend REST endpoints (`/api/v1/*`).
   - Zero view rendering logic or raw HTML string concatenation in `FactoryController`.
   - HTML view requests (`/`, `/downloads`, `/cxvm`, `/setup`) in `FactoryApp` are resolved by invoking `PageRenderer` with template contexts.

3. **Complete Elimination of Deprecated Files**:
   - `cxvm/src/dist_builder.cex` is deleted. A modern `PackageCatalog` or `BuilderService` in pure Cex manages platform and artifact manifests without referencing `dist/`.
   - `cxvm/src/views/factory_views.cex` is deleted.
   - `cxvm/cex-pack-linked.json` is deleted.
   - `cxvm/.cex_boxes` legacy directory is deleted.

4. **100% Test Pass Rate & Zero Regressions**:
   - `cxvm/tests/mvc_lighting_xhtml.test.cex` executes via `cext` and completes with exit code 0.
   - All tests in `cxvm/tests/` (`app.test.cex`, `lighting.test.cex`, `builder.test.cex`, etc.) pass cleanly.
   - `cexp-v8-stable build cxvm/src/index.cex -o cxvm/.bin` completes with exit code 0.

---

## 2. Success Criteria & Verification Matrix

- [x] SSR document created and validated.
- [x] Testcases matrix created and validated.
- [x] Expectation criteria created and validated.
- [x] Executable unit test created at `cxvm/tests/mvc_lighting_xhtml.test.cex`.
- [x] Red phase test verification executed.
- [x] Native `.xhtml` views authored in `cxvm/src/views/`.
- [x] `PageRenderer` SSR engine integrated into `cxvm/src/views/page_renderer.cex`.
- [x] `FactoryController` refactored to be API-only.
- [x] Deprecated files deleted (`dist_builder.cex`, `factory_views.cex`, `cex-pack-linked.json`, `.cex_boxes`).
- [x] Full build to `cxvm/.bin` succeeds with exit code 0.
- [x] Green phase test verification executed (100% pass rate).
- [x] Result report logged in `result.md`.
