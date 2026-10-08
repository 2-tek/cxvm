---
trigger: always_on
---

# 2-TEK cxvm: Project Standards & Governance

<!-- Standard Specification: .agents/rules/standard-for-project.md -->
<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths) -->

> **CORE PRINCIPLE**:
> `cxvm` (`@2tek/cxvm`) is the official cross-platform distribution engine and runtime version manager for the Cex native language ecosystem.
> It is powered natively by **Lighting Fullstack MVC** using Pure Cex (`cexr` runtime engine + `cexp` direct machine compiler), with zero C++ build dependencies in v2.
>
> In conformance with **Rule 69**:
> In CexR v8 of `.cex_boxes`; when loaded, dependencies load from the dist file of `.cex_boxes/{dependencyName}` to runtime, with `cex-pack.json`. If target is runtime, do not use `.gitignore` for dist bundle file.
> **The `dist/` directory is retained, tracked, and populated with all 36 cross-platform distribution bundles.**

---

## 1. Governance & Structural Rules

1. **Rule 69 (Target Immutability & Dist Retention)**:
   - Manifest `target` must always remain `"target": "runtime"`.
   - `dist/` must remain un-ignored in `.gitignore` and contain pre-built cross-platform packages, installer scripts, `manifest.json`, and `SHA256SUMS`.
2. **Rule 29 (EOF Integrity)**:
   - Every file must terminate with exactly one newline character (`\n`).
3. **Rule 72 (Dynamic Paths)**:
   - Zero hardcoded personal paths (`/home/user/...`). All paths resolve relative to `$HOME`, `$CXVM_DIR`, `$CEX_HOME`, or the working directory.
4. **Pure Cex Standard (v2)**:
   - In v2, do not use C++ compilers (`g++`, `clang++`, `MSVC`). Execution is handled directly by `cexr` and machine compilation by `cexp`.
5. **Project Dispatchers & Default Runtimes**:
   - Default `./bin/cexr` and `./bin/cex` prioritize **CexR v8.0.0** (with quick-switch support for **v6.0.0**).
6. **Cross-Platform Setup Window**:
   - Provide an interactive visual setup window via CLI (`cxvm setup`, `scripts/setup.sh`, `scripts/setup.ps1`, `setup.cmd`) and Web (`http://localhost:3080/setup`) to configure PATH, environment variables, default runtimes, and local `./bin/` dispatchers.
7. **Automated Testing**:
   - All tests live under `tests/` (`tests/cxvm.test.cex`, `tests/factory.test.cex`) and must pass cleanly with `cexr run <test_file>`.

---

## 2. Directory Layout Standard

```text
cxvm/
├── .agents/                      # Agent governance, target specs, standards, and rules
│   ├── PRODUCT_TARGET.md         # Canonical target specification
│   ├── rules/                    # Enforced coding and architecture rules
│   └── standards/                # Architectural layout and setup window specifications
├── bin/                          # Toolchain entry dispatchers (cexr, cex, cxvm, .cmd, .ps1)
├── dist/                         # Retained cross-platform distribution bundles (Rule 69)
├── downloads/                    # Public download mirror store (36 bundles + manifests)
├── scripts/                      # Build automation and setup scripts
│   ├── generate_distributions.sh # Distribution builder and dist sync
│   ├── setup.sh                  # POSIX setup window script
│   └── setup.ps1                 # Windows PowerShell setup window script
├── src/                          # Lighting MVC application kernel
│   ├── app.cex                   # Lighting MVC kernel and route definitions
│   ├── builder/                  # Package builder and checksum engine
│   ├── controllers/              # MVC controllers (FactoryController)
│   ├── cxvm/                     # CXVM version manager engine core
│   ├── models/                   # Validated entities (Platform, Version, Artifact)
│   ├── views/                    # Visual templates & Setup Window
│   ├── index.cex                 # Package entrypoint & live server
│   └── lighting_mvc.cex          # Lighting MVC framework integration
├── tests/                        # Full regression test suite
│   ├── cxvm.test.cex             # CXVM engine & endpoint verification
│   └── factory.test.cex          # Factory architecture & model validation
├── cex-pack.json                 # Package manifest (target: runtime)
└── README.md                     # Comprehensive cross-platform documentation
```
