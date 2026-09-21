import json
import pathlib
import re
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
CORE_SKILLS = {
    "issues",
    "implement",
    "sdlc-do",
    "code-review",
}


class PluginTests(unittest.TestCase):
    def test_manifests_share_name_and_version(self):
        codex = json.loads((ROOT / ".codex-plugin" / "plugin.json").read_text(encoding="utf-8"))
        claude = json.loads((ROOT / ".claude-plugin" / "plugin.json").read_text(encoding="utf-8"))
        self.assertEqual(codex["name"], "agent-code-starter")
        self.assertEqual(codex["name"], claude["name"])
        self.assertEqual(codex["version"], claude["version"])
        self.assertEqual(codex["skills"], "./skills/")
        self.assertEqual(codex["hooks"], {})

    def test_repo_is_its_own_codex_marketplace(self):
        marketplace = json.loads(
            (ROOT / ".agents" / "plugins" / "marketplace.json").read_text(encoding="utf-8")
        )
        self.assertEqual(marketplace["name"], "agent-code-starter")
        self.assertEqual(len(marketplace["plugins"]), 1)
        self.assertEqual(marketplace["plugins"][0]["name"], "agent-code-starter")

    def test_repo_is_its_own_claude_marketplace(self):
        marketplace = json.loads(
            (ROOT / ".claude-plugin" / "marketplace.json").read_text(encoding="utf-8")
        )
        self.assertEqual(marketplace["name"], "agent-code-starter")
        self.assertEqual(len(marketplace["plugins"]), 1)
        self.assertEqual(marketplace["plugins"][0]["name"], "agent-code-starter")

    def test_exactly_four_skills_exist(self):
        found = {path.parent.name for path in (ROOT / "skills").glob("*/SKILL.md")}
        self.assertEqual(found, CORE_SKILLS)
        for name in CORE_SKILLS:
            text = (ROOT / "skills" / name / "SKILL.md").read_text(encoding="utf-8")
            match = re.search(r"^description:\s*(.+)$", text, re.MULTILINE)
            self.assertIsNotNone(match, name)
            self.assertTrue(match.group(1).startswith("Use when"), name)

    def test_execution_skills_are_hard_bounded(self):
        implement = (ROOT / "skills" / "implement" / "SKILL.md").read_text(encoding="utf-8")
        sdlc = (ROOT / "skills" / "sdlc-do" / "SKILL.md").read_text(encoding="utf-8")
        review = (ROOT / "skills" / "code-review" / "SKILL.md").read_text(encoding="utf-8")

        for text in (implement, sdlc):
            self.assertIn("One primary agent.", text)
            self.assertIn("Zero sub-agents.", text)
            self.assertIn("At most one review invocation per execution.", text)
            self.assertIn("Zero autonomous review/fix/re-review loops.", text)
            self.assertIn("Zero automatic retries after command failure.", text)

        self.assertIn("Perform exactly one skeptical review pass.", review)
        self.assertIn("Do not spawn sub-agents", review)
        self.assertIn("must not edit, remediate, re-run itself, or launch another review", review)

    def test_automatic_routing_is_not_part_of_runtime(self):
        self.assertFalse((ROOT / "runtime" / "route.py").exists())

    def test_legacy_distribution_paths_are_gone(self):
        self.assertFalse((ROOT / "codex-skills").exists())
        self.assertFalse((ROOT / ".claude" / "commands").exists())
        self.assertFalse((ROOT / "agentic-scripts").exists())
        self.assertFalse((ROOT / "scripts" / "propagate-agent-infra.sh").exists())
        self.assertFalse((ROOT / "scripts" / "bootstrap_codex_project.sh").exists())

    def test_shell_runtime_has_valid_syntax(self):
        for script in (ROOT / "runtime").glob("*.sh"):
            proc = subprocess.run(["bash", "-n", str(script)], capture_output=True, text=True)
            self.assertEqual(proc.returncode, 0, f"{script}: {proc.stderr}")


if __name__ == "__main__":
    unittest.main()
