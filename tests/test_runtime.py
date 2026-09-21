import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "runtime"


def run(cmd, cwd=None, input_text=None):
    return subprocess.run(
        cmd,
        cwd=cwd,
        input=input_text,
        capture_output=True,
        text=True,
    )


class RepoFixture:
    def __init__(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.tmp.name)

    def __enter__(self):
        proc = run(["git", "init", "-b", "main"], cwd=self.root)
        if proc.returncode != 0:
            run(["git", "init"], cwd=self.root)
            run(["git", "checkout", "-b", "main"], cwd=self.root)
        run(["git", "config", "user.email", "test@example.com"], cwd=self.root)
        run(["git", "config", "user.name", "Agent Code Tests"], cwd=self.root)
        (self.root / "README.md").write_text("fixture\n", encoding="utf-8")
        run(["git", "add", "README.md"], cwd=self.root)
        commit = run(["git", "commit", "-m", "initial"], cwd=self.root)
        if commit.returncode != 0:
            raise RuntimeError(commit.stderr)
        return self.root

    def __exit__(self, *args):
        self.tmp.cleanup()


class RuntimeTests(unittest.TestCase):
    def test_no_tests_is_none_found_not_pass(self):
        with RepoFixture() as root:
            proc = run([sys.executable, str(RUNTIME / "verify.py"), "tests"], cwd=root)
            self.assertEqual(proc.returncode, 0, proc.stderr)
            payload = json.loads(proc.stdout)
            self.assertTrue(payload["ok"])
            self.assertEqual(payload["status"], "none-found")
            self.assertEqual(payload["results"], [])

    def test_python_tests_are_detected(self):
        with RepoFixture() as root:
            tests = root / "tests"
            tests.mkdir()
            (tests / "test_sample.py").write_text(
                "import unittest\n\n"
                "class Sample(unittest.TestCase):\n"
                "    def test_ok(self):\n"
                "        self.assertEqual(2 + 2, 4)\n",
                encoding="utf-8",
            )
            run(["git", "add", "tests/test_sample.py"], cwd=root)
            run(["git", "commit", "-m", "add test"], cwd=root)
            proc = run([sys.executable, str(RUNTIME / "verify.py"), "tests"], cwd=root)
            self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
            payload = json.loads(proc.stdout)
            self.assertEqual(payload["status"], "pass")
            self.assertTrue(payload["results"])

    def test_custom_test_failure_returns_nonzero(self):
        with RepoFixture() as root:
            (root / ".agent-code.json").write_text(json.dumps({
                "commands": {
                    "tests": [f"{sys.executable} -c 'import sys; sys.exit(7)'"]
                }
            }), encoding="utf-8")
            proc = run([sys.executable, str(RUNTIME / "verify.py"), "tests"], cwd=root)
            self.assertNotEqual(proc.returncode, 0)
            payload = json.loads(proc.stdout)
            self.assertFalse(payload["ok"])
            self.assertEqual(payload["status"], "fail")
            self.assertEqual(payload["results"][0]["exit_code"], 7)

    def test_inplace_branch_setup_refuses_dirty_tree(self):
        with RepoFixture() as root:
            (root / "dirty.txt").write_text("do not overwrite\n", encoding="utf-8")
            proc = run(["bash", str(RUNTIME / "start_worktree.sh"), "story-1", "inplace"], cwd=root)
            self.assertNotEqual(proc.returncode, 0)
            self.assertIn("dirty working tree", proc.stderr)

    def test_finalization_refuses_trunk(self):
        with RepoFixture() as root:
            context = root / "context.json"
            context.write_text(json.dumps({"title": "Test change", "summary": "Test change"}), encoding="utf-8")
            (root / "change.txt").write_text("change\n", encoding="utf-8")
            proc = run(["bash", str(RUNTIME / "finalize_work.sh"), "merge", str(context)], cwd=root)
            self.assertNotEqual(proc.returncode, 0)
            self.assertIn("directly on trunk", proc.stderr)

    def test_update_pr_requires_explicit_pr_number(self):
        with RepoFixture() as root:
            run(["git", "checkout", "-b", "agent/review-fix"], cwd=root)
            context = root / "context.json"
            context.write_text(json.dumps({
                "title": "Address review feedback",
                "summary": "Address review feedback",
            }), encoding="utf-8")
            (root / "change.txt").write_text("change\n", encoding="utf-8")
            proc = run(["bash", str(RUNTIME / "finalize_work.sh"), "update-pr", str(context)], cwd=root)
            self.assertNotEqual(proc.returncode, 0)
            self.assertIn("requires a numeric PR number", proc.stderr)


if __name__ == "__main__":
    unittest.main()
