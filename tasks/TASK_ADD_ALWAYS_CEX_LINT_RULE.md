# Automated Task Specification: Always Cex-Lint Rule in MVC & MVP Projects

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 80 (Root @), Rule 82 (CXVM & Direct CexR), Rule 85 (Lint Gate) -->

> **CANONICAL ALWAYS CEX-LINT RULE ENFORCEMENT DIRECTIVE**:
> In all `mvc-lighting`, `mvp-deepsea`, and Cex project workspaces:
> All projects must enforce the **Always Cex-Lint Rule** (`RULE_CEX_LINT.md` and `rule-cex-lint.md`) with frontmatter `trigger: always_on` inside `.agents/rules/`, and expose `"lint": "cxvm lint"` and `"lint:fix": "cxvm lint --fix"` in `cex-pack.json` scripts.

---

## 1. Task Objective & Architectural Rationale

1. **Active Rule Injection via Frontmatter**:
    - Standard markdown rules without frontmatter require explicit activation or manual trigger matching.
    - Injecting `trigger: always_on` guarantees that Antigravity loads and enforces the `RULE_CEX_LINT` gate continuously during any pair-programming session, file editing, and automated build dispatch.
2. **Mandatory Automatic Lint Gate**:
    - Zero-lint-error gate (`exit code 0`) before any compilation (`cxvm build`), test run (`cxvm test`), or commit/push (`cvm commit`, `cvm push`).
    - Automatically repairs code style violations using `cxvm lint --fix` (member access normalization `this.`, trailing whitespace cleanup, tab-to-spaces, semicolon enforcement, and single EOF newline).
3. **Multi-Project Coverage**:
    - Covers all fullstack MVC projects (`MVC-Lighting`, `cat-store`, `lighting-app-3055`, `mvclt/*`).
    - Covers all microservices & presenter gateways (`MVP-DeepSea`, `mvclt/IAM`).
    - Covers core toolchain and dependency packages (`cxvm`, `cexr`, `dependencies`).

---

## 2. Automated Task Runner: `task_add_always_cex_lint_rule.cex`

The task is implemented as a standalone, native `v8 cexr` task script:

- **Location**: [`tasks/task_add_always_cex_lint_rule.cex`](file:///home/viettd/Projects/tasks/task_add_always_cex_lint_rule.cex)
- **Engine**: Pure Cex native execution via `cexr` (no `run` subcommand).

### Task Operations:

- Traverses all MVC, MVP, and ecosystem projects.
- Audits `.agents/rules/RULE_CEX_LINT.md` and `.agents/rules/rule-cex-lint.md`.
- Injects canonical rule definition with `trigger: always_on` frontmatter.
- Audits `cex-pack.json` for `"lint"` and `"lint:fix"` scripts.
- Supports dry-run audit mode and automated `--fix` application mode.

---

## 3. CLI Invocations & Multi-Queue Scheduling

### Standalone CLI Execution:

```bash
# 1. Audit / Dry-Run Mode
cexr tasks/task_add_always_cex_lint_rule.cex

# 2. Automated Apply / Fix Mode
cexr tasks/task_add_always_cex_lint_rule.cex --fix
```

### Multi-Queue Scheduling via `cex-racer`:

```bash
# Schedule on default queue
cxvm racer run "cexr tasks/task_add_always_cex_lint_rule.cex --fix" --queue default
```

---

## 4. Verification & Unit Testing

- Unit Test Suite: [`tasks/test/always_cex_lint_rule.test.cex`](file:///home/viettd/Projects/tasks/test/always_cex_lint_rule.test.cex)
- Command:
    ```bash
    cxvm test tasks/test/always_cex_lint_rule.test.cex
    ```
