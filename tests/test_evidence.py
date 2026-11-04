import copy
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


CHECKER = Path(__file__).resolve().parents[1] / "skills/a-plus/tools/check-evidence.py"


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.standard = self.root / "standard"
        self.standard.mkdir()
        # Minimal catalog fixture: the ledger cannot choose which controls exist.
        (self.standard / "VERSION").write_text("2.4.0\n")
        (self.standard / "01-constitution.md").write_text("### C-01 A control\n### C-02 Another\n")
        (self.root / "implementation.py").write_text("pass\n")
        artifact = self.root / "run.log"
        artifact.write_text("fixture gate completed\n")
        self.report = {
            "standard_version": "2.4.0", "revision": "fixture-revision", "environment": "local-fixture",
            "controls": [
                {"id": "C-01", "applies": True, "status": "verified",
                 "implementation": ["implementation.py"], "evidence": [
                     {"path": "run.log", "sha256": hashlib.sha256(artifact.read_bytes()).hexdigest(),
                      "command": "fixture gate", "exit_code": 0, "revision": "fixture-revision",
                      "environment": "local-fixture"}]},
                {"id": "C-02", "applies": False, "status": "not-applicable",
                 "reason": "Fixture has no corresponding capability", "context_evidence": ["implementation.py"]},
            ],
        }

    def tearDown(self):
        self.tmp.cleanup()

    def run_check(self, report=None):
        path = self.root / "evidence.json"
        path.write_text(json.dumps(self.report if report is None else report))
        return subprocess.run([sys.executable, str(CHECKER), "--standard-dir", str(self.standard),
            "--repo", str(self.root), "--evidence", str(path), "--revision", "fixture-revision"],
            capture_output=True, text=True)

    def test_complete_ledger_passes_accounting_only(self):
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("accounting", result.stdout.lower())

    def test_missing_duplicate_unknown_or_grouped_controls_fail(self):
        for mode in ("missing", "duplicate", "unknown", "grouped"):
            report = copy.deepcopy(self.report)
            if mode == "missing": report["controls"].pop()
            if mode == "duplicate": report["controls"].append(report["controls"][0])
            if mode == "unknown": report["controls"][0]["id"] = "C-99"
            if mode == "grouped": report["controls"][0]["id"] = "C-01,C-02"
            with self.subTest(mode=mode): self.assertNotEqual(self.run_check(report).returncode, 0)

    def test_unverified_and_exception_states_cannot_pass(self):
        for status in ("missing", "implemented", "failed", "blocked", "exception", "skipped"):
            report = copy.deepcopy(self.report)
            report["controls"][0]["status"] = status
            with self.subTest(status=status): self.assertNotEqual(self.run_check(report).returncode, 0)

    def test_stale_missing_tampered_or_failed_evidence_fails(self):
        for field, value in (("revision", "old"), ("path", "absent.log"), ("sha256", "0" * 64),
                             ("exit_code", 1), ("exit_code", False), ("command", "")):
            report = copy.deepcopy(self.report)
            report["controls"][0]["evidence"][0][field] = value
            with self.subTest(field=field, value=value): self.assertNotEqual(self.run_check(report).returncode, 0)

    def test_na_needs_context_and_cannot_hide_applicable_control(self):
        for field, value in (("reason", ""), ("context_evidence", []), ("applies", True)):
            report = copy.deepcopy(self.report)
            report["controls"][1][field] = value
            with self.subTest(field=field): self.assertNotEqual(self.run_check(report).returncode, 0)

    def test_artifact_cannot_escape_repo(self):
        report = copy.deepcopy(self.report)
        report["controls"][0]["evidence"][0]["path"] = "../outside.log"
        self.assertNotEqual(self.run_check(report).returncode, 0)

    def test_bad_input_fails_cleanly(self):
        for report in ({}, {"controls": "not a list"}, []):
            result = self.run_check(report)
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn("Traceback", result.stderr)

    def test_catalog_reads_declared_rows_and_suffixes_but_not_examples(self):
        (self.standard / "03-playbook-web.md").write_text(
            "| W-1a | web | Rule |\n| W-26 | React | UI |\n"
            "Reference to C-99 in prose.\n```text\n| W-99 | fake | example |\n```\n")
        (self.standard / "07-reference-layouts.md").write_text("| R-C6 | MUST | Rule |\n")
        result = subprocess.run([sys.executable, str(CHECKER), "--standard-dir", str(self.standard),
                                 "--list-controls"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(set(json.loads(result.stdout)), {"C-01", "C-02", "W-1a", "W-26", "R-C6"})

    def test_symlink_cannot_escape_repo(self):
        with tempfile.TemporaryDirectory() as outside:
            artifact = Path(outside) / "secret.log"
            artifact.write_text("external data")
            (self.root / "linked.log").symlink_to(artifact)
            report = copy.deepcopy(self.report)
            report["controls"][0]["evidence"][0]["path"] = "linked.log"
            result = self.run_check(report)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("escapes repository", result.stderr)


if __name__ == "__main__":
    unittest.main()
