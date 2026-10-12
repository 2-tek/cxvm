---
trigger: always_on
---

# Mandatory Rule: Prohibition of '+=' String Concatenation for HTML Generation (RULE_NO_HTML_PLUS_CONCAT)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 82 (CXVM & Direct CexR), Rule 85 (Lint Gate) -->

> **MANDATORY BAN ON '+=' STRING CONCATENATION FOR HTML GENERATION**:
> In all `mvc-lighting`, `mvp-deepsea`, Cex microservices, repositories, packages, views, controllers, and agent workflows:
>
> 1. **STRICT PROHIBITION OF '+=' / '+' HTML STRING CONCATENATION**:
>    - Generating, assembling, or rendering HTML markup using incremental string concatenation (`html += "<div..."`, `out += "<span>"`, `s = s + "<tr>"`, or multiline `+=` chains) is **STRICTLY PROHIBITED**.
>    - Views, presenters, controllers, and components must NOT manually build HTML responses through raw string accumulation.
>
> 2. **ARCHITECTURAL & SECURITY RATIONALE**:
>    - **Performance Invariant**: Repetitive string concatenation triggers repeated memory reallocations and heap thrashing ($O(N^2)$ buffer reallocations), severely degrading native server throughput.
>    - **Security Invariant (XSS Prevention)**: Raw string concatenation risks Cross-Site Scripting (XSS) and injection vulnerabilities when dynamic values are spliced without contextual HTML escaping.
>    - **DOM Integrity**: Manual string gluing frequently leads to unclosed tags, malformed attribute quotes, and untrackable layout bugs.
>
> 3. **MANDATED CANONICAL ALTERNATIVES**:
>    - **Virtual DOM (`@cex-virtual-dom` / `VNode` / `DOMBuilder`)**:
>      Construct structured Virtual DOM trees using `VNode::createElement(tag, props, children)` or declarative DOM builder methods (`vdom->div()`, `vdom->table()`). Let the engine serialize the tree into output buffers.
>    - **Dedicated HTML Template Files (`.html` / `.html.cex` / `.vdom.cex`)**:
>      Keep HTML markup in clean external template files (e.g. `src/views/console.html`, `public/index.html`) and bind parameters using template engines or variable replacement dictionaries.
>    - **Pre-Allocated Buffer / Stream Writers**:
>      When high-throughput streaming is necessary, write into pre-allocated memory buffers (`ByteBuffer`, `StringBuilder` with known initial capacity) or socket stream writers with HTML entity escaping.
>
> 4. **TASK TRACKING & REFACTORING DISCIPLINE VIA `.agents/features`**:
>    - When existing `+=` HTML concatenation is discovered in any project, the agent/developer MUST immediately record a task in `.agents/features/{DD-MM-YYYY}.md`:
>      `- [ ] refactor(views): eliminate += HTML concatenation in <source-path> using Virtual DOM or HTML template`
>    - Refactor the view to use Virtual DOM nodes or external template files.
>    - Verify zero lint errors (`cxvm lint`) and 100% test pass rate (`cxvm test`).
>    - Mark the task completed:
>      `- [x] refactor(views): eliminate += HTML concatenation in <source-path> using Virtual DOM or HTML template`
