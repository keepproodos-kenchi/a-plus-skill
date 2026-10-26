# Layer 2 — Context, Risk and Quality Policies

**Status:** Reference standard v2.0, adopted through a project profile.  
**Date:** 2026-10-26  
**Depends on:** [Layer 1 Constitution](./01-constitution.md). Nothing here weakens a C-control.

## 1. System context

The profile (Layer 4 §1) declares these facts once, with the evidence for each. Every control
in Layers 1–3 states its applicability with them. Unknown is not a value: an unknown fact is
recorded as the stricter value until it is settled.

| Fact | Values | Evidence that settles it |
| --- | --- | --- |
| `roles` | any of `service`, `web`, `mobile`, `library`, `cli`, `pipeline`, `ai` | manifests, entry points |
| `users` | `single-owner` · `multi-user` · `multi-tenant` | product requirement, data model |
| `auth` | `none` · `owner-session` · `user-accounts` · `external-idp` · `machine` (any combination) | auth module, middleware |
| `exposure` | `local` (loopback or offline only) · `private` (network or VPN-restricted) · `public` | bind address, ingress, deployment config |
| `delivery` | `local-process` · `server-deploy` · `app-store` · `package-registry` | deploy or publish workflow |
| `personal-data` | `yes` · `no` | data model, inputs collected |
| `money` | `yes` · `no` | payment, pricing or billing code |
| `regulated` | `none` or the regimes (for example GDPR, HIPAA, PCI DSS, SOC 2) | contracts, market |
| `persistent-data` | `yes` · `no` (and whether it is recreatable) | stores, files, volumes |
| `async` | `yes` · `no` (queues, jobs, schedulers, streams, webhooks in) | worker and scheduler code |
| `integrations` | outbound third parties, inbound webhooks, model providers | adapters, config |
| `locales` | `one` · `many` | product requirement |
| `availability` | `best-effort` · `slo` (an availability or latency promise exists) | agreements, product requirement |
| `team` | `solo` · `team` | contributors |

**Shorthands used in "Applies when":** `exposed` = `exposure ≠ local`; `multi-user+` =
`users ≠ single-owner`; `deployed` = `delivery ≠ local-process`; `ui` = `roles` includes
`web` or `mobile`; `authenticated` = `auth ≠ none`; `always` = every system.

**Target context.** The profile MAY also declare the context the system is heading to, with a
date or trigger. Gates use the current context. Designs and reviews flag any choice that would
make a target-context control expensive to add (for example hard-coding a single owner id
into the data layer when `multi-user` is the target).

**Context changes.** Changing a fact is a High-tier change: the profile is updated first, the
newly applicable controls are listed, and each becomes either met or a dated known gap before
the context change ships. Exposing a loopback system to a network is the common case.

## 2. Risk classification

Every change is classified before work starts. The highest matching row applies.

| Tier | Triggers | Mandatory extras |
| --- | --- | --- |
| **Critical** | Authentication, authorisation, tenancy boundary, money movement, cryptography, destructive migration, production access, availability of a critical journey, personal-data deletion or export, a context change that widens exposure or users | Threat model (P-S24), independent review (P-S25), replay and concurrency tests where the change touches C-08/C-09 operations, rollback or containment plan, deployment through the artefact gate (C-14) |
| **High** | New endpoint, event, job or tool callable by a model; schema change; permission change; new dependency with network or filesystem access; new third-party processor; change to limits or budgets; any other context change | Threat model, negative tests, impact analysis, detection disposition (P-O2) |
| **Medium** | Any behaviour change not classified above, new UI state, new background job | Red-before-green test, observable failure modes (C-15) |
| **Low** | Documentation, copy, presentation or refactor **proven** behaviour-preserving by the existing test suite | Static evidence only; any behaviour change re-classifies to Medium or above |

