# Rule 69: Keep Target of Project & Dist Bundle File Standard

<!-- Rule Conformance: Rule 69 (Keep Target of Project) & Rule 29 (EOF Integrity) -->

1. **Target Immutability**: Always preserve `"target": "runtime"` in `cex-pack.json`. Never alter the target field.
2. **Distribution Bundle Standard**: In CexR v8 of `.cex_boxes`; when loaded, dependencies load from the dist file of `.cex_boxes/{dependencyName}` to runtime, with `cex-pack.json`. If target is runtime, **do not use `.gitignore` for dist bundle file**.
3. **Keep `dist/` Directory**: Always keep `dist/` containing all cross-platform distribution downloads of `cxvm` (Linux x86_64/aarch64, macOS Apple Silicon/Intel, Windows x64/arm64). The `dist/` directory must NEVER be ignored in `.gitignore`.
4. **Pure Cex Native Toolchain**: In v2 and above, do not use C++ compilers (`g++`, `clang++`, `MSVC`) or C++ headers (`#include <iostream>`). Use purely `cexr` (Cex Runtime Engine) and `cexp` (Cex Direct Machine Compiler).
5. **Required Dependencies**: Maintain `"required": { "cexr": "^8", "cexp": "^8" }` in `cex-pack.json`.
6. **Cross-Platform Setup Window**: Provide both CLI (`cxvm setup`, `scripts/setup.sh`, `scripts/setup.ps1`, `setup.cmd`) and Web (`/setup`) setup windows to configure `CXVM_DIR`, `CEX_HOME`, shell PATH, default runtimes (v8 & v6), and project `./bin/` dispatchers.
7. **Project Dispatchers**: Maintain `./bin/cexr` and `./bin/cex` configured for running cxvm with CexR v8.0.0 by default, with instant support for CexR v6.0.0.
8. **Rule 29 (EOF Integrity)**: All source, script, configuration, test, and documentation files must end with exactly ONE newline (`\n`).
9. **Rule 72 (Dynamic Paths)**: All scripts and source files must dynamically resolve paths relative to current working directory or environment variables (`$HOME`, `$CXVM_DIR`, `$CEX_HOME`). Zero hardcoded personal user paths.
