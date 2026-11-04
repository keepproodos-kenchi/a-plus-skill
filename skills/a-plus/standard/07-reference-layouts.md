# Layer 7 — Reference Layouts (FastAPI, Next.js) and Observability

**Status:** Reference v2.3. Distilled from a working, A+-reviewed modular monolith whose
structure is enforced by tests, then generalised.

## 0. How to use this layer

**Strict about properties, flexible about paths.** A+ requires correct ownership, dependency
direction, runtime isolation, security boundaries and verification. It does not require a
particular folder name, depth or file template. Each rule below is marked:

- **MUST**: an architectural invariant; a violation is a finding (C-16, B-2, B-3, W-1–W-3).
- **SHOULD**: the recommended default; a documented alternative with the same properties passes.
- **MAY**: optional; its absence is never a finding.

| Id | Rule |
| --- | --- |
| R-0a | **Reference, not mandate.** The trees are examples. Reviewers MUST assess properties (responsibilities, imports, runtime and security boundaries, testability, operability), not exact names. A repository's declared structure (profile §4) wins over these trees (rule 4, C-16). |
| R-0b | **No migration without a demonstrated problem.** Do not recommend renaming or moving files in a passing application unless it fixes a verified defect; any move preserves public import paths, startup, tests, migrations and has a rollback. |
| R-0c | **No empty scaffolding.** A missing optional file or folder is never a finding. Create a layer only when it has a real responsibility. |
| R-0d | **Classify every structure finding** (05 §5 `Class`): *verified defect* (evidence shows a broken invariant), *risk requiring evidence* (name the check that would settle it), *optional improvement*, or *acceptable alternative* (record it in the profile, not as a finding). |

Placeholders: `<package>` is the Python import package (for example `shop`); `<feature>` a
business capability (`orders`, `billing`), never a technical layer; `<namespace>` an optional
grouping of related features (`commerce`, `governance`).

## 1. Repository layout and shared invariants

### 1.1 Repository

```text
<repo>/
├── api/                  # FastAPI service (§2)
├── frontend/             # Next.js app (§3)
├── contracts/            # MAY: OpenAPI snapshot or generated client types shared by both (P-C2)
├── infra/                # MAY: deployment and observability configuration (§4.5)
├── docs/                 # profile (docs/standards/a-plus-profile.md), ADRs, runbooks
├── AGENTS.md | CLAUDE.md # ownership lanes: who may change api/, frontend/, root
└── <gate>                # one command that runs both apps' checks (Makefile, justfile, root package.json)
```

**Accepted alternatives (all pass review):** `apps/<name>/` (for example `apps/api`,
`apps/web`, `apps/worker`) when a workspace tool expects it or there are several deployables,
with `packages/` for code that has more than one declared consumer; `backend/`, `services/<name>/`
or a domain-specific name; a single-app repository whose root is the app. Names come from the
repository's convention; identity comes from `pyproject.toml` / `package.json`.

**`src/` is a source root, never the application name.** In Python, `src/<package>/` gives a
stable import namespace (`<package>.features…`). In Next.js, `src/` holds `app/` (the App
Router: routes, layouts, boundaries) beside `features/`, `platform/`, `shared/`; there is no
directory named after the application inside `src/`.

**Checks (SHOULD, when the layout changes):** the Python package imports from outside the
repository working directory; Next.js resolves its `src/app` routes; workspace build and test
commands pass; entrypoints and deploy paths are unchanged; cross-package imports use declared
dependencies, not relative filesystem paths.

**Deployment ownership (SHOULD).** For the paired FastAPI + Next.js example, FastAPI owns
business rules, authoritative database writes and transactions. Next.js owns presentation,
browser state and session-aware server calls to FastAPI. Its server layer does not duplicate
repositories or authoritative decisions for the same data. Frontend domain rules support UI
and drafts; the backend validates authoritative operations independently. A standalone Next.js
backend MAY own persistence. When ownership is split across deployables, document each
capability's authoritative writer and transaction boundary in the profile (R-2).

### 1.2 Invariants shared by both stacks