**Conformance.** A control applies when its "Applies when" predicate is true for the current
context. Every applicable Layer 1 control is MUST. Every applicable Layer 2 and Layer 3 control
is MUST for its tier; rows marked **P1** are SHOULD for Low-tier changes and MUST otherwise. A
"not applicable" disposition names the context fact that makes it so; a disposition without a
fact is invalid. Where a control names a test class (P-Q2) the class is owed only where the
risk it addresses is present.

## 3. Assessment model

Three axes, reported separately. A roll-up label MAY be derived; it MUST NOT be assigned
directly, and an agent MUST NOT assign one. "A+" is the derived label for: code quality
"meets bar", every verification dimension that applies "pass", release readiness "ready".

| Axis | Values | Meaning |
| --- | --- | --- |
| **Code quality** | meets bar · gaps · fails P0 · unassessed | Does the code satisfy the controls applicable to its context and tier? "Unassessed" when no reviewer has checked the evidence. |
| **Verification confidence** | per evidence dimension: pass · fail · missing · stale | Dimensions: static analysis (format, lint, typecheck, boundary check, SAST, dependency audit); executable tests (unit, integration, contract, e2e, accessibility, concurrency); environment reached (local · ephemeral CI · preview/staging · production-like); independent review (present or absent). Stale = evidence predates the current diff digest. |
| **Release readiness** | ready · blocked (blockers named) | Operability controls present, migration safety, rollout and rollback written, exceptions unexpired, advisories dispositioned, artefact gate satisfied. |

**Merge eligibility:** code quality "meets bar", or "gaps" where every gap is dispositioned:
an unmet SHOULD carries an owned follow-up with a date; an unmet MUST carries an approved,
unexpired exception (§16); a non-waivable control (P-Z2) always blocks. "Unassessed" and
"fails P0" do not merge. Static analysis and the applicable tests pass; independent review
present for Critical; evidence bound to the diff digest.  
**Release eligibility** additionally: environment reached is the highest the delivery allows
(`deployed`: ≥ preview/staging; `local-process`: a clean build from the committed tree run by
the gate); user-facing journeys and accessibility green there when `ui`; integration and
contract evidence green there otherwise; release readiness "ready".

## 4. Evidence rules

| Id | Control |
| --- | --- |
| P-E1 | Evidence is bound to the diff digest or artefact digest it was produced from. A material change to the diff invalidates affected evidence and approvals. |
| P-E2 | Evidence records the exact commands, exit codes, environment, commit and digest, and the location of artefacts (logs, reports, screenshots). |
| P-E3 | Freshness: static and test evidence from the final diff; environment evidence from an artefact built from the final diff; review evidence from the final diff. |
| P-E4 | Partial work is reported as partial. "Should pass" is not evidence. |

## 5. Security policies

Baseline OWASP ASVS Level 2 when `exposed`; Level 3 for money, administration and
personal-data export. A `local` system still meets the input, output, secrets and supply-chain
rows: local tools read untrusted files, repositories and model output.

### 5.1 Authentication and sessions

| Id | Applies when | Control |
| --- | --- | --- |
| P-S1 | the system verifies passwords | Argon2id or bcrypt at current cost, breached-password check, identifier-keyed and IP-keyed login limits, constant-time comparison, no user enumeration by response or timing. |
| P-S2 | OAuth or OIDC is used | Per RFC 9700 and RFC 8252: authorization-code flow only; PKCE S256 for all clients; transaction binding through `state` and PKCE; exact redirect-URI matching; issuer, audience, signature, expiry and (OIDC) nonce validated; native apps use the system browser; confidential clients authenticate with an approved method. Prefer a maintained library already in the stack over hand-rolled flows. |
| P-S3 | `authenticated` and sessions or tokens outlive one request | Revocation is an outcome: effective within N seconds (profile-defined) for all affected tokens, sessions and caches, with the maximum exposure window tested. Logout invalidates server-side state. Refresh tokens rotate with reuse detection. |
| P-S4 | browser sessions | Cookies `HttpOnly`, `Secure`, `SameSite` from validated config, scoped path and domain. A credential readable by script is permitted only with an architecture note and an enforced CSP. |
| P-S5 | administrative, money-moving or data-export actions exist and `multi-user+` | Step-up or multi-factor authentication; recovery flows identifier-keyed and rate-limited. |
| P-S6 | native apps whose threat model needs client trust | Client attestation with trust tiers that scale limits; failure degrades, never silently passes. |
| P-S26 | a development or bootstrap login exists | It is bound to loopback, refuses any non-local request or forwarded header, is disabled by configuration in production, and has a test proving each refusal. |

