---
trigger: always_on
---

# Rule: Auto-Commit Code

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths) -->

1. Whenever a milestone, task, or significant update is completed and verified against the test suites, perform a clean `git commit` to maintain clean tracking.
2. Use descriptive commit messages following the Conventional Commits format (e.g. `feat(cxvm): ...`, `fix(cxvm): ...`, `chore(cxvm): ...`).
3. Retain tracked distribution assets in `dist/` as mandated by Rule 69.
4. Never commit personal user paths, secrets, or temporary build scratch files outside the repository.
