# Mandatory Rule: Build and Run Tests Before Updating or Creating Features (RULE_BUILD_TESTS_BEFORE_FEATURE)
<!-- Extends: documents/rules/.agents/RULE_BUILD_TESTS_BEFORE_FEATURE.md -->

<!-- Canonical Base Standard: agent-rules-integrated -->

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), RULE_CEX_SCRIPT_ONLY, RULE_GENERATE_SSR_BEFORE_AGENT_FIX, RULE_AUTO_BUILD_ENVIRONMENT_ON_PUSH_CXVM -->

> **MANDATORY DIRECTIVE: ALWAYS BUILD AND RUN TESTS BEFORE UPDATING OR CREATING ANY FEATURE**:
> In all `compilers/`, `frameworks/`, `projects/`, `runtimes/`, `models/`, `cxvm`, `cext`, `documents`, ecosystem box packages, and developer/AI agent workflows:
>
> 1. **PRE-FLIGHT BASELINE BUILD, SSR GENERATION & TEST VERIFICATION**:
>    - **BEFORE** writing any code, modifying existing modules, or creating/updating feature tasks in `.agents/features/{DD-MM-YYYY}.md`:
>      - The developer or AI agent MUST author and save `ssr.md` into `.agents/ssr/{DD-MM-YYYY}/{task_name}/ssr.md` per `RULE_GENERATE_SSR_BEFORE_AGENT_FIX`.
>      - The developer or AI agent MUST compile the current project and execute the complete existing test suite:
>        ```bash
>        cxvm test
>        ```
>        (or project-specific test runners: `cext test/<suite>.test.cex`, `lighting test test/<suite>.test.cex`).
>    - **Zero Tolerated Baseline Breakages**: If the existing build fails or any existing test fails, the codebase is in a degraded baseline state. The developer or agent MUST NOT introduce new features or update features on top of a failing baseline. The baseline failures must be investigated, resolved, and verified (100% pass rate) before new feature work begins.
>
> 2. **SPECIFICATION BY BUILD TEST & TESTCASE GENERATION (TEST-FIRST DISCIPLINE)**:
>    - Based on the functional requirements defined in `ssr.md`, the developer or agent MUST author:
>      1. **`testcases.md`**: In `.agents/ssr/{DD-MM-YYYY}/{task_name}/testcases.md`, defining test matrix, preconditions, inputs, edge/boundary cases, and assertions.
>      2. **`expectation.md`**: In `.agents/ssr/{DD-MM-YYYY}/{task_name}/expectation.md`, defining expected behaviors, contracts, and pass thresholds.
>      3. **Executable Unit Tests**: In `test/*.test.cex` (or `tests/*.test.cex`).
>    - The test cases must explicitly define and assert:
>      - Expected functional behavior, return values, and data structures.
>      - Architectural constraints and contract invariants.
>      - Edge cases, error handling, and memory cleanup behavior.
>    - **Red Phase Verification**: Execute the newly authored test to verify the initial failing/baseline state before writing code.
>
> 3. **BUILD & VERIFY TEST LOOP (GREEN PHASE)**:
>    - Implement or update the feature source code to satisfy the test specifications.
>    - Execute the project compiler build to ensure static invariants, types, and imports compile cleanly:
>      ```bash
>      cxvm build
>      ```
>      (or `cexp-v8-stable build src/index.cex -o .bin`, `lighting build`).
>    - Execute the full test suite again to verify that:
>      1. The newly created or updated feature tests pass.
>      2. All legacy test suites continue to pass with zero regressions (100% pass rate).
>    - Log forensic execution details, output logs, and assertion metrics into `.agents/ssr/{DD-MM-YYYY}/{task_name}/result.md`.
>
> 4. **MANDATORY LOGGING IN `.agents/features/{DD-MM-YYYY}.md` & 4-ARTIFACT LINKAGE**:
>    - Every feature entry in `.agents/features/{DD-MM-YYYY}.md` MUST link to the task-scoped artifacts:
>      ```markdown
>      ## feat(<scope>): <feature title>
>      - [ ] feat(<scope>): implement <feature details> ([SSR](.agents/ssr/{DD-MM-YYYY}/{task_name}/ssr.md), [Testcases](.agents/ssr/{DD-MM-YYYY}/{task_name}/testcases.md), [Expectation](.agents/ssr/{DD-MM-YYYY}/{task_name}/expectation.md), [Result](.agents/ssr/{DD-MM-YYYY}/{task_name}/result.md))
>        - [ ] test(<scope>): author testcases and unit tests asserting expected behavior
>        - [ ] feat(<scope>): implement source logic
>        - [ ] test(verify): compile and verify 100% test pass rate across all suites
>      ```
>    - A feature task may ONLY be marked as completed (`[x]`) after the build succeeds, tests pass with 100% success rate, and `result.md` is populated.
>
> 5. **COMMIT & PUSH GATE INTEGRATION**:
>    - Conforming to `RULE_AUTO_BUILD_ENVIRONMENT_ON_PUSH_CXVM` and `RULE_PROJECT_CHECKLIST`:
>      - No commit (`cvm commit`) or push (`cvm push`) is allowed without running tests and achieving 100% pass rate.
>      - The test verification pipeline prevents broken features from entering version history or remote repositories.
