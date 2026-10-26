# Install instructions for an AI agent

You are Claude Code, Codex or opencode, and the user asked you to install the `a-plus` skill from this repository. Do this:

1. Clone it somewhere stable, not a temp dir (the default install symlinks into the clone):
   `git clone <this repo URL> ~/.local/share/a-plus-skill` (skip if already cloned; `git -C <dir> pull` instead).
2. Preview: `sh ~/.local/share/a-plus-skill/install.sh --dry-run`
3. Install: `sh ~/.local/share/a-plus-skill/install.sh` (add `--copy` if the user wants no link to the clone, or `--agents claude`, `--agents codex`, `--agents opencode` to limit targets).
4. Verify `~/.claude/skills/a-plus/SKILL.md` and `~/.agents/skills/a-plus/SKILL.md` exist, then tell the user to restart the session.

Skill directories used: Claude Code `~/.claude/skills`, Codex `~/.agents/skills`, opencode reads both of those (and `~/.config/opencode/skills`). The script never overwrites a real directory or a foreign link; if it reports a skip, show the user and stop.

Uninstall: `sh install.sh --uninstall`. Update: `git pull` (links) or re-run with `--copy`.
