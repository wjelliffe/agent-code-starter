#!/usr/bin/env bash
set -euo pipefail

context_path="${1:-}"
checks_path="${2:-}"
tests_path="${3:-}"

command -v git >/dev/null 2>&1 || { echo "git is required" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required" >&2; exit 1; }
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "${repo_root}" ]] || { echo "validate_dod.sh must run inside a git repository" >&2; exit 1; }

status_short="$(git status --short)"
changed_files="$(git diff --name-only)"

CONTEXT="${context_path}" CHECKS="${checks_path}" TESTS="${tests_path}" STATUS="${status_short}" CHANGED="${changed_files}" python3 <<'PY'
import json, os

def load_result(path, label):
    if not path:
        return None
    if not os.path.exists(path):
        return {"name": label, "pass": False, "detail": f"missing {path}", "status": "missing"}
    with open(path, encoding="utf-8") as handle:
        payload = json.load(handle)
    status = payload.get("status", "unknown")
    return {
        "name": label,
        "pass": bool(payload.get("ok")) and status != "fail",
        "detail": path,
        "status": status,
    }

status_lines = [line for line in os.environ.get("STATUS", "").splitlines() if line.strip()]
changed = [line for line in os.environ.get("CHANGED", "").splitlines() if line.strip()]
checks = [
    {"name": "changes_present", "pass": bool(status_lines or changed), "detail": "changes detected" if (status_lines or changed) else "no changes detected"},
    {
        "name": "merge_conflicts_absent",
        "pass": not any(line[:2] in {"UU", "AA", "DD", "AU", "UA", "DU", "UD"} for line in status_lines),
        "detail": "working tree has no unresolved merge conflicts",
    },
]
context = os.environ.get("CONTEXT", "")
if context:
    checks.append({"name": "context_present", "pass": os.path.exists(context), "detail": context})
for path, label in ((os.environ.get("CHECKS", ""), "checks"), (os.environ.get("TESTS", ""), "tests")):
    item = load_result(path, label)
    if item:
        checks.append(item)

failed = [item["name"] for item in checks if not item["pass"]]
warnings = [
    f"{item['name']} status is none-found; explicitly assess whether proceeding without executable coverage is acceptable"
    for item in checks if item.get("status") == "none-found"
]
print(json.dumps({
    "ok": not failed,
    "failed_checks": failed,
    "warnings": warnings,
    "checks": checks,
    "manual_review_required": [
        "acceptance criteria satisfied",
        "security/data invariants reviewed where relevant",
        "no obvious regressions",
        "docs/config updated if required",
        "risks and none-found verification states disclosed",
    ],
}, indent=2))
if failed:
    raise SystemExit(1)
PY
