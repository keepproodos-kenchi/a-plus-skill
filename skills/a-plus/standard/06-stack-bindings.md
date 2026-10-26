# Layer 6 — Example Bindings by Ecosystem

**Status:** Reference v2.0. **Examples, not requirements.** This layer helps an agent find the
native way to meet a control. Always apply the ladder (Layer 1 §1.3, X-11): first look for what
the repository already uses (manifests, lockfiles, existing modules); only then consult these
tables; anything not already in the lockfile needs approval. When the repository already has a
working mechanism for a concern, that mechanism is the binding, even if it is not listed here.

## How to read the tables

Within a cell, options are ordered: framework built-in or standard library first, then common
ecosystem tools. A tool listed for one ecosystem is never a recommendation for another.

## Python (FastAPI, Django, Flask, plain packages)

| Concern (controls) | Native options |
| --- | --- |
| Boundary parsing (C-02) | FastAPI: pydantic request/response models and `response_model`; Django: forms, DRF serializers; plain: pydantic, `attrs` + `cattrs`, `msgspec`, dataclasses plus explicit checks |
| Config fail-closed (C-06, B-19) | pydantic-settings; Django settings module with explicit checks at startup; a typed dataclass loaded and validated in `main` |
| Canonical schema and contract (P-C2) | FastAPI's generated OpenAPI document; drf-spectacular; contract tests with Schemathesis against the OpenAPI document |
| Structured logs and errors (C-15, P-O1) | stdlib `logging` with a JSON formatter; `structlog`; FastAPI exception handlers mapping to the error registry |
| Structure check (C-16) | `import-linter` contracts; package-private modules (leading underscore); Django apps as module units |
| Lint, format, types (P-M5) | `ruff check`, `ruff format`; `mypy --strict` or `pyright` strict |
| Tests (P-Q2) | `pytest`, `pytest-asyncio`, `hypothesis` for properties; FastAPI `TestClient` or `httpx.AsyncClient` with ASGI transport; Django test client |
| Data and migrations (P-D1, P-D3) | SQLAlchemy plus Alembic; Django ORM migrations; stdlib `sqlite3` with versioned migration scripts |
| Rate limiting (C-10, B-18) | a dependency or middleware in the app; `slowapi`; at the proxy |
| Dependency audit (C-11) | `pip-audit`; `uv` lockfile plus OSV-Scanner |
| SAST and secrets (P-S23) | `ruff` `S` (bandit) rules; `bandit`; Semgrep; gitleaks |
| Auth (P-S2) | Authlib; framework session middleware; Django auth |

## TypeScript and JavaScript (Node services, React, Vue, Svelte, Next.js, NestJS)

| Concern (controls) | Native options |
| --- | --- |
| Boundary parsing (C-02) | NestJS: `ValidationPipe` with class-validator DTOs; Fastify: route JSON schemas (Ajv); Next.js server actions and route handlers: the schema library already in the repo; clients of the project's own API: types generated from its OpenAPI (`openapi-typescript`, `orval`) plus a contract check; a schema library (zod, valibot, typebox) only if already used or approved |
| Config fail-closed (C-06) | NestJS `ConfigModule` with a validation schema; one `env` module that parses `process.env` at startup; Vite: only `VITE_`-prefixed public values in the client |
| Canonical schema and contract (P-C2) | `@nestjs/swagger` OpenAPI; a shared `contracts` workspace package; server's OpenAPI consumed by generated types |
| Structured logs and errors (C-15) | NestJS `Logger` or `nestjs-pino`; `pino`; framework exception filters or error boundaries |
| Structure check (C-16) | `eslint-plugin-boundaries`, `dependency-cruiser`, `eslint-plugin-import` `no-restricted-paths`; package `exports` maps; Nx or Turbo project boundaries |
| Lint, format, types (P-M5) | ESLint (typescript-eslint) or Biome; Prettier or Biome; `tsc --noEmit` with `strict` |
| Tests (P-Q2) | Vitest or Jest; Testing Library; Playwright for e2e; `@axe-core/playwright` for accessibility; Supertest or the framework's test app for services |
| Server state (W-5) | TanStack Query, SWR, RTK Query, or the framework's loaders, whichever the app uses |
| Data and migrations (P-D3) | Prisma Migrate; Drizzle Kit; TypeORM or Knex migrations |
| Rate limiting (C-10) | `@nestjs/throttler`; `@fastify/rate-limit`; middleware at the edge |
| Budgets (W-15) | a build-output check script; `size-limit`; Lighthouse CI |
| Dependency audit (C-11) | `pnpm audit`, `npm audit`, `yarn npm audit`; OSV-Scanner |
| Dead exports (P-M4) | `knip`; `ts-prune` |

## Go

| Concern | Native options |
| --- | --- |
| Boundary parsing (C-02) | `encoding/json` into typed structs with `DisallowUnknownFields` plus explicit validation; `go-playground/validator` if used |
| Config (C-06) | a typed config struct loaded and validated in `main` |
| Logs (C-15) | `log/slog` with a JSON handler |
| Structure (C-16) | `internal/` packages; `go vet`; `depguard` via golangci-lint |
| Lint and tests | `gofmt`, `go vet`, `staticcheck` or `golangci-lint`; `go test -race` |
| Migrations | `golang-migrate`, `goose` |
| Audit and SAST | `govulncheck`; `gosec` |

## JVM (Java, Kotlin, Spring)

| Concern | Native options |
| --- | --- |
| Boundary parsing (C-02) | Bean Validation (`@Valid`) on DTOs; Jackson with strict deserialisation |
| Config (C-06) | `@ConfigurationProperties` with `@Validated` |
| Logs (C-15) | SLF4J with a JSON encoder |
| Structure (C-16) | ArchUnit tests; Gradle or Maven modules; Spring Modulith |
| Lint and tests | Spotless, Checkstyle or ktlint and detekt, Error Prone; JUnit 5, Testcontainers |
| Migrations | Flyway, Liquibase |
| Resilience (P-C6) | Resilience4j |
| Audit | OWASP Dependency-Check; OSV-Scanner |

## Rust

| Concern | Native options |
| --- | --- |
| Boundary parsing | `serde` with `deny_unknown_fields` plus validation (`validator` if used) |
| Logs | `tracing` with a JSON subscriber |
| Lint and tests | `rustfmt`, `cargo clippy -- -D warnings`, `cargo test` |
| Audit | `cargo audit`, `cargo deny` |

## Mobile

| Concern | Native options |
| --- | --- |
| Swift | `Codable` plus explicit validation; Keychain; SwiftLint; XCTest and XCUITest; `os.Logger` |
| Kotlin / Android | `kotlinx.serialization` or Moshi; EncryptedSharedPreferences or Keystore; ktlint, detekt; JUnit, Espresso, Compose UI tests |
| Flutter | `json_serializable` or `freezed`; `flutter_secure_storage`; `dart analyze`, `flutter test`, integration_test |
| React Native / Expo | the TypeScript rows above; Expo SecureStore; Detox or Maestro for journeys |

## Cross-ecosystem

| Concern | Options |
| --- | --- |
| Secret scanning | gitleaks, trufflehog, the forge's built-in scanning |
| SAST | Semgrep, CodeQL |
| Vulnerabilities across lockfiles and images | OSV-Scanner, Trivy, Grype |
| Dependency updates | Renovate, Dependabot |
| One gate command | `make check`, `just check`, a `scripts/gate` script, or the root `package.json` / `pyproject` task the repo already uses |
| Pre-merge hooks | pre-commit, lefthook, husky (whichever the repo already uses) |
