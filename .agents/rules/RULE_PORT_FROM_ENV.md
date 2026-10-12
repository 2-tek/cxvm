---
trigger: always_on
---

# Mandatory Rule: Dynamic Port Configuration via process.env | getenv() Inside ./src (RULE_PORT_FROM_ENV)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 82 (CXVM & Direct CexR), Rule 85 (Lint Gate) -->

> **MANDATORY DYNAMIC PORT LOADING VIA ENVIRONMENT VARIABLES**:
> In all `mvc-lighting`, `mvp-deepsea`, Cex microservices, repositories, packages, servers, controllers, kernels, and agent workflows:
>
> 1. **STRICT PROHIBITION OF HARDCODED PORTS IN `./src`**:
>     - Hardcoding network port numbers (e.g. `3000`, `8080`, `4055`, `3072`, `5000`, `80`, `443`, or arbitrary integer literals) directly inside `./src` source code without reading from the environment is **STRICTLY PROHIBITED**.
>     - Server instantiation (`new Server(...)`, `new LightingApp(...)`, `new DeepSeaKernel(...)`), socket binding (`socket->bind(...)`, `listen(...)`), and application start methods must NEVER accept raw fixed integer ports in production source files.
> 2. **MANDATORY DYNAMIC RESOLUTION FROM `process.env` OR `getenv()`**:
>     - All server, microservice, API, and gateway ports in `./src` MUST be resolved dynamically from environment variables:
>         - **In Cex / Native C++ Runtimes**: Load via `getenv("PORT")` (or `getenv("SERVER_PORT")`, `getenv("APP_PORT")`, `std::getenv("PORT")`):
>             ```cex
>             let portEnv: char* = getenv("PORT");
>             let port: int = (portEnv != nullptr && string(portEnv).length() > 0) ? atoi(portEnv) : 3000;
>             ```
>         - **In JavaScript / TypeScript / Node.js Contexts**: Load via `process.env`:
>             ```javascript
>             const port = parseInt(
>                 process.env.PORT || process.env.SERVER_PORT || "3000",
>                 10,
>             );
>             ```
> 3. **DEFAULT / FALLBACK PORT DISCIPLINE**:
>     - If the environment variable is unset, empty, or invalid, the code MUST supply a deterministic fallback default port (e.g. default `3000`, `4055`, etc.).
>     - Fallbacks must only activate after evaluating `getenv()` or `process.env`.
> 4. **ARCHITECTURAL & CONTAINER INVARIANTS**:
>     - **Thunder & Container Orchestration**: Thunder daemon, Docker containers, Kubernetes pods, and edge reverse-proxies inject dynamic `$PORT` environment variables upon runtime scheduling. Hardcoded ports break multi-tenant container placement and trigger port collision (`EADDRINUSE`) faults.
>     - **12-Factor App Compliance**: Operating environment variables must remain the single source of truth for runtime network bindings.
> 5. **TEST SUITE EXCLUSION (`./test` or `./tests`)**:
>     - The prohibition applies strictly to production server code inside `./src` (and `./bin`, `./builder`).
>     - Test suites located in `./test` or `./tests` may supply explicit mock, ephemeral, or isolated port numbers (e.g. `8999`, `0`) to isolate integration test harnesses from ambient production environment configurations.
> 6. **TASK TRACKING & REFACTORING DISCIPLINE VIA `.agents/features`**:
>     - Whenever hardcoded port literals are identified in `./src`, the agent/developer MUST immediately record a task in `.agents/features/{DD-MM-YYYY}.md`:
>       `- [ ] refactor(port): load PORT from process.env / getenv() in <src-path>`
>     - Refactor the affected file to resolve port through `getenv("PORT")` / `process.env.PORT` with fallback.
>     - Verify zero lint errors (`cxvm lint`) and 100% test pass rate (`cxvm test`).
>     - Mark the task completed:
>       `- [x] refactor(port): load PORT from process.env / getenv() in <src-path>`
