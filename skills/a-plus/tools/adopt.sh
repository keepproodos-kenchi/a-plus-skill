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
#   adopt.sh --roles ROLES [--repo DIR] [--dest PATH]
#            [--agents-file FILE]... [--upgrade] [--dry-run]
#
# ROLES is a comma list of: service, web, mobile, library, cli, pipeline, ai
# (backend is accepted for service; --stacks is accepted for --roles). Only the matching
# playbooks are copied, so pick the roles the system really has (see scan-repo.sh).
#
# Defaults: --repo .  --dest docs/standards
#           agents files: existing AGENTS.md and CLAUDE.md; AGENTS.md is created if neither exists.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(cd "$SCRIPT_DIR/../standard" && pwd)"
MARKER="<!-- a-plus:pointer -->"

repo="."
dest="docs/standards"
roles=""
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
    --roles|--stacks) roles="${2:?$1 needs a value}"; shift 2 ;;
    --agents-file) agents_files="$agents_files ${2:?--agents-file needs a value}"; shift 2 ;;
    --upgrade) upgrade=1; shift ;;
    --dry-run) dry=1; shift ;;
    -h|--help) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
done

[ -d "$repo" ] || die "repository directory not found: $repo"
repo="$(cd "$repo" && pwd)"
case "$dest" in /*|*..*) die "--dest must be a relative path inside the repository: $dest" ;; esac
[ -f "$SRC/VERSION" ] || die "standard not found next to this script: $SRC"
version="$(tr -d '[:space:]' < "$SRC/VERSION")"

# Map roles to playbooks, without duplicates.
[ -n "$roles" ] || die "--roles is required (service, web, mobile, library, cli, pipeline, ai); run scan-repo.sh to see candidates"
playbooks=""
add_playbook() { case " $playbooks " in *" $1 "*) ;; *) playbooks="$playbooks $1" ;; esac; }
old_ifs="$IFS"; IFS=','
for r in $roles; do
  case "$r" in
    service|backend) add_playbook 03-playbook-service.md ;;
    web) add_playbook 03-playbook-web.md ;;
    mobile) add_playbook 03-playbook-mobile.md ;;
    library|cli) add_playbook 03-playbook-library-cli.md ;;
    pipeline|ai) add_playbook 03-playbook-pipeline-ai.md ;;
    "") ;;
    *) IFS="$old_ifs"; die "unknown role: $r (use service, web, mobile, library, cli, pipeline, ai)" ;;
  esac
done
IFS="$old_ifs"
[ -n "$playbooks" ] || die "--roles selected no playbook"

target="$repo/$dest/a-plus"
profile="$repo/$dest/a-plus-profile.md"
[ "$dry" -eq 1 ] && say "dry run: nothing will be written"
say "repository: $repo"
say "standard $version -> $dest/a-plus/ (roles: $roles)"

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
    # Keep the playbooks the repository already had (v1 "backend" is v2 "service").
    for old in "$target"/03-playbook-*.md; do
      [ -f "$old" ] || continue
      case "${old##*/}" in
        03-playbook-backend.md) add_playbook 03-playbook-service.md ;;
        *) [ -f "$SRC/${old##*/}" ] && add_playbook "${old##*/}" ;;
      esac
    done
    say "upgrading $current -> $version; previous layers kept in $dest/a-plus.bak-$current; playbooks:$playbooks"
    say "after upgrade, add the new profile sections (context, stack, structure, applicability) from 04-project-profile-template.md"
    run mv "$target" "$backup"
  fi
fi
if [ "$copy_layers" -eq 1 ]; then
  run mkdir -p "$target"
  for f in 01-constitution.md 02-context-risk-and-policies.md 04-project-profile-template.md \
           05-agent-execution-contract.md 06-stack-bindings.md README.md CHANGELOG.md VERSION $playbooks; do
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
END_MARKER="<!-- /a-plus:pointer -->"
pointer_block() {
  echo "$MARKER"
  echo "## Engineering standard"
  echo
  echo "Before any code change, read \`$dest/a-plus-profile.md\` (context, stack, structure,"
  echo "applicable controls), then \`$dest/a-plus/05-agent-execution-contract.md\`. Use its brief,"
  echo "report, gap and finding formats. Meet controls with the mechanisms this repository already"
  echo "uses (X-11); a new dependency needs approval. Controls under the profile's \"Known gaps\" are"
  echo "not implemented; do not assume them. Load \`$dest/a-plus/01-constitution.md\`,"
  echo "\`02-context-risk-and-policies.md\`, \`06-stack-bindings.md\` and the playbook for the role you"
  echo "touch as the task requires."
  echo "$END_MARKER"
}
for f in $agents_files; do
  path="$repo/$f"
  if [ -f "$path" ] && grep -qF "$MARKER" "$path"; then
    if [ "$upgrade" -eq 1 ] && grep -qF "$END_MARKER" "$path"; then
      # Replace only the block this script wrote, between its markers.
      if [ "$dry" -eq 1 ]; then
        echo "  [dry-run] refresh A+ pointer block in $f"
      else
        block="$(pointer_block)"
        tmp="$(mktemp "$path.XXXXXX")"
        awk -v start="$MARKER" -v end="$END_MARKER" -v block="$block" '
          $0 == start { print block; skip = 1; next }
          skip && $0 == end { skip = 0; next }
          !skip { print }
        ' "$path" > "$tmp" && mv "$tmp" "$path"
        say "refreshed pointer in $f"
      fi
    else
      say "pointer already present in $f"
    fi
    continue
  fi
  if [ "$dry" -eq 1 ]; then
    echo "  [dry-run] append A+ pointer block to $f"
    continue
  fi
  {
    [ -s "$path" ] && echo
    pointer_block
  } >> "$path"
  say "added pointer to $f"
done

say "done. Next: fill $dest/a-plus-profile.md (context, stack, commands, structure, applicability, gaps)."
