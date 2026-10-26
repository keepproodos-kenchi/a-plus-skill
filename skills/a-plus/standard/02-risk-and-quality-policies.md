# Layer 2 — Risk and Quality Policies

**Status:** Reference standard v1.1, awaiting adoption through a project profile.  
**Date:** 2026-10-25  
**Depends on:** [Layer 1 Constitution](./01-constitution.md). Nothing here weakens a C-control.

## 1. Risk classification

Every change is classified before work starts. The highest matching row applies.

| Tier | Triggers | Mandatory extras |
| --- | --- | --- |
| **Critical** | Authentication, authorisation, tenancy boundary, money movement, cryptography, destructive migration, production access, availability of a critical journey, personal-data deletion or export | Threat model (P-S24), independent review (P-S25), replay and concurrency tests where the change touches C-08/C-09 operations, rollback or containment plan, deployment through the artefact gate (C-14) |
| **High** | New endpoint or event, schema change, permission change, new dependency with network or filesystem access, new third-party processor, change to limits or budgets | Threat model, negative tests, impact analysis, detection disposition (P-O2) |
| **Medium** | Any behaviour change not classified above, new UI state, new background job | Red-before-green test, telemetry for new failure modes |
| **Low** | Documentation, copy, presentation or refactor **proven** behaviour-preserving by the existing test suite | Static evidence only; any behaviour change re-classifies to Medium or above |

**Conformance levels.** Every Layer 1 control is MUST. Every Layer 2 control is MUST when
applicable to the change's tier and stack; controls marked **P1** are SHOULD for Low-tier
changes and MUST otherwise. Applicability is decided per control in the task contract; a
"not applicable" disposition is written with its reason and is reviewable. Where a control
names a test class (P-Q2) the class is owed only where the risk it addresses is present.

## 2. Assessment model

Three axes, reported separately. A roll-up label MAY be derived from them; it MUST NOT be
assigned directly, and an agent MUST NOT assign one.

| Axis | Values | Meaning |
| --- | --- | --- |
| **Code quality** | meets bar · gaps · fails P0 · unassessed | Does the code satisfy the controls applicable to its tier? "Unassessed" when no reviewer has checked the evidence. |
| **Verification confidence** | per evidence dimension: pass · fail · missing · stale | Dimensions: static analysis (format, lint, typecheck, SAST, dependency audit); executable tests (unit, integration, contract, e2e, accessibility, concurrency); environment reached (local · ephemeral CI · preview/staging · production-like); independent review (present or absent). Stale = evidence predates the current diff digest. |
| **Release readiness** | ready · blocked (blockers named) | Operability controls present, migration safety, rollout and rollback written, exceptions unexpired, advisories dispositioned, artefact gate satisfied. |

**Merge eligibility** requires: code quality assessed as "meets bar", or "gaps" where every
gap is dispositioned as follows: an unmet **SHOULD** control may carry an owned follow-up
with a date; an unmet **MUST** control requires an approved, unexpired exception per §15;
a non-waivable control (P-Z2) always blocks. "Unassessed" and "fails P0" do not merge.
Static analysis and the applicable executable tests pass; independent review present for
Critical; evidence bound to the diff digest.  
**Release eligibility** additionally requires: environment reached ≥ preview/staging; for
deliverables with a user interface, journeys and accessibility green there; for
backend-only deliverables, integration and contract evidence green there; release
readiness "ready". Not-applicable dispositions are justified in the release record.

## 3. Evidence rules

| Id | Control |
| --- | --- |
| P-E1 | Evidence is bound to the diff digest or artefact digest it was produced from. A material change to the diff invalidates affected evidence and approvals. |
| P-E2 | Evidence records the exact commands, exit codes, environment, commit and digest, and the location of artefacts (logs, reports, screenshots). |
| P-E3 | Evidence freshness: static and test evidence must be from the final diff; environment evidence from an artefact built from the final diff; review evidence from the final diff. |
| P-E4 | Partial work is reported as partial. "Should pass" is not evidence. |

## 4. Security policies

Baseline OWASP ASVS Level 2; Level 3 for money, administration and personal-data export.

### 4.1 Authentication and sessions

