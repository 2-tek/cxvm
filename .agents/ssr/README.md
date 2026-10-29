# Software Specification Reports (SSR) & Testcase Governance Directory

<!-- Standard Specification: .agents/rules/RULE_GENERATE_SSR_BEFORE_AGENT_FIX.md -->
<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols) -->

Welcome to the canonical repository of **Software Specification Reports (SSR)** and pre-code **Unit Testcases**.

## 1. Overview & Mandatory Requirement

Per **`RULE_GENERATE_SSR_BEFORE_AGENT_FIX`** and **`RULE_BUILD_TESTS_BEFORE_FEATURE`**, before any AI agent, automation runner, or developer begins modifying source code, debugging, or applying fixes for any feature request or bug report, they **MUST ALWAYS** generate the task-scoped quadruple artifact under `.agents/ssr/{DD-MM-YYYY}/{task_name}/`.

Modifying source code without active, validated SSR and unit testcases in this directory is strictly prohibited.

## 2. Directory Structure & Task-Scoped Quadruple Artifact

The legacy single daily file (`.agents/ssr/{DD-MM-YYYY}.md`) is broken down into modular, task-dedicated directories:

```
{projectRoot}/.agents/ssr/{DD-MM-YYYY}/{task_name}/
├── ssr.md           # Software Specification Report (Why, What, Scope, How, Invariants)
├── testcases.md     # Unit testcase matrix generated before code (Inputs, Assertions, Boundaries)
├── expectation.md   # Behavioral expectations, API contracts, 100% pass criteria
└── result.md        # Execution logs, compiler traces, test runner outputs, metrics
```

### Bidirectional Task Linkage
Every task in `.agents/features/{DD-MM-YYYY}.md` must link to all 4 documents:
```markdown
- [ ] feat(<scope>): <task_name> ([SSR](.agents/ssr/{DD-MM-YYYY}/{task_name}/ssr.md), [Testcases](.agents/ssr/{DD-MM-YYYY}/{task_name}/testcases.md), [Expectation](.agents/ssr/{DD-MM-YYYY}/{task_name}/expectation.md), [Result](.agents/ssr/{DD-MM-YYYY}/{task_name}/result.md))
```

---

## 3. Standard Artifact Templates

### Template 1: Software Specification Report (`ssr.md`)

```markdown
# SSR: feat(<scope>): <Title>

- **Date**: DD-MM-YYYY
- **Task Reference**: `.agents/features/{DD-MM-YYYY}.md`
- **Location**: `.agents/ssr/{DD-MM-YYYY}/{task_name}/ssr.md`
- **Status**: DRAFT | IN_PROGRESS | COMPLETED

### 1. Objective & Teleological Rationale (Why)
- Problem statement and user requirement.
- Systemic justification within the Cex / CXVM ecosystem.
- Expected impact on developers, users, or runtime performance.

### 2. Functional & Non-Functional Specifications (What)
- Expected functional behaviors, inputs, and outputs.
- Edge case handling, error boundaries, and performance invariants.
- API signatures, data schemas, or protocol contracts.

### 3. Architectural Impact & Scope
- List of exact files, directories, and modules modified or created.
- Dependency relationships (upstream libraries, downstream consumers).

### 4. Technical Design & Implementation Details (How)
- Classes, interfaces, functions, algorithms, and data structures.
- Strict adherence to `RULE_NO_HARD_EDIT_TO_CODE` (dynamic, generalized logic).
- Conformance to `RULE_STANDARDS` and explicit typing (Rule 44).

### 5. Ecosystem Invariants Verification
- Rule 29 (single newline EOF integrity): [YES/NO]
- Rule 69 ("target": "runtime"): [YES/NO]
- Rule 72 (dynamic paths from .env / getenv()): [YES/NO]
- Pure ASCII output (Rule No Symbols): [YES/NO]
```

### Template 2: Unit Testcases Matrix (`testcases.md`)

```markdown
# Testcases: feat(<scope>): <Title>

- **Date**: DD-MM-YYYY
- **Task Reference**: `.agents/features/{DD-MM-YYYY}.md`
- **SSR Reference**: `.agents/ssr/{DD-MM-YYYY}/{task_name}/ssr.md`
- **Target Test File**: `test/<suite>.test.cex`

### 1. Test Matrix

| Test ID | Category | Description | Preconditions | Inputs | Expected Assertions |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-01 | Positive | Nominal operation | System initialized | Valid payload | Returns exit code 0 |
| TC-02 | Boundary | Limit bounds check | Input at boundary | Limit values | Handles boundary cleanly |
| TC-03 | Negative | Invalid input error | Error state | Malformed input | Throws specific error |
| TC-04 | Regression| Legacy regression | Clean baseline | Existing suite | 100% pass across legacy tests |
```

### Template 3: Behavioral Expectations (`expectation.md`)

```markdown
# Expectation: feat(<scope>): <Title>

- **Date**: DD-MM-YYYY
- **Task Reference**: `.agents/features/{DD-MM-YYYY}.md`
- **SSR Reference**: `.agents/ssr/{DD-MM-YYYY}/{task_name}/ssr.md`

### 1. Expected Behaviors & Contracts
- Detailed specifications of expected outputs.
- Invariants and performance contracts.
- 100% test pass threshold.
```

### Template 4: Execution Results & Audit Log (`result.md`)

```markdown
# Result: feat(<scope>): <Title>

- **Date**: DD-MM-YYYY
- **Task Reference**: `.agents/features/{DD-MM-YYYY}.md`
- **Status**: RESOLVED | COMPLETED

### 1. Execution Trace
- Test suite execution output.
- Compilation status via `cexp-v8-stable`.
- Assertion count and pass rate (100%).
```
