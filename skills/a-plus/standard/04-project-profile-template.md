# Layer 4 — Project Profile Template

**Purpose:** The profile is the only place that names this repository's tools, paths, commands
and numbers. It declares the system's context, decides which controls apply, and binds each
applicable control to the mechanism the repository already uses. Agents load it first. A
control without a binding is a known gap, never improvised. Every value cites its evidence
(a file, a command and its exit code, or an owner's decision with a date).

Copy this file to the repository's rules folder, fill every section, date it, keep it current.

## 1. Identity and context

| Field | Value | Evidence |
| --- | --- | --- |
| Repository | | |
| Profile version and date | | |
| Standard version adopted | v2.2 | `<dest>/a-plus/VERSION` |
| Accountable owners | engineering · security · product · operations (one person may hold several) | |
| Risk owner for exceptions | | |

**Current context** (Layer 2 §1; record the stricter value when unsure):

| Fact | Value | Evidence |
| --- | --- | --- |
| `roles` | | |
| `users` | | |
| `auth` | | |
| `exposure` | | |
| `delivery` | | |
| `personal-data` | | |
| `money` | | |
| `regulated` | | |
| `persistent-data` | | |
| `async` | | |
| `integrations` | | |
| `locales` | | |
| `availability` | | |
| `team` | | |

**Target context** (facts that will change, with trigger or date): …

## 2. Stack

| Component (path) | Role | Language and framework | Package manager and lockfile | Test runner | Lint, format, typecheck |
| --- | --- | --- | --- | --- | --- |
| | | | | | |

## 3. Commands (exact, copy-pasteable, one per row; every row located in a manifest, script or CI file)

| Purpose | Command | Source of truth | Gate (merge/release/diagnostic) |
| --- | --- | --- | --- |
| **gate (runs every merge row below)** | | | merge |
| format check | | | |
| lint, including boundary checks (C-16) | | | |
| typecheck | | | |
| unit tests | | | |
| integration tests (infrastructure needed: …) | | | |
| contract or route-surface tests | | | |
| end-to-end | | | |
| accessibility automation | | | |
| build | | | |
| bundle or size budget | | | |
| dependency audit (each lockfile) | | | |
| secret scan / SAST | | | |
| evaluation suite (`ai`) | | | |

## 4. Structure and conventions (C-16, P-M7, P-M8)

| Item | Binding |
| --- | --- |
| Layout per component (where routes, use cases, domain, adapters, components, tests, scripts live) | |
| Public interface convention per component | |
| Allowed and forbidden import directions and the check enforcing them | |
| Naming conventions (files, modules, types, tests, routes, env keys, events) | |
| Canonical schema location and compatibility check (P-C2) | |
| Configuration schema module (C-06, B-19) | |

**One way per concern** (P-M8): the single sanctioned mechanism for each.

| Concern | Mechanism (module or library already in use) |
| --- | --- |
| HTTP client / API access | |
| Validation at boundaries (C-02) | |
| Configuration and secrets | |
| Logging and error reporting | |
| Error registry and mapping | |
| Data access and migrations | |
| Server state / caching (clients) | |
| Dates, money, ids | |
| Feature flags | |

## 5. Applicability register

One row per control family that applies; one row per control that is not applicable, with the
context fact that rules it out. Controls not listed default to applicable.

| Control id(s) | Applies? | Context fact (for N/A) or binding (for applies) | Evidence command or artefact |
| --- | --- | --- | --- |
| C-02 | yes | e.g. pydantic models at the API edge; generated client types + contract check | |
| C-03 tenant clause, P-S8 | e.g. no | e.g. `users = single-owner` | — |
| C-10, B-18 | e.g. no | e.g. `exposure = local` (bind address in …) | — |
| C-14 | | | |
| C-15, P-O1, P-O2 | yes | | |
| C-16, P-M7, P-M8 | yes | see §4 | |
| P-P1 budgets | | see §6 | |

## 6. Budgets (with method and date)

| Budget | Value | Measured how | Date | Change approval |
| --- | --- | --- | --- | --- |
| | | | | |

## 7. Exemplars

One module per layer that meets the bar and is safe to copy (service module, web feature,
job, CLI command…), with the traits to extract.

## 8. Known gaps (dated; each with owner and backlog item)

Use the gap format of Layer 5 §4.

| Control id | Gap | Native options | Owner | Target date |
| --- | --- | --- | --- | --- |
| | | | | |

Agents MUST treat every row here as not implemented.

## 9. Exceptions register

Open exceptions with control id, accepted risk, compensating control, approver and expiry
(P-Z1–Z4).

## 10. Agent bindings

| Item | Binding |
| --- | --- |
| Trusted instruction sources (X-1) | e.g. `AGENTS.md`, `CLAUDE.md`, this profile |
| Ownership lanes and forbidden paths | |
| Default permission scope per task type (X-2) | |
| Approval channel and approvers (X-3) | |
| Independent reviewer arrangement (X-6) | |
| Report destination and format (X-8) | |