| Id | Level | Rule |
| --- | --- | --- |
| R-1 | MUST | **Zones and direction.** *Composition* (entrypoint, route assembly, providers) → *features* → *platform* → *shared*. Composition wires features and adapters. Platform never imports features or composition; shared imports nothing internal; features never import composition. |
| R-2 | MUST | **Ownership.** Every state transition, API contract, persistence model and integration has one owning feature. Internal repositories and models are not shared APIs. |
| R-3 | MUST | **Explicit public contracts.** Cross-feature imports use the feature's documented public module only. Python: lightweight `public.py` / `contracts.py` or safe `__init__.py` exports; composition may import the documented `router.py` entrypoint. TypeScript: client-safe `index.ts`, server-only `server.ts`, and optional public `actions.ts` for callable Server Actions (§3.1). A barrel is a means, not a requirement. |
| R-4 | MUST | **Acyclic graph.** No cycles among features (or namespaced features), checked on the actual import graph. The allowed feature → feature edges SHOULD be declared in the check, so a new edge is a reviewed design change. |
| R-5 | MUST | **Domain independence.** Domain rules import no HTTP framework, database session or telemetry SDK and do no I/O. Data layers never import delivery or UI. |
| R-6 | SHOULD | **Ports only where they pay.** Application code depends on an abstraction (protocol / interface) when it isolates a consequential infrastructure choice (a database, an external provider, a queue). Trivial operations do not get interfaces; no one-file-per-pattern mandates. |
| R-7 | MUST | **Hierarchical features.** `features/<feature>/` and `features/<namespace>/<feature>/` are both valid; a cohesive bounded context MAY also have internal sub-modules. A namespace organises code; it grants siblings no access to each other's internals. Prefer at most one namespace level; deeper nesting needs a stated reason. |
| R-8 | MUST | **One mechanism per concern** (P-M8): HTTP transport, configuration, logging/telemetry, auth session, storage each live in one platform module (which MAY have separate client/server entrypoints); a lint rule or test bans the raw primitive elsewhere. |
| R-9 | MUST | **Import does not acquire runtime resources.** Importing application modules opens no file, socket or pool, starts no worker and initialises no telemetry exporter. Inert application and route construction is allowed. Python factories assemble the app; lifespan acquires and releases resources. Next.js uses its framework lifecycle entrypoints; application configuration follows R-N5. |
| R-10 | MUST | **Checked by a tested checker.** Boundary and cycle rules run in the normal suite or lint. Choose the checker by the ladder: a tool the repository already uses → a stdlib AST (Python) or compiler-resolved (TypeScript) test → a dedicated tool (`import-linter`, `dependency-cruiser`, `eslint-plugin-boundaries`) with approval. The checker MUST resolve the repository's import forms (relative, absolute, path aliases such as `@/`, re-exports, dynamic imports) and have negative fixtures proving it catches a deep import, a cycle and a server→client leak. Imports it cannot resolve (computed `import()` or `importlib` targets) are reported, never silently skipped. |
| R-11 | SHOULD | **Tests have clear ownership.** Python: `tests/{unit,integration}/…` mirror `src/<package>/…`; TypeScript: `*.test.ts(x)` next to the file or in the owning feature's `__tests__/`, following the repository's convention. Keep browser journeys in the app's `e2e/`. A directory allowlist MAY enforce this; responsibilities and imports are what MUST be enforced. |

## 2. FastAPI service

### 2.1 Tree (illustrative)

