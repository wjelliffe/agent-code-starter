import json
import pathlib
import re
import subprocess
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
CORE_SKILLS = {
    "issues",
    "implement",
    "sdlc-do",
    "code-review",
    "systematic-debugging",
    "verify",
    "address-review",
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
        plugin = marketplace["plugins"][0]
        self.assertEqual(plugin["name"], "agent-code-starter")
        self.assertEqual(plugin["source"], {"source": "local", "path": "."})
        self.assertEqual(plugin["category"], "Developer Tools")
        self.assertEqual(plugin["policy"]["products"], ["CODEX"])

    def test_core_skills_exist_and_have_trigger_descriptions(self):
        found = {path.parent.name for path in (ROOT / "skills").glob("*/SKILL.md")}
        self.assertTrue(CORE_SKILLS.issubset(found))
        for name in CORE_SKILLS:
            text = (ROOT / "skills" / name / "SKILL.md").read_text(encoding="utf-8")
            match = re.search(r"^description:\s*(.+)$", text, re.MULTILINE)
            self.assertIsNotNone(match, name)
            self.assertTrue(match.group(1).startswith("Use when"), name)

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

    def test_routing_evals(self):
        scenarios = json.loads((ROOT / "evals" / "scenarios.json").read_text(encoding="utf-8"))
        for scenario in scenarios:
            proc = subprocess.run(
                [sys.executable, str(ROOT / "runtime" / "route.py"), scenario["text"]],
                capture_output=True,
                text=True,
            )
            self.assertEqual(proc.returncode, 0, scenario["name"])
            actual = json.loads(proc.stdout)["mode"]
            self.assertEqual(actual, scenario["expected_mode"], scenario["name"])


if __name__ == "__main__":
    unittest.main()
