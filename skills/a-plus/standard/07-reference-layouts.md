# Layer 7 — Reference Layouts (FastAPI, Next.js) and Observability

**Status:** Reference v2.1. **Reference, not mandate.** These layouts are distilled from a
working, A+-reviewed modular monolith whose structure is enforced by tests, then
generalised. Use them when a repository has no declared structure yet, when a review asks
"where does this belong", or when a gap needs a concrete target. The framework's
conventions and an existing declared structure win (rule 4, C-16). Never create empty
files or folders to match a tree: a small feature omits the layers it does not use, and a
file becomes a folder of the same name only when it grows.

Names in angle brackets are placeholders: `<package>` is the Python import package (for
example `shop`), `<feature>` a business capability (for example `orders`, `billing`,
`accounts`), never a technical layer.

## 1. Repository layout and shared principles

### 1.1 Repository

```text
<repo>/
├── api/                  # FastAPI service (§2)
├── frontend/             # Next.js app (§3)
├── contracts/            # optional: OpenAPI snapshot or generated client types shared by api and frontend (P-C2)
├── infra/                # optional: compose files, deployment, observability backends (§4.4)
├── docs/                 # profile (docs/standards/a-plus-profile.md), ADRs, runbooks
├── AGENTS.md | CLAUDE.md # ownership lanes: who may change api/, frontend/, root
└── <gate>                # one command that runs both apps' checks (Makefile, justfile, root package.json)
```

A single-app repository keeps the app's own tree at the root. A workspace tool
(pnpm/uv workspaces, Turborepo, Nx) may require a container folder; keep the `api` and
`frontend` names inside it.

### 1.2 Principles

| Id | Rule |
| --- | --- |
| R-1 | **Four zones, inward dependencies.** *Composition* (entrypoint, route assembly, providers) → *features* → *platform* → *shared*. Platform never imports features or composition; shared imports nothing internal; features never import composition. |
| R-2 | **Feature = vertical slice** named after a business capability. It owns its delivery, use cases, domain, data access, schemas and tests. Each layer has one fixed file or folder name across all features. |
| R-3 | **Public interface per feature.** `__init__.py` / `index.ts` re-exports what others may use. Cross-feature imports go through it only (`features.<feature>`, never `features.<feature>.repository`). |
| R-4 | **Declared feature graph.** The allowed feature → feature edges are written in the architecture test; anything else fails. The graph is acyclic. Adding an edge is a design change with a reason. |
| R-5 | **Data layers never import delivery or UI.** Services, repositories, schemas, `data/` and `domain/` never import routers, pages, screens or components. Domain imports no framework and does no I/O. |
| R-6 | **One mechanism per concern, one module** (P-M8): HTTP transport, configuration, logging/telemetry, auth session, storage and cross-cutting types each live in one platform module; a lint rule or test bans the raw primitive elsewhere. |
| R-7 | **Import has no side effects.** Importing the entrypoint creates no runtime, reads no secret, opens no file, socket or connection pool. Runtime is built by a factory and started in the lifespan. |
| R-8 | **Structure is executable.** An architecture test in the normal suite (stdlib AST or a regex import graph; no new dependency needed) asserts: expected files exist, unknown entries fail, zone rules, public-interface rule, declared graph, no cycles, raw-primitive bans. A second test proves the import scanner sees every import form, so the graph has no blind spots. |
| R-9 | **Tests mirror the layout.** Python: `tests/unit/…` and `tests/integration/…` mirror `src/<package>/…`. TypeScript: `*.test.ts(x)` next to the file it tests. Contract snapshots sit with contract tests. |

## 2. FastAPI service (`api/`)

### 2.1 Tree

