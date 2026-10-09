---
trigger: always_on
---

# Rule: Pure ASCII Output & Zero Emoji/Symbol Usage (RULE_NO_SYMBOLS)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols) -->

> **ZERO EMOJI & ZERO SYMBOL DIRECTIVE**:
> All source code, console output messages, CLI runners, setup windows, documentation, and agent rules inside `cxvm` MUST use pure ASCII text.
> **DO NOT USE** emojis, non-ASCII decorative symbols, or non-standard icon characters (such as red/yellow/green dots, checkmarks, warning icons, or box-drawing characters) inside `cxvm`.

---

## 1. Requirements

1. **Pure ASCII Output Formatting**:
   - Success status: Use `[OK]` instead of checkmarks or emojis.
   - Warning status: Use `[WARN]` instead of warning symbols.
   - Error status: Use `[FAIL]` or `[ERROR]` instead of error icons.
   - UI status indicators: Use `[RED] [YELLOW] [GREEN]` or `[R] [Y] [G]` for UI window control lights.
2. **Directory & Architecture Layouts**:
   - Use standard ASCII characters (`+--`, `|  `, `+--`) for directory tree diagrams instead of Unicode box-drawing characters.
3. **Agent Headings & Rule Titles**:
   - Headers in `.agents/` must be pure ASCII markdown text without emoji prefixes.
4. **Cex Class Member Access**:
   - Standardize all class member and method invocations in Cex to standard dot notation (`this.member`, `object.method()`) instead of pointer arrow (`->`) symbols.
5. **Rule 29 Compliance**:
   - Every file created or edited must terminate with exactly ONE newline (`\n`).
