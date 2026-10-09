# Rule: Mandatory Feature and Task Tracking in .agents/features (RULE_FEATURES_TRACKING)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths) -->

> **CANONICAL FEATURE TRACKING SPECIFICATION**:
> All feature checklists, task tracking, bug tracking, and daily progress logs MUST reside in `.agents/features/{DD-MM-YYYY}.md` (e.g. `.agents/features/09-10-2026.md`).
> The legacy root directory `.features/` is deprecated and replaced by `.agents/features/`.

---

## 1. Governance & Execution Requirements

1. **Scan File Path**: Scan `*/.agents/features/*.md`.
2. **Automatic Checkbox Entry**: When submitting a task or receiving user input, automatically input a task checkbox (`- [ ]`) into the corresponding feature section. If it is a bug report/fix, label with `bug(...)`, otherwise use `feat(...)`, `test(...)`, or `refactor(...)`.
3. **Current Date Priority**: Prioritize the file matching the current date (format: `DD-MM-YYYY.md`, e.g. `09-10-2026.md`).
4. **Completion Discipline**: As subtasks and verifications are completed, immediately mark the corresponding checkbox with `- [x]`.
5. **Rule 29 Conformance**: All `.agents/features/*.md` files must end with exactly one newline character (`\n`).