```text
api/
├── pyproject.toml | uv.lock (or the repo's lockfile) | .env.example | README.md   # README states layout and dependency direction
├── migrations/                      # Alembic or versioned SQL scripts (B-14), also for SQLite
├── src/<package>/
│   ├── __init__.py
│   ├── main.py                      # create_app(settings=None): build dependencies, lifespan, middleware, call register_*; declares no routes
│   ├── asgi.py                      # app = create_app(): the only module that instantiates
│   ├── routes.py                    # register_routes(app, …): include each feature router; then the /api catch-all 404
│   ├── errors.py                    # register_errors(app): the one exception → HTTP map
│   ├── container.py                 # optional: wiring shared by several features (stores, clients)
│   ├── features/
│   │   └── <feature>/
│   │       ├── __init__.py          # public interface (__all__)
│   │       ├── router.py            # create_router(deps) -> APIRouter; thin (B-4)
│   │       ├── schemas.py           # pydantic request/response models (C-02, P-C2)
│   │       ├── service.py           # use cases; transaction boundary (B-11)
│   │       ├── repository.py        # the only path to the store (B-10)
│   │       ├── models.py            # ORM tables, only when an ORM is used
│   │       ├── domain.py            # pure rules and value objects: no fastapi, httpx, database, os
│   │       ├── adapters.py          # clients for external systems behind a protocol the service owns (B-9)
│   │       ├── dependencies.py      # FastAPI Depends providers for this feature
│   │       ├── errors.py            # typed feature errors + their status mapping
│   │       ├── jobs.py              # background work owned by the feature (B-15)
│   │       └── <subdomain>/         # a large feature splits into sub-packages with the same file names
│   ├── platform/                    # never imports features or composition
│   │   ├── config.py                # pydantic-settings Settings: env prefix, SecretStr, validated at startup (C-06, B-19)
│   │   ├── database.py              # engine/session or connection mechanics, transaction helper
│   │   ├── security.py              # authentication dependencies, host/origin and auth middleware
│   │   ├── http_client.py           # the one outbound client: deadlines, retries, request-id propagation
│   │   └── observability/           # §4.1
│   └── shared/                      # pure: wire envelopes, pagination, error body, id and time types
└── tests/
    ├── conftest.py                  # app factory with test settings; temporary stores
    ├── unit/                        # test_architecture.py, features/<feature>/, platform/observability/
    ├── integration/                 # features/<feature>/ against the real store engine; platform/observability/test_http.py
    └── contract/                    # openapi.json snapshot and its check
```

Variants: a feature with one or two endpoints may be `router.py` + `service.py` only. A
`platform/` module grows into a folder of the same name (`platform/database/`) when it needs
several files. Django and other frameworks keep their own module unit (`03-playbook-service.md` §1).

### 2.2 Rules

| Id | Rule |
| --- | --- |
| R-F1 | `main.py` composes; it declares no route (test: no `@<x>.get/post/put/patch/delete/api_route` decorator in `main.py`). Features expose `create_router(deps)` factories that receive dependencies explicitly, not module globals. |
| R-F2 | Run the factory (`uvicorn <package>.main:create_app --factory`) or `<package>.asgi:app`. A test imports `<package>.main` in a subprocess with a temporary runtime directory and asserts nothing was created and no connection opened (R-7). |
| R-F3 | `routes.py` includes feature routers, then an `/api/{path:path}` catch-all returning 404 (or 405 for known paths), then any static fallback, so unknown API paths never return the frontend's HTML. |
| R-F4 | `errors.py` is the only exception → HTTP map: validation → 422, store unavailable → 503, feature errors through the feature's status mapping, `Exception` → 500. Bodies carry a stable code and generic `detail`, never `str(exc)`; each handler emits a vocabulary event (§4); error responses are `no-store`. |
| R-F5 | Schemas and ORM models are feature-owned; there is no global `models.py` or `schemas.py`. `shared/` holds only types that are cross-cutting by nature; feature types never move there to save an import. |
| R-F6 | `service.py`, `repository.py`, `schemas.py` and `domain.py` never import a router; `domain.py` imports no framework or I/O module. Modules that must stay light (domain, jobs) have a subprocess test asserting importing them does not load `fastapi` or the telemetry SDK. |
| R-F7 | Optional or legacy surfaces (compatibility shims, experimental routers) live in a named sub-package that production composition does not import unless a setting enables it; a test enforces it. |

### 2.3 Architecture test (stdlib only)

```python
# tests/unit/test_architecture.py
SOURCE = Path(__file__).resolve().parents[2] / "src" / "<package>"
COMPOSITION = {"main", "asgi", "routes", "errors", "container"}

def local_imports(path):  # ast.walk Import/ImportFrom; resolve relative ones with importlib.util.resolve_name
    ...

def test_dependencies_point_inward_and_cross_features_use_public_interfaces():
    for path in SOURCE.rglob("*.py"):
        zone = path.relative_to(SOURCE).parts[0]
        for dep in local_imports(path):
            # platform -> features or composition: violation
            # shared -> anything inside <package>: violation
            # features -> composition: violation
            # features.<other>.<module> (deeper than the public package): violation
            # service/repository/schemas/domain -> *.router: violation
    # then DFS the feature -> feature edges against ALLOWED and fail on a cycle
```

