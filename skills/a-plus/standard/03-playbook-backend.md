# Layer 3 — Backend Playbook

**Status:** Reference v1.1. Stack mechanics for services and APIs. Binds to Layer 1 and 2 controls; adds nothing that weakens them.

## 1. Structure

| Id | Rule |
| --- | --- |
| B-1 | Default to a modular monolith. A new deployable (service, worker, consumer, scheduler) requires an architecture decision record naming the isolation, scaling, ownership or compliance reason **and an accountable owner** (P-M6). |
| B-2 | Layering as roles with inward dependencies: `delivery → application → domain`; adapters implement ports owned by the inner layers. Domain is pure (no I/O, no framework types). Directories MAY collapse for small modules when the dependency direction and policy boundaries survive and a boundary check still enforces them. |
| B-3 | Modules expose a public interface; cross-module imports go through it only; the module graph is acyclic and checked in lint. |
| B-4 | Delivery (controllers, handlers, resolvers) is thin: authenticate, validate against the canonical schema, delegate, map errors through the registry. Business rules in delivery are defects. |
| B-5 | Configuration is a typed schema validated at startup; production requires every secret a live feature needs (C-06). |

## 2. Request lifecycle

| Id | Rule |
| --- | --- |
| B-6 | Every route declares: authentication requirement and audience, authorisation policy, abuse class (C-10), request schema, response schema, error codes, idempotency requirement (C-08) and documentation operation (P-C7). A route-surface test snapshots this and fails on undeclared routes. |
| B-7 | Verified context (tenant, actor, roles, session, client tier) is attached by guards and read only from there (C-03). |
| B-8 | Request ids and trace ids propagate through logs, outbound calls and queues (P-O3). |
| B-9 | Outbound calls carry deadlines, retry budgets and, where failure cascades, breakers (P-C6); clients for third parties live in adapters with their own tests and fakes. |

## 3. Data access

| Id | Rule |
| --- | --- |
| B-10 | Repositories are the only path to the store; they take the verified tenant and scope every statement (P-S8). |
| B-11 | Transactions open at the use case boundary; repositories join; after-commit effects through the outbox (P-D1). |
| B-12 | Contended rows carry a version or take a lock; conflicts map to a typed error (C-09). |
| B-13 | Query performance evidenced by plans and load tests against the endpoint class budget (P-P3). |
| B-14 | Migrations expand → migrate → contract with compatibility code shipped first (P-D3); destructive steps audited. |

## 4. Background work and messaging

| Id | Rule |
| --- | --- |
| B-15 | Jobs are idempotent, bounded in time and size, retry with jittered backoff to a budget, and dead-letter with an alert (P-C8). |
| B-16 | Schedulers run on one elected instance or use leases; no duplicate execution across replicas. |
| B-17 | Consumers verify event schema versions and reject unknown breaking versions explicitly. |

## 5. Security mechanics

| Id | Rule |
| --- | --- |
| B-18 | Rate limiting through one centralised guard with policy classes; verified-subject keys with network backstop; identifier-hashed keys for authentication flows; fail policy per class (closed for auth and money, degraded-local for others) with telemetry. |
| B-19 | Secrets read from the validated config only; no `process.env` or equivalent outside the schema module. |
| B-20 | Webhooks verified by signature in constant time with replay protection (P-S19). |
| B-21 | Proxies trusted by explicit CIDR lists, IPv4 and IPv6 (P-S18). |

## 6. Operability

| Id | Rule |
| --- | --- |
| B-22 | Liveness and readiness endpoints; readiness checks the database, cache and queue the service depends on (P-R4). |
| B-23 | Structured logging with event types; metrics for limits, queues, caches, external calls; detection disposition per new failure mode (P-O2). |
| B-24 | Graceful shutdown drains in-flight requests and jobs within the platform's stop timeout. |

## 7. Tests the backend owes

Unit for every domain rule and mapping; integration against real database and cache for repositories, transactions, outbox and consumers; contract tests against the canonical schema; route-surface and rate-limit coverage tests; cross-tenant negative tests per repository; concurrency and replay tests for C-08/C-09 operations; dependency-failure tests for each degradation ladder row; load tests before scale claims.
