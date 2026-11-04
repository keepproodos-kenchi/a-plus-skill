# Refactor to A+ — implementation workflow

Use this workflow when the user requests whole-project A+ implementation, hardening or
refactoring. Ordinary scoped fixes use the build mode. Document adoption installs guidance;
it does not implement controls. Resolve the user's scope before labeling an outcome complete.

## 1. Bind the task

Record the loaded skill path/version and adopted project version, dirty-work baseline,
component roots, frameworks/lockfiles, current and target context, and authorized actions.
Read `01`, `02`, relevant `03` playbooks, the profile, `05`, `06` and all applicable parts of
`07`. Reconcile stale installed copies; explicit upgrade authorization suffices, otherwise
prepare the upgrade for approval. Preserve the existing profile and owner instructions.

Declare in profile §4:

- **Layout:** `preserve` by default; `canonical` when the user requests exact reference
  structure or selects it. Expand Layer 7 into a concrete target tree with roots, feature
  boundaries, filenames, test locations, public entrypoints and an old → new path map.
  Enforce that target. Business filenames come from actual capabilities, not the cart sample.
- **Observability:** `native` by default; `canonical` selects Layer 7 §4.6 for FastAPI/Next.js.
  Layout selection alone does not select vendors. An approved canonical stack supersedes
  native-first for those named mechanisms; preserve runtime compatibility and scope.
- **UI:** inspect component usage and tokens, not just installed packages. Follow W-26:
  propose shadcn/ui when a compatible React UI has no adopted design system. Implement an
  authorized adoption; reuse a verified existing system unless replacement is authorized.

Canonical migration authorization supersedes the preserve-layout default. Honor approvals
already given; ask only for missing decisions or actions outside scope. Credentials, hosted
configuration, destructive data operations and external telemetry transmission retain their
actual authorization boundaries. Work on independent local tasks while those are unresolved.

## 2. Account for every control

Inventory real routes, actions, jobs, stores, authentication/authorization paths, integrations,
streams, error handlers and deployed telemetry. Run existing baseline commands. Use one row
per control from the installed standard plus project-specific requirements. A family heading
does not satisfy its member controls. Record applicability, context evidence, implementation,
verification, revision/environment, status and blocker/owner. Unknown is an open gap.

Use these statuses: `missing`, `implemented`, `verified`, `failed`, `blocked`, `not-applicable`.
Only verified applicable controls count as met. N/A needs a concrete context fact and evidence;
lack of credentials or effort is never N/A. If a compound control is partially met, the whole
row remains incomplete; list the satisfied and missing clauses. Temporary exceptions remain
unmet and cannot turn a refactor-complete/A+ claim green.

## 3. Plan and execute verified slices

Produce the target map, baseline evidence, control ledger and ordered migration plan in the
project's documentation location. For each slice name compatibility constraints, entrypoints,
API/schema changes, test coverage, deployment order and rollback. These artifacts are inputs
to implementation, not completion of a refactor request.

1. Establish shared mechanisms and their wiring without unused scaffolding.
2. Migrate one end-to-end feature, including authorization, telemetry and tests; verify it.
3. Apply the proven pattern to remaining features; preserve parallel work and public contracts.
4. Remove obsolete paths only after consumers and startup/deploy commands are migrated.

Use real dependency/AST/compiler checks for architecture. Enforce declared paths and resolved
imports, aliases, re-exports, cycles, public modules and runtime boundaries. Prove rejection of
deep imports/cycles/server leaks and acceptance of valid Server Actions. A directory inventory
alone cannot verify dependencies; a regex import scanner is not sufficient (R-10).

Security work exercises actual handlers and data access: denied unauthenticated/unauthorized
requests, object/tenant isolation, validation and abuse bounds, safe queries, session/cookie/
CSRF behavior where applicable, secret handling, concurrency and replay. Select cases from
the profile, not a universal login template. Security files alone are not evidence.