| Id | Control |
| --- | --- |
| P-S1 | Passwords: Argon2id or bcrypt at current cost, breached-password check, identifier-keyed and IP-keyed login limits, constant-time comparison, no user enumeration by response or timing. |
| P-S2 | OAuth 2.0 / OIDC per RFC 9700 and RFC 8252: authorization-code flow only (no implicit, no password grant); PKCE S256 for **all** clients; transaction binding through `state` and PKCE; exact redirect-URI matching; token validation of issuer, audience, signature, expiry and, for OIDC, nonce; native apps use the system browser or an external user-agent, never an embedded web view; confidential clients authenticate with any approved method (client secret, `private_key_jwt`, mTLS). |
| P-S3 | Revocation is an outcome: revocation becomes effective within N seconds (profile-defined, from the revoke event) for all affected access tokens, refresh tokens, resource servers and caches, with clock tolerance and outage behaviour defined and the maximum exposure window tested. Online checks (introspection, session store, denylist) are required only where token expiry cannot meet N. Refresh tokens rotate with reuse detection and family revocation. |
| P-S4 | Cookies: `HttpOnly`, `Secure`, `SameSite` from validated config, scoped path and domain. A credential readable by script (JavaScript-visible cookie, web storage) is permitted only with an architecture note and an enforced CSP. |
| P-S5 | Step-up or multi-factor authentication for administrative, money-moving and data-export actions; recovery flows identifier-keyed and rate-limited. |
| P-S6 | Client attestation for native apps where the threat model requires it, with trust tiers that scale limits; attestation failure degrades, it never silently passes. |

### 4.2 Authorisation and tenancy

| Id | Control |
| --- | --- |
| P-S7 | Permissions are data with deny by default; evaluated by one engine, not by branches scattered across handlers. |
| P-S8 | Tenant scoping in the data layer: every query carries the verified tenant through row-level security or a scoped repository that is the only access path; cross-tenant not-found is indistinguishable from not-found; a cross-tenant negative test exists per repository. |
| P-S9 | Object access checks ownership on every request (C-04). Capability URLs (bearer-style links) require their own policy: entropy, expiry, scope, revocation, logging. |
| P-S10 | Administrative and break-glass access is just-in-time, logged, reviewed and time-boxed. |

### 4.3 Input, output and transport

| Id | Control |
| --- | --- |
| P-S11 | All input bounded: length, size, count, depth, numeric range, character set, content type; pagination and fan-out bounded. |
| P-S12 | Output encoded by context; templates auto-escape; raw HTML sinks require a sanitiser and review. |
| P-S13 | Parameterised queries and safe client APIs only; no string-built SQL, NoSQL, LDAP, XPath or shell. |
| P-S14 | Outbound requests validated against scheme and host allow-lists; private ranges and metadata endpoints blocked; redirects not followed blindly. |
| P-S15 | Uploads: type and size allow-list client- and server-side; content sniffed, re-encoded or scanned; stored outside the web root on an isolated origin; count limits applied atomically. |
| P-S16 | Security headers in code or proven at the edge: CSP enforced with an explicit source list (report-only is a rollout phase with an owner and an end date), HSTS, `X-Content-Type-Options`, frame-ancestors, `Referrer-Policy`, `Permissions-Policy`; server fingerprint headers off. |
| P-S17 | CSRF: same-site cookies plus a synchroniser or double-submit token for browser state changes; native and server clients use bearer tokens. |
| P-S18 | Trusted proxies are explicit CIDRs (IPv4 and IPv6); client IP read from forwarded headers only behind them, right-to-left; otherwise the socket address. |
| P-S19 | Webhooks and callbacks: signature verified in constant time, timestamp window, replay store, idempotent processing. |

### 4.4 Cryptography, secrets and supply chain

| Id | Control |
| --- | --- |
| P-S20 | Vetted primitives from the platform library only (AES-GCM or ChaCha20-Poly1305; SHA-256 or better; HMAC; Argon2id or bcrypt; Ed25519 or ECDSA P-256); CSPRNG for every security-relevant random value; no custom cryptography. |
| P-S21 | Secrets in a secret manager, rotated on schedule and on incident, never in code, images or logs; rotation drilled and recorded. |
| P-S22 | Dependencies pinned with a committed lockfile; provenance reviewed on add; vulnerability scan on every PR; SBOM per release; license policy enforced. |
| P-S23 | Build and deploy integrity: reproducible builds, signed artefacts, protected branches, required reviews, secret scanning and SAST on every PR; deployment admits only the verified digest (C-14). |
| P-S24 | Threat model for Critical and High: assets, actors, entry points, abuse cases, mitigations, written before coding and attached to the change. |
| P-S25 | Independent review for Critical: the reviewer is not the author and not any human or agent that took part in the authoring session; the reviewer has the real diff and the evidence, not a summary. |

## 5. Privacy and data protection

