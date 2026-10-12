---
trigger: always_on
---

# Mandatory Rule: Seeding Data Exclusively Restricted to Test Folder (RULE_SEEDING_TEST_ONLY)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule 82 (CXVM & Direct CexR), Rule 85 (Lint Gate) -->

> **MANDATORY DIRECTIVE: ONLY USE SEEDING DATA IN ./test OR ./tests FOLDER**:
> In all `mvc-lighting`, `mvp-deepsea`, Cex microservices, repositories, packages, and agent workflows:
>
> 1. **STRICT PROHIBITION OF SEEDED DATA IN `src/` & PRODUCTION RUNTIME**:
>    - Core repositories, models, presenters, controllers, databases, and kernels (`src/`, `src/models/`, `src/kernel.cex`) MUST NOT contain hardcoded mock data, dummy users, fake records, or test fixtures.
>    - Initialization functions (`constructor()`, `initialize()`, repository setup) must start in a clean state with zero initial mock records.
>    - Production servers (`dist/server`) and Thunder container instances must start with zero pre-populated mock database rows.
>
> 2. **ALL SEEDING MUST RESIDE EXCLUSIVELY IN `./test` OR `./tests`**:
>    - Test fixture generation, mock entities, dummy credentials, and sample datasets MUST be placed exclusively in the `./test` (or `./tests`) directory (e.g. `test/seeder.cex`, `tests/fixtures/`, `test/helpers/seeder.cex`).
>    - Test suites requiring pre-populated state must explicitly invoke dedicated test seeders (e.g. `DeepSeaTestSeeder::seed(repo)`).
>    - All tests must teardown or clear mock fixtures upon completion to prevent state pollution across test runs.
>
> 3. **TASK TRACKING DISCIPLINE VIA `.agents/features`**:
>    - Whenever existing seeding logic or mock records are identified in `src/`, the agent/developer MUST immediately record a task in `.agents/features/{DD-MM-YYYY}.md`:
>      `- [ ] refactor(seeding): move seeding data from <src-path> to ./tests (or ./test)`
>    - Relocate the seeding methods to a dedicated test seeder file in `./tests` / `./test`.
>    - Update the affected test suites to consume the test seeder.
>    - Verify that all tests pass (`cxvm test`) with 100% pass rate.
>    - Mark the task completed:
>      `- [x] refactor(seeding): move seeding data from <src-path> to ./tests (or ./test)`
