---
trigger: always_on
---

# Mandatory Rule: No Hardcoded Values — Load Paths and Configuration from .env (RULE_NO_HARDCODE_PATH_FROM_ENV)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 82 (CXVM & Direct cexp), Rule 85 (Lint Gate) -->

> **MANDATORY ZERO-HARDCODE & .ENV PATH LOADING DIRECTIVE**:
> In all `mvc-lighting`, `mvp-deepsea`, Cex microservices, repositories, packages, servers, controllers, kernels, CLI tools, and agent workflows:
>
> 1. **STRICT PROHIBITION OF HARDCODED VALUES & PATHS IN SOURCE CODE**:
>     - Do NOT hardcode filesystem paths, storage directories, database file paths, asset directories, workspace paths, log paths, socket paths, certificate paths, or external URLs/endpoints directly inside source files (`./src`, `./bin`, `./builder`, controllers, models, services, presenters, kernels).
>     - Hardcoded absolute paths (e.g. `/home/user/...`, `/var/...`, `/tmp/...`, `/opt/...`, `C:\Users\...`) or hardcoded environment-specific paths in production logic are **STRICTLY PROHIBITED**.
> 2. **MANDATORY DYNAMIC PATH RESOLUTION FROM `.env`**:
>     - Whenever any file path, directory path, or external resource location is used, it MUST be configured in `.env` and dynamically loaded at runtime via `@cex-env` (`EnvLoader` / `CexEnv`), `getenv()`, or `process.env`:
>         - **In Cex (`@cex-env` / `EnvLoader` / `CexEnv`)**:
>             ```cex
>             import "@cex-env/src/env_loader.cex";
>
>             let dataDir: string = CexEnv::loadString("DATA_DIR", "./data");
>             let dbPath: string = CexEnv::loadString("DB_PATH", "./data/app.db");
>             let uploadDir: string = EnvLoader::loadString("UPLOAD_DIR", "./public/uploads");
>             ```
>         - **In Cex / Native C++ Runtimes via `getenv()`**:
>             ```cex
>             let pathEnv: char* = getenv("STORAGE_PATH");
>             let storagePath: string = (pathEnv != nullptr && string(pathEnv).length() > 0) ? string(pathEnv) : "./storage";
>             ```
>         - **In JavaScript / TypeScript / Node.js Contexts**:
>             ```javascript
>             const storagePath = process.env.STORAGE_PATH || "./storage";
>             ```
> 3. **`.env` CONFIGURATION & RELATIVE FALLBACK DISCIPLINE**:
>     - Every configurable path (e.g. `DB_PATH`, `DATA_DIR`, `STORAGE_PATH`, `LOG_DIR`, `PUBLIC_DIR`, `UPLOAD_DIR`, `CACHE_DIR`, `CONFIG_PATH`, `CERTS_DIR`, `WORKSPACE_DIR`, `STATIC_PATH`) MUST be resolved from `.env` first before falling back to a safe relative default.
>     - Fallbacks must only activate when the `.env` entry and environment variable are unset or empty, and must strictly be relative to the project root or current working directory (never hardcoded machine-specific absolute paths).
> 4. **PROHIBITION OF OTHER HARDCODED RUNTIME CONSTANTS**:
>     - In addition to filesystem paths, never hardcode ports (`PORT`), hostnames (`HOST`), database connection strings (`DB_URL`), credentials/secrets (`JWT_SECRET`, `API_KEY`), or upstream service URLs (`SSO_URL`, `REMOTE_URL`). All runtime parameters must be loaded from `.env`.
> 5. **TEST SUITE ISOLATION (`./test` or `./tests`)**:
>     - Test suites located in `./test` or `./tests` may override `.env` path variables or supply isolated test-specific relative paths so that production directories and databases remain untouched during testing.
> 6. **TASK TRACKING & REFACTORING DISCIPLINE VIA `.agents/features`**:
>     - Whenever hardcoded paths or configuration literals are identified in `./src`, the agent/developer MUST immediately record a task in `.agents/features/{DD-MM-YYYY}.md`:
>       `- [ ] refactor(env): replace hardcoded path/value with .env loader in <src-path>`
>     - Refactor the affected file to load the path from `.env` via `CexEnv::loadString(...)` / `EnvLoader::loadString(...)` / `getenv(...)`.
>     - Verify zero lint errors (`cxvm lint`) and 100% test pass rate (`cxvm test`).
>     - Mark the task completed:
>       `- [x] refactor(env): replace hardcoded path/value with .env loader in <src-path>`
