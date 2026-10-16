---
trigger: always_on
---

# Mandatory Rule: Directory Structure Preservation via .gitkeep and .cvmkeep (RULE_DIRECTORY_STRUCTURE_KEEP)

> **Severity: MANDATORY / STRICT**
> **Rule Conformance**: Rule 69 (Target), Rule 29 (EOF Integrity), Rule 72 (Dynamic Paths), Rule 84 (Canonical Naming)

---

## 1. Absolute Invariant

Both Git and CodeVersionManager (`.cvm`) track file blobs rather than empty directories. Any intentional directory structure required by the workspace, core runtimes, build pipelines, package systems, or frameworks MUST be preserved using **paired marker files**:
- `.gitkeep`: Retains directory hierarchy within Git version control.
- `.cvmkeep`: Retains directory hierarchy within CodeVersionManager (`.cvm`) repositories.

---

## 2. Mandatory Usage Scenarios

1. **Empty Structural Folders**:
   - Any directory checked into a repository that currently contains no source files (e.g. `logs/`, `packages/`, `resources/`, platform targets `bin/macos/`, `bin/linux/`, `bin/window/`).
2. **Build, Distribution & Output Directories**:
   - Directories designed to receive compiled outputs or binaries (e.g. `bin/`, `dist/`, `build/`, `tmp/`).
   - Binaries and transient files must be excluded by ignore rules, while the directory itself remains permanently checked in via `.gitkeep` and `.cvmkeep`.
3. **Scaffolding and Project Initialization**:
   - `cxvm init`, `cxvm lighting create`, and framework scaffolders must automatically place `.gitkeep` and `.cvmkeep` inside generated structural directories.

---

## 3. Ignore Rules Compatibility (.gitignore & .cvmignore)

When ignoring binary or artifact directories, use glob negation so that marker files are NEVER excluded:

```gitignore
# Correct: Ignore folder contents while preserving directory structure
bin/*
!bin/.gitkeep
!bin/.cvmkeep

dist/*
!dist/.gitkeep
!dist/.cvmkeep

logs/*
!logs/.gitkeep
!logs/.cvmkeep
```

---

## 4. File Format & Integrity (Rule 29 Conformance)

1. **Content**: Every `.gitkeep` and `.cvmkeep` file must either be empty with a single newline or contain a short comment ending with **exactly one trailing newline (`\n`)**:
   ```
   # Keep directory structure for Git and CVM
   ```
2. **No Orphan Markers**: Never add a `.gitkeep` or `.cvmkeep` without its twin `.cvmkeep` or `.gitkeep`. Both systems must stay in 1:1 synchronization.

---

## 5. Verification Commands

Scan the workspace to ensure no intentional empty directories exist without preservation markers:

```bash
find . -type d -empty ! -path "*/.git/*" ! -path "*/.cvm/*" ! -path "*/.cex_cache/*"
```
