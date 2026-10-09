---
trigger: always_on
---

# Rule: Mandatory Documentation Book Update on Feature Additions (RULE_DOCUMENTS_UPDATE)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols) -->

> **DOCUMENTATION SYNCHRONIZATION DIRECTIVE**:
> Whenever a new feature, command, API, model, or architectural component is added or modified in any project under the Cex ecosystem (e.g., `cxvm`, `cexp`, `cexr`, or packages in `cxvm/packages/*`):
> **MANDATORY**: Update the central documentation book located at `documents/` (accessible via `../documents` from sibling projects, or referenced as `../{projectName}`).

---

## 1. Governance & Execution Requirements

1. **Rule Priority**:
   - Before completing any task or feature implementation in `../{projectName}`, the corresponding documentation chapter in `documents/src/{projectName}/` must be updated.
2. **Project Path Resolution**:
   - Projects resolve the documentation repository dynamically at `../documents`.
   - The documentation book organizes chapters by project name:
     - `documents/src/cxvm/` for CXVM distribution and version manager features.
     - `documents/src/cexp/` for CexP direct machine compiler features.
     - `documents/src/cexr/` for CexR runtime engine features.
     - `documents/src/packages/{packageName}/` for Cex ecosystem packages (e.g., `cex-pack`, `cex-cli`, `cex-cvm`, `cex-cvm-cli`).
3. **Table of Contents Synchronization**:
   - Whenever a new chapter or document file is added, update `documents/src/SUMMARY.md` to include the new section link.
4. **Git Repository Tracking & Commits**:
   - The `documents/` directory is an independent git repository.
   - All documentation updates must be cleanly committed following conventional commits: `docs({projectName}): document new feature X`.
5. **Standards Compliance**:
   - Conformance with **Rule 29 (EOF Integrity)**: All markdown and configuration files must end with exactly one newline character (`\n`).
   - Conformance with **Rule (No Symbols)**: Pure ASCII text only. Do not use emojis or unicode decorative symbols.
   - Conformance with **Rule 72 (Dynamic Paths)**: No hardcoded absolute user paths; use relative references (`../{projectName}`).
6. **Pure Cex Toolchain**:
   - Documentation generators, readers, scripts, and validators must be built in `.cex` utilizing Cex ecosystem libraries (`cexr`, `cexp`, `cex-view`, `cex-service`, `cex-pack`). No Node.js or JavaScript runtime dependencies.
