#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
context_path="${2:-}"
pr_number="${3:-}"

if [[ "${mode}" != "merge" && "${mode}" != "pr" && "${mode}" != "update-pr" ]]; then
  echo "usage: $0 <merge|pr|update-pr> <context-json> [pr-number]" >&2
  exit 1
fi
[[ -n "${context_path}" && -f "${context_path}" ]] || { echo "context file not found: ${context_path}" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "git is required" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required" >&2; exit 1; }

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "${repo_root}" ]] || { echo "finalize_work.sh must run inside the target git repository" >&2; exit 1; }

configured_trunk="$(cd "${repo_root}" && python3 "${script_dir}/config.py" get trunk_branch)"
if [[ -n "${configured_trunk}" ]]; then
  trunk_branch="${configured_trunk}"
else
  trunk_branch="$(
    cd "${repo_root}"
    git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's#^refs/remotes/origin/##' || true
  )"
  trunk_branch="${trunk_branch:-main}"
fi

current_branch="$(git -C "${repo_root}" branch --show-current)"
if [[ -z "${current_branch}" ]]; then
  echo "refusing finalization from detached HEAD" >&2
  exit 1
fi
if [[ "${current_branch}" == "${trunk_branch}" ]]; then
  echo "refusing to commit or finalize directly on trunk (${trunk_branch})" >&2
  exit 1
fi

if [[ "${mode}" == "update-pr" ]]; then
  [[ "${pr_number}" =~ ^[0-9]+$ ]] || { echo "update-pr requires a numeric PR number" >&2; exit 1; }
  command -v gh >/dev/null 2>&1 || { echo "gh CLI is required for update-pr finalization" >&2; exit 1; }

  if ! pr_json="$(gh pr view "${pr_number}" --json number,state,headRefName 2>&1)"; then
    echo "failed to load pull request #${pr_number}: ${pr_json}" >&2
    exit 1
  fi

  read -r pr_state pr_head < <(
    PR_JSON="${pr_json}" python3 <<'PY'
import json, os
payload = json.loads(os.environ["PR_JSON"])
print(payload.get("state", ""), payload.get("headRefName", ""))
PY
  )

  if [[ "${pr_state}" != "OPEN" ]]; then
    echo "refusing to update PR #${pr_number}: state is ${pr_state}" >&2
    exit 1
  fi
  if [[ "${pr_head}" != "${current_branch}" ]]; then
    echo "refusing to update PR #${pr_number}: current branch ${current_branch} is not PR head ${pr_head}" >&2
    exit 1
  fi
fi

read_context="$(
CONTEXT_PATH="${context_path}" python3 <<'PY'
import json, os, re
with open(os.environ["CONTEXT_PATH"], encoding="utf-8") as handle:
    payload = json.load(handle)
title = str(payload.get("title") or payload.get("summary") or payload.get("slug") or "update").strip()
title = re.sub(r"\s+", " ", title)[:72]
refs = payload.get("closing_issue_numbers")
if refs is None:
    refs = payload.get("closing_issue_number", payload.get("issue_number"))
if refs is None:
    refs = []
elif not isinstance(refs, list):
    refs = [refs]
refs = [str(value).strip().lstrip("#") for value in refs if str(value).strip()]
print(json.dumps({
    "title": title,
    "summary": str(payload.get("summary") or title).strip(),
    "closing": refs,
    "has_issue_context": bool(payload.get("issue_number") or payload.get("issue_numbers") or refs),
}))
PY
)"

title="$(READ_CONTEXT="${read_context}" python3 -c 'import json,os; print(json.loads(os.environ["READ_CONTEXT"])["title"])')"
summary="$(READ_CONTEXT="${read_context}" python3 -c 'import json,os; print(json.loads(os.environ["READ_CONTEXT"])["summary"])')"
closing_json="$(READ_CONTEXT="${read_context}" python3 -c 'import json,os; print(json.dumps(json.loads(os.environ["READ_CONTEXT"])["closing"]))')"
has_issue_context="$(READ_CONTEXT="${read_context}" python3 -c 'import json,os; print("true" if json.loads(os.environ["READ_CONTEXT"])["has_issue_context"] else "false")')"

