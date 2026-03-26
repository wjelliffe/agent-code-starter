#!/usr/bin/env bash
set -euo pipefail

issue_number="${1:-}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${repo_root}" ]]; then
  echo "validate_dod.sh must be executed inside a git repository" >&2
  exit 1
fi

status_short="$(git status --short)"
changed_files="$(git diff --name-only)"
issue_json=""
if [[ -n "${issue_number}" ]]; then
  issue_json="${repo_root}/.tmp/issue-${issue_number}.json"
fi

ISSUE_JSON="${issue_json}" STATUS_SHORT="${status_short}" CHANGED_FILES="${changed_files}" python3 <<'PY'
import json
import os

status_lines = [line for line in os.environ.get("STATUS_SHORT", "").splitlines() if line.strip()]
changed_files = [line for line in os.environ.get("CHANGED_FILES", "").splitlines() if line.strip()]
issue_json = os.environ.get("ISSUE_JSON", "")

checks = [
    {
        "name": "changes_present",
        "pass": bool(changed_files or status_lines),
        "detail": "Repository has changes to review." if (changed_files or status_lines) else "No tracked changes detected.",
    },
    {
        "name": "merge_conflicts_absent",
        "pass": not any(line.startswith("UU ") or line.startswith("AA ") for line in status_lines),
        "detail": "No merge conflicts detected." if not any(line.startswith("UU ") or line.startswith("AA ") for line in status_lines) else "Resolve merge conflicts before claiming DOD.",
    },
]

if issue_json:
    checks.insert(1, {
        "name": "issue_context_present",
        "pass": os.path.exists(issue_json),
        "detail": issue_json if os.path.exists(issue_json) else f"Missing {issue_json}",
    })

manual_items = [
    "acceptance criteria satisfied",
    "no obvious regressions",
    "docs updated if needed",
    "risks noted",
    "ready for review",
    "worktree clean when claiming final done",
]

failed = [item["name"] for item in checks if not item["pass"]]
payload = {
    "ok": len(failed) == 0,
    "failed_checks": failed,
    "checks": checks,
    "manual_review_required": manual_items,
}
print(json.dumps(payload, indent=2))
PY
