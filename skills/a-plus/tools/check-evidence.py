#!/usr/bin/env python3
"""Check completion accounting, not application correctness. Never executes ledger commands."""

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path


CONTROL = r"(?:C-\d+[a-z]?|P-[A-Z]+\d+[a-z]?|(?:B|W|M|L|J|AI|X)-\d+[a-z]?|R-(?:[A-Z]+)?\d+[a-z]?)"


def require(condition, message):
    if not condition:
        raise ValueError(message)


def nonempty(value):
    return isinstance(value, str) and bool(value.strip())


def catalog(standard):
    """Parse declared control headings/table rows, not references or application imports."""
    ids = set()
    for path in sorted(standard.glob("*.md")):
        if not path.name.startswith(("01-", "02-", "03-", "05-", "07-")):
            continue
        fenced = False
        for line in path.read_text().splitlines():
            if line.startswith("```"):
                fenced = not fenced
            if fenced:
                continue
            match = re.match(rf"^(?:###\s+|\|\s*)({CONTROL})(?:\s+|\s*\|)", line)
            if match:
                ids.add(match.group(1))
    require(ids, "No declared controls found in standard directory")
    return ids


def local_file(repo, value):
    require(nonempty(value), "File reference must be a nonempty relative path")
    path = Path(value)
    require(not path.is_absolute(), f"Absolute file reference is not allowed: {value}")
    path = (repo / path).resolve()
    require(path.is_relative_to(repo), f"File reference escapes repository: {value}")
    require(path.is_file(), f"Missing evidence/implementation file: {value}")
    return path


def check(report, standard, repo, revision):
    require(isinstance(report, dict), "Evidence must be a JSON object")
    version = (standard / "VERSION").read_text().strip()
    require(report.get("standard_version") == version, "Standard version mismatch")
    require(nonempty(revision) and report.get("revision") == revision, "Revision mismatch")
    require(nonempty(report.get("environment")), "Missing report environment")
    rows = report.get("controls")
    require(isinstance(rows, list), "controls must be a list")
    required = catalog(standard)
    seen = set()
    incomplete = []
    for row in rows:
        require(isinstance(row, dict), "Control rows must be objects")
        control = row.get("id")
        require(isinstance(control, str) and control in required, f"Unknown or grouped control: {control}")
        require(control not in seen, f"Duplicate control: {control}")
        seen.add(control)
        applies = row.get("applies")
        require(type(applies) is bool, f"{control}: applies must be boolean")
        if not applies:
            require(row.get("status") == "not-applicable", f"{control}: N/A status required")
            require(nonempty(row.get("reason")), f"{control}: N/A needs a context reason")
            paths = row.get("context_evidence")
            require(isinstance(paths, list) and paths, f"{control}: N/A needs context evidence")
            for path in paths:
                local_file(repo, path)
            continue
        status = row.get("status")
        require(status in ("missing", "implemented", "verified", "failed", "blocked"),
                f"{control}: invalid applicable status: {status}")
        if status != "verified":
            incomplete.append(f"{control}={status}")
            continue
        locations = row.get("implementation")
        require(isinstance(locations, list) and locations, f"{control}: missing implementation references")
        for path in locations:
            local_file(repo, path)
        evidence = row.get("evidence")
        require(isinstance(evidence, list) and evidence, f"{control}: missing verification evidence")
        for item in evidence:
            require(isinstance(item, dict), f"{control}: evidence must be an object")
            require(item.get("revision") == revision, f"{control}: stale evidence revision")
            require(nonempty(item.get("environment")), f"{control}: missing evidence environment")
            require(nonempty(item.get("command")), f"{control}: missing verification command or review procedure")
            require(type(item.get("exit_code")) is int and item["exit_code"] == 0,
                    f"{control}: verification did not exit successfully")
            path = local_file(repo, item.get("path"))
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            require(item.get("sha256") == digest, f"{control}: artifact digest mismatch")
    require(seen == required, "Missing controls: " + ", ".join(sorted(required - seen)))
    require(not incomplete, "Incomplete controls: " + ", ".join(incomplete))
    return len(seen)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--standard-dir", type=Path, required=True)
    parser.add_argument("--list-controls", action="store_true")
    parser.add_argument("--repo", type=Path)
    parser.add_argument("--evidence", type=Path)
    parser.add_argument("--revision", help="Verified source/artifact digest or clean commit; supplied by trusted gate")
    args = parser.parse_args()
    try:
        if args.list_controls:
            print(json.dumps(sorted(catalog(args.standard_dir)), indent=2))
            return 0
        require(args.repo is not None and args.evidence is not None and args.revision is not None,
                "--repo, --evidence and --revision are required for completion checking")
        report = json.loads(args.evidence.read_text())
        count = check(report, args.standard_dir, args.repo.resolve(), args.revision)
        print(f"Completion accounting passed for {count} controls. Evidence content and applicability still require review.")
        return 0
    except (OSError, ValueError, TypeError) as exc:
        print(f"evidence: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
