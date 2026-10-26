#!/usr/bin/env bash
# Adopt the A+ Engineering Standard in a repository.
#
# Copies the standard's layer files into <repo>/<dest>/a-plus/, creates the project
# profile from the Layer 4 template if none exists, and adds a marked pointer block to the
# repository's agent instruction files. Safe to re-run: it never overwrites a profile, never
# rewrites existing text in instruction files, and refuses a version change without
# --upgrade.
#
# Usage:
#   adopt.sh [--repo DIR] [--dest PATH] [--stacks backend,web,mobile]
#            [--agents-file FILE]... [--upgrade] [--dry-run]
#
# Defaults: --repo .  --dest docs/standards  --stacks backend,web,mobile
#           agents files: existing AGENTS.md and CLAUDE.md; AGENTS.md is created if neither exists.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(cd "$SCRIPT_DIR/../standard" && pwd)"
MARKER="<!-- a-plus:pointer -->"

repo="."
dest="docs/standards"
stacks="backend,web,mobile"
agents_files=""
upgrade=0
dry=0

die() { echo "adopt: $*" >&2; exit 1; }
say() { echo "adopt: $*"; }
run() {
  if [ "$dry" -eq 1 ]; then
    # Show paths relative to the repository to keep the plan readable.
    local line="$*"
    echo "  [dry-run] ${line//$SRC\//standard/}" | sed "s#${repo:-.}/##g"
  else
    "$@"
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --repo) repo="${2:?--repo needs a value}"; shift 2 ;;
    --dest) dest="${2:?--dest needs a value}"; shift 2 ;;
    --stacks) stacks="${2:?--stacks needs a value}"; shift 2 ;;
    --agents-file) agents_files="$agents_files ${2:?--agents-file needs a value}"; shift 2 ;;
    --upgrade) upgrade=1; shift ;;
    --dry-run) dry=1; shift ;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
done

[ -d "$repo" ] || die "repository directory not found: $repo"
repo="$(cd "$repo" && pwd)"
case "$dest" in /*|*..*) die "--dest must be a relative path inside the repository: $dest" ;; esac
[ -f "$SRC/VERSION" ] || die "standard not found next to this script: $SRC"
version="$(tr -d '[:space:]' < "$SRC/VERSION")"

# Validate stacks.
playbooks=""
old_ifs="$IFS"; IFS=','
for s in $stacks; do
  case "$s" in
    backend|web|mobile) playbooks="$playbooks 03-playbook-$s.md" ;;
    "") ;;
    *) IFS="$old_ifs"; die "unknown stack: $s (use backend, web, mobile)" ;;
  esac
done
IFS="$old_ifs"
[ -n "$playbooks" ] || die "--stacks selected no playbook"

target="$repo/$dest/a-plus"
profile="$repo/$dest/a-plus-profile.md"
[ "$dry" -eq 1 ] && say "dry run: nothing will be written"
say "repository: $repo"
say "standard $version -> $dest/a-plus/ (stacks: $stacks)"

# 1. Copy the layers.
copy_layers=1
if [ -f "$target/VERSION" ]; then
  current="$(tr -d '[:space:]' < "$target/VERSION")"
  if [ "$current" = "$version" ]; then
    say "already at $version; layer files left as they are"
    copy_layers=0
    for f in $playbooks; do
      if [ ! -f "$target/$f" ]; then
        run cp "$SRC/$f" "$target/$f"
        say "added playbook $f"
      fi
    done
  elif [ "$upgrade" -eq 0 ]; then
    die "installed version is $current, this package is $version. Re-run with --upgrade to replace the layer files (the profile is never touched)."
  else
    backup="$target.bak-$current"
    [ -e "$backup" ] && die "backup already exists: $backup. Move it away, then re-run."
    say "upgrading $current -> $version; previous layers kept in $dest/a-plus.bak-$current"
    run mv "$target" "$backup"
  fi
fi
if [ "$copy_layers" -eq 1 ]; then
  run mkdir -p "$target"
  for f in 01-constitution.md 02-risk-and-quality-policies.md 04-project-profile-template.md \
           05-agent-execution-contract.md README.md CHANGELOG.md VERSION $playbooks; do
    run cp "$SRC/$f" "$target/$f"
  done
  say "copied layer files"
fi

# 2. Create the profile if absent.
if [ -e "$profile" ]; then
  say "profile exists, not touched: $dest/a-plus-profile.md"
else
  repo_name="$(basename "$repo")"
  today="$(date +%Y-%m-%d)"
  if [ "$dry" -eq 1 ]; then
    echo "  [dry-run] create $dest/a-plus-profile.md from the Layer 4 template"
  else
    mkdir -p "$(dirname "$profile")"
    {
      echo "# A+ Project Profile — $repo_name"
      echo
      echo "**Adopted standard:** A+ Engineering Standard $version (\`$dest/a-plus/\`) on $today."
      echo "**Status:** draft — fill every section; until a control has a binding it belongs in Known gaps."
      echo
      sed '1d' "$SRC/04-project-profile-template.md"
    } > "$profile"
  fi
  say "created profile: $dest/a-plus-profile.md (draft)"
fi

# 3. Add the pointer to agent instruction files.
if [ -z "$agents_files" ]; then
  for f in AGENTS.md CLAUDE.md; do
    [ -f "$repo/$f" ] && agents_files="$agents_files $f"
  done
  [ -n "$agents_files" ] || agents_files=" AGENTS.md"
fi
for f in $agents_files; do
  path="$repo/$f"
  if [ -f "$path" ] && grep -qF "$MARKER" "$path"; then
    say "pointer already present in $f"
    continue
  fi
  if [ "$dry" -eq 1 ]; then
    echo "  [dry-run] append A+ pointer block to $f"
    continue
  fi
  {
    [ -s "$path" ] && echo
    echo "$MARKER"
    echo "## Engineering standard"
    echo
    echo "Before any code change, read \`$dest/a-plus-profile.md\`, then"
    echo "\`$dest/a-plus/05-agent-execution-contract.md\`. Use its brief and report templates."
    echo "Controls listed under the profile's \"Known gaps\" are not implemented; do not assume them."
    echo "Load \`$dest/a-plus/01-constitution.md\`, \`02-risk-and-quality-policies.md\` and the playbook"
    echo "for the stack you touch as the task requires."
    echo "<!-- /a-plus:pointer -->"
  } >> "$path"
  say "added pointer to $f"
done

say "done. Next: fill $dest/a-plus-profile.md (commands, risk map, control bindings, budgets, exemplars, known gaps)."