```text
api/
├── pyproject.toml | <lockfile> | .env.example | README.md
├── migrations/                       # app-wide versioned migration history (B-14)
├── src/<package>/
│   ├── __init__.py                   # lightweight; no runtime initialization
│   ├── main.py                       # create_app(): assemble application; no business routes
│   ├── lifespan.py                   # acquire and release runtime resources
│   ├── asgi.py                       # MAY: app = create_app(), inert construction only
│   ├── api/                          # HTTP composition
│   │   ├── router.py                 # include feature routers
│   │   ├── dependencies.py           # application-level dependency wiring
│   │   └── errors.py                 # exception → HTTP response mapping
│   ├── features/
│   │   ├── cart/                     # example <feature>; create only the parts needed
│   │   │   ├── __init__.py           # empty or lightweight; no eager router exports
│   │   │   ├── public.py             # MAY: contracts consumed by other features
│   │   │   ├── router.py             # endpoints and HTTP dependencies; thin (B-4)
│   │   │   ├── schemas.py            # request/response validation (C-02, P-C2)
│   │   │   ├── service.py            # use cases and transaction coordination (B-11)
│   │   │   ├── domain.py             # MAY: pure business rules and value types
│   │   │   ├── errors.py             # MAY: feature errors independent of HTTP
│   │   │   ├── repository.py         # MAY: feature queries and persistence
│   │   │   ├── models.py             # MAY: ORM models, when an ORM is used
│   │   │   ├── adapters.py           # MAY: external integrations
│   │   │   └── dependencies.py | jobs.py | <module>/   # MAY: feature wiring, jobs, sub-modules
│   │   └── <namespace>/<feature>/    # MAY: namespaced features (R-7)
│   ├── platform/                     # never imports features or composition
│   │   ├── config.py                 # settings validated at startup
│   │   ├── database.py               # engine, session and transaction mechanics
│   │   ├── http.py                   # outbound transport: deadlines, request-id propagation
│   │   ├── security/                 # identity verification and auth mechanisms
│   │   └── observability/            # §4.1
│   └── shared/                       # pure cross-cutting types
└── tests/
    ├── conftest.py
    ├── architecture/
    │   └── test_boundaries.py
    ├── unit/features/cart/
    │   ├── test_domain.py
    │   └── test_service.py
    ├── integration/features/cart/
    │   ├── test_repository.py        # against the real store engine
    │   └── test_router.py
    └── contract/
        └── test_openapi.py           # MAY: contract snapshot/check
```

Python package markers are omitted from some directories for readability. Unit and integration
tests also cover platform modules when present. Existing root composition files (`routes.py`,
`errors.py`, `container.py`) remain valid. Lifespan may stay in `main.py` when small. A module
such as `domain.py`, `repository.py` or `database.py` becomes a package only when there are
several cohesive responsibilities to organize. Django and other frameworks keep their own
module unit (`03-playbook-service.md` §1).

**Feature placement guide (SHOULD).** `public.py` serves other features; `router.py` serves
application composition. Keep public business contracts and package initializers free of eager
router imports: Python executes parent initializers even when importing a domain submodule.
A public service export is appropriate only if it preserves these import boundaries.

`service.py` owns the use case and transaction boundary; repositories execute persistence
operations within that boundary. `schemas.py` describes HTTP contracts; `domain.py` describes
business concepts. Separate their types where responsibilities differ, without mechanically
duplicating every shape. `platform/security/` supplies identity verification and common auth
mechanisms; feature-specific authorization belongs with the protected use case.

### 2.2 Rules

| Id | Level | Rule |
| --- | --- | --- |
| R-F1 | MUST | Composition declares no business routes; features expose a documented router entrypoint. `APIRouter` with FastAPI `Depends` or `create_router(deps)` are valid; inject runtime dependencies rather than capturing live sessions or clients in module globals. |
| R-F2 | MUST | Run the factory (`uvicorn <package>.main:create_app --factory`) or `uvicorn <package>.asgi:app`. Fresh-process checks import each supported entrypoint and assert no external resources are acquired (R-9); lifespan tests verify startup and cleanup, including startup failure. Inert ASGI application construction is allowed. |
| R-F3 | MUST | One exception → HTTP map (`api/errors.py` or `errors.py`): validation → 422, store unavailable → 503, feature errors via the feature's mapping, `Exception` → 500. Bodies carry a stable code and generic message, never `str(exc)`; each handler emits a vocabulary event (§4); error responses are `no-store`. |
| R-F4 | MUST | Schemas and ORM models are feature-owned; no global `models.py` / `schemas.py`. `shared/` holds only types that are cross-cutting by nature. |
| R-F5 | MUST | `service`, `repository`, `schemas` and `domain` never import a router. Modules that must stay light (domain, jobs) have a subprocess test asserting importing them does not load `fastapi` or the telemetry SDK. |
| R-F6 | SHOULD | Optional or legacy surfaces (compatibility shims, experimental routers) live in a named sub-package that production composition imports only behind a setting. |
| R-F7 | MAY | **Catch-all only when hosting needs it.** When the API also serves the frontend (static fallback on the same origin), register an `/api/{path:path}` 404 before the fallback so unknown API paths never return HTML. Otherwise FastAPI's default 404 is enough. |

### 2.3 Architecture test (stdlib, when no checker exists yet)

