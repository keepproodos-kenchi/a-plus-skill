#!/usr/bin/env bash
# Read-only scan of a repository to help draft an A+ project profile.
# Prints Markdown facts: components, frameworks, candidate roles, context hints, candidate
# commands, CI, quality and security tooling. It infers nothing it did not find; every line
# is a candidate for a human or agent to confirm against the code.
#
# Usage: scan-repo.sh [DIR]
set -euo pipefail

repo="${1:-.}"
[ -d "$repo" ] || { echo "scan-repo: not a directory: $repo" >&2; exit 1; }
cd "$repo"

PRUNE=( -name node_modules -o -name .git -o -name .venv -o -name venv -o -name dist -o -name build
        -o -name .next -o -name .turbo -o -name target -o -name __pycache__ -o -name .runtime
        -o -name coverage -o -name .pytest_cache -o -name .ruff_cache -o -name .mypy_cache )
# List files up to a depth, skipping vendored and generated trees.
files() { find . -maxdepth "$1" \( "${PRUNE[@]}" \) -prune -o -type f "${@:2}" -print 2>/dev/null | sed 's#^\./##' | sort; }
found() { echo "- $*"; }
# Manifests whose text names a dependency (case-insensitive word match).
manifests="$(files 4 \( -name package.json -o -name pyproject.toml -o -name 'requirements*.txt' -o -name setup.py \
  -o -name setup.cfg -o -name go.mod -o -name Cargo.toml -o -name pom.xml -o -name 'build.gradle*' -o -name pubspec.yaml \
  -o -name Gemfile -o -name composer.json \))"