Pair it with `ruff check`, `ruff format --check` and a strict type checker. `import-linter`
is an alternative only if already locked; the AST test meets C-16 without a dependency.

## 3. Next.js app (`frontend/`, App Router)

The reference client was a React SPA; the same slice rules map onto Next.js with its file
routing and server/client boundary added. **Vite or another SPA:** keep `features/` and
`platform/`, make `app/` the shell (router config, providers, error boundary), and drop
`server.ts`, `server/`, `instrumentation*.ts` and `middleware.ts`.

### 3.1 Tree

```text
frontend/
├── package.json | next.config.ts | tsconfig.json (strict) | eslint.config.js | budget.json
├── scripts/                         # gate checks, each with a test: check-budget, check-bundle-secrets (and check-sw for a PWA)
├── public/                          # static assets; manifest and sw.js for a PWA (W-23)
├── e2e/                             # Playwright journeys and accessibility checks
└── src/
    ├── instrumentation.ts           # server telemetry register() and onRequestError (§4.2)
    ├── instrumentation-client.ts    # browser global error logging (§4.2)
    ├── middleware.ts                # request id, security headers and CSP (W-12); no business logic
    ├── architecture.test.ts         # R-8
    ├── app/                         # routing only (W-1)
    │   ├── layout.tsx | providers.tsx | not-found.tsx | global-error.tsx
    │   ├── (<group>)/<route>/page.tsx | loading.tsx | error.tsx      # renders a feature screen
    │   └── api/<path>/route.ts      # route handler: parse → feature server.ts → map errors
    ├── features/
    │   └── <feature>/
    │       ├── index.ts             # client-safe public interface: screens, components, hooks
    │       ├── server.ts            # server-only public interface (`import "server-only"`)
    │       ├── data/                # queries.ts, mutations.ts, keys.ts, schemas.ts (parsers), types.ts
    │       ├── server/              # actions.ts ("use server"), service.ts, repository.ts: server-only
    │       ├── domain/              # pure rules, mappers, error mapper (W-8)
    │       ├── components/          # feature UI pieces
    │       └── screens/             # what a page renders
    └── platform/                    # never imports features or app
        ├── http.ts                  # the one transport: base URL, credentials, deadlines, Retry-After, ApiError{status, code, requestId}
        ├── query.ts                 # data-fetching client and key conventions (W-5)
        ├── env.ts                   # server env parsed once ("server-only"); env.client.ts: NEXT_PUBLIC_* only
        ├── auth.ts                  # session read/clear; logout clears caches (W-7)
        ├── log.ts                   # allow-listed browser events (§4.2)
        ├── observability/           # server logger and request context ("server-only")
        ├── types.ts                 # cross-cutting types only (envelope, error body)
        └── ui/                      # design-system primitives, error boundary, designed states (W-9, W-21)
```

If the repo already uses another convention for shared UI (for example shadcn's
`components/ui`), that location is the binding; keep it free of feature imports.

### 3.2 Rules