### 5.2 Authorisation and tenancy

| Id | Applies when | Control |
| --- | --- | --- |
| P-S7 | roles or permissions exist | Permissions are data with deny by default, evaluated by one engine, not by branches scattered across handlers. |
| P-S8 | `multi-tenant` | Tenant scoping in the data layer: every query carries the verified tenant through row-level security or a scoped repository that is the only access path; cross-tenant not-found is indistinguishable from not-found; a cross-tenant negative test exists per repository. |
| P-S9 | non-public objects | Object access checks ownership on every request (C-04). Capability URLs need their own policy: entropy, expiry, scope, revocation, logging. |
| P-S10 | `deployed` with administrative or production access | Administrative and break-glass access is just-in-time, logged, reviewed and time-boxed. |

### 5.3 Input, output and transport

| Id | Applies when | Control |
| --- | --- | --- |
| P-S11 | always | All input bounded: length, size, count, depth, numeric range, character set, content type; pagination and fan-out bounded. |
| P-S12 | output reaches a renderer, shell, document or model | Output encoded by context; templates auto-escape; raw HTML sinks require a sanitiser and review. |
| P-S13 | always | Parameterised queries and safe client APIs only; no string-built SQL, NoSQL, LDAP, XPath or shell; no `eval` of untrusted data. |
| P-S14 | the system fetches URLs or paths derived from input | Outbound requests validated against scheme and host allow-lists; private ranges and metadata endpoints blocked; redirects not followed blindly. File paths resolved and confined to an allow-listed root with traversal and symlink-escape tests. |
| P-S15 | uploads | Type and size allow-list client- and server-side; content sniffed, re-encoded or scanned; stored outside the web root; count limits applied atomically. |
| P-S16 | `web` | Security headers in code or proven at the edge: CSP with an explicit source list (report-only only as a dated rollout phase), HSTS when served over TLS, `X-Content-Type-Options`, frame-ancestors, `Referrer-Policy`, `Permissions-Policy`; fingerprint headers off. |
| P-S17 | browser sessions with state-changing requests | CSRF: same-site cookies plus a synchroniser or double-submit token, or a verified `Origin`/`Host` check, with tests. |
| P-S18 | the service runs behind a proxy | Trusted proxies are explicit CIDRs (IPv4 and IPv6); client IP read from forwarded headers only behind them, right-to-left; otherwise the socket address. Host header allow-listed. |
| P-S19 | inbound webhooks or callbacks | Signature verified in constant time, timestamp window, replay store, idempotent processing. |

### 5.4 Cryptography, secrets and supply chain

| Id | Applies when | Control |
| --- | --- | --- |
| P-S20 | any cryptographic or security-relevant random value | Vetted primitives from the platform library only (AES-GCM or ChaCha20-Poly1305; SHA-256 or better; HMAC; Argon2id or bcrypt; Ed25519 or ECDSA P-256); CSPRNG for every security-relevant random value; no custom cryptography. |
| P-S21 | always | Secrets never in code, images, logs or the client; loaded through the configuration schema; `deployed`: held in a secret manager and rotated on schedule and on incident. |
| P-S22 | always | Dependencies pinned with a committed lockfile per ecosystem; provenance reviewed on add; vulnerability scan in the gate; `deployed` or `package-registry`: SBOM per release and license policy enforced. |
| P-S23 | `deployed` or `team` | Protected branches, required reviews, secret scanning and SAST in CI; reproducible builds and signed artefacts where the delivery supports them (C-14). |
| P-S24 | Critical and High changes | Threat model: assets, actors, entry points, abuse cases, mitigations, written before coding and attached to the change. |
| P-S25 | Critical changes | Independent review: the reviewer is not the author and took no part in the authoring session; for `team = solo` a separate agent session given only the diff and evidence qualifies. |

