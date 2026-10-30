# Software Specification Report (SSR): Rewrite CXVM with Last Version of MVC-Lighting

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), Rule 44 (Explicit Types), RULE_BUILD_POSITION, RULE_NO_SYMLINK_BETWEEN_BOXES, RULE_NO_HARD_EDIT_TO_CODE -->

## 1. Objective

Upgrade the CXVM Application Kernel and Web Server to the latest architecture of **MVC-Lighting** (v6.1+):
1. **Adopt Native `.xhtml` Single-File Components & Views**: Migrate from legacy hardcoded Cex string concatenations in `factory_views.cex` to declarative, semantic `.xhtml` templates adhering to the canonical 2-TEK XHTML specification (`xmlns="https://www.2-tek.com/xhtml"`).
2. **Dedicated REST API Controllers**: Enforce strict separation of concerns where `FactoryController` inherits from `BaseController` and is used exclusively for RESTful JSON API operations (`/api/v1/...`). All HTML view serving is decoupled from API controller methods.
3. **Purge Deprecated Files**: Eliminate obsolete build artifacts and legacy files, specifically `src/dist_builder.cex` (in compliance with `RULE_BUILD_POSITION`), `src/views/factory_views.cex`, legacy `cex-pack-linked.json`, and unneeded `.cex_boxes` legacy directories.

- **Timestamp**: 2026-10-30T10:56:00+07:00
- **Scope**: `cxvm` (`src/app.cex`, `src/controllers/factory_controller.cex`, `src/views/`, `tests/`)
- **Target Framework**: `mvc-lighting` v6.1+ with native `.xhtml` rendering pipeline

---

## 2. Requirements & Scope

1. **Native `.xhtml` Template Engine Integration**:
   - Provide standard 2-TEK XHTML templates in `cxvm/src/views/`:
     - `views/layout.xhtml`: Root document layout containing `<slot />` or `<!-- REALITY_PAGE_SLOT -->`, standard headers, navigation, and theme styling.
     - `views/dashboard.xhtml`: Portal overview displaying active CXVM version, runtime statistics, system diagnostics, and quick start guides.
     - `views/downloads.xhtml`: Interactive catalog table of cross-platform runtime archives.
     - `views/cxvm_docs.xhtml`: Complete command reference and operational documentation for `cxvm`.
     - `views/setup.xhtml`: Diagnostic setup and configuration control panel.
   - Implement `PageRenderer` & `TemplateEngine` directly in `cxvm/src/views/page_renderer.cex` (mirroring `mvc-lighting`) to dynamically process conditionals (`{{#if ...}}`), loops (`{{#each ...}}`), and variable interpolation (`{{key}}`).

2. **Controller Dedicated Strictly to REST APIs**:
   - `FactoryController : BaseController` provides zero HTML-returning actions.
   - All controller endpoints return JSON payloads via `this->json(doc)` or serve raw installer downloads (`/install.sh`, `/setup.cex`).
   - Browser routes (`/`, `/downloads`, `/cxvm`, `/setup`) in `FactoryApp` are resolved directly by reading `.xhtml` views and passing context to `PageRenderer`.

3. **Elimination of Deprecated Files & Logic**:
   - Delete `cxvm/src/dist_builder.cex`: Replaced by dynamic platform and version catalogs that do not depend on legacy `dist/` positions.
   - Delete `cxvm/src/views/factory_views.cex`: Superseded by declarative `.xhtml` files.
   - Delete `cxvm/cex-pack-linked.json`: Deprecated v1.0.0 encrypted lockfile.
   - Delete legacy `cxvm/.cex_boxes` directory: Conforming to `RULE_NO_SYMLINK_BETWEEN_BOXES` and ecosystem cleanup.

4. **Backward Compatibility & Verification Gate**:
   - Preserve all existing REST API contracts (`/api/v1/status`, `/api/v1/versions`, `/api/v1/platforms`, `/api/v1/downloads`, `/api/v1/manifest`, `/api/v1/setup`, `/api/v1/build`, etc.).
   - Verify syntax via explicit types (`Rule 44`), single EOF newline (`Rule 29`), and dynamic path resolution (`Rule 72`).
   - Verify test suite passes 100% via `cext cxvm/tests/*.test.cex`.

---

## 3. Architectural Impact & Technical Design

### Class & Component Diagram:
```
+-------------------------------------------------------------+
| FactoryApp (src/app.cex)                                    |
| - router: LightingRouter                                     |
| - controller: FactoryController (APIs only)                 |
| - pageRenderer: PageRenderer (.xhtml SSR Engine)            |
+-------------------------------------------------------------+
          |                                  |
          | (REST APIs: /api/v1/*)           | (Views: /, /downloads, /cxvm, /setup)
          v                                  v
+------------------------------------+  +------------------------------------+
| FactoryController                  |  | PageRenderer & TemplateEngine     |
| (src/controllers/                  |  | (src/views/page_renderer.cex)      |
|  factory_controller.cex)           |  | - reads .xhtml template files      |
| - apiStatus()                      |  | - renders variables & loops        |
| - apiVersions()                    |  | - slots into views/layout.xhtml    |
| - apiPlatforms()                   |  +------------------------------------+
| - apiDownloads()                   |                   |
| - apiCvm*(), apiThunder*()         |                   v
+------------------------------------+  +------------------------------------+
                                        | Views (.xhtml):                    |
                                        | - layout.xhtml                     |
                                        | - dashboard.xhtml                  |
                                        | - downloads.xhtml                  |
                                        | - cxvm_docs.xhtml                  |
                                        | - setup.xhtml                      |
                                        +------------------------------------+
```

---

## 4. Invariants

- **RULE 29**: File ends with single newline.
- **RULE 72**: Dynamic path resolution (`$HOME`, `$CXVM_DIR`, environment variables, no hardcoded user paths).
- **RULE No Symbols**: Pure ASCII output only (`[OK]`, `[FAIL]`, zero decorative emojis).
- **RULE 44**: Explicit types throughout all classes, methods, and declarations.
- **RULE_BUILD_POSITION**: Zero output to `dist/`; clean output to `.bin`.
- **RULE_NO_SYMLINK_BETWEEN_BOXES**: Independent, real package directories inside `cex_boxes`.
- **RULE_NO_HARD_EDIT_TO_CODE**: Generalized parsing and template evaluation.
