#!/usr/bin/env bash
# Read-only scan of a repository to help draft an A+ project profile.
# Prints Markdown facts (stacks, package manager, scripts, CI, test and lint tooling,
# security scanners). It infers nothing it did not find; everything it prints is a
# candidate binding for a human or agent to confirm.
#
# Usage: scan-repo.sh [DIR]
set -euo pipefail

repo="${1:-.}"
[ -d "$repo" ] || { echo "scan-repo: not a directory: $repo" >&2; exit 1; }
cd "$repo"

has() { [ -e "$1" ]; }
found() { echo "- $*"; }

echo "# Repository scan: $(basename "$(pwd)")"
echo
echo "_Read-only. Every line is a candidate for the profile, to be confirmed._"
echo

echo "## Package managers and workspaces"
for f in pnpm-lock.yaml package-lock.json yarn.lock bun.lockb pnpm-workspace.yaml turbo.json nx.json \
         go.mod Cargo.toml pyproject.toml poetry.lock requirements.txt Gemfile build.gradle build.gradle.kts \
         settings.gradle pom.xml Package.swift Podfile pubspec.yaml composer.json; do
  has "$f" && found "\`$f\`"
done
echo

echo "## Stacks detected"
backend=0; web=0; mobile=0
if find . -maxdepth 4 -name package.json -not -path '*/node_modules/*' 2>/dev/null | head -50 | \
   xargs grep -l -E '"(@nestjs/core|express|fastify|koa|hono)"' 2>/dev/null | grep -q .; then backend=1; fi
has go.mod && backend=1; has Cargo.toml && backend=1; has pyproject.toml && backend=1; has pom.xml && backend=1
if find . -maxdepth 4 -name package.json -not -path '*/node_modules/*' 2>/dev/null | head -50 | \
   xargs grep -l -E '"(next|react-dom|vue|svelte|@angular/core|nuxt|astro)"' 2>/dev/null | grep -q .; then web=1; fi
if find . -maxdepth 4 -name package.json -not -path '*/node_modules/*' 2>/dev/null | head -50 | \
   xargs grep -l -E '"(react-native|expo)"' 2>/dev/null | grep -q .; then mobile=1; fi
has pubspec.yaml && mobile=1
find . -maxdepth 3 \( -name '*.xcodeproj' -o -name AndroidManifest.xml \) -not -path '*/node_modules/*' 2>/dev/null | grep -q . && mobile=1
[ "$backend" -eq 1 ] && found "backend"
[ "$web" -eq 1 ] && found "web"
[ "$mobile" -eq 1 ] && found "mobile"
[ $((backend + web + mobile)) -eq 0 ] && found "none recognised — choose stacks manually"
echo

echo "## Scripts per package (candidate commands)"
if command -v python3 >/dev/null 2>&1; then
  find . -maxdepth 4 -name package.json -not -path '*/node_modules/*' 2>/dev/null | sort | head -40 | \
  python3 -I -c '
import json, sys
keys = ("lint","typecheck","type-check","test","test:unit","test:integration","test:e2e","e2e","build",
        "format","format:check","check","audit","coverage")
for path in sys.stdin.read().split():
    try:
        data = json.load(open(path))
    except Exception:
        continue
    scripts = data.get("scripts") or {}
    picked = [k for k in scripts if k in keys or k.startswith(("lint","test","check","typecheck","build"))]
    if not picked:
        continue
    name = data.get("name", "unnamed")
    print(f"- `{path}` ({name})")
    for k in picked[:14]:
        print(f"  - `{k}`: `{scripts[k][:110]}`")
'
else
  echo "- python3 not available; inspect package.json scripts manually"
fi
has Makefile && { found "\`Makefile\` targets:"; grep -E '^[a-zA-Z0-9_.-]+:' Makefile | cut -d: -f1 | head -20 | sed 's/^/  - /'; }
echo

echo "## CI"
for d in .github/workflows .gitlab-ci.yml .circleci azure-pipelines.yml bitbucket-pipelines.yml Jenkinsfile; do
  has "$d" && found "\`$d\`"
done
if has .github/workflows; then
  for wf in .github/workflows/*.y*ml; do
    [ -f "$wf" ] || continue
    names="$(grep -E '^[[:space:]]+- name:' "$wf" | sed -E 's/^[[:space:]]+- name:[[:space:]]*//' | head -25 | paste -sd ';' - | sed 's/;/; /g')"
    found "\`$wf\` steps: ${names:-none named}"
  done
fi
echo

echo "## Quality and security tooling"
for f in eslint.config.js eslint.config.mjs .eslintrc.js .eslintrc.json .eslintrc.cjs biome.json \
         .prettierrc prettier.config.js tsconfig.json vitest.config.ts jest.config.js jest.config.ts \
         playwright.config.ts cypress.config.ts stryker.conf.json stryker.config.mjs \
         .gitleaks.toml .github/security/gitleaks.toml .semgrep.yml semgrep.yml .snyk osv-scanner.toml \
         renovate.json .github/dependabot.yml sonar-project.properties; do
  has "$f" && found "\`$f\`"
done
echo

echo "## Agent instruction files"
for f in AGENTS.md CLAUDE.md .cursorrules .cursor/rules GEMINI.md .github/copilot-instructions.md; do
  has "$f" && found "\`$f\`"
done
grep -l "a-plus:pointer" AGENTS.md CLAUDE.md 2>/dev/null | sed 's/^/- A+ pointer present in /' || true
echo

echo "## Existing A+ adoption"
for f in docs/standards/a-plus/VERSION docs/standards/a-plus-profile.md; do
  has "$f" && found "\`$f\`$( [ "${f##*/}" = VERSION ] && echo " = $(cat "$f")")"
done
true
