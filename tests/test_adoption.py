import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


SOURCE = Path(__file__).resolve().parents[1] / "skills/a-plus"


class AdoptionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.skill = self.root / "skill"
        shutil.copytree(SOURCE, self.skill)
        self.repo = self.root / "project with spaces"
        self.repo.mkdir()
        (self.repo / "AGENTS.md").write_text("# Owner instructions\nKeep this text.\n")

    def tearDown(self):
        self.tmp.cleanup()

    def adopt(self, *extra):
        return subprocess.run(
            ["bash", str(self.skill / "tools/adopt.sh"), "--repo", str(self.repo),
             "--roles", "service,web", *extra], capture_output=True, text=True)

    def test_dry_run_does_not_write(self):
        before = (self.repo / "AGENTS.md").read_bytes()
        result = self.adopt("--layout", "canonical", "--observability", "canonical", "--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.repo / "docs").exists())
        self.assertEqual((self.repo / "AGENTS.md").read_bytes(), before)

    def test_installs_workflow_checker_and_current_profile_without_touching_app(self):
        (self.repo / "main.py").write_text("# application stays unchanged\n")
        result = self.adopt("--layout", "canonical", "--observability", "canonical")
        self.assertEqual(result.returncode, 0, result.stderr)
        standard = self.repo / "docs/standards/a-plus"
        self.assertTrue((standard / "08-refactor-workflow.md").is_file())
        self.assertTrue((standard / "tools/check-evidence.py").is_file())
        profile = (self.repo / "docs/standards/a-plus-profile.md").read_text()
        version = (self.skill / "standard/VERSION").read_text().strip()
        self.assertIn(f"| Standard version adopted | {version} |", profile)
        self.assertIn("| Layout policy | canonical |", profile)
        self.assertIn("| Observability policy | canonical |", profile)
        self.assertNotIn("{{", profile)
        self.assertEqual((self.repo / "main.py").read_text(), "# application stays unchanged\n")
        self.assertIn("08-refactor-workflow.md", (self.repo / "AGENTS.md").read_text())

    def test_rerun_and_upgrade_preserve_profile_and_owner_text(self):
        self.assertEqual(self.adopt().returncode, 0)
        profile = self.repo / "docs/standards/a-plus-profile.md"
        profile.write_text("# Custom owner profile\n")
        self.assertEqual(self.adopt().returncode, 0)
        (self.repo / "AGENTS.md").write_text(
            "# Owner instructions\nKeep this text.\n<!-- a-plus:pointer -->\n"
            "OLD_POINTER_SENTINEL\n<!-- /a-plus:pointer -->\n# Owner footer\n")
        (self.skill / "standard/VERSION").write_text("99.0.0\n")
        self.assertNotEqual(self.adopt().returncode, 0)
        result = self.adopt("--upgrade")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(profile.read_text(), "# Custom owner profile\n")
        instructions = (self.repo / "AGENTS.md").read_text()
        self.assertTrue(instructions.startswith("# Owner instructions\nKeep this text.\n"))
        self.assertEqual(instructions.count("<!-- a-plus:pointer -->"), 1)
        self.assertNotIn("OLD_POINTER_SENTINEL", instructions)
        self.assertIn("08-refactor-workflow.md", instructions)
        self.assertTrue(instructions.endswith("# Owner footer\n"))
        self.assertTrue((self.repo / "docs/standards/a-plus/08-refactor-workflow.md").exists())

    def test_invalid_policy_fails_before_writes(self):
        result = self.adopt("--layout", "anything")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.repo / "docs").exists())

    def test_malformed_pointer_upgrade_preserves_owner_text_and_standard(self):
        self.assertEqual(self.adopt().returncode, 0)
        target_version = self.repo / "docs/standards/a-plus/VERSION"
        original_version = target_version.read_bytes()
        (self.skill / "standard/VERSION").write_text("99.0.0\n")
        for markers in (
            "<!-- /a-plus:pointer -->\n<!-- a-plus:pointer -->\n",
            "<!-- a-plus:pointer -->\n",
            "<!-- a-plus:pointer -->\n<!-- a-plus:pointer -->\n<!-- /a-plus:pointer -->\n",
        ):
            content = "# Owner prefix\n" + markers + "# Owner suffix\nKEEP\n"
            (self.repo / "AGENTS.md").write_text(content)
            result = self.adopt("--upgrade")
            with self.subTest(markers=markers):
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual((self.repo / "AGENTS.md").read_text(), content)
                self.assertEqual(target_version.read_bytes(), original_version)


if __name__ == "__main__":
    unittest.main()
