# Test Cases Matrix: Rewrite CXVM with Last Version of MVC-Lighting

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), Rule 44 (Explicit Types) -->

## 1. Test Matrix Overview

| Test ID | Objective | Preconditions | Inputs / Actions | Expected Assertions | Boundary / Edge Cases |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-CXVM-01** | Verify `.xhtml` Template Files Exist | Views directory created | Check existence of `layout.xhtml`, `dashboard.xhtml`, `downloads.xhtml`, `cxvm_docs.xhtml`, `setup.xhtml` | All files exist and declare 2-TEK XHTML namespace | Missing template file or incorrect namespace |
| **TC-CXVM-02** | Verify `.xhtml` Rendering via PageRenderer | Application initialized | `app->simulateRequest("GET", "/", "", "text/html")` | Status 200, HTML contains valid rendered slots, title, and dynamic active version | Empty template context or slot injection failure |
| **TC-CXVM-03** | Verify All Views Accessible | Web server running | Query `GET /downloads`, `GET /cxvm`, `GET /setup` | Status 200 for all views, correct view content loaded | 404 handler fallback or missing route |
| **TC-CXVM-04** | Verify FactoryController API Only | Controller instantiated | Check methods on `FactoryController` | Controller does not implement HTML returning methods; returns JSON for `/api/v1/*` | Accidental leak of HTML string generation into API controller |
| **TC-CXVM-05** | Verify Deprecated Files Purged | Clean codebase | Check filesystem for `dist_builder.cex`, `factory_views.cex`, `cex-pack-linked.json`, and `.cex_boxes` | Files and legacy directories must not exist | Stale leftover files remaining in git tree |
| **TC-CXVM-06** | Verify REST APIs Retained | FactoryApp started | `GET /api/v1/status`, `GET /api/v1/versions`, `GET /api/v1/platforms` | Status 200, valid JSON response with expected fields | Regression in existing REST API contract |

---

## 2. Execution Protocol

- **Executable Runner**: `cxvm/tests/mvc_lighting_xhtml.test.cex`
- **Compiler / Test Runner**: `cext`
- **Red Phase**: Initial test execution establishes baseline failing state prior to code migration.
- **Green Phase**: Post-migration execution confirms 100% assertions passed with zero errors.
