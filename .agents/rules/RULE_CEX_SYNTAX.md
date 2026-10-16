# Rule: Mandatory Cex Language Syntax Standards (RULE_CEX_SYNTAX)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols), Rule 81 (Native Syntax), Rule 87 (Copytype/Copyvalue) -->

> **MANDATORY CEX LANGUAGE SYNTAX GOVERNANCE DIRECTIVE**:
> All source code, libraries, services, applications, and frameworks across the Cex ecosystem MUST strictly adhere to native `.cex` language syntax standards.
> All projects governed by `cex-pack.json` must enforce these syntax invariants during authoring, building, and pre-flight linting.

---

## 1. Syntax Directives

### 1.1 Explicit Variable Typing (Rule 44)
Every variable declared with `let` or `const` must define an explicit type annotation before the assignment operator `=`:
```cex
// VALID: Explicit type annotation before '='
let port: int = 3080;
let latency: double = 0.008;
let service: AuthService* = new AuthService();

// PROHIBITED: Untyped or inferred assignment
let port = 3080; // VIOLATION
```

### 1.2 Mandatory `this.` Member Access (Rule 81 / Rule NO_SYMBOLS)
Inside class instance methods and constructors, all properties and methods of the current instance must be accessed using standard dot notation (`this.property`, `this.method()`).
- The C++ arrow syntax `this->` within class bodies is strictly prohibited.
- Bare field references without `this.` are strictly prohibited.

### 1.3 Object-Oriented Inheritance (`extends`)
Classes declare inheritance using the `extends` keyword (`class Child extends Parent`).
- C++ inheritance syntax (`: public Parent`) is prohibited and rejected by `cex-lint`.
- Multiple inheritance is replaced by composition or `copytype` (Rule 87).

### 1.4 Prototyping Syntax: `copytype` & `copyvalue` (Rule 87)
- `copytype Target From;`: Generates class `Target` inheriting logic, constructors, and properties of `From`.
- `copyvalue target from;`: Synchronizes matching public fields between instances after value comparison.

### 1.5 Module Imports & Zero Raw Includes (RULE_CEX_LINT)
All dependencies, files, and system headers must be imported via `import` statements:
- Relative: `import "./types.cex";`
- Root/Alias: `import "@/src/services/api.cex";`
- Packages: `import "@cex-virtual-dom/src/virtual_dom.cex";`
- System headers: `import ... from "cpp/vector";` or `import ... from "c/unistd.h";`
- Direct preprocessor `#include` directives are strictly prohibited.

### 1.6 Package Manifest Invariants (`cex-pack.json`)
Every project manifest must declare:
- `"target": "runtime"` (Rule 69).
- `"required": { "cexr": "^8", "cexp": "^8" }` (Caret version bounds).
- Execution scripts must invoke `cexr <file.cex>` directly without the deprecated `run` subcommand.

### 1.7 End-Of-File (EOF) Integrity (Rule 29)
Every `.cex`, `.json`, and `.md` file must terminate with exactly one newline character (`\n`).

### 1.8 Pure ASCII Output (Rule NO_SYMBOLS)
Console output, status logs, diagnostics, and documentation must use clean ASCII text without emojis or non-standard unicode symbols.

---

## 2. Documentation Book Synchronization (RULE_DOCUMENTS_UPDATE)

Whenever new language features, syntax constructs, or compiler capabilities are introduced, the canonical reference chapters under `documents/src/syntax/` and `documents/src/SUMMARY.md` must be updated and committed.