Observability work uses Layer 7's coverage matrix and acceptance checks on real workflows:
success, denial, expected/unexpected failure, integration timeouts and stream cancellation.
Prove redaction, correlation, bounded metrics, exporter failure isolation and destination
delivery. Diagnostic logs, product analytics and durable audit records have distinct owners.
For UI, verify the adopted system on representative screens and real keyboard/responsive
journeys; a component package alone does not satisfy design or accessibility controls.

## 4. Gate and independent review

Wire one repository-native gate that runs all applicable required checks and fails if a
required check or evidence is absent. CI must run the gate without a success-on-skip path.
Protect acceptance definitions, test gates and source-of-truth standards against unilateral
weakening; use review and required checks where supported. Changes needed to strengthen an
approved gate are within that approved scope; never delete checks to obtain green.

The supplied `tools/check-evidence.py` validates accounting only. Invoke it through Python,
from the installed standard or skill package. It never executes commands in the ledger and
cannot prove truthful N/A claims, meaningful tests, deployed delivery or independence.
Run architecture, security, UI, integration and operational checks separately. Review their
artifacts, and obtain independent review for consequential security/data changes per `01`/`05`.

List the installed catalog (only adopted role playbooks should be present):

```sh
python3 docs/standards/a-plus/tools/check-evidence.py --standard-dir docs/standards/a-plus --list-controls
```

Store completion accounting as JSON in the profile's declared evidence location. Example
row shapes (replace placeholders; include every catalog control, not just these examples):

```json
{
  "standard_version": "<installed VERSION>",
  "revision": "<verified source or artifact digest>",
  "environment": "<overall verification scope>",
  "controls": [
    {
      "id": "C-01", "applies": true, "status": "verified",
      "implementation": ["src/example.py"],
      "evidence": [{"path": "evidence/gate.log", "sha256": "<artifact SHA-256>",
        "command": "<exact command or review procedure>", "exit_code": 0,
        "revision": "<same verified digest>", "environment": "<actual environment>"}]
    },
    {
      "id": "P-S8", "applies": false, "status": "not-applicable",
      "reason": "<context fact excluding tenancy>",
      "context_evidence": ["docs/standards/a-plus-profile.md"]
    }
  ]
}
```

For `blocked`/`failed`/`missing`/`implemented` rows, include the missing evidence, owner and next
action. Project-specific requirements need their own gate checks in addition to this catalog.
Store review outputs and sanitized external evidence locally; artifact paths are repository
relative and may not escape via symlinks. Evidence metadata binds to the tested revision;
the trusted gate supplies it, not a value copied from the ledger. For dirty trees use a digest
of the tested source snapshot, excluding generated evidence; a clean commit is also valid.

```sh
python3 docs/standards/a-plus/tools/check-evidence.py --standard-dir docs/standards/a-plus --repo . --evidence docs/standards/a-plus-evidence.json --revision "$VERIFIED_REVISION"
```

Artifacts may come from different environments but all must match the tested revision.
Review environment coverage per control: a local mock does not establish hosted behavior.
Artifact hashes detect changes, not fabricated content. Protect the catalog and verify selected
roles against the profile so deleting a playbook cannot remove requirements unnoticed.

## 5. Completion

Continue implementation until the authorized scope is complete or an actual blocker prevents
progress. Independent local work should continue when one external gate is blocked. Finish
with the three axes separately: code quality, verification confidence and release readiness.
Give changed paths, executed commands/exits, artifacts, reviewed revision, unmet controls and
exact next steps. A blocked destination means incomplete operational verification; no hosted
claim. An exception may permit a separately approved release decision, never full conformance.

Full refactor completion requires every applicable control verified, the declared canonical
target enforced when selected, actual security/telemetry wiring, UI acceptance where applicable,
and relevant independent review. A profile, a plan, empty folders or a passing accounting
checker is not that outcome.
