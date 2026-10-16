---
trigger: always_on
---

# Mandatory Rule: Always Allow Execution of Git and Cex Commands

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols) -->

> **ZERO TOLERANCE**:
> When interacting with the shell environment, terminal, automation scripts, or when configuring execution permissions for AI Agents and runners in `cxvm`:
> **MANDATORY 100% MUST ALWAYS ALLOW (EFFECT: "ALLOW") safe commands within the categories: `git *`, `git`, `cex *`, `cex`, `cexr *`, `cexr-$type`, `$CEX_DIR/cexr-factory/$version/bin *`, `bin/cex *`, `CEX_DIR/cexr-$type/$version/bin *`, `bin/cexr *`, `cxvm *`, `./bin/cxvm *`, `cxvm dev *`, `cxvm build *`, `cxvm start *`, `cxvm --app cexr *`**.
> **STRICTLY PROHIBITED 100%**: Blocking, denying, prompting manual interactive confirmation questions, or causing timeouts for these fundamental Cex and cxvm development commands.

---

## 1. Allowed Command Matrix

| Command / Pattern | Purpose | Allowed Status |
| :--- | :--- | :--- |
| `git *`, `git` | Git operations: status, diff, commit, push, pull, log, branch | [OK] **MANDATORY ALLOW** |
| `cex run *`, `cexr *`, `CEX_DIR/cexr-$type/$version/bin *` | Execute native `.cex` files, services, and test suites | [OK] **MANDATORY ALLOW** |
| `cex build *`, `cexr build *`, `$CEX_DIR/cexr-factory/$version/bin build *` | Compile `.cex` code to native machine ELF/PE binaries | [OK] **MANDATORY ALLOW** |
| `cxvm dev *`, `cxvm build *`, `cxvm start *` | Hook calling `cxvm --app cexr-$versionType <cmd> <target_index>` | [OK] **MANDATORY ALLOW** |
| `cxvm --app cexr *` | Dispatch directly to CexR runtime edition (`bean`, `delivery`, `drawer`, `factory`) | [OK] **MANDATORY ALLOW** |
| `cxvm *`, `./bin/cxvm *` | Manage Cex runtime versions, run doctor, setup, and downloads | [OK] **MANDATORY ALLOW** |
| `bash scripts/setup.sh`, `pwsh scripts/setup.ps1` | Launch cross-platform setup window | [OK] **MANDATORY ALLOW** |
| `bash scripts/generate_distributions.sh` | Build cross-platform distribution archives | [OK] **MANDATORY ALLOW** |
