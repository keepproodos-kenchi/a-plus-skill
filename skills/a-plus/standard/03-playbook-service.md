# Layer 3 — Service Playbook

**Status:** Reference v2.0. Applies when `roles` includes `service`: any process that answers
requests (HTTP, gRPC, GraphQL, RPC, server-rendered pages' server side) and the workers it
owns. Binds to Layer 1 and 2 controls; adds nothing that weakens them. Rows without an
"Applies when" apply to every service.

## 1. Structure

| Id | Applies when | Rule |
| --- | --- | --- |
| B-1 | | Default to a modular monolith. A new deployable (service, worker, consumer, scheduler) requires an ADR naming the isolation, scaling, ownership or compliance reason and an accountable owner (P-M6). |
| B-2 | | Layering as roles with inward dependencies: `delivery → application → domain`; adapters implement ports owned by inner layers. Domain is pure (no I/O, no framework types). Directories MAY collapse for small modules when the dependency direction survives and a boundary check enforces it (C-16). |
| B-3 | | Modules expose a public interface; cross-module imports go through it only; the module graph is acyclic and checked. |
| B-4 | | Delivery (controllers, routers, handlers, resolvers) is thin: authenticate, validate against the canonical schema, delegate, map errors through the registry. Business rules in delivery are defects. |
| B-5 | | Configuration is a typed schema validated at startup; production requires every secret a live feature needs (C-06). |

**Where the roles live, by framework.** Use the framework's own unit of modularity; do not
import another ecosystem's layout. These are the usual mappings, not mandates:

| Framework | Module unit | Delivery | Application | Domain | Adapters / data |
| --- | --- | --- | --- | --- | --- |
| FastAPI | package per feature under the app package | `APIRouter` + pydantic request/response models | service functions or classes | plain dataclasses or pydantic models without I/O | repository modules, `httpx` clients |
| Django | Django app | views, DRF serializers | services module | models' pure methods or a domain module | ORM managers, querysets |
| NestJS | Nest module | controllers, DTOs, guards, pipes | providers (use cases) | plain TS classes and functions | repositories (Prisma, TypeORM), clients |
| Express, Fastify, Hono | folder per feature | route plugin, schema | service | domain folder | repository, client |
| Go | package per feature under `internal/` | `http.Handler`s | service type | domain package | store and client packages |
| Spring | package or module per feature | `@RestController` | `@Service` | entities without persistence logic, value objects | `@Repository`, clients |

A complete FastAPI tree (composition, `features/`, `platform/`, `shared/`), its enforcing
architecture test and the `platform/observability/` module layout are in
`07-reference-layouts.md` §2 and §4.1.

## 2. Request lifecycle

| Id | Applies when | Rule |
| --- | --- | --- |
| B-6 | | Every route declares: authentication requirement and audience, authorisation policy, abuse class when `exposed` (C-10), request schema, response schema, error codes, idempotency requirement (C-08) and documentation operation (P-C7). A route-surface test enumerates the routes and fails on an undeclared one. |
| B-7 | `authenticated` | Verified context (tenant, actor, roles, session, client tier) is attached by guards or dependencies and read only from there (C-03). |
| B-8 | | Request ids propagate through logs, outbound calls and queues; trace ids where traced (P-O3). |
| B-9 | outbound calls | Deadlines, retry budgets and, where failure cascades, breakers (P-C6); third-party clients live in adapters with their own tests and fakes. |

## 3. Data access

| Id | Applies when | Rule |
| --- | --- | --- |
| B-10 | `persistent-data` | Repositories are the only path to the store; with `multi-tenant` they take the verified tenant and scope every statement (P-S8). |
| B-11 | `persistent-data` | Transactions open at the use-case boundary; repositories join; after-commit effects through an outbox or hook (P-D1). |
| B-12 | C-09 applies | Contended rows carry a version or take a lock; conflicts map to a typed error. |
| B-13 | queries on a request path | Query performance evidenced against the endpoint budget (P-P3). |
| B-14 | schema migrations | Expand → migrate → contract (P-D3); destructive steps audited. Embedded stores (SQLite and similar) use versioned migrations too, never ad-hoc `CREATE IF NOT EXISTS` drift. |

## 4. Background work and messaging

| Id | Applies when | Rule |
| --- | --- | --- |
| B-15 | `async` | Jobs are idempotent, bounded in time and size, retry with jittered backoff to a budget, and dead-letter or record failure visibly. |
| B-16 | schedulers with more than one instance possible | One elected instance or leases; no duplicate execution across replicas. |
| B-17 | consumers of events | Consumers verify schema versions and reject unknown breaking versions explicitly. |

## 5. Security mechanics

| Id | Applies when | Rule |
| --- | --- | --- |
| B-18 | `exposed` | Rate limiting through one centralised guard with policy classes; verified-subject keys with network backstop; identifier-hashed keys for authentication flows; fail closed for auth and money, degraded-local for others, with telemetry. |
| B-19 | | Secrets and environment read only through the configuration schema module; no `os.environ`, `process.env` or equivalent elsewhere, enforced by lint or search in the gate. |
| B-20 | inbound webhooks | Signature verified in constant time with replay protection (P-S19). |
| B-21 | behind a proxy | Proxies trusted by explicit CIDR lists, IPv4 and IPv6 (P-S18). |
| B-25 | `exposure = local` | Bind to loopback by default; refuse to start on a non-loopback bind unless the configuration explicitly declares the wider exposure and the controls it requires are enabled. Validate `Host` and `Origin` to block DNS rebinding. |

## 6. Operability

| Id | Applies when | Rule |
| --- | --- | --- |
| B-22 | | Liveness and readiness endpoints; readiness checks the stores and services the process depends on and reports partial states honestly (P-R4). |
| B-23 | | Structured logging with event types; metrics or counters for limits, queues, caches and external calls (P-O7); detection disposition per new failure mode (P-O2). Rules R-O1–R-O10 in `07-reference-layouts.md` §4 show one complete binding. |
| B-24 | | Graceful shutdown drains in-flight requests and jobs within the platform's stop timeout. |

## 7. Tests the service owes

Unit for every domain rule and mapping; integration against the real store engine for
repositories, transactions, outbox and consumers; contract tests against the canonical
schema; route-surface test, plus rate-limit coverage when `exposed`; authorisation negative
tests per route class, plus cross-tenant tests per repository when `multi-tenant`;
concurrency and replay tests for C-08/C-09 operations; dependency-failure tests for each
degradation ladder row; load tests before scale claims.
