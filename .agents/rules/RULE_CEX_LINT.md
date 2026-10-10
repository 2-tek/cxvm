# Mandatory Rule: Cex-Lint Code Quality & Syntax Standards (RULE_CEX_LINT)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 85 (Lint Gate) -->

> **MANDATORY CEX-LINT ENFORCEMENT & SYNTAX GOVERNANCE DIRECTIVE**:
> In all project workspaces, development sessions, build pipelines, testing suites, and agent workflows containing `.cex` code:
>
> 1. **MANDATORY AUTOMATIC LINT GATE**:
>     - All `.cex` files must pass `cex lint` with zero errors (`exit code 0`).
>     - Before any compilation (`cexp build`), test execution (`cxvm test`), or version control staging (`cvm add`, `git add`), `cex lint` must be executed to validate code health.
>     - If lint errors are detected, the agent/developer MUST resolve them before proceeding.
> 2. **SYNTAX & CODE QUALITY STANDARDS**:
>     - **No Raw Includes (`no-raw-include`)**: Direct `#include` directives are strictly prohibited in `.cex` source files. All native headers and libraries must be loaded via `import ... from "cpp/..."` or `import ... from "c/..."`.
>     - **This-Dot Member Access (`this-dot`)**: Use `this.` member access syntax instead of pointer arrow `this->` within class bodies.
>     - **Semicolon Discipline (`semi`)**: Statements declaring variables (`let`, `const`), control flow (`return`, `break`, `continue`, `throw`), imports (`import`), and value/type operations (`copyvalue`, `copytype`) must terminate with semicolons.
>     - **EOF Integrity (Rule 29, `eol-last`)**: Every `.cex` file must terminate with exactly one trailing newline (`\n`).
>     - **Whitespace Discipline**: Indentation must use spaces without tabs (`no-tabs`), trailing whitespace at end of lines is prohibited (`no-trailing-spaces`), and consecutive empty lines must not exceed 1 (`no-multiple-empty-lines`).
>     - **Identifier & Type Integrity**: Class names must be unique within a package (`no-duplicate-class-name`), import specifiers must not be duplicated (`no-duplicate-imports`), and class names must use PascalCase (`class-name-case`).
> 3. **AUTOMATED REMEDIATION & WORKFLOW**:
>     - Run `cex lint --fix` to automatically format, clean trailing whitespace, fix tab indentation, convert raw `#include` statements, and normalize member access.
>     - Manually inspect and resolve any remaining structural or syntax errors reported by `cex lint`.
> 4. **TASK & BUG TRACKING DISCIPLINE**:
>     - Any bugs or lint issues detected must be documented as tasks in `.agents/features/{DD-MM-YYYY}.md` with `bug(lint):` checkboxes (`- [ ]`) and marked completed (`- [x]`) upon clean verification.