```python
# tests/architecture/test_boundaries.py
SOURCE = Path(__file__).resolve().parents[2] / "src" / "<package>"

def local_imports(path):
    # ast.walk Import/ImportFrom; resolve relative ones with importlib.util.resolve_name;
    # report importlib.import_module / __import__ calls with non-literal targets (R-10)
    ...

def public_unit(module):
    # "features.<f>" or "features.<ns>.<f>": the deepest existing package under features/ that
    # has declared public entrypoints; other modules are internal (R-3, R-7)
    # allow composition -> router entrypoints without exposing routers to sibling features
    ...

def test_dependencies_point_inward_and_cross_features_use_public_interfaces(): ...
def test_feature_graph_is_declared_and_acyclic(): ...
def test_checker_catches_known_violations(tmp_path):
    # negative fixtures: deep cross-feature import, cycle, platform -> feature (R-10)
    ...
```

Pair it with `ruff check`, `ruff format --check` and a strict type checker. Where
`import-linter` is already locked, its `layers`, `independence` and `forbidden` contracts meet
R-1, R-4 and R-5 directly.

## 3. Next.js app (App Router)

**Version first (MUST).** Read the installed `next` version from the lockfile before choosing
conventions, and record it in the profile. Next.js 16 and later: request interception is
`src/proxy.ts` (Node.js runtime); earlier versions use `src/middleware.ts` (Edge by
default; Node.js support is stable from 15.5, experimental in 15.2). Node-only imports are
forbidden when the selected runtime is Edge. `instrumentation-client.ts` needs 15.3 or later;
`onRequestError` in `instrumentation.ts` needs 15 or later. **Vite or another SPA:** keep
`features/`, `platform/`, `shared/`; `app/` becomes the shell (router, providers, error
boundary); drop the server-only parts.

### 3.1 Tree (illustrative; starts at `frontend/` or the app root)

```text
frontend/
├── package.json | <lockfile> | next.config.ts | tsconfig.json (strict) | eslint.config.js
├── .env.example | README.md | budget.json
├── scripts/                         # gate checks with tests: check-budget, check-bundle-secrets
├── public/                          # static assets; manifest and sw.js for a PWA (W-23)
├── e2e/                             # Playwright journeys and accessibility checks
│   └── checkout.spec.ts
├── tests/architecture/
│   └── boundaries.test.ts
└── src/                             # source root (not the app name)
    ├── app/                         # App Router: routes, layouts, boundaries only
    │   ├── layout.tsx | providers.tsx | not-found.tsx | global-error.tsx
    │   ├── (shop)/cart/
    │   │   ├── page.tsx
    │   │   ├── loading.tsx
    │   │   └── error.tsx
    │   └── api/<path>/route.ts       # MAY: route handlers
    ├── instrumentation.ts           # server telemetry (§4.2)
    ├── instrumentation-client.ts    # MAY: browser error logging, version permitting
    ├── proxy.ts                     # MAY: request id, headers, redirects (middleware.ts before Next 16)
    ├── features/
    │   ├── cart/                    # example <feature>; create only the parts needed
    │   │   ├── index.ts             # client-safe public interface
    │   │   ├── server.ts            # MAY: server-only public interface (`import "server-only"`)
    │   │   ├── actions.ts           # MAY: public "use server" actions; async functions only
    │   │   ├── api/                 # feature API adapter (data/ is an accepted convention)
    │   │   │   ├── cart.api.ts       # browser-facing API adapter
    │   │   │   └── cart.dto.ts       # MAY: wire types/parsers; reuse generated contracts
    │   │   ├── domain/              # pure business rules and domain types; no I/O
    │   │   │   ├── cart.types.ts
    │   │   │   ├── cart-conflict.ts
    │   │   │   ├── cart-error.ts
    │   │   │   ├── has-foreign-line.ts
    │   │   │   └── snapshots.ts
    │   │   ├── hooks/               # React state and workflow orchestration
    │   │   │   └── useCart.ts
    │   │   ├── components/          # feature-owned UI
    │   │   │   ├── AddToCartButton.tsx
    │   │   │   ├── CartConflictNotice.tsx
    │   │   │   ├── CartRow.tsx
    │   │   │   └── RemoveItemDialog.tsx
    │   │   ├── screens/             # feature entry UI composed by app routes
    │   │   │   ├── CartScreen.tsx    # server-rendered feature composition
    │   │   │   └── CartClient.tsx    # MAY: interactive "use client" boundary
    │   │   ├── storage/             # MAY: feature draft format and persistence policy
    │   │   │   └── draft-cart-storage.ts
    │   │   ├── server/              # MAY: server-side feature orchestration
    │   │   │   └── cart.service.ts   # session-aware FastAPI calls and mapping
    │   │   └── __tests__/           # or colocated *.test.ts(x), per repo convention
    │   │       ├── cart-conflict.test.ts
    │   │       ├── cart-error.test.ts
    │   │       ├── cart-service.test.ts
    │   │       ├── cart-client.test.tsx
    │   │       ├── draft-cart-storage.test.ts
    │   │       ├── has-foreign-line.test.ts
    │   │       ├── remote-checkout-journey.test.tsx
    │   │       ├── remove-item-dialog.test.tsx
    │   │       ├── snapshots.test.ts
    │   │       └── use-cart.test.tsx
    │   └── <namespace>/<feature>/   # MAY: namespaced features (R-7)
    ├── platform/                    # never imports features or app
    │   ├── http/                    # one transport concern, runtime-specific entrypoints
    │   │   ├── client.ts            # browser transport
    │   │   ├── server.ts            # server-only transport and credential handling
    │   │   └── errors.ts            # ApiError{status, code, requestId}
    │   ├── env.server.ts            # server-only validated application configuration
    │   ├── env.client.ts            # NEXT_PUBLIC_* only
    │   ├── storage/                 # MAY: browser storage mechanism
    │   ├── auth/                    # session read/clear
    │   ├── observability/           # §4.2: server/, client/, shared/ when it grows
    │   ├── analytics/               # MAY: product analytics (§4.3)
    │   └── ui/                      # design-system primitives, error boundary, designed states
    └── shared/                      # MAY: pure cross-cutting types and helpers
```

