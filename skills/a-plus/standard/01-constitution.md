# Layer 1 — Engineering Constitution

**Status:** Reference standard v2.0, stack-agnostic, adopted through a project profile (Layer 4).  
**Date:** 2026-10-26 · **Change log:** `CHANGELOG.md`  
**Authority:** This layer changes only through an architecture decision record. A profile may add controls and may raise a bar; it may not weaken a control that applies to its declared context.

## Conformance language

- **MUST / MUST NOT**: required where the control applies; a violation is a defect of the stated tier.
- **SHOULD / SHOULD NOT**: required unless a recorded reason exists in the change record.
- **MAY**: permitted.
- Every control has a stable id (`C-nn` here, `P-…` in Layer 2, `B-/W-/M-/L-/J-/AI-…` in Layer 3,
  `X-…` in Layer 5). Reports, exceptions and reviews cite ids, not prose.

## 1. How this standard binds to a project

A+ means: **every control that applies to the system's declared context is met, with evidence.**
The bar is the same for every project; which controls apply depends on facts about the system,
not on its size, its owner's preference or the reviewer's habits. Four rules govern every use.

1. **Context decides applicability.** Each control states *Applies when* in terms of the
   context facts declared in the profile (Layer 2 §1). A control whose predicate is false is
   recorded as not applicable with the fact that makes it so. A context fact is a claim about
   the system and is reviewable; a false fact is a defect of the highest tier it hides.
2. **Intent over mechanism.** A control is met when its **intent** holds and its **evidence**
   exists. Tools, libraries and patterns named in this standard are examples, never
   requirements. A different mechanism that produces the same evidence meets the control.
3. **Native first.** A control is bound with the project's own stack, in this order:
   (a) a mechanism the repository already uses; (b) the framework's built-in facility;
   (c) the language or platform standard library; (d) a dependency already in the lockfile;
   (e) a new dependency, which needs the evidence that (a)–(d) cannot meet the intent and human
   approval (X-3). Recommending a tool the project does not use, while a native option exists,
   is a review defect.
4. **Designed for the target context.** The profile declares the current context and, when
   known, the target context (for example "loopback today, public next quarter"). Gates check
   the current context; design decisions MUST NOT close off controls the target context will
   require.

## 2. Principles

1. **Prove, do not describe.** A quality claim is a command, a test, a measurement or an
   artefact with provenance. Adjectives are not evidence.
2. **One source of truth.** Every concept, rule, shape, key and message is defined once in
   the layer that owns it. Duplication is a defect even when copies agree.
3. **Trust nothing that crossed a boundary.** Parse and bound every input at every edge:
   network, storage, environment, user, third party, another module, another agent.
4. **Fail closed, visibly.** Missing configuration, an unreachable dependency or an unknown
   state produces a refusal or a declared degraded mode that telemetry can see.
5. **The server is authoritative.** Clients render; servers decide price, permission, state
   transitions and identity.
6. **Writes are replay-safe.** Retrying an operation never duplicates or harms.
7. **Secrets and personal data stay in their lane.** Never in logged URLs, logs, telemetry,
   analytics, prompts, fixtures, screenshots or error messages.
8. **Smallest complete change.** Code, tests, telemetry, documentation, migration, rollout
   and rollback ship together; nothing is left for "later" without a recorded owner.
9. **Follow the house style.** The framework's idioms and the repository's established
   conventions win over this standard's examples. Consistency inside the codebase outranks
   any external preference.
10. **Design for the weakest device and network you serve.** Budgets come from the supported
    floor, not the developer's machine.
11. **Independent eyes on risk.** Authors, human or agent, do not approve their own changes to
    authentication, authorisation, money, cryptography, data deletion or availability.
12. **Compliance is not quality.** Following every procedure can still ship a concurrency
    bug. Independent technical checks are owed regardless of how carefully the process ran.

## 3. Non-negotiables (tier P0)

A P0 violation of an applicable control blocks merge unless an approved, unexpired exception
exists for a waivable control (Layer 2 §16 lists the non-waivable ones). Predicates use the
context vocabulary of Layer 2 §1. Example bindings are illustrations; Layer 6 lists more per
ecosystem.

