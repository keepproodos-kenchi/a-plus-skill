# Changelog — A+ Engineering Standard

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
