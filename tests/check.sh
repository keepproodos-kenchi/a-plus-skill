#!/usr/bin/env bash
# Local package gate; does not certify an adopting application.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -B -m unittest discover -s tests -v
bash -n skills/a-plus/tools/adopt.sh skills/a-plus/tools/scan-repo.sh install.sh tests/check.sh
git diff --check