dep() { [ -n "$manifests" ] && printf '%s\n' "$manifests" | tr '\n' '\0' | xargs -0 grep -l -i -E "$1" 2>/dev/null | head -5 | paste -sd ',' - | sed 's/,/, /g' || true; }
# Source files mentioning a pattern (bounded, for context hints only).
src_hits() { files 6 \( -name '*.py' -o -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.go' -o -name '*.java' -o -name '*.kt' -o -name '*.rs' \) \
  | grep -v -E '(^|/)(tests?|__tests__|spec)/|\.test\.|\.spec\.|_test\.' | head -3000 | tr '\n' '\0' \
  | xargs -0 grep -l -E "$1" 2>/dev/null | wc -l | tr -d ' ' || true; }

echo "# Repository scan: $(basename "$(pwd)")"
echo
echo "_Read-only. Every line is a candidate for the profile, to be confirmed against the code._"
echo

echo "## Components (manifests)"
if [ -n "$manifests" ]; then printf '%s\n' "$manifests" | sed 's/^/- `/; s/$/`/'; else found "none found"; fi
for d in apps packages services libs modules cmd; do
  [ -d "$d" ] || continue
  for c in "$d"/*/; do
    [ -d "$c" ] || continue
    c="${c%/}"
    langs="$(find "$c" -maxdepth 4 \( "${PRUNE[@]}" \) -prune -o -type f -print 2>/dev/null | sed -n 's/.*\.\([a-z]*\)$/\1/p' \
      | grep -E '^(py|ts|tsx|js|jsx|go|rs|java|kt|swift|dart)$' | sort | uniq -c | sort -rn | head -3 | awk '{printf "%s %s; ", $2, $1}')"
    found "\`$c\`: ${langs:-no source files}"
  done
done
for f in pnpm-workspace.yaml turbo.json nx.json lerna.json uv.lock poetry.lock pnpm-lock.yaml package-lock.json yarn.lock bun.lockb go.sum Cargo.lock; do
  [ -e "$f" ] && found "lock/workspace: \`$f\`"
done
echo

echo "## Frameworks and libraries detected"
check() { local hit; hit="$(dep "$2")"; [ -n "$hit" ] && found "$1 (in $hit)"; return 0; }
check "NestJS" '"@nestjs/core"'
check "Express / Fastify / Koa / Hono" '"(express|fastify|koa|hono)"'
check "Next.js" '"next"'
check "Vite" '"vite"'
check "React" '"react-dom"'
check "Vue / Nuxt / Svelte / Angular / Astro / Remix" '"(vue|nuxt|svelte|@sveltejs/kit|@angular/core|astro|@remix-run/[a-z]+)"'
check "React Native / Expo" '"(react-native|expo)"'
check "Electron" '"electron"'
check "Node CLI framework" '"(commander|yargs|oclif|@oclif/core|clipanion|cac)"'
check "Prisma / Drizzle / TypeORM" '"(prisma|@prisma/client|drizzle-orm|typeorm)"'
check "zod / valibot / typebox / class-validator" '"(zod|valibot|@sinclair/typebox|class-validator)"'
check "PWA tooling" '"(vite-plugin-pwa|workbox-[a-z-]+|next-pwa|@serwist/[a-z]+)"'
check "FastAPI / Starlette" '(^|[^a-z])(fastapi|starlette)([^a-z]|$)'
check "Django" '(^|[^a-z])django([^a-z]|$)'
check "Flask" '(^|[^a-z])flask([^a-z]|$)'
check "pydantic / pydantic-settings" 'pydantic'
check "SQLAlchemy / Alembic" '(sqlalchemy|alembic)'
check "Python CLI framework" '(^|[^a-z])(typer|click)([^a-z]|$)'
check "Task queue / scheduler" '(celery|(^|[^a-z])rq([^a-z]|$)|dramatiq|apscheduler|arq|bullmq|temporalio|"bull")'
check "Pipeline orchestrator" '(apache-airflow|dagster|prefect|luigi|dbt-core)'
check "LLM / agent SDK" '(anthropic|openai|langchain|llama-index|litellm|@ai-sdk|"ai"|instructor|pydantic-ai)'
check "Auth library" '(authlib|next-auth|@auth/core|passport|@nestjs/passport|python-jose|pyjwt|jose|django-allauth|lucia)'
check "Payments" '(stripe|paddle|braintree|adyen|square)'
check "i18n" '(i18next|react-intl|next-intl|vue-i18n|babel|gettext|fluent)'
check "Go HTTP / CLI" '(gin-gonic|labstack/echo|go-chi|gorilla/mux|spf13/cobra|urfave/cli)'
check "Spring" 'spring-boot'
check "Flutter" 'flutter'
echo

echo "## Candidate roles (confirm)"
roles=""
addr() { case ",$roles," in *",$1,"*) ;; *) roles="${roles:+$roles,}$1" ;; esac; }
[ -n "$(dep '"(@nestjs/core|express|fastify|koa|hono|next)"|(^|[^a-z])(fastapi|starlette|django|flask)([^a-z]|$)|spring-boot|gin-gonic|labstack/echo|go-chi')" ] && addr service
[ -n "$(dep '"(react-dom|vue|svelte|@angular/core|nuxt|astro|next|vite)"')" ] && addr web
{ [ -n "$(dep '"(react-native|expo)"')" ] || [ -n "$(files 1 -name pubspec.yaml)" ] || \
  [ -n "$(find . -maxdepth 3 \( -name '*.xcodeproj' -o -name AndroidManifest.xml \) -not -path '*/node_modules/*' 2>/dev/null)" ]; } && addr mobile
[ -n "$(dep '"bin"|\[project\.scripts\]|(^|[^a-z])(typer|click)([^a-z]|$)|"(commander|yargs|oclif)"|spf13/cobra|urfave/cli')" ] && addr cli
[ -n "$(dep '(celery|dramatiq|apscheduler|arq|bullmq|temporalio|apache-airflow|dagster|prefect|dbt-core)')" ] && addr pipeline
[ -n "$(dep '(anthropic|openai|langchain|llama-index|litellm|@ai-sdk|pydantic-ai|instructor)')" ] && addr ai
if [ -n "$roles" ]; then found "$roles  →  \`adopt.sh --roles $roles\`"; else found "none recognised — choose roles manually"; fi
found "\`library\` is not inferred: add it when other code imports a package from this repo"
echo

echo "## Context hints (each needs confirmation; Layer 2 §1)"
deploy="$(files 3 \( -name Dockerfile -o -name 'docker-compose*.y*ml' -o -name 'compose*.y*ml' -o -name fly.toml -o -name vercel.json \
  -o -name netlify.toml -o -name Procfile -o -name 'app.yaml' -o -name '*.tf' -o -name Chart.yaml -o -name kustomization.yaml \
  -o -name render.yaml -o -name railway.json -o -name wrangler.toml \) | head -8 | paste -sd ',' - | sed 's/,/, /g')"
found "delivery: ${deploy:+deploy config found: $deploy}${deploy:-no deploy config found (candidate: local-process)}"
loop="$(src_hits '127\.0\.0\.1|localhost|::1')"; anyb="$(src_hits '0\.0\.0\.0')"
found "exposure: files binding or referencing loopback: $loop; files referencing 0.0.0.0: $anyb"
found "users: files mentioning tenant ids: $(src_hits '[Tt]enant_?[Ii]d|tenant_id'); files mentioning user ids: $(src_hits '[Uu]ser_?[Ii]d|user_id')"
found "personal-data: files mentioning email/phone/address fields: $(src_hits '(email|phone|address|birth)[_A-Za-z]*[[:space:]]*[:=]')"
stores="$(files 5 \( -name '*.sqlite*' -o -name '*.db' -o -name 'schema.prisma' -o -name 'alembic.ini' \) | head -4 | paste -sd ',' - | sed 's/,/, /g')"
[ -n "$(files 5 -path '*migrations*' | head -1)" ] && stores="${stores:+$stores; }migrations folder present"
found "persistent-data: store files ${stores:-none found}; source files using a database driver: $(src_hits 'sqlite3|sqlalchemy|psycopg|asyncpg|prisma|drizzle|typeorm|mongoose|database/sql|gorm')"
sw="$(files 5 \( -name 'sw.js' -o -name 'service-worker.*' -o -name 'sw.ts' -o -name '*.webmanifest' -o -name 'manifest.json' \) | grep -v node_modules | head -4 | paste -sd ',' - | sed 's/,/, /g')"
[ -n "$sw" ] && found "PWA / service worker files: $sw"
echo

echo "## Candidate commands"
if command -v python3 >/dev/null 2>&1; then
  files 4 -name package.json | python3 -I -c '
import json, sys
for path in sys.stdin.read().split():
    try:
        data = json.load(open(path))
    except Exception:
        continue
    scripts = data.get("scripts") or {}
    picked = [k for k in scripts if k.startswith(("lint","test","check","typecheck","type-check","build","format","audit","coverage","e2e","budget","gate","verify"))]
    if picked:
        name = data.get("name", "unnamed")
        print(f"- `{path}` ({name})")
        for k in picked[:16]:
            print(f"  - `{k}`: `{scripts[k][:110]}`")
'
  files 3 -name pyproject.toml | python3 -I -c '
import sys
try:
    import tomllib
except ImportError:
    tomllib = None
for path in sys.stdin.read().split():
    if tomllib is None:
        print(f"- `{path}`: inspect manually (python < 3.11)"); continue
    try:
        data = tomllib.load(open(path, "rb"))
    except Exception:
        continue
    tool = data.get("tool", {})
    sections = sorted(k for k in tool if k in ("ruff","mypy","pyright","pytest","coverage","importlinter","poe","hatch","pdm","tox","bandit","black","isort","uv"))
    scripts = data.get("project", {}).get("scripts", {})
    groups = {**data.get("dependency-groups", {}), **data.get("project", {}).get("optional-dependencies", {})}
    dev = sorted({d.split("[")[0].split("<")[0].split(">")[0].split("=")[0].split("~")[0].strip() for g in groups.values() for d in g if isinstance(d, str)})
    none = "none"
    print(f"- `{path}`: tool sections {sections or none}; console scripts {sorted(scripts) or none}; dev deps {dev[:14] or none}")
    poe = tool.get("poe", {}).get("tasks", {})
    for k in list(poe)[:12]:
        print(f"  - poe `{k}`")
'
else
  echo "- python3 not available; inspect manifests manually"
fi
for f in Makefile justfile Justfile Taskfile.yml; do
  [ -f "$f" ] && { found "\`$f\` targets:"; grep -E '^[a-zA-Z0-9_.-]+:' "$f" | grep -v '^\.' | cut -d: -f1 | head -20 | sed 's/^/  - /'; }
done
for f in tox.ini noxfile.py .pre-commit-config.yaml lefthook.yml .husky; do [ -e "$f" ] && found "\`$f\`"; done
[ -d scripts ] && found "\`scripts/\`: $(ls scripts | head -12 | paste -sd ',' - | sed 's/,/, /g')"
grep -h -o -E '`(uv run|pnpm|npm run|yarn|poetry run|make|just|go test|cargo)[^`]*`' README.md CLAUDE.md AGENTS.md 2>/dev/null | sort -u | head -15 | sed 's/^/- documented: /' || true
echo

echo "## CI"
ci=0
for d in .github/workflows .gitlab-ci.yml .circleci azure-pipelines.yml bitbucket-pipelines.yml Jenkinsfile .woodpecker.yml; do
  [ -e "$d" ] && { found "\`$d\`"; ci=1; }
done
if [ -d .github/workflows ]; then
  for wf in .github/workflows/*.y*ml; do
    [ -f "$wf" ] || continue
    names="$(grep -E '^[[:space:]]+- name:' "$wf" | sed -E 's/^[[:space:]]+- name:[[:space:]]*//' | head -25 | paste -sd ';' - | sed 's/;/; /g')"
    found "\`$wf\` steps: ${names:-none named}"
  done
fi
[ "$ci" -eq 0 ] && found "none — P-Q8 needs a gate command (and CI once a remote exists)"
git rev-parse --git-dir >/dev/null 2>&1 && { git remote | grep -q . && found "git remote: $(git remote | paste -sd ',' -)" || found "git: no remote"; } || found "not a git repository"
echo

echo "## Quality and security tooling"
files 3 \( -name 'eslint.config.*' -o -name '.eslintrc*' -o -name biome.json -o -name biome.jsonc -o -name '.prettierrc*' \
  -o -name 'prettier.config.*' -o -name 'tsconfig*.json' -o -name 'vitest.config.*' -o -name 'jest.config.*' \
  -o -name 'playwright.config.*' -o -name 'cypress.config.*' -o -name '.dependency-cruiser.*' -o -name 'knip.json' \
  -o -name '.size-limit*' -o -name 'budget.json' -o -name 'lighthouserc*' -o -name 'stryker.*' \
  -o -name ruff.toml -o -name .ruff.toml -o -name mypy.ini -o -name pyrightconfig.json -o -name pytest.ini -o -name conftest.py \
  -o -name .importlinter -o -name .bandit -o -name .golangci.yml -o -name .golangci.yaml -o -name clippy.toml -o -name deny.toml \
  -o -name detekt.yml -o -name .swiftlint.yml -o -name analysis_options.yaml \
  -o -name .gitleaks.toml -o -name '.semgrep*' -o -name 'semgrep.yml' -o -name .snyk -o -name osv-scanner.toml \
  -o -name renovate.json -o -name dependabot.yml -o -name sonar-project.properties -o -name 'codeql*.yml' \) \
  | grep -v -E '(^|/)tsconfig\.tsbuildinfo$' | head -40 | sed 's/^/- `/; s/$/`/'
echo

echo "## Agent instruction files"
files 3 \( -name AGENTS.md -o -name CLAUDE.md -o -name GEMINI.md -o -name .cursorrules -o -name copilot-instructions.md \) | sed 's/^/- `/; s/$/`/'
[ -d .cursor/rules ] && found "\`.cursor/rules/\`"
grep -l "a-plus:pointer" AGENTS.md CLAUDE.md 2>/dev/null | sed 's/^/- A+ pointer present in /' || true
echo

echo "## Existing A+ adoption"
for f in docs/standards/a-plus/VERSION docs/standards/a-plus-profile.md; do
  [ -e "$f" ] && found "\`$f\`$( [ "${f##*/}" = VERSION ] && echo " = $(cat "$f")")"
done
true