### C-01 One definition per concept
- **Applies when:** always.
- **Intent:** a rule, predicate, status vocabulary, key builder, formatter, error mapping or
  shape exists once and is imported everywhere else, so a change cannot leave a stale copy.
- **Evidence:** the definition's single location named in the change; no second
  implementation found by search; shared shapes generated or imported, not retyped.
- **Examples:** a shared contracts package; types generated from the server's OpenAPI
  document; one `errors` registry module; one settings module.

### C-02 Every untrusted boundary is parsed, never asserted
- **Applies when:** always.
- **Intent:** data that crossed a trust boundary cannot drive behaviour until a parser has
  checked its shape, types and bounds; type assertions, `any`-style escapes, type-ignore
  pragmas and lint suppressions do not appear on boundary code.
- **Untrusted boundaries:** inbound requests, messages and webhooks; third-party responses;
  storage and caches read back; environment and configuration; files and user uploads;
  model and agent output; deep links; anything persisted by an older client version.
- **Same-system boundary:** a client calling its own server through one canonical schema
  (P-C2) MAY rely on types generated from that schema plus a CI contract check, instead of
  runtime parsing, when client and server ship together. Runtime parsing is still required
  where versions can skew (installed mobile clients, public SDK consumers, cached payloads
  across deploys) or where a malformed value would reach authorisation, money or persistence.
- **Evidence:** the parser at each boundary and a test that a malformed input is rejected
  with a typed error; a lint rule or review check for assertions on boundary paths.
- **Examples:** pydantic models in FastAPI; class-validator or the existing validation pipe
  in NestJS; the schema library the TypeScript codebase already uses; `encoding/json` into
  typed structs plus a validator in Go; Codable plus explicit checks in Swift.

### C-03 Identity and tenant come only from verified context
- **Applies when:** the system authenticates anyone (`auth ≠ none`); the tenant clause when
  `users = multi-tenant`.
- **Intent:** who the caller is, and which tenant they act for, is read only from context an
  authenticated layer attached; never from a caller-controlled header, body, path or query.
- **Evidence:** the guard or dependency that attaches identity; a negative test that a
  forged identity or tenant value in the request is ignored or rejected.
- **Examples:** a FastAPI dependency returning the verified session; a NestJS guard writing
  to the request context; middleware in Go setting a typed context value.

### C-04 Authorisation is enforced where the consequence lives
- **Applies when:** the system has any non-public data or action.
- **Intent:** the edge authenticates and checks audience; the owning use case or repository
  checks ownership and permission on every access. Unguessable identifiers are defence in
  depth, never a substitute. For `users = single-owner` this reduces to: every non-public
  route and action requires the authenticated owner, enforced by a test that fails when a
  new route lacks it.
- **Evidence:** a route-surface or policy test that enumerates routes and their requirement;
  negative tests for another user's object (multi-user) or an unauthenticated caller.

### C-05 Credentials and personal data never leave their lane
- **Applies when:** always.
- **Intent:** tokens, OTPs, cookies, nonces, keys, payment credentials, signed payloads and
  personal identifiers do not appear in logged URLs, client logs, telemetry, analytics,
  error messages, prompts or fixtures.
- **Evidence:** a scrub or redaction step that works by allow-list of keys, with tests; a
  secret scan in the gate; fixtures that are synthetic.

### C-06 Fail closed on configuration and unknown outcomes
- **Applies when:** always.
- **Intent:** the system refuses to start when configuration a live feature needs is missing
  or malformed; unknown outcomes are surfaced, never assumed successful; a secret never has a
  default.
- **Evidence:** a typed configuration schema validated at startup and a test that startup
  fails without each required value.
- **Examples:** pydantic-settings; the framework's config module with a validation schema;
  a Go config struct validated in `main`.

### C-07 Money and permissions are server-authoritative
- **Applies when:** `money = yes` (amounts) or the system has roles or permissions.
- **Intent:** clients display server-provided amounts and permissions; servers compute,
  round and decide. Amounts use a decimal money type with explicit currency.
- **Evidence:** no client code computes a charged amount or grants a permission; tests for
  rounding and currency at the server.

### C-08 Replay safety
- **Applies when:** any operation can be retried by a client, a network layer, a queue or a
  scheduler and the retry can duplicate or harm.
