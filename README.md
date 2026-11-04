# a-plus skill

The A+ Engineering Standard (v2.4.0) packaged as one agent skill for Claude Code, Codex and opencode. It is a plain `SKILL.md` folder, the format all three read.

**What it is for:** building, hardening and reviewing software to a production-ready, enterprise-grade bar (security, data integrity, reliability, observability, structure, consistency, testing, release) in any stack. **A+ = every control that applies to the system's declared context is met, with evidence.** The project's context (users, exposure, delivery, data, money…) decides which controls apply; the project's own stack decides how each is met. Named tools are examples; the agent uses what the repository already has before proposing anything new.

| Works with | Playbook |
|---|---|
| APIs and servers: FastAPI, Django, Flask, NestJS, Express, Fastify, Go, Spring… | `service` |
| Browser apps: React + Vite, Next.js, Vue, Svelte, Angular, PWAs | `web` |
| Native and cross-platform apps: Swift, Kotlin, React Native, Expo, Flutter | `mobile` |
| Libraries, SDKs, CLIs, repository scripts | `library-cli` |
| Batch, ETL, stream, ML, LLM features and agents | `pipeline-ai` |

**Not for:** certifying compliance (it prepares evidence, it does not certify), replacing your linters, or deciding which features to build.

```
skills/a-plus/
  SKILL.md      how the agent uses the standard (adopt, build, review, gaps, briefs)
  standard/     layers 1-7, refactor workflow, profile template, changelog
  tools/        scan-repo.sh (read-only), adopt.sh, check-evidence.py
install.sh      links or copies the skill into each agent's skills directory
INSTALL.md      steps an agent can follow on any machine
```

## Install on a new machine

Tell your agent: *"Install the a-plus skill from `<repo URL>`; follow INSTALL.md in the repo."* Or by hand:

```sh
git clone <repo URL> ~/.local/share/a-plus-skill
sh ~/.local/share/a-plus-skill/install.sh        # --copy, --agents claude,codex,opencode, --dry-run, --uninstall
```

Then restart the agent session and ask for "adopt the A+ standard in this repo" or "review this diff against A+".

## Updating the standard

Edit under `skills/a-plus/standard/`, bump `VERSION`, add a `CHANGELOG.md` entry, push. Repositories with an older copy upgrade with `tools/adopt.sh --roles <roles> --upgrade` (the profile is never touched; previous layers are kept as a backup).

## Refactor a project to A+

Use the explicit **Refactor to A+** mode for implementation. Select `layout = canonical` for
an exact project-specific target derived from Layer 7, and `observability = canonical` for
its FastAPI/Next.js stack. These selections are separate. The workflow implements and verifies
security, observability and UI requirements; a profile or gap report alone is not completion.
For compatible React UIs without an adopted design system, the skill proposes shadcn/ui.

Document setup (this command does not refactor application code):

```sh
bash skills/a-plus/tools/adopt.sh --repo /path/to/project --roles service,web --layout canonical --observability canonical --dry-run
```

Run without `--dry-run` when authorized; use `--upgrade` for an older adopted version. Existing
profiles are preserved and need explicit reconciliation. Runtime and hosted verification are
separate from evidence-accounting checks; unavailable destinations remain verification gaps.

## Verify this skill package

```sh
bash tests/check.sh
```

The local gate tests adoption and evidence accounting, shell syntax and whitespace. See
`tests/skill-scenarios.md` for isolated agent evaluations. Neither gate certifies an adopting
application's security or production readiness.