## 6. Privacy and data protection

| Id | Applies when | Control |
| --- | --- | --- |
| P-V1 | `personal-data` | Data classification on every stored field drives encryption, logging, retention and access. |
| P-V2 | `personal-data` | Minimisation: collect only what a documented purpose needs; derived data inherits the strictest source classification. |
| P-V3 | `persistent-data` with restricted or personal data, or `exposed` | TLS 1.2+ in transit when traffic leaves the host; encryption at rest for restricted and personal data; field-level encryption for secrets and payment data. |
| P-V4 | `personal-data` | Retention and deletion tested across primary store, backups, caches, search indexes, analytics and logs; deleted data does not resurrect from a restore. |
| P-V5 | `personal-data` and `multi-user+` | Subject rights (access, export, erasure) are auditable workflows. |
| P-V6 | `personal-data` | Logs and analytics carry pseudonymous ids only. |
| P-V7 | third-party processors receive data (including model providers) | Processors inventoried with data categories, region, contract and transfer basis. |

## 7. API, contracts and compatibility

| Id | Applies when | Control |
| --- | --- | --- |
| P-C1 | `service` | One error envelope: stable machine code, status, message authored once in a registry, request id; no stack traces or internals. |
| P-C2 | two components exchange data (client and server, producer and consumer, library and caller) | One canonical schema defines every request, response, event and error shape; the other side derives from it (shared package, generated types or clients) and CI checks compatibility. Use the schema the server framework already produces (for example FastAPI or NestJS OpenAPI) before introducing another. |
| P-C3 | consumers can run an older version than the producer | Additive by default; breaking changes behind a new version with deprecation window, usage telemetry and removal date; mobile clients get a minimum supported version and forced-upgrade path. |
| P-C4 | list endpoints | Bounded page size, opaque cursors, filter and sort allow-lists. |
| P-C5 | C-08 applies with the key strategy | Operations accept an idempotency key, store the outcome and reject reuse with a different payload; natural idempotence records its proof instead. |
| P-C6 | outbound calls | Every outbound call has a deadline and a retry budget (which MAY be zero); retries only for replay-safe operations with jittered backoff; circuit breakers where a failure can cascade or exhaust shared pools. |
| P-C7 | `service` or `library` | Every route, event and public API has generated documentation checked in CI; disabled public docs in production are a deployment choice, not missing documentation. |
| P-C8 | `async` with events or messages | Events are schema-versioned; consumers idempotent; at-least-once delivery handled; dead letters alerted. |

## 8. Data integrity

| Id | Applies when | Control |
| --- | --- | --- |
| P-D1 | `persistent-data` | One transaction per use case opened by the outermost caller; repositories join; after-commit effects go through an outbox or explicit after-commit hook. |
| P-D2 | `persistent-data` with a database | Constraints exist in the database as well as in code. |
| P-D3 | schema migrations | Expand → migrate → contract; code compatible with both shapes ships first; destructive steps have a backfill, rollback or documented forward-fix and an audit entry. A migration tool already in the stack is used. |
| P-D4 | caches | Personalised caches keyed by tenant and actor; invalidation defined with the write; public and client-side caches (including service workers) never hold credentials or private data unless designed and documented. |
| P-D5 | changes to money, permissions, personal data, configuration, or owner decisions | Audit trail: who, what, when, from where, before and after; automated writers labelled; append-only. |
| P-D6 | `persistent-data` not recreatable | Backups automated and encrypted where data is sensitive; RPO and RTO declared; restore drilled and timed. |

## 9. Reliability

