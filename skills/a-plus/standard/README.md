# A+ Engineering Standard (generic, v1.1)

A stack-agnostic standard for producing and reviewing enterprise SaaS code (backend, web,
mobile) by engineers and AI coding agents. It names no tools, paths or numbers; a
**project profile** binds it to a specific repository.

## What is in this folder

| File | Layer | Edit per project? |
| --- | --- | --- |
| `01-constitution.md` | 1. Principles and non-negotiables `C-01`…`C-14` | No |
| `02-risk-and-quality-policies.md` | 2. Risk tiers, assessment axes, controls `P-…`, exceptions | No |
| `03-playbook-backend.md`, `03-playbook-web.md`, `03-playbook-mobile.md` | 3. Stack mechanics `B-`, `W-`, `M-` | No (keep only the stacks you use) |
| `04-project-profile-template.md` | 4. Template for the project profile | **Copy and fill** |
| `05-agent-execution-contract.md` | 5. Agent rules `X-1`…`X-10`, brief and report templates, reviewer checklist | No |

Change log: `CHANGELOG.md`. Version: `VERSION`.

## Adopt it in a project (once)

1. **Copy** this folder into the project, for example `docs/standards/a-plus/`. Do not
   edit the layer files; changes to them go through an architecture decision record.
2. **Create the profile**: copy `04-project-profile-template.md` to
   `docs/standards/a-plus-profile.md` and fill every section:
   - commands (lint, typecheck, test, build, audit, budgets), one script per line;
   - risk map (which modules are Critical, High, Medium);
   - a binding for each control id: the lint rule, script or test that enforces it;
   - budgets with measurement method and date;
   - one exemplar module per layer;
   - known gaps (control not yet enforced, owner, date);
   - agent bindings (trusted instruction files, approvers, independent reviewer).
3. **Point agents at it**: add to `AGENTS.md` / `CLAUDE.md`:
   > Read `docs/standards/a-plus-profile.md`, then `docs/standards/a-plus/05-agent-execution-contract.md`.
   > Use its brief and report templates. Anything in the profile's "known gaps" is not implemented.
4. **Wire CI** to run the profile's gate list. A control without an enforcing command stays
   in "known gaps" until one exists.

## Use it on every change

1. **Classify** the change with the risk tiers in `02` §1 and list the applicable control ids.
2. **Write the brief** with the template in `05` §3 (scope, tier, allowed paths, controls,
   baseline, verification commands, report format).
3. **Implement and verify**: red-before-green tests, then run the profile commands and read
   the exit codes.
4. **Report** with the template in `05` §4, including what could not be verified.
5. **Review** with the checklist in `05` §5. Record the three axes separately: code quality,
   verification confidence, release readiness. Never assign a single grade by hand.
6. **Merge and release** only when the eligibility rules in `02` §2 are met.

## Keep it current

- Update the profile whenever a tool, budget, gap or exception changes; date the change.
- Keep one master copy of this folder outside any single project and pull tagged versions
  into each project.

## Rule of thumb

If you cannot tell whether a control is met, it is not met. Add the test, lint rule or
measurement that settles it.