if [[ "${mode}" != "update-pr" && "${has_issue_context}" == "true" && "${closing_json}" == "[]" ]]; then
  echo "issue-based finalization requires at least one closing issue reference" >&2
  exit 1
fi

cd "${repo_root}"
git add -A
git diff --cached --quiet && { echo "no staged changes to finalize" >&2; exit 1; }

if [[ "${mode}" == "update-pr" ]]; then
  commit_args=(-m "fix: ${title}")
else
  commit_args=(-m "feat: ${title}")
  while IFS= read -r ref; do
    [[ -n "${ref}" ]] && commit_args+=(-m "Fixes #${ref}")
  done < <(CLOSING="${closing_json}" python3 -c 'import json,os; [print(x) for x in json.loads(os.environ["CLOSING"])]')
fi

git commit "${commit_args[@]}" >/dev/null
commit_sha="$(git rev-parse HEAD)"

if [[ "${mode}" == "update-pr" ]]; then
  git push origin "${current_branch}" >/dev/null
  COMMIT_SHA="${commit_sha}" BRANCH="${current_branch}" PR_NUMBER="${pr_number}" python3 <<'PY'
import json, os
print(json.dumps({
    "ok": True,
    "mode": "update-pr",
    "commit": os.environ["COMMIT_SHA"],
    "branch": os.environ["BRANCH"],
    "pr_number": int(os.environ["PR_NUMBER"]),
}))
PY
  exit 0
fi

if [[ "${mode}" == "pr" ]]; then
  command -v gh >/dev/null 2>&1 || { echo "gh CLI is required for PR finalization" >&2; exit 1; }
  git push -u origin "${current_branch}" >/dev/null

  pr_body="${summary}"
  while IFS= read -r ref; do
    [[ -n "${ref}" ]] && pr_body="${pr_body}"$'\n\n'"Resolves #${ref}"
  done < <(CLOSING="${closing_json}" python3 -c 'import json,os; [print(x) for x in json.loads(os.environ["CLOSING"])]')

  if ! pr_url="$(gh pr create --title "${title}" --body "${pr_body}" --base "${trunk_branch}" --head "${current_branch}" 2>&1)"; then
    echo "failed to create pull request: ${pr_url}" >&2
    exit 1
  fi

  COMMIT_SHA="${commit_sha}" BRANCH="${current_branch}" TRUNK="${trunk_branch}" PR_URL="${pr_url}" python3 <<'PY'
import json, os
print(json.dumps({
    "ok": True,
    "mode": "pr",
    "commit": os.environ["COMMIT_SHA"],
    "branch": os.environ["BRANCH"],
    "trunk_branch": os.environ["TRUNK"],
    "pr_url": os.environ["PR_URL"].strip(),
}))
PY
  exit 0
fi

main_worktree="$(
git worktree list --porcelain | awk '/^worktree / {print substr($0,10); exit}'
)"

if [[ -n "${main_worktree}" && "${main_worktree}" != "${repo_root}" ]]; then
  git -C "${main_worktree}" checkout "${trunk_branch}" >/dev/null
  git -C "${main_worktree}" merge --ff-only "${current_branch}" >/dev/null || git -C "${main_worktree}" merge "${current_branch}" >/dev/null
  git -C "${main_worktree}" worktree remove "${repo_root}" >/dev/null
  git -C "${main_worktree}" branch -d "${current_branch}" >/dev/null || true
  removed="true"
else
  git checkout "${trunk_branch}" >/dev/null
  git merge --ff-only "${current_branch}" >/dev/null || git merge "${current_branch}" >/dev/null
  git branch -d "${current_branch}" >/dev/null || true
  removed="false"
fi

COMMIT_SHA="${commit_sha}" TRUNK="${trunk_branch}" BRANCH="${current_branch}" REMOVED="${removed}" python3 <<'PY'
import json, os
print(json.dumps({
    "ok": True,
    "mode": "merge",
    "commit": os.environ["COMMIT_SHA"],
    "trunk_branch": os.environ["TRUNK"],
    "merged_branch": os.environ["BRANCH"],
    "worktree_removed": os.environ["REMOVED"] == "true",
}))
PY