| Id | Control |
| --- | --- |
| P-V1 | Data classification on every stored field drives encryption, logging, retention and access. |
| P-V2 | Minimisation: collect only what a documented purpose needs; derived data inherits the strictest source classification. |
| P-V3 | TLS 1.2+ in transit; encryption at rest for restricted and personal data with managed keys; field-level encryption for secrets and payment data. |
| P-V4 | Retention and deletion paths tested across primary store, backups, caches, search indexes, analytics and logs; deleted data MUST NOT resurrect from a restore (post-restore reconciliation defined). Legal holds override retention with an auditable record. |
| P-V5 | Subject rights (access, export, erasure) are auditable workflows. |
| P-V6 | Logs and analytics carry pseudonymous ids only, with a documented re-identification control. |
| P-V7 | Processors inventoried with data categories, region, contract and transfer basis. |

## 6. API, contracts and compatibility

| Id | Control |
| --- | --- |
| P-C1 | One error envelope: stable machine code, HTTP status, message authored once in a registry, request id; no stack traces or internals. |
| P-C2 | A canonical schema is the single definition of every request, response, event and error shape; producers and consumers verify compatibility against it in CI (shared package, generated clients or contract tests are all acceptable bindings). |
| P-C3 | Compatibility: additive by default; breaking changes behind a new version with a deprecation window, usage telemetry and a removal date; mobile clients get a minimum supported version and a forced-upgrade path. |
| P-C4 | Pagination with bounded page size and opaque cursors; filters and sorts are an allow-list. |
| P-C5 | Operations covered by C-08 that use the key strategy accept an idempotency key, store the outcome and reject reuse with a different payload. Operations relying on natural idempotence record the proof that the whole effect chain is replay-safe (C-08) instead. |
| P-C6 | Every outbound call has a deadline sized to the operation and a retry budget (which MAY be zero); retries only for replay-safe operations with jittered backoff; circuit breakers where a dependency failure can cascade or exhaust shared pools. |
| P-C7 | Every route and event has generated, complete documentation checked in CI. |
| P-C8 | Events are schema-versioned; consumers idempotent; at-least-once delivery handled; dead-letter queues alerted. |

## 7. Data integrity

| Id | Control |
| --- | --- |
| P-D1 | One transaction per use case opened by the outermost caller; repositories join; after-commit effects go through an outbox or explicit after-commit hook (reliable side effects are a separate obligation from C-08). |
| P-D2 | Constraints exist in the database as well as in code. |
| P-D3 | Migrations follow expand → migrate → contract; code compatible with both shapes ships before contract; destructive steps have a backfill, a rollback or a documented forward-fix and an audit entry. |
| P-D4 | Caches keyed by tenant and actor when personalised; invalidation defined with the write; public caches never contain credentials. |
| P-D5 | Audit trail for state changes to money, permissions, personal data and configuration: who, what, when, from where, before and after; automated writers labelled. |
| P-D6 | Backups automated, encrypted, retention-bound; RPO and RTO declared per data store and proven by scheduled restore drills with recorded recovery time. |

## 8. Reliability

| Id | Control |
| --- | --- |
| P-R1 | SLOs (availability, latency) for critical user journeys and service boundaries, with error budgets; paging on budget burn. |
| P-R2 | Degradation ladder per dependency: what still works when it is down; security fails closed, reads degrade gracefully. |
| P-R3 | Bulkheads and backpressure: bounded pools, queues and concurrency per dependency; load shedding before collapse. |
| P-R4 | Liveness distinct from readiness; readiness checks real dependencies; graceful shutdown drains. |
| P-R5 | Capacity: production-shaped load evidence establishes saturation and headroom before any scale claim; cost budgeted per tenant tier. |
| P-R6 | Runbooks per failure mode, on-call ownership, post-incident reviews with tracked actions. |

## 9. Observability

| Id | Control |
| --- | --- |
| P-O1 | Structured logs with event type, severity, request id, trace id and pseudonymous tenant and actor ids; never payloads or secrets. Production clients ship warnings and errors to a telemetry backend. |
| P-O2 | Every new failure mode has an observable signal and a **detection disposition** recorded in the change: covered by an existing alert, a new actionable alert (owner, severity, response), or diagnostic-only with rationale. Paging reflects urgency. |
| P-O3 | Tracing propagates across services, queues and clients; the client mints a request id, the server echoes it. |
| P-O4 | Error tracking scrubs by allow-list, default PII collection off, releases tagged, source maps private. |
| P-O5 | Dashboards per service and per critical journey. |
| P-O6 | No silent catch: rethrow, map to a typed outcome, or log with the error code. |

## 10. Performance and efficiency (P1)