| Id | Applies when | Control |
| --- | --- | --- |
| P-R1 | `availability = slo` | SLOs for critical journeys and service boundaries with error budgets; paging on budget burn. |
| P-R2 | the system depends on another process or service | Degradation ladder per dependency: what still works when it is down; security fails closed; reads degrade visibly (never shown as fresh or zero). |
| P-R3 | `service` or `async` | Bounded pools, queues and concurrency per dependency; load shedding before collapse. |
| P-R4 | `service` or long-running workers | Liveness distinct from readiness; readiness checks real dependencies; graceful shutdown drains. |
| P-R5 | a scale claim is made | Production-shaped load evidence establishes saturation and headroom before the claim. |
| P-R6 | `availability = slo` or `team` | Runbooks per failure mode, on-call ownership, post-incident reviews with tracked actions. `best-effort` solo systems keep a recovery note per failure mode instead. |

## 10. Observability

| Id | Applies when | Control |
| --- | --- | --- |
| P-O1 | always | Structured logs with event type, severity, request or run id, trace id where traced, and pseudonymous actor ids; never payloads or secrets. `deployed`: logs and client errors ship to a telemetry backend. `local-process`: logs persist to a rotated local file. |
| P-O2 | always | Every new failure mode has an observable signal and a **detection disposition** in the change: an existing alert, a new actionable alert (owner, severity, response), or diagnostic-only with rationale. |
| P-O3 | more than one process, or a client and a server | Correlation propagates across processes, queues and clients; the client mints a request id, the server echoes it; distributed tracing where `deployed` with several services. |
| P-O4 | error tracking is used | Scrubbed by allow-list, default PII collection off, releases tagged, source maps private. |
| P-O5 | `availability = slo` | Dashboards per service and per critical journey. |
| P-O6 | always | No silent catch: rethrow, map to a typed outcome, or log with the error code (C-15). |
| P-O7 | `service` | Health and metrics for the things that fail: request rate, error rate, latency, queue depth, external-call outcomes, limiter decisions. |

## 11. Performance and efficiency (P1)

| Id | Applies when | Control |
| --- | --- | --- |
| P-P1 | always | Budgets that matter for the roles (client bundle, cold start, p95 latency per endpoint class, memory, run time, cost) are declared in the profile with method and date and enforced in the gate. A budget changes only by a measured, approved decision. An agent MUST NOT change a budget on its own initiative (X-3). |
| P-P2 | `ui` | Heavy or rare modules load lazily; motion respects reduced-motion preferences. |
| P-P3 | `persistent-data` with queries on a request path | Query performance proven by representative plans and load evidence against the budget; indexes justified by that evidence. |
| P-P4 | clients poll | Named intervals, capped exponential backoff, stop conditions, pause on `429` until `Retry-After`, pause when hidden; push preferred when fan-out justifies it. |
| P-P5 | `service` | Background work bounded, cancellable and off the request path. |

## 12. Accessibility and localisation (P1)

| Id | Applies when | Control |
| --- | --- | --- |
| P-L1 | `ui` | WCAG 2.2 AA. Automated checks (zero serious or critical) on primary screens; `multi-user+` or `public`: human keyboard and screen-reader evidence on primary journeys per release. |
| P-L2 | `ui` | Every user-facing string externalised; `locales = many`: key parity enforced, longest-locale growth tested, locale-aware dates, numbers and currencies, machine-drafted copy reviewed by a native reader. |
| P-L3 | `ui` | Design tokens only; no second visual language. |

## 13. Testing