An existing UI convention (for example shadcn's `components/ui`) is the binding; keep it free
of feature imports.

**Feature placement guide (SHOULD).** The cart is an example of ownership, not a required
template. Keep small features small (R-0c); use the repository's file naming convention.
Use `.tsx` only for files containing JSX; a hook without JSX uses `.ts`.

| Location | Responsibility and boundary |
| --- | --- |
| `index.ts`, `server.ts`, `actions.ts` | Export only contracts consumers need; see the entrypoint table below. Internal modules import each other directly rather than their own barrel. Keep server-only exports out of `index.ts` (R-N2). |
| `api/` or `data/` | Own browser endpoint calls through `platform/http/client`, wire DTOs, response parsing and mapping. Reuse generated API contract types when available instead of maintaining duplicate DTOs. Query keys, queries and mutations belong here when used. Choose the repo's existing name; split transport from query orchestration only when they have distinct responsibilities. |
| `domain/` | Own business types, conflict/error rules and pure transformations. A snapshot belongs here only if creating it is pure; reading or writing it belongs in an adapter. Domain types stay here; wire DTOs stay with the API adapter. |
| `hooks/` | Coordinate domain rules, API/query state and local drafts for React consumers. Keep business decisions in `domain/`; hooks do not call transport or browser storage primitives directly. |
| `components/`, `screens/` | Components render feature UI; screens assemble the feature workflow for a route. Server screens use server services; interactive components use client hooks. Export server screens through `server.ts`; keep `"use client"` at the interactive boundary. Routes remain in `app/` (R-N1). |
| `storage/` | Own draft serialization, versioning, validation and recovery policy. Delegate browser storage access to the single `platform` storage module (R-8); keep browser access out of module initialization and server execution. This is separate from a server database repository. |
| `server/` | Own session-aware API calls and server orchestration in the paired deployment (§1.1), using `platform/http/server`. Mark modules `server-only` and expose needed contracts through `server.ts`. Add a repository only when Next.js owns that persistence; do not duplicate FastAPI-owned writes. |
| `__tests__/` | Keep feature unit, component and integration tests here, or colocate them beside source files. `remote-checkout-journey.test.tsx` is a component/integration journey; a real-browser checkout journey belongs in `e2e/`. Tests may import their own feature's internals; other features still use public contracts. |

**Public entrypoints (SHOULD):**

| Entrypoint | Consumers | Exports |
| --- | --- | --- |
| `index.ts` | Client or server consumers | Client-safe components, types and pure helpers; client hooks only used by client consumers |
| `server.ts` | Server Components and server modules | Server screens and services; marked `import "server-only"` |
| `actions.ts` | Client or server consumers | Optional callable Server Actions; file-level `"use server"`, async function exports only |

Server Actions delegate to server-only services, validate untrusted inputs and authorize the
operation on the server. A Client Component may import the public action module or receive an
action as a prop from a Server Component. It must not import `server.ts` to reach an action.
`"use server"` defines a callable boundary; it does not make arbitrary server modules safe to
expose. Choose actions or browser API calls per workflow; do not automatically implement both.

**Dependency direction:** Server Component → server service/API adapter → platform server
transport; Client Component → hook → browser API/storage adapter → platform client mechanisms.
Server screens can compose interactive Client Components. Domain imports no UI, React,
adapters or platform I/O; UI and adapters may use domain rules. API, storage and server
persistence modules never import UI or client hooks. Cross-feature dependencies still follow
R-3 and R-4, including in tests.

Use server rendering for initial data where appropriate; neither two screen files nor both
runtime paths are mandatory. An existing single `platform/http.ts` remains valid when it
preserves runtime isolation. With separate entrypoints, share pure error contracts and common
policy while keeping server credentials and browser-only dependencies in their own modules.

### 3.2 Rules

| Id | Level | Rule |
| --- | --- | --- |
| R-N1 | MUST | `app/` composes: a `page.tsx` renders a feature's screen through its public module; a `route.ts` or server action delegates to the feature's server interface. Business rules in `app/` are defects (B-4, W-1). |
| R-N2 | MUST | **Runtime isolation.** Server-only code (`import "server-only"`) never reaches a client bundle; Node-only modules never reach an Edge runtime; the build fails on violation (W-3). Keep ordinary server-only exports out of client-safe `index.ts`; expose them through `server.ts`. Public `actions.ts` is a distinct framework-mediated callable boundary (§3.1), not an ordinary client import of server implementation code. |
| R-N3 | SHOULD | Feature folders use the declared layer names; an allowlist test MAY enforce them. Missing layers are fine (R-0c). |
| R-N4 | MUST | Endpoint paths appear only in the API/data or server layers and the platform transport; raw `fetch`, `XMLHttpRequest`, `WebSocket`, `EventSource`, `navigator.sendBeacon` are banned outside the transport by `no-restricted-globals` / `no-restricted-properties` (W-4). |
| R-N5 | MUST | Application environment reads live in `platform/env.server.ts` (or the existing `env.ts`) and `env.client.ts` (`NEXT_PUBLIC_*` only), validated at the appropriate server startup or client build boundary (C-06, B-19). Framework selectors such as `process.env.NEXT_RUNTIME` are allowed in `instrumentation.ts`; build configuration reads stay in documented build entrypoints. These exceptions do not permit application secrets in client modules. A bundle scan in the gate fails on secret patterns without printing the match. |
| R-N6 | MUST | Lint for C-02 and C-15: no type assertions outside tests, `no-explicit-any`, `no-non-null-assertion`, no empty `catch`, `no-floating-promises`, `no-misused-promises`; a lint-rules test proves each fires. |
| R-N7 | MUST | The boundary check (R-10) resolves `tsconfig` path aliases (`@/…`) as well as relative, type, side-effect, re-export, dynamic and `new URL(…, import.meta.url)` imports, and asserts: no cycles, platform purity, public-interface rule, `app` → features only via public modules, data layers never import UI, the declared feature graph, and server-only versus callable action boundaries. When actions are used, include a positive fixture for a valid client-to-action call alongside negative server-only import fixtures. A regex scanner that only follows relative paths does not meet this rule. |
| R-N8 | MUST | Feature flags never replace server-side authorisation. |

## 4. Observability reference

Binds C-15, P-O1–P-O7, B-8, B-22–B-24, W-10, W-13. Require correlated, privacy-safe,
actionable telemetry with a verified destination; never a particular vendor.

| Signal | FastAPI | Next.js | Contract |
| --- | --- | --- | --- |
| Logs | `logging` + JSON formatter | pino (or the logger already used) on the Node server | structured, allow-listed, correlated; stdout by default, rotated file for `local-process` |
| Traces | OpenTelemetry Python | OpenTelemetry JS via `instrumentation.ts` | context across HTTP calls and async work |
| Metrics | OpenTelemetry (or Prometheus-compatible if already used) | OpenTelemetry-compatible | rate, errors, latency, critical workflows; bounded attributes |
| Collection | MAY: OpenTelemetry Collector | MAY: OpenTelemetry Collector | bounded, non-blocking export to a configured destination |
| Errors | MAY: Sentry | MAY: Sentry or the analytics tool's error tracking | one primary exception pipeline unless duplication is justified |
| Product analytics | usually none | MAY (§4.3) | consent and privacy controls; separate from operational telemetry |

### 4.1 FastAPI: `platform/observability/`

| Module | Responsibility |
| --- | --- |
| `__init__.py` | The facade features import: `emit(event, **fields)`, `operation(name)` context manager, `@observed(name)`, outbound propagation headers. Features never import a telemetry SDK. |
| `events.py` | Finite vocabulary (`EVENTS`, `OPERATIONS`, `OUTCOMES`, `REASONS`) and `safe_fields()` that drops unknown keys and values before anything is queued; inbound request-id validation. |
| `context.py` | `contextvars` for request id and runtime; context carried into background tasks; never auth objects or payloads. |
| `setup.py` | App-owned providers (no globals at import), resource attributes `service.name/version/instance.id`, idempotent start/stop from the lifespan, flush deadlines. |
| `middleware.py` | Outermost pure-ASGI middleware (sees security denials and 500s): accept one valid `X-Request-Id` or mint one, echo it on every response, root span, `http.completed` / `http.failed` with the route **template**; unmatched paths get a fixed label. |
| `logging.py` | JSON records (UTC timestamp, severity, event code, service identity, request and trace ids) through a bounded queue and one writer; library loggers routed through the same allow-list. |
| `metrics.py`, `tracing.py` | Explicit histogram buckets, bounded attribute keys, sampling; OTLP export only with a destination. |
| `safety.py` | Wraps SDK and sink calls: failures count as drops and never fail the request or log the original exception. |
| `health.py` | Liveness (process only) and readiness (bounded, read-only checks of required dependencies; 503 on failure). |

Tests: a fixture secret in every field never reaches a sink; a full queue drops and counts
without raising; attributes stay in the vocabulary; start/stop twice is safe; request id
echoed on success, 401 and 500; invalid inbound id replaced; `traceparent` reaches a mocked
downstream call; readiness 503 when a required store fails; stream cancellation cleans up.

### 4.2 Next.js

| Location | Responsibility |
| --- | --- |
| `instrumentation.ts` | `register()` initialises server telemetry once per runtime, branching on `process.env.NEXT_RUNTIME` so Node-only SDKs never load on Edge; `onRequestError` emits a structured event with route template and digest, never the message or body. |
| `proxy.ts` / `middleware.ts` | Validate or mint `x-request-id`, forward it, echo it on the response. |
| `platform/observability/server/` | Server-only JSON logger, the §4.1 vocabulary and allow-list, request context through `AsyncLocalStorage`. |
| `platform/observability/client/` | `logEvent(code, fields)` with allow-listed keys (`error_name`, `status`, `code`, `request_id`), `errorFields(err)` that never returns the message, global `error` / `unhandledrejection` listeners installed from `instrumentation-client.ts`. Without a server sink, browser events are a recorded gap. |
| `app/error.tsx`, `app/global-error.tsx` | User-facing copy with the request id or digest as support reference (W-10). |
| `platform/http/errors.ts` (or existing `http.ts`) | `ApiError` carries the response's `X-Request-Id`, correlating browser failures with server logs (P-O3). |

### 4.3 Product analytics (MAY)

Behavioural analytics (for example PostHog) is not operational telemetry. When used, it lives
in `platform/analytics/` (`client.ts`, `server.ts`, `events.ts` vocabulary, `privacy.ts`
consent and scrubbing, `feature-flags.ts`), separate from `platform/observability/`; features
call its facade, never the SDK. Consent gates collection where P-S/C-05 require it; flags
never authorise (R-N8). Adding a vendor follows the ladder and needs approval.

### 4.4 Rules (both stacks)

| Id | Level | Rule |
| --- | --- | --- |
| R-O1 | MUST | **Vocabulary, not free text.** Events, operations, outcomes, reasons are finite sets in one module; unknown values never enter the pipeline. |
| R-O2 | MUST | **Allow-list fields** (C-05): no credentials, cookies, auth headers, query strings, bodies, prompts, user content or exception messages in logs, spans or browser events; tested with a fixture secret on success, error and unexpected-exception paths. |
| R-O3 | MUST | **Correlation:** validate inbound request ids, mint when absent or invalid, echo on every response, propagate `traceparent` to downstream calls and queued work; ids never authorise. |
| R-O4 | MUST | **Cardinality:** metric labels are route templates, methods, status classes, operation and outcome names, never raw URLs or user, entity, request or trace ids. |
| R-O5 | MUST | **Failure isolation:** bounded queues, timeouts and flush deadlines; telemetry failure never fails a request; drops and sink errors are visible. |
| R-O6 | MUST | **Lifecycle:** no telemetry initialization at import; idempotent setup and teardown under reload, tests and multiple workers; no duplicate spans, handlers or double-counted metrics alongside auto-instrumentation. |
| R-O7 | MUST | **Audit is separate:** logs and sampled traces are diagnostic; approvals, money and permission changes keep their own durable records. |
| R-O8 | SHOULD | **Streams and jobs:** record open, first event, disconnect, cancellation and cleanup for streams; start, outcome, duration and retries for jobs. |
| R-O9 | MUST | **Health semantics:** liveness = process responsive; readiness = required dependencies within a deadline; optional upstreams are degraded, not not-ready. |
| R-O10 | MUST | **Honest destination** (P-O1): telemetry is integrated only when a query against the configured destination is shown; actionable alerts exist where P-O2 requires them. |

### 4.5 Infrastructure (only when deploying backends)

```text
infra/observability/
├── otel-collector.yaml      # receive OTLP, filter, batch, export
├── prometheus.yml           # or an OTLP-compatible metrics backend
├── grafana/{dashboards,provisioning}/
├── loki.yaml                # logs need an explicit shipper from stdout
└── tempo.yaml               # traces
```

Phases: **1 local foundation** (JSON logs, correlation, redaction, health, privacy/drop/lifecycle
tests) → **2 production baseline** (verified destination, retention and access policy,
dashboards, actionable alerts with runbooks, pipeline self-monitoring) → **3 advanced** (SLIs
and SLOs per P-O5, sampling and cost tuning, profiling, incident drills).

## 5. Review checklist

- [ ] Findings are classified (R-0d); no finding cites a folder name alone; acceptable alternatives are recorded in the profile.
- [ ] Zones, ownership and public contracts hold (R-1–R-3); flat and namespaced features both accepted (R-7).
- [ ] The feature graph is acyclic and declared; the checker resolves the repository's import forms and has negative fixtures (R-4, R-10, R-N7).
- [ ] Domain is framework- and I/O-free; ports exist only where they isolate a consequential choice (R-5, R-6).
- [ ] Importing supported entrypoints acquires no runtime resources; lifespan cleanup is checked; Next.js ordinary server-only/client/Edge boundaries fail the build when crossed and valid action calls pass (R-9, R-N2).
- [ ] Authoritative persistence ownership is declared across deployables (§1.1); Python package initializers preserve domain isolation.
- [ ] Next.js conventions match the installed version (§3); server screens, client interaction and callable actions have explicit entrypoints.
- [ ] One module per concern with a ban on the raw primitive elsewhere (R-8).
- [ ] Logs are JSON, allow-listed and correlated; request id echoed on every response and present in browser error events; one primary error pipeline.
- [ ] Metric labels bounded; telemetry outage does not fail requests; drops visible; liveness and readiness tested with dependency failures.
- [ ] The telemetry destination is stated honestly and verified by a query.

## 6. Framework references

Check these against the installed versions when applying the examples:

- [FastAPI application composition](https://fastapi.tiangolo.com/tutorial/bigger-applications/)
  and [lifespan](https://fastapi.tiangolo.com/advanced/events/).
- [Python package initialization](https://docs.python.org/3/reference/import.html#regular-packages).
- [Next.js Server and Client Components](https://nextjs.org/docs/app/getting-started/server-and-client-components)
  and [Server Functions](https://nextjs.org/docs/app/api-reference/directives/use-server).
- [Next.js instrumentation](https://nextjs.org/docs/app/api-reference/file-conventions/instrumentation)
  and [Proxy version history](https://nextjs.org/docs/app/api-reference/file-conventions/proxy#version-history).
