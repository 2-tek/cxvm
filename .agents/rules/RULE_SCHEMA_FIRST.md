---
trigger: always_on
---

# Mandatory Rule: Schema First — Auto-Generate SCHEMA.md Before Any Other Task (RULE_SCHEMA_FIRST)

<!-- Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths) -->

> **MANDATORY SCHEMA-FIRST GATE**:
> In every project, package, workspace, and agent workflow, the data schema is designed **before** anything else is touched.
>
> 1. **SCHEMA.md IS ALWAYS STEP 0 (BLOCKING GATE)**:
>    - Before starting or updating ANY other task (feature, model, controller / presenter, view, `/api` route, migration, seed, test, refactor), the agent MUST first auto-generate or update `SCHEMA.md` at the project root (or at the package root `{package}/SCHEMA.md` in multi-package repositories).
>    - No other task may be started, edited, or marked done until `SCHEMA.md` reflects the intended data and API change.
>    - If `SCHEMA.md` is missing, generate it immediately by scanning the existing sources (`src/models/`, entities, migrations, SQL files, ORM / `cex-sql` definitions, controllers, presenters, `/api` routes).
>    - If a task does not change data or API, still verify that `SCHEMA.md` exists and is in sync with the code before continuing.
>    - In `.agents/features/{DD-MM-YYYY}.md`, the schema task is always listed FIRST: `- [ ] schema(<scope>): update SCHEMA.md` and must be checked (`- [x]`) before any other task in the list.
>
> 2. **SCHEMA.md MANDATORY STRUCTURE (IN THIS ORDER)**:
>    - `## 1. Entities` — every table written in **SQL DDL syntax** inside a ```` ```sql ```` block: `CREATE TABLE` with column types, `PRIMARY KEY`, `NOT NULL`, `UNIQUE`, `DEFAULT`, `REFERENCES ... ON DELETE ...`, and `CREATE INDEX` statements.
>    - `## 2. Relationships` — every relation written in cardinality notation inside a ```` ```text ```` block (see legend below).
>    - `## 3. API (/api)` — every endpoint, always prefixed with `/api`, mapped to its entity and action. Relations are exposed as nested routes (e.g. `/api/users/:id/profile`).
>
> 3. **RELATIONSHIP NOTATION LEGEND**:
>    - Format: `<entity_a> -<A_has_B>-<B_has_A>- <entity_b>`
>      - `<A_has_B>`: how many `entity_b` rows one `entity_a` row has.
>      - `<B_has_A>`: how many `entity_a` rows one `entity_b` row belongs to.
>    - Cardinality tokens: `0:1` (zero or one), `1:1` (exactly one), `0:*` (zero or many), `1:*` (one or many).
>    - Foreign key placement: the side that has `1:1` / `0:1` toward the other entity owns the FK (`1:1` = `NOT NULL`, `0:1` = nullable). One-to-one FKs are `UNIQUE`. `0:*`-`0:*` relations require a junction table.
>    - Examples:
>      - `user -0:1-1:1- profile` : a user has zero or one profile; a profile belongs to exactly one user (`profile.user_id UNIQUE NOT NULL`).
>      - `user -0:*-1:1- post` : a user has many posts; a post belongs to exactly one user (`post.user_id NOT NULL`).
>      - `post -0:*-0:*- tag` : many-to-many through junction table `post_tag(post_id, tag_id)`.
>
> 4. **SYNCHRONIZATION & SOURCE OF TRUTH**:
>    - `SCHEMA.md` is the single source of truth. Models, migrations, DTOs, controllers / presenters, and `/api` routes MUST match it exactly; on conflict, update `SCHEMA.md` first, then the code.
>    - Table names use `snake_case` singular (`user`, `user_profile`); API paths use plural kebab-case resources (`/api/users`, `/api/user-profiles`).
>    - Schema changes are committed in the same commit as the code that implements them, and the commit message is prefixed with the schema scope (e.g. `feat(schema): add profile to user`).
>    - Never put credentials, real data, or absolute personal paths in `SCHEMA.md` (Rule 72).
>
> 5. **CANONICAL SCHEMA.md TEMPLATE**:
>
>    ````markdown
>    # SCHEMA
>
>    ## 1. Entities
>
>    ```sql
>    CREATE TABLE user (
>        id          BIGINT       PRIMARY KEY,
>        email       VARCHAR(255) NOT NULL UNIQUE,
>        created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
>    );
>
>    CREATE TABLE profile (
>        id          BIGINT       PRIMARY KEY,
>        user_id     BIGINT       NOT NULL UNIQUE REFERENCES user(id) ON DELETE CASCADE,
>        full_name   VARCHAR(255) NOT NULL,
>        avatar_url  TEXT
>    );
>    ```
>
>    ## 2. Relationships
>
>    ```text
>    user -0:1-1:1- profile
>    ```
>
>    ## 3. API (/api)
>
>    | Method | Path                     | Entity  | Action                 |
>    | :----- | :----------------------- | :------ | :--------------------- |
>    | GET    | /api/users               | user    | list                   |
>    | POST   | /api/users               | user    | create                 |
>    | GET    | /api/users/:id           | user    | read                   |
>    | PUT    | /api/users/:id           | user    | update                 |
>    | DELETE | /api/users/:id           | user    | delete                 |
>    | GET    | /api/users/:id/profile   | profile | read profile of user   |
>    | PUT    | /api/users/:id/profile   | profile | upsert profile of user |
>    ````
