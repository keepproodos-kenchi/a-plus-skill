# Layer 4 — Project Profile Template

**Purpose:** The profile is the only place that names tools, paths, commands and numbers. It binds each control id from Layers 1–3 to how this repository satisfies it. Agents load the profile first; a control without a binding is reported as a gap, never improvised.

Copy this file to the repository's rules folder, fill every section, date it, and keep it current.

## 1. Identity

| Field | Value |
| --- | --- |
| Repository | |
| Profile version and date | |
| Standard version adopted | Layers 1–3 v1.1 |
| Accountable owners | engineering · security · product · operations |
| Risk owner for exceptions | |

## 2. Risk map

| Module or path | Tier (Critical/High/Medium/Low) | Reason | Reviewer group | Required test classes |
| --- | --- | --- | --- | --- |
| | | | | |

## 3. Commands (one script per invocation; exact, copy-pasteable)

| Purpose | Command | Gate (merge/release/diagnostic) |
| --- | --- | --- |
| format | | |
| lint (incl. boundary checks) | | |
| typecheck | | |
| unit tests | | |
| integration tests (infrastructure needed: …) | | |
| contract / route-surface tests | | |
| end-to-end | | |
| accessibility automation | | |
| build | | |
| bundle or size budget | | |
| dependency audit | | |
| secret scan / SAST | | |
| mutation testing (if adopted; scope, operators, exclusions, threshold, surviving-mutant review) | | |

## 4. Structure and boundaries

| Item | Binding |
| --- | --- |
| Module layout per layer (B-2, W-1) | |
| Public interface convention | |
| Allowed and forbidden import directions and the script enforcing them (B-3, W-2) | |
| Canonical schema location and compatibility check (P-C2) | |
| Configuration schema module (C-06, B-19) | |

## 5. Control bindings

| Control id | Implemented by (rule, script, test, module) | Evidence command or artefact |
| --- | --- | --- |
| C-02 | e.g. lint rule banning assertions in `<paths>`; parse-schema rule in API clients | |
| C-05 | e.g. telemetry scrub module and its tests | |
| C-08 / C-09 | | |
| C-10 | e.g. rate-limit coverage test per app | |
| C-11 | | |
| C-14 | e.g. deploy workflow verifying artefact digest and attestation | |
| P-S2 / P-S3 (N = … seconds) | | |
| P-S16 (CSP state: enforced / report-only until …) | | |
| P-O2 (alert catalogue location) | | |
| P-P1 budgets (see §6) | | |
| P-L1 human a11y evidence process | | |
| P-X2 rollout order and halt criteria | | |

## 6. Budgets (with method and date)

| Budget | Value | Measured how | Date | Change approval |
| --- | --- | --- | --- | --- |
| first-load JS per route | | | | |
| p95 latency per endpoint class | | | | |
| mobile cold start, app size | | | | |
| error budget per SLO | | | | |

## 7. Exemplars

One module per layer that meets the bar and is safe to copy: backend module …, web feature …, mobile module …, with the traits to extract.

## 8. Known gaps (dated; each with owner and backlog item)

| Control id | Gap | Owner | Backlog item | Target date |
| --- | --- | --- | --- | --- |
| | | | | |

Agents MUST treat every row here as not implemented.

## 9. Exceptions register

Link to the register; list open exceptions with control id, approver and expiry (P-Z1–Z4).

## 10. Agent bindings

| Item | Binding |
| --- | --- |
| Instruction sources that are delegated (trusted) in this repository (X-1) | e.g. `AGENTS.md`, `CLAUDE.md`, rules folder |
| Default permission scope per task type (X-2) | |
| Approval channel and approvers (X-3) | |
| Independent reviewer arrangement (X-6) | |
| Report destination and format (X-8) | |