- **Intent:** the whole operation, external effects included, is replay-safe through an
  idempotency key with defined scope, retention, payload-mismatch, concurrent-duplicate and
  ambiguous-outcome handling, or through natural idempotence proven for the whole effect
  chain. Concurrency (C-09) and reliable side effects (P-D1) are separate obligations.
- **Evidence:** a test that replays the operation, including concurrently, and observes one
  effect.

### C-09 Contended state is concurrency-safe
- **Applies when:** two writers can race on the same state (users, devices, tabs, workers,
  replicas, scheduled jobs).
- **Intent:** versions or locks protect contended rows; the loser receives a typed conflict,
  never a silent overwrite.
- **Evidence:** a concurrency test that races two writers and asserts one typed conflict.

### C-10 Every reachable endpoint declares an abuse class
- **Applies when:** `exposure ∈ {private, public}`.
- **Intent:** each externally reachable endpoint has a limit keyed on a verified subject
  where one exists plus a network backstop, answers `429` with `Retry-After`, and a test
  fails when a new endpoint lacks a declared class.
- **Evidence:** the limiter binding and the coverage test.

### C-11 No known vulnerability ships
- **Applies when:** always.
- **Intent:** a change that introduces an advisory does not merge; each pre-existing advisory
  carries a disposition (fixed, mitigated with evidence, or an unexpired exception) before
  release.
- **Evidence:** the ecosystem's audit command in the gate, for every lockfile in the repo.
- **Examples:** `pnpm audit`, `npm audit`, `pip-audit`, `uv` with an audit tool,
  `govulncheck`, `cargo audit`, OSV-Scanner across all of them.

### C-12 Behaviour changes carry a failing test first
- **Applies when:** always.
- **Intent:** each behaviour change is pinned by a test that failed before the change, tied
  to the invariant, boundary or failure mode it protects, in the owning layer.
- **Evidence:** the red run and the green run, both recorded (P-Q3).

### C-13 Personal data is classified, minimised, protected and deletable
- **Applies when:** `personal-data = yes`.
- **Intent:** every personal field has a classification, purpose, retention period, access
  path and a tested deletion or anonymisation path.
- **Evidence:** the data catalogue and the deletion test.

### C-14 Only the verified artefact runs
- **Applies when:** `delivery ∈ {server-deploy, app-store, package-registry}`.
- **Intent:** the deployment or publication step admits exactly the immutable artefact
  (digest) that passed verification and approval, with provenance; any other digest is
  rejected. For `delivery = local-process`, the runnable build is produced by the gate
  command from a committed tree, never edited in place.
- **Evidence:** the deploy or publish workflow's digest check.

### C-15 Every failure is observable
- **Applies when:** always.
- **Intent:** no failure disappears. Errors are rethrown, mapped to a typed outcome or
  logged as a structured event with an error code; each new failure mode has a signal and a
  detection disposition (P-O2). Logs are structured and correlated by request or run id.
- **Evidence:** no empty or swallow-only error handlers (lint or search); a test that a
  failure produces its event; the disposition in the change record.
- **Examples:** the framework's exception handler plus a structured logger already in use
  (`logging` with a JSON formatter, `structlog`, `pino`, `slog`, NestJS `Logger`).

### C-16 One declared structure, enforced
- **Applies when:** always.
- **Intent:** the codebase has one declared layout, a public interface per module and a
  dependency direction, written in the profile and enforced by a check, so every recurring
  kind of thing (route, use case, repository, component, job, test, config) has exactly one
  home and one way of being done. The declared layout follows the framework's conventions
  (Layer 3 structure sections) before any external pattern.
- **Evidence:** the layout and import rules in the profile §4; a boundary check in lint or a
  test that fails on a forbidden import or a cycle; exemplar modules (profile §7).
- **Examples:** `import-linter` for Python, `eslint-plugin-boundaries` or
  `dependency-cruiser` for TypeScript, Go `internal/` packages, Gradle module dependencies.

## 4. What this layer does not do

It names no required tool, path, framework or number. Bindings live in Layer 3 (role
mechanics), Layer 4 (the project profile) and Layer 6 (example bindings per ecosystem). An
agent that cannot find a binding for an applicable control MUST report the gap in the gap
format (Layer 5 §4), not invent one.
