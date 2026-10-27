# A+ Engineering Standard (generic, v2.1)

A stack-agnostic standard for building and reviewing production-ready, enterprise-grade
software (services, web and mobile clients, libraries and CLIs, pipelines and AI features)
by engineers and AI coding agents. It covers security, data integrity, reliability,
observability, structure, consistency, testing and release.

**A+ means:** every control that applies to the system's declared context is met, with
evidence. The bar is the same for every project; the project's context decides which controls
apply, and the project's own stack decides how each is met.

## What is in this folder

| File | Layer | Edit per project? |
| --- | --- | --- |
| `01-constitution.md` | 1. How the standard binds (context, intent, native first), principles, non-negotiables `C-01`…`C-16` | No |
| `02-context-risk-and-policies.md` | 2. Context model, risk tiers, assessment axes, policies `P-…` with applicability, exceptions | No |
| `03-playbook-service.md`, `03-playbook-web.md`, `03-playbook-mobile.md`, `03-playbook-library-cli.md`, `03-playbook-pipeline-ai.md` | 3. Role mechanics `B-`, `W-`, `M-`, `L-`, `J-`/`AI-` | No (keep only the roles you have) |
| `04-project-profile-template.md` | 4. Template for the project profile | **Copy and fill** |
| `05-agent-execution-contract.md` | 5. Agent rules `X-1`…`X-12`, brief, report, gap and finding formats, reviewer checklist | No |
| `06-stack-bindings.md` | 6. Example native bindings per ecosystem (examples, never requirements) | No |
| `07-reference-layouts.md` | 7. Reference FastAPI and Next.js trees, architecture tests, observability layout (reference, not mandate) | No |

Change log: `CHANGELOG.md`. Version: `VERSION`.

## Adopt it in a project (once)

1. **Copy** this folder into the project, for example `docs/standards/a-plus/`. Do not edit
   the layer files; changes to them go through an architecture decision record.
2. **Create the profile** from `04-project-profile-template.md` as
   `docs/standards/a-plus-profile.md`, filled from evidence:
   - context facts and target context, each with its evidence;
   - stack per component; exact commands, each located in a manifest, script or CI file;
   - structure, naming and the one mechanism per concern the repository already uses;
   - applicability register (not-applicable rows cite a context fact);
   - risk-relevant budgets, exemplars, known gaps in the gap format, agent bindings.
3. **Point agents at it** from `AGENTS.md` / `CLAUDE.md`.
4. **Wire one gate command** that runs the profile's merge rows, in CI when a remote exists.

## Use it on every change

1. **Classify** the change (Layer 2 §2) and list the applicable control ids with their
   profile bindings.
2. **Brief** with Layer 5 §3; **implement** in the declared structure, test first;
   **verify** with the profile commands and read exit codes.
3. **Report** with Layer 5 §3; **review** with Layer 5 §5; record the three axes separately.
4. **Merge and release** only when Layer 2 §3 eligibility is met.

## Keep it current

- Update the profile whenever a tool, context fact, budget, gap or exception changes; date it.
- Keep one master copy outside any project and pull tagged versions into each project.

## Rules of thumb

- If you cannot tell whether an applicable control is met, it is not met. Add the test, check
  or measurement that settles it.
- If a recommendation names a tool the project does not already use, first show why every
  native option fails.