| Id | Control |
| --- | --- |
| P-P1 | Budgets (client bundle, cold start, p95 latency per endpoint class, memory, cost) are declared in the profile with measurement method and date and enforced in CI. A budget changes only by a measured, approved decision with user-impact justification. An agent MUST NOT change a budget on its own initiative; it MAY implement an explicitly approved revision, recording the approval, method and justification (X-3). |
| P-P2 | Heavy or rarely used modules load lazily; motion respects reduced-motion preferences. |
| P-P3 | Query performance is proven by representative query plans and load evidence against the endpoint class budget; indexes, materialisations or redesign are justified by that evidence, not mandated per filter. |
| P-P4 | Polling uses named intervals, capped exponential backoff, stop conditions and pauses on `429` until `Retry-After`; push preferred when fan-out justifies it. |
| P-P5 | Background work bounded, cancellable and off the request path. |

## 11. Accessibility and localisation (P1)

| Id | Control |
| --- | --- |
| P-L1 | WCAG 2.2 AA. Automated checks (zero serious or critical) **and** human keyboard and screen-reader evidence on primary journeys per release. |
| P-L2 | Every user-facing string externalised; locale key parity enforced; text growth tested on the longest locale; locale-aware dates, numbers and currencies; machine-drafted copy flagged for native review before release. |
| P-L3 | Design tokens only; no second aesthetic. |

## 12. Testing (MUST where applicable to the tier; see §1 conformance levels)

| Id | Control |
| --- | --- |
| P-Q1 | **Traceability**: every test names the invariant, boundary or failure mode it pins; every Critical and High control in the change has at least one test or an explicit evidence substitute. |
| P-Q2 | Classes by risk: unit for every domain rule, parser and mapping; component tests for every designed state; integration against real infrastructure for repositories, transactions and consumers; contract tests both sides; end-to-end for critical journeys; accessibility automation on primary screens; concurrency and replay tests for C-08/C-09 operations; security tests for authn, authz, cross-tenant, injection and replay; load tests before scale claims; dependency-failure tests for degradation ladders. |
| P-Q3 | Red before green (C-12) with the failing run recorded. |
| P-Q4 | Mocks are partial and never replace the behaviour under test; clock, randomness and network injected; mocks restored per test; assertions on outcomes. |
| P-Q5 | Changed tests explained; accepting a defect, deleting coverage without replacement or making a failing gate optional is prohibited. |
| P-Q6 | Flaky tests quarantined with owner and deadline; never retried into green. |
| P-Q7 | Diagnostics, not gates: test-to-source line ratios MAY flag thin coverage for review; they MUST NOT be a merge or release gate. Mutation testing, where the profile adopts it, defines scope, operators, exclusions, threshold and surviving-mutant review; where tooling is unavailable the profile names the alternative evidence. |
| P-Q8 | CI on every pull request runs the profile's full gate list; main deploys only from green. |

## 13. Maintainability (P1)

| Id | Control |
| --- | --- |
| P-M1 | Domain glossary terms used consistently in code, tests, contracts, telemetry and commits. |
| P-M2 | Size and complexity are review triggers, not gates: long functions, large files and high cyclomatic complexity prompt a reason in review. |
| P-M3 | Comments say why and cite the decision or control id; stale comments are defects. |
| P-M4 | Public exports minimal; exports without callers removed in the change that orphans them; pre-existing dead code reported, not silently deleted. |
| P-M5 | Formatting automated; commit messages carry Problem, What changed, Verification, Rollout and Rollback in prose. |
| P-M6 | Architecture decisions recorded when a choice is expensive to reverse, crosses teams, or touches money, security, privacy or data. |

## 14. Change safety and release

| Id | Control |
| --- | --- |
| P-X1 | Customer-visible behaviour changes ship behind a flag defaulting off in production, or are presentation-only with a revert path. |
| P-X2 | Rollout order preview → staging → production with a named check and halt criterion at each step; staged rollout for clients that cannot be rolled back (mobile) with measurement window and sample size defined. |
| P-X3 | Every change states its containment: what to flip, revert or scale down, and which signal says so. |
| P-X4 | Release gate: artefact digest verified (C-14), advisories dispositioned (C-11), exceptions unexpired, environment evidence fresh, operability controls present. |

## 15. Exceptions

| Id | Control |
| --- | --- |
| P-Z1 | An exception names the control id, the accepted risk, the compensating control, the accountable approver and an expiry date. |
| P-Z2 | Non-waivable: C-03, C-04, C-05, C-07, C-11 (new advisories), C-14, P-S20. A violation of these blocks merge with no exception path. |
| P-Z3 | An approved, unexpired exception changes the **gate disposition** for its control to "merge or release with recorded exception"; it never changes the control's **status**, which stays "not met". Code quality for the module reports "gaps (excepted)"; an expired exception fails the release gate. |
| P-Z4 | Approvers: Critical exceptions by the security or risk owner; others by the module owner. |