| Id | Applies when | Control |
| --- | --- | --- |
| P-Q1 | always | **Traceability:** every test names the invariant, boundary or failure mode it pins; every Critical and High control in the change has a test or an explicit evidence substitute. |
| P-Q2 | always | Classes by risk, each owed only where its risk exists: unit for domain rules, parsers and mappings; component tests for every designed state; integration against real infrastructure (or the same engine, for example SQLite to SQLite) for repositories, transactions and consumers; contract tests both sides; end-to-end for critical journeys; accessibility automation on primary screens; concurrency and replay tests for C-08/C-09; security tests for authn, authz, tenancy, injection, traversal and replay; load tests before scale claims; dependency-failure tests for degradation ladders. |
| P-Q3 | always | Red before green (C-12) with the failing run recorded. |
| P-Q4 | always | Mocks are partial and never replace the behaviour under test; clock, randomness and network injected; assertions on outcomes. |
| P-Q5 | always | Changed tests explained; accepting a defect, deleting coverage without replacement or making a failing gate optional is prohibited. |
| P-Q6 | always | Flaky tests quarantined with owner and deadline; never retried into green. |
| P-Q7 | always | Line coverage and test-to-source ratios are diagnostics, never gates. Mutation testing, where adopted, defines scope, operators, threshold and surviving-mutant review. |
| P-Q8 | always | One gate command per repository runs the profile's full gate list; CI runs it on every pull request when a remote exists; until then a committed pre-push hook or script runs it, and the lack of CI is a known gap when `deployed` or `team`. |

## 14. Maintainability, structure and consistency (P1 unless marked)

| Id | Applies when | Control |
| --- | --- | --- |
| P-M1 | always | Domain glossary terms used consistently in code, tests, contracts, telemetry and commits. |
| P-M2 | always | Size and complexity are review triggers, not gates: long functions, large files and deep nesting need a reason in review. |
| P-M3 | always | Comments say why and cite the decision or control id; stale comments are defects. |
| P-M4 | always | Public exports minimal; exports without callers removed in the change that orphans them; pre-existing dead code reported, not silently deleted. |
| P-M5 | always | Formatting and linting automated with the ecosystem's standard tools; static typing at its strictest practical setting (strict TypeScript, a Python type checker, the compiler's warnings as errors). Commit messages state problem, change, verification, rollout and rollback. |
| P-M6 | always | Architecture decisions recorded when a choice is expensive to reverse, crosses components, or touches money, security, privacy or data. |
| P-M7 | always (MUST) | **Structure (C-16):** files live where the declared layout says; names follow one convention per kind (files, modules, types, functions, tests, routes, env keys, events); tests sit in the declared place and mirror the source layout; generated code is marked and never hand-edited. |
| P-M8 | always (MUST) | **One way per concern:** HTTP access, configuration, logging, errors, data access, date and money handling, and feature flags each have one sanctioned mechanism named in the profile; a second mechanism is a defect until an ADR replaces the first. |
| P-M9 | always | Repository hygiene: README with run, test and gate commands that work as written; reproducible setup from the lockfiles; no committed build output, runtime data or secrets; ignore files cover them. |

## 15. Change safety and release

| Id | Applies when | Control |
| --- | --- | --- |
| P-X1 | `deployed` with users other than the author | Customer-visible behaviour changes ship behind a flag defaulting off, or are presentation-only with a revert path. |
| P-X2 | `deployed` | Rollout order preview → staging → production with a named check and halt criterion per step; staged rollout for clients that cannot be rolled back (mobile, published packages). |
| P-X3 | always | Every change states its containment: what to flip, revert or scale down, and which signal says so. |
| P-X4 | always | Release gate: artefact verified (C-14), advisories dispositioned (C-11), exceptions unexpired, environment evidence fresh, operability controls present. |

## 16. Exceptions

| Id | Control |
| --- | --- |
| P-Z1 | An exception names the control id, the accepted risk, the compensating control, the accountable approver and an expiry date. An exception is for an applicable control; a control that does not apply needs a context fact, not an exception. |
| P-Z2 | Non-waivable where they apply: C-03, C-04, C-05, C-07, C-11 (new advisories), C-14, P-S20. A violation blocks merge with no exception path. |
| P-Z3 | An approved, unexpired exception changes the **gate disposition** to "merge or release with recorded exception"; it never changes the control's **status**, which stays "not met". An expired exception fails the release gate. |
| P-Z4 | Approvers: Critical exceptions by the security or risk owner; others by the module owner; for `team = solo`, the owner, with the risk written down. |
