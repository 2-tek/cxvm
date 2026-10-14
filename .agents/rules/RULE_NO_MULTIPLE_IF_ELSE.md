---
trigger: always_on
---

# Mandatory Rule: Prohibition of Multiple If-Else Chains — Use Switch-Case (RULE_NO_MULTIPLE_IF_ELSE)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 82 (CXVM & Direct cexp), Rule 85 (Lint Gate) -->

> **MANDATORY PROHIBITION OF MULTIPLE IF-ELSE CHAINS (`else if`) DIRECTIVE**:
> In all `mvc-lighting`, `mvp-deepsea`, `cxvm`, Cex microservices, repositories, packages, CLI dispatchers, controllers, and agent workflows:
>
> 1. **STRICT PROHIBITION OF MULTIPLE `if - else` (`else if`) LADDERS**:
>     - Chained `if (...) { ... } else if (...) { ... } else { ... }` ladders and sequential multi-branch `if` chains dispatching on the same selector or state are **STRICTLY PROHIBITED**.
>     - Do NOT write multiple `if - else` branches to route commands, status codes, file extensions, protocol states, or configuration options.
> 2. **MANDATED `switch - case` REPLACEMENT**:
>     - All multi-branch conditional routing MUST be structured as a canonical `switch (...) { case ...: ... break; default: ... break; }` statement.
>     - For integer, character, or enum selectors, switch directly on the value:
>         ```cex
>         switch (code) {
>             case 1:
>                 return this.handleInit();
>             case 2:
>                 return this.handleBuild();
>             default:
>                 return this.handleDefault();
>         }
>         ```
>     - For string or composite condition selectors in Cex (which compiles to native C++20), map the selector to a deterministic integer case code (via a resolver expression or helper method) and dispatch with `switch (caseCode)`:
>         ```cex
>         let cmdCode: int = (cmd == "init") ? 1 : ((cmd == "build") ? 2 : ((cmd == "test") ? 3 : 0));
>         switch (cmdCode) {
>             case 1:
>                 return this.cmdInit(arg1);
>             case 2:
>                 return this.cmdBuild(arg1);
>             case 3:
>                 return this.cmdTest(arg1);
>             default:
>                 return this.cmdHelp();
>         }
>         ```
> 3. **ARCHITECTURAL & PERFORMANCE RATIONALE**:
>     - **Compiler Jump-Table Optimization**: Native `switch-case` blocks allow the C++20 / `cexp` backend to emit $O(1)$ jump tables and indexed branch targets instead of $O(N)$ sequential branch evaluations.
>     - **Control-Flow Clarity & Maintainability**: `switch-case` blocks enforce explicit case boundaries (`case N:` / `break;` / `return;`) and `default:` fallback handling.
> 4. **AUTOMATED SCAN, LINT & TASK TRACKING DISCIPLINE**:
>     - Scan any repository for violations using:
>         ```bash
>         grep -rn "else if" src/ tasks/ scripts/
>         ```
>     - Whenever multiple `if - else` (`else if`) chains are found, record a task in `.agents/features/{DD-MM-YYYY}.md`, refactor all occurrences to `switch - case`, and verify 0 lint warnings/errors (`cxvm lint`) and 100% test pass rate (`cxvm test`).
