# Layer 1 — Engineering Constitution

**Status:** Reference standard v1.1, stack-agnostic, awaiting adoption through a project profile (Layer 4).  
**Date:** 2026-10-25 · **Change log:** `CHANGELOG.md`  
**Authority:** This layer changes only through an architecture decision record. A project profile may add controls; it may not weaken a constitutional control.

## Conformance language

- **MUST / MUST NOT**: required; a violation is a defect of the stated tier.
- **SHOULD / SHOULD NOT**: required unless a recorded reason exists in the change record.
- **MAY**: permitted.
- Every control has a stable id (`C-nn` here, `P-…` in Layer 2, `B-/W-/M-…` in Layer 3,
  `X-…` in Layer 5). Reports, exceptions and reviews cite ids, not prose.

## 1. Principles

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
7. **Secrets and personal data stay in their lane.** Never in URLs that are logged, logs,
   telemetry, analytics, prompts, fixtures, screenshots or error messages.
8. **Smallest complete change.** Code, tests, telemetry, documentation, migration, rollout
   and rollback ship together; nothing is left for "later" without a recorded owner.
9. **Design for the weakest device and network you serve.** Budgets come from the
   supported floor, not the developer's machine.
10. **Independent eyes on risk.** Authors, human or agent, do not approve changes to
    authentication, authorisation, money, cryptography, data deletion or availability.
11. **Compliance is not quality.** Following every procedure can still ship a concurrency
    bug. Independent technical checks are owed regardless of who wrote the code or how
    carefully the process was followed.

## 2. Non-negotiables (tier P0)

Each is a constitutional MUST. A P0 violation blocks merge unless an approved, unexpired
exception exists for a waivable control (Layer 2 §15 lists the non-waivable ones); an
exception changes the gate disposition, never the control's status.

| Id | Control |
| --- | --- |
| C-01 | **One definition per concept.** A rule, predicate, status vocabulary, key builder, formatter or error mapping exists once and is imported everywhere else. |
| C-02 | **Every external boundary is parsed with a schema**, never asserted. Type assertions, `any`-style escapes, type-ignore pragmas and lint suppressions MUST NOT appear on boundary code. |
| C-03 | **Identity and tenant come only from verified context** attached by an authenticated layer; never from a caller-controlled header, body, path or query value. |
| C-04 | **Authorisation is enforced where the consequence lives.** The edge authenticates and checks audience; the owning use case or repository checks ownership and permission on every access to non-public data. Unguessable identifiers are defence in depth, never a substitute. |
| C-05 | **Credentials and personal data never leave their lane.** Tokens, OTPs, cookies, nonces, keys, payment credentials, signed payloads and personal identifiers MUST NOT appear in logged URLs, client logs, telemetry, analytics, error messages, prompts or fixtures. Telemetry scrubs by allow-list of keys, with tests. |
| C-06 | **Fail closed.** Production MUST refuse to start on missing or malformed configuration a live feature needs; unknown outcomes are surfaced, never assumed successful; no `?? default` on a secret. |
| C-07 | **Money and permissions are server-authoritative.** Clients display server-provided amounts and permissions; servers compute, round and decide. Amounts use a decimal money type with explicit currency. |
| C-08 | **Replay safety for every operation whose retry can duplicate or harm.** The whole operation, including external effects, is replay-safe through an idempotency key with defined scope, retention, payload-mismatch handling, concurrent-duplicate handling and ambiguous-outcome handling, or through natural idempotence proven for the whole effect chain. Concurrency safety (C-09) and reliable side effects (Layer 2 P-D) are separate obligations. |
| C-09 | **Contended state is concurrency-safe.** Versions or locks protect rows two actors can race on; the loser receives a typed conflict, never a silent overwrite. |
| C-10 | **Every externally reachable endpoint declares an abuse class** with a limit keyed on a verified subject where one exists and a network backstop, answers `429` with `Retry-After`, and is covered by a test that fails when a new endpoint lacks it. |
| C-11 | **No known vulnerability ships.** A change that introduces an advisory does not merge; every pre-existing advisory carries a disposition (fixed, mitigated with evidence, or an unexpired exception) before release. |
| C-12 | **Behaviour changes carry a failing test first**, tied to the invariant, boundary or failure mode they protect, in the owning layer and at the affected boundary. |
| C-13 | **Personal data is classified, minimised, protected and deletable.** Every personal field has a classification, a purpose, a retention period, an access path and a tested deletion or anonymisation path. |
| C-14 | **Only the verified artefact deploys.** The deployment gate admits exactly the immutable artefact (digest) that passed verification and approval, with provenance attestation; a different digest is rejected. |

## 3. What this layer does not do

It names no tool, path, framework or number. Those bindings live in Layer 2 (policies and
tiers), Layer 3 (stack mechanics) and Layer 4 (the project profile). An agent that cannot
find a binding for a control in the profile MUST report the gap, not invent one.
