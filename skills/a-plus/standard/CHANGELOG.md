# Changelog — A+ Engineering Standard

## 2.0.0 — 2026-10-26

Makes the standard follow each project's stack and context instead of assuming one product
class. Control ids are unchanged; files were renamed and added.

- **Context model** (Layer 2 §1): a profile declares facts (roles, users, auth, exposure,
  delivery, personal data, money, persistence, async, integrations, locales, availability,
  team) and an optional target context. Every control states *Applies when*; a
  not-applicable disposition must cite a fact. Changing a fact is a High-tier change.
- **Intent over mechanism**: constitution controls rewritten as Intent / Applies when /
  Evidence / Examples. Named tools are examples, never requirements.
- **Native first** (Layer 1 §1.3, X-11): bindings and recommendations use the existing
  repository mechanism, then framework built-ins, the standard library, locked
  dependencies; a new dependency needs proof and approval. Proposing a library the project
  does not use while a native option exists is a defect.
- C-02 clarifies untrusted boundaries and when a same-system client may rely on types
  generated from the canonical schema plus a CI contract check instead of runtime parsing.
- New constitution controls: **C-15** every failure is observable; **C-16** one declared
  structure, enforced. New policies **P-M7** structure and naming, **P-M8** one way per
  concern, **P-M9** repository hygiene, **P-O7** service metrics, **P-S26** development
  login safety.
- Playbooks by role: `03-playbook-backend.md` renamed `03-playbook-service.md` (framework
  layout map, B-25 loopback binding); web adds W-22 sanitised rendering and PWA rules
  W-23–W-25; mobile adds structure M-18–M-19; new `03-playbook-library-cli.md` (`L-`) and
  `03-playbook-pipeline-ai.md` (`J-`, `AI-`).
- New `06-stack-bindings.md`: native options per concern for Python, TypeScript, Go, JVM,
  Rust and mobile.
- Profile template: context and target context first, stack table, structure and "one way
  per concern", applicability register, gap table with native options.
- Agent contract: X-11 native first, X-12 applicability before findings, fixed gap format
  and review finding format with severities.
- `02-risk-and-quality-policies.md` renamed `02-context-risk-and-policies.md`; local-only and
  solo projects get explicit equivalents for CI, release, review and backup rules.

## 1.1.0 — 2026-10-25

Split the single v1.0 document into five layers after an external review and a two-reviewer
collaboration that converged after six rounds.

- Three assessment axes (code quality, verification confidence, release readiness) replace
  the A+/A-/B/C letter grade; merge eligibility distinct from release eligibility.
- Conformance levels (MUST/SHOULD/MAY), risk tiers with applicability, and justified
  not-applicable dispositions.
- Test-to-source line ratios are diagnostics only; the gate is invariant-to-test
  traceability plus risk-specific test classes; mutation thresholds belong to profiles.
- OAuth per RFC 9700 and RFC 8252: authorization code with PKCE S256 for all clients.
- Session revocation stated as an outcome within N seconds; mechanism free.
- Replay safety (C-08) replaces "every write idempotent"; concurrency safety (C-09) and
  reliable side effects (P-D1) are separate obligations.
- Dependency direction `delivery → application → domain`; layers may collapse when
  boundaries survive; new deployables need an ADR and an accountable owner.
- Query optimisation by evidence instead of per-filter index mandates; risk-triggered
  circuit breakers; detection disposition per failure mode instead of an alert each.
- Deployment admits only the verified artefact digest (C-14).
- Exceptions change gate disposition, never control status; non-waivable list (P-Z2).
- Agent execution contract with ten controls: instruction trust, permission isolation,
  approval boundaries, impact analysis, provenance, independent verification, failure
  recovery, honest reporting, bounded batches, no secrets in the loop.

## 1.0.0 — 2026-10-25

Single-document generic standard with a letter grade, twelve non-negotiables and an agent
protocol.
