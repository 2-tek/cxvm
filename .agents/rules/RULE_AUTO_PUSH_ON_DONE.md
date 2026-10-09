# Rule: Auto Push Code on Done

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 82 (CXVM & Direct CexR) -->

## Policy & Invariants
Whenever any task, milestone, feature, bug fix, or refactor is completed:

### 1. Verification & Tests
- Ensure all relevant test suites pass (100% pass rate) prior to finishing.
- Never commit broken code, failing tests, personal credentials, or temporary `/tmp` artifacts.

### 2. Stage & Commit
- Stage changes according to `.gitignore` and `.cvmignore`:
  ```bash
  git add -A
  ```
- Commit using Conventional Commits format (`feat(...)`, `fix(...)`, `refactor(...)`, `chore(...)`, `test(...)`, `rules(...)`).

### 3. Auto Push to Git (.git)
- Automatically attempt to push committed code to upstream remote:
  ```bash
  git push origin <current-branch>
  ```
  (or via `cxvm git push origin <current-branch>`).

### 4. CVM Push Attempt (.cvm)
- If the repository integrates with `.cvm` (`.cvm/` exists):
  - Record the state in `.cvm/records/` and update `.cvm/refs/heads/<branch>`.
  - Try pushing `.cvm` to remote if configured or supported:
    ```bash
    cvm push || cxvm cvm push
    ```

### 5. Graceful Fallback (Break Step by Commit Only)
- If the push step fails or cannot be completed (e.g. no remote repository configured, network disconnected, remote authentication required, or CVM remote not initialized):
  - **Do NOT abort, revert, or fail the entire task.**
  - **Break step by commit only**: Keep the commit safely recorded in the local repository.
  - Inform the user that the code has been committed locally and push was skipped or gracefully broken.