| Id | Rule |
| --- | --- |
| R-N1 | `app/` holds routing, metadata, layout and boundary files only. A `page.tsx` imports a feature's `index.ts` (or `server.ts` in a server component) and renders its screen; a `route.ts` or server action delegates to `server.ts`. Business rules in `app/` are defects (B-4, W-1). |
| R-N2 | Two public interfaces per feature: `index.ts` (client-safe) and `server.ts` (`import "server-only"`). `server/` is reachable only through `server.ts`; client components never import it; the build fails on violation (W-3). |
| R-N3 | A feature folder allows only `index.ts`, `server.ts`, `data`, `server`, `domain`, `components`, `screens` and root-level tests; the architecture test fails on anything else and on a feature without `index.ts`. |
| R-N4 | Endpoint paths appear only in `data/`, `server/` and `platform/http.ts`. `fetch`, `XMLHttpRequest`, `WebSocket`, `EventSource` and `navigator.sendBeacon` are banned by `no-restricted-globals` / `no-restricted-properties` outside `platform/http.ts` (W-4). |
| R-N5 | `process.env` is read only in `platform/env.ts` (server) and `env.client.ts` (`NEXT_PUBLIC_*`), parsed at startup (C-06, B-19). A bundle scan in the gate fails on secret patterns without printing the match. |
| R-N6 | Lint for C-02 and C-15: no type assertions outside tests (parse, don't assert), `no-explicit-any`, `no-non-null-assertion`, no empty `catch` (even with only a comment), `no-floating-promises`, `no-misused-promises`. A lint-rules test proves each rule fires. |
| R-N7 | The architecture test builds the import graph (static, type, side-effect, re-export, dynamic and `new URL(…, import.meta.url)`) and asserts: layout, no cycles, platform purity, public-interface rule, `app` → features only via `index.ts` / `server.ts`, data layers never import UI, the declared feature graph, and single-module bans for any primitive the profile names. |
| R-N8 | `platform/types.ts` exports only cross-cutting types; domain types stay in their feature (the test asserts the exported names). |

## 4. Observability reference

Binds C-15, P-O1–P-O7, B-8, B-22–B-24, W-10, W-13. Require observable behaviour and
verifiable evidence, not a vendor stack. Default foundation: the language's logging module
with JSON output, plus the OpenTelemetry API/SDK when tracing or metrics apply.

### 4.1 FastAPI: `api/src/<package>/platform/observability/`

| Module | Responsibility |
| --- | --- |
| `__init__.py` | The facade features import: `emit(event, **fields)`, `operation(name, dependency=None)` context manager, `@observed(name)`, `outbound_headers()` for propagation. Features never import OpenTelemetry or a vendor SDK. |
| `events.py` | **Finite vocabulary:** `EVENTS`, `OPERATIONS`, `OUTCOMES`, `REASONS` as frozensets, and `safe_fields()` that drops unknown keys and out-of-vocabulary values before anything is queued. Validates inbound request ids. |
| `context.py` | `contextvars` for request id and runtime; a helper that carries context into background tasks; never holds auth objects or payloads. |
| `setup.py` | App-owned runtime: providers created by the factory (no globals at import), resource attributes `service.name`, `service.version`, `service.instance.id`, metric instruments, idempotent start/stop from the lifespan, shutdown with flush deadlines. |
| `middleware.py` | Outermost pure-ASGI middleware (so it also sees security denials and 500s): accept one valid inbound `X-Request-Id` or mint one, echo it on every response, root span, `http.completed` / `http.failed` with route **template**, method, status and duration. Unmatched paths get a fixed label such as `__unmatched__`. |
| `logging.py` | JSON records with UTC timestamp, severity, event code, service identity, request and trace ids. Bounded queue and one writer to stdout (`deployed`) or a rotated private file (`local-process`). Library loggers (uvicorn, httpx, the SDK) are routed through the same allow-list. |
| `metrics.py`, `tracing.py` | SDK instruments with explicit histogram buckets and bounded attribute keys; sampling (ratio, always for critical operations); OTLP exporter only when a destination exists. |
| `safety.py` | Wraps every SDK and sink call: a failure increments a drop counter and never fails the request or logs the original exception. |
| `health.py` | `/health/live` (process only) and `/health/ready` (bounded, read-only checks of required stores and feature checks; 503 on failure). |
| `sentry.py` | Optional; allow-list scrubbing, PII off, release tagged (P-O4). |

Tests in `tests/unit/platform/observability/`: a fixture secret passed in every field never
reaches a sink; a full queue drops and counts without raising; metric attributes stay in
the vocabulary; start and stop twice are safe; import creates no runtime. In
`tests/integration/platform/observability/`: request id echoed on success, 401 and 500;
invalid inbound id replaced; `traceparent` and request id reach a mocked downstream call;
readiness returns 503 when a required store fails.

### 4.2 Next.js: `frontend/src/`

| Location | Responsibility |
| --- | --- |
| `instrumentation.ts` | `register()` initialises server telemetry once per runtime (OpenTelemetry through the package already locked, or one approved per the ladder); `onRequestError` emits a structured event with route template and error digest, never the message or request body. |
| `middleware.ts` | Validate or mint `x-request-id`, pass it to route handlers and upstream calls, echo it on the response. |
| `platform/observability/` | Server-only JSON logger to stdout (pino if locked, otherwise a small JSON writer) with the same vocabulary and allow-list as §4.1; request context through `AsyncLocalStorage`. |
| `platform/log.ts` | Browser `logEvent(code, fields)` keeping only allow-listed keys (`error_name`, `status`, `code`, `request_id`), truncated; `errorFields(err)` returns name, status and request id, never the message; `installGlobalErrorLogging()` for `error` and `unhandledrejection`, called from `instrumentation-client.ts`. Without a server sink, browser events are a recorded gap. |
| `app/error.tsx`, `app/global-error.tsx` | User-facing copy with the request id or digest as support reference; log through `logEvent` (W-10). |
| `platform/http.ts` | `ApiError` carries the response's `X-Request-Id`, so a browser failure correlates with the API log (P-O3). |

### 4.3 Rules (both stacks)

| Id | Rule |
| --- | --- |
| R-O1 | **Vocabulary, not free text.** Events, operations, outcomes and reasons are finite sets in one module; unknown values never enter the pipeline. Event names are stable codes (`http.failed`, `dependency.degraded`, `job.failed`). |
| R-O2 | **Allow-list fields** (C-05): no credentials, cookies, auth headers, query strings, bodies, prompts, user content or exception messages in logs, spans or browser events; tested with a fixture secret on success, error and unexpected-exception paths. |
| R-O3 | **Correlation:** validate inbound request ids, mint when absent or invalid, echo on every response, propagate with `traceparent` to downstream calls and queued jobs; ids are never authorisation. |
| R-O4 | **Cardinality:** metric labels are route templates, methods, status classes, operation and outcome names, never raw URLs or user, entity, request or trace ids. |
| R-O5 | **Telemetry never breaks the product:** bounded queues, timeouts, flush deadlines; drops and sink errors are counted and visible in metrics or health diagnostics. |
| R-O6 | **Lifecycle:** nothing at import; setup and teardown idempotent under reload, tests and multiple workers; no duplicate spans or double-counted metrics when auto-instrumentation is also enabled. |
| R-O7 | **Audit is separate:** logs and sampled traces are diagnostic; audit records (approvals, money, permission changes) keep their own durable store and access control. |
| R-O8 | **Streams and jobs** (where they exist): record open, time to first event, disconnect, cancellation and cleanup for streams; start, outcome, duration and retries for jobs, separately from request duration. |
| R-O9 | **Health semantics:** liveness = process responsive; readiness = required dependencies within a deadline; optional upstream outages are degraded capabilities, not not-ready. |
| R-O10 | **Honest destination** (P-O1): `local-process` → rotated local file plus a runbook to find a request by id; `deployed` → a verified backend. Telemetry is not integrated until a query against the destination is shown. |

### 4.4 Infrastructure (only when deploying backends)

```text
infra/observability/
├── otel-collector.yaml      # receive OTLP, filter, batch, export
├── prometheus.yml           # or an OTLP-compatible metrics backend
├── grafana/{dashboards,provisioning}/
├── loki.yaml                # logs: stdout needs an explicit shipper; it does not reach the Collector by itself
└── tempo.yaml               # traces
```

Phases: **1 local foundation** (JSON logs, correlation, redaction, health, SDK with no-op or
local exporters, tests for privacy, drops and lifecycle) → **2 production baseline**
(verified destination, retention and access policy, dashboards, actionable alerts with
runbooks, pipeline self-monitoring) → **3 advanced** (SLIs and SLOs per P-O5, sampling and
cost tuning, profiling, incident drills).

## 5. Review checklist

- [ ] The declared structure exists and an executable test enforces it (R-8, C-16).
- [ ] Composition holds no routes or business logic; each feature has one public interface (two in Next.js).
- [ ] Platform and shared import nothing above them; data layers import no delivery or UI; the feature graph is declared and acyclic.
- [ ] One module per concern (transport, env/config, logging, auth session) with a lint or test ban on the raw primitive elsewhere.
- [ ] Importing the entrypoint creates no runtime, files or connections.
- [ ] Logs are JSON with UTC timestamp, severity, event code, service identity and request id; a fixture secret never reaches a sink.
- [ ] The request id is echoed on every response, including denials and 500s, and appears in browser error events.
- [ ] Metric labels are bounded; a telemetry outage does not fail requests; drops are visible.
- [ ] Liveness and readiness are tested with dependency failures.
- [ ] The telemetry destination is stated honestly and verified by a query.
