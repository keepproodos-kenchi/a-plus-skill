# a-plus skill

The A+ Engineering Standard (v1.1.0) packaged as one agent skill for Claude Code, Codex and opencode. It is a plain `SKILL.md` folder, the format all three read.

```
skills/a-plus/
  SKILL.md      when/how the agent uses the standard (adopt, build, review, brief)
  standard/     layers 1-5, profile template, changelog
  tools/        adopt.sh, scan-repo.sh
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

Edit under `skills/a-plus/standard/`, bump `VERSION`, add a `CHANGELOG.md` entry, push.
