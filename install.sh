#!/bin/sh
# Install the a-plus skill for Claude Code, Codex and opencode.
#
# Usage: sh install.sh [--copy] [--agents claude,codex,opencode] [--dry-run] [--uninstall]
#
# Default is a symlink into this checkout, so `git pull` updates the skill everywhere.
# --copy installs a standalone copy instead. Never overwrites a real directory or a
# link that points somewhere else. opencode also reads ~/.claude/skills and ~/.agents/skills,
# so it needs its own target only when you pass --agents opencode without the others.
set -eu
[ "$(id -u)" != 0 ] || { echo 'Refusing to run as root.' >&2; exit 1; }
: "${HOME:?HOME must be set}"

mode=link
dry=0
uninstall=0
agents=claude,codex,opencode
while [ "$#" -gt 0 ]; do
  case $1 in
    --copy) mode=copy ;;
    --dry-run) dry=1 ;;
    --uninstall) uninstall=1 ;;
    --agents) [ "$#" -ge 2 ] || { echo 'usage: --agents needs a value' >&2; exit 2; }; agents=$2; shift ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

repo=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
src=$repo/skills/a-plus
[ -f "$src/SKILL.md" ] || { echo "missing $src/SKILL.md" >&2; exit 1; }

# Map agent names to skill directories, de-duplicated. Claude and Codex dirs are read by opencode too.
targets=
add() { case " $targets " in *" $1 "*) ;; *) targets="$targets $1" ;; esac; }
case ,$agents, in *,claude,*) add "$HOME/.claude/skills" ;; esac
case ,$agents, in *,codex,*) add "$HOME/.agents/skills" ;; esac
case ,$agents, in
  *,opencode,*)
    case " $targets " in
      *" $HOME/.claude/skills "*|*" $HOME/.agents/skills "*) ;;
      *) add "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills" ;;
    esac ;;
esac
[ -n "$targets" ] || { echo "no valid agent in: $agents" >&2; exit 2; }

run() { if [ "$dry" = 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }
status=0
for dir in $targets; do
  dest=$dir/a-plus
  if [ "$uninstall" = 1 ]; then
    if [ -L "$dest" ]; then run rm "$dest"; echo "removed link $dest"
    elif [ -d "$dest" ] && [ -f "$dest/.installed-by-a-plus-skill" ]; then run rm -r "$dest"; echo "removed copy $dest"
    elif [ -e "$dest" ]; then echo "skip $dest: not installed by this script" >&2; status=1
    fi
    continue
  fi
  if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" = "$src" ] && [ "$mode" = link ]; then echo "ok $dest (already linked)"; continue; fi
    if [ "$(readlink "$dest")" = "$src" ]; then run rm "$dest"; else echo "skip $dest: link points elsewhere" >&2; status=1; continue; fi
  elif [ -e "$dest" ]; then
    if [ -f "$dest/.installed-by-a-plus-skill" ] && [ "$mode" = copy ]; then run rm -r "$dest"
    else echo "skip $dest: exists and was not installed by this script" >&2; status=1; continue; fi
  fi
  run mkdir -p "$dir"
  if [ "$mode" = link ]; then
    run ln -s "$src" "$dest"
  else
    run cp -R "$src" "$dest"
    [ "$dry" = 1 ] || : > "$dest/.installed-by-a-plus-skill"
  fi
  if [ "$dry" = 1 ]; then echo "would install $dest ($mode)"; else echo "installed $dest ($mode)"; fi
done
[ "$uninstall" = 1 ] || echo "Restart the agent session so it rediscovers skills."
exit $status
