# Mandatory Rule: Zero Duplicated Rules in .agents/rules (RULE_NO_DUPLICATED_RULES)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF Integrity), Rule 72 (Dynamic Paths), Rule (No Symbols) -->

> **ZERO DUPLICATED RULES DIRECTIVE**:
> Across the root workspace and every subproject (`cexp-v$shortVersion`, `cexr-$type`, `cxvm`, `documents`, `deps/*`, `frameworks/*`, `projects/*`), each `.agents/rules/` directory MUST contain only unique, canonical rule definitions.
> **Duplicated rule files (by normalized filename, identical content checksum, or identical top-level rule heading/ID) and redundant nested `features/.agents/rules/` copies are strictly prohibited.**

---

## 1. Requirements

1. **Canonical Uppercase Naming (`RULE_<NAME>.md`)**:
   - All `RULE_*` specifications MUST use uppercase snake_case filenames (`RULE_<NAME>.md`).
   - Creating a lowercase hyphenated mirror (`rule-<name>.md`) alongside `RULE_<NAME>.md` in the same `.agents/rules/` directory is strictly forbidden.
2. **Zero Content or Heading Duplicates**:
   - Two files in the same `.agents/rules/` directory must NEVER share identical content checksums or identical `# ... (RULE_...)` top-level headings.
   - When upgrading a versioned rule (e.g., from `V7` to `V8`), either update the rule in place with a distinct scope or remove the superseded duplicate file so two files do not declare the same `(RULE_...)` identifier.
3. **Single `.agents/rules/` Root per Project/Package**:
   - Rules belong exclusively in `<project>/.agents/rules/`.
   - Do not duplicate `.agents/rules/` directories inside `src/*/features/.agents/rules/` or other source subdirectories.
4. **Rule 29 (EOF Integrity) & Rule (No Symbols)**:
   - Every rule file must use pure ASCII characters and terminate with exactly one newline character (`\n`).

---

## 2. Verification Command

Scan all `.agents/rules/` directories across the workspace to verify zero normalized-name, checksum, or heading duplicates exist:

```bash
for d in $(find . -type d -path "*/.agents/rules" -not -path "*/.cex_boxes/*" -not -path "*/.git/*" -not -path "*/.cvm/*" | sort); do
  ls "$d"/*.md 2>/dev/null | xargs -n1 basename 2>/dev/null | awk '{ orig=$0; n=tolower($0); gsub(/_/, "-", n); print n, orig }' | sort | awk 'prev==$1 { print "[NORM DUP] " prev_orig " <-> " $2 } { prev=$1; prev_orig=$2 }'
  cksum "$d"/*.md 2>/dev/null | awk '{ print $1"_"$2, $3 }' | sort | awk 'prev==$1 { print "[CKSUM DUP] " prev_file " <-> " $2 } { prev=$1; prev_file=$2 }'
done
```
