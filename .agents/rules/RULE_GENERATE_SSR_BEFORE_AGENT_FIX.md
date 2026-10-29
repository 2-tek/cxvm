# Mandatory Rule: Generate Software Specification Report (SSR) and Unit Testcases Into .agents/ssr/{DD-MM-YYYY}/{task_name}/ Before Starting Fixes or Feature Development (RULE_GENERATE_SSR_BEFORE_AGENT_FIX)
<!-- Extends: documents/rules/.agents/RULE_GENERATE_SSR_BEFORE_AGENT_FIX.md -->

<!-- Canonical Base Standard: agent-rules-integrated -->

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), RULE_CVM_AGENT_VCS, RULE_FETCH_CVM_BEFORE_GENERATE_TASKS, RULE_BUILD_TESTS_BEFORE_FEATURE, RULE_BUILD_TO_BIN_BEFORE_COMMIT_AND_PUSH, RULE_NO_HARD_EDIT_TO_CODE -->

> **MANDATORY DIRECTIVE: GENERATE SSR AND UNIT TESTCASES BEFORE WRITING CODE**:
> Across all `compilers/`, `frameworks/`, `projects/`, `runtimes/`, `models/`, `cxvm`, `cext`, `documents`, ecosystem box packages, repositories, and autonomous AI agent workflows:
>
> 1. **MANDATORY PRE-FIX & PRE-DEVELOPMENT SSR & TESTCASE GATE**:
>    - **BEFORE** an AI agent, runner, or developer begins writing code, modifying existing modules, debugging, or applying fixes for any feature request or bug report:
>      - The agent MUST ALWAYS author a comprehensive **Software Specification Report (`ssr.md`)** and **Unit Testcases (`testcases.md`)** along with expectations into `.agents/ssr/{DD-MM-YYYY}/{task_name}/`.
>      - Modifying source code, creating implementation files, or patching defects without active, validated SSR and testcase documents in `.agents/ssr/{DD-MM-YYYY}/{task_name}/` is **STRICTLY PROHIBITED**.
>    - **Rationale**: Generating SSR and testcases before writing code ensures architectural rigor, formalizes functional requirements, uncovers root causes before editing code, eliminates hasty and brittle workarounds, and enforces test-driven development (TDD) discipline.
>
> 2. **CANONICAL STORAGE LOCATION & TASK-SCOPED QUADRUPLE ARTIFACT**:
>    - All task specification documents MUST reside in task-dedicated directories:
>      ```
>      {projectRoot}/.agents/ssr/{DD-MM-YYYY}/{task_name}/
>      ```
>      (or the workspace root `.agents/ssr/{DD-MM-YYYY}/{task_name}/`).
>    - The legacy single daily file (`.agents/ssr/{DD-MM-YYYY}.md`) is formally broken down into four task-scoped markdown documents:
>      1. **`ssr.md`**: Software Specification Report (teleological rationale, functional requirements, architectural scope, technical design, invariants).
>      2. **`testcases.md`**: Test cases and unit test matrix generated *before* code implementation (inputs, expected assertions, boundaries, edge cases, mapping to `test/*.test.cex`).
>      3. **`expectation.md`**: Formal specification of expected runtime behavior, API contracts, boundary criteria, and pass conditions.
>      4. **`result.md`**: Execution logs, compiler diagnostics, unit test traces, pass/fail status, and final verification metrics.
>    - **Bidirectional Task Linkage**:
>      Every task checkbox in `.agents/features/{DD-MM-YYYY}.md` MUST link to all four documents:
>      ```markdown
>      ## feat(<scope>): <feature title>
>      - [ ] feat(<scope>): <feature task description> ([SSR](.agents/ssr/{DD-MM-YYYY}/{task_name}/ssr.md), [Testcases](.agents/ssr/{DD-MM-YYYY}/{task_name}/testcases.md), [Expectation](.agents/ssr/{DD-MM-YYYY}/{task_name}/expectation.md), [Result](.agents/ssr/{DD-MM-YYYY}/{task_name}/result.md))
>      ```
>
> 3. **MANDATORY SSR SCHEMA (`ssr.md`)**:
>    Every `ssr.md` entry MUST contain the following structured sections:
>    - For New Features (`feat`):
>      - **1. Objective & Teleological Rationale (Why)**: Clear statement of the problem, user requirement, systemic justification, and expected impact.
>      - **2. Functional & Non-Functional Specifications (What)**: Detailed behavioral expectations, inputs, outputs, data models, API signatures, and boundary constraints.
>      - **3. Architectural Impact & Scope**: Exact list of files, directories, dependencies, and packages modified or created.
>      - **4. Technical Design & Implementation Details (How)**: Classes, methods, functions, data structures, and algorithms to implement, strictly adhering to `RULE_NO_HARD_EDIT_TO_CODE` and `RULE_STANDARDS`.
>      - **5. Ecosystem Invariants Verification**: Checkpoints verifying Rule 29 (single newline EOF), Rule 69 (target runtime), Rule 72 (dynamic paths from env), and pure ASCII output.
>    - For Defects & Bugs (`bug` / `fix`):
>      - **1. Defect Description & Observed Symptoms**: Detailed symptoms, observed vs expected behavior, failure error logs, and exit codes.
>      - **2. Minimal Reproduction Steps & Test Case**: Deterministic steps, CLI commands, or minimal reproduction code.
>      - **3. Root Cause Analysis (RCA)**: Deep forensic inspection pinpointing exact files, line numbers, and logic/type/syntax flaws triggering the bug.
>      - **4. Scope of Impact**: Upstream and downstream modules, services, or callers affected.
>      - **5. Proposed Remediation Strategy**: Generic, systematic, data-driven solution eliminating the root cause without hardcoded branch shortcuts or magic conditions (`RULE_NO_HARD_EDIT_TO_CODE`).
>      - **6. Regression Testing Plan**: Strategy ensuring reproduction test passes post-fix and legacy test suites remain 100% green.
>
> 4. **MANDATORY TESTCASES SCHEMA (`testcases.md` & `expectation.md`)**:
>    - **`testcases.md`**: Matrix defining Test ID, category (Positive, Negative, Boundary, Edge Case), preconditions, test inputs, expected assertions, and target test file (`test/*.test.cex`). Must be authored before source code.
>    - **`expectation.md`**: Defines behavioral specifications, contracts, and criteria for 100% pass rate.
>
> 5. **INTEGRATED AGENT EXECUTION PIPELINE**:
>    The complete lifecycle for processing user requests proceeds strictly through these phases:
>    - **Phase 1 (Sync)**: Run `cvm fetch origin` (or `cvm pull origin <branch>`) per `RULE_FETCH_CVM_BEFORE_GENERATE_TASKS`.
>    - **Phase 2 (Feature / Bug Ingestion)**: Scan `.agents/features/{DD-MM-YYYY}.md` (prioritizing current date) and append task checkbox with links to SSR, Testcases, Expectation, and Result.
>    - **Phase 3 (SSR Authoring - MANDATORY GATE)**: Author `ssr.md` in `.agents/ssr/{DD-MM-YYYY}/{task_name}/ssr.md` before touching any code.
>    - **Phase 4 (Unit Testcase & Expectation Generation - MANDATORY PRE-CODE GATE)**:
>      - Conforming to `RULE_BUILD_TESTS_BEFORE_FEATURE`, author `testcases.md` and `expectation.md` in `.agents/ssr/{DD-MM-YYYY}/{task_name}/`.
>      - Author executable unit test files in `test/*.test.cex` (or `tests/*.test.cex`).
>      - Run tests (`cxvm test` or `cext`) to verify baseline / failing state (Red phase) before writing code.
>    - **Phase 5 (Implementation & Build Gate)**: Implement source code to satisfy testcases (Green phase). Compile entrypoint to `{rootProjectPath}/.bin` using `cexp-v8-stable` per `RULE_BUILD_TO_BIN_BEFORE_COMMIT_AND_PUSH`.
>    - **Phase 6 (Execution Logging & Verification)**: Run full test suite (`cxvm test` -> 100% pass). Record execution traces, exit codes, and assertion metrics into `result.md`. Mark task checkbox completed `[x]` in `.agents/features/{DD-MM-YYYY}.md`.
>    - **Phase 7 (Stage, Commit & Push)**: Stage via `cvm add .`, commit via `cvm commit`, and push via `cvm push origin <branch>` (with Git fallback per `RULE_CVM_AGENT_VCS`).
>
> 6. **AUDIT & ENFORCEMENT**:
>    - AI agents, reviewers, and automated runners MUST verify that `ssr.md`, `testcases.md`, and `expectation.md` exist in `.agents/ssr/{DD-MM-YYYY}/{task_name}/` before source code changes are accepted.
>    - If any agent begins modifying code without generating SSR and testcases first, the agent must immediately halt, revert unverified edits, author the artifacts, and resume execution.
