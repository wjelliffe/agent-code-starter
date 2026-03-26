#!/usr/bin/env bash
set -euo pipefail

issue_number="${1:-}"
mode="${2:-inplace}"

if [[ -z "$issue_number" ]]; then
  echo "usage: $0 <issue-number> [inplace|worktree]" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
issue_json="${repo_root}/.tmp/issue-${issue_number}.json"

if [[ ! -f "${issue_json}" ]]; then
  echo "missing issue context: ${issue_json}" >&2
  exit 1
fi

branch_name="$(
ISSUE_JSON="${issue_json}" python3 <<'PY'
import json
import os

with open(os.environ["ISSUE_JSON"], "r", encoding="utf-8") as handle:
    payload = json.load(handle)

slug = payload.get("normalized", {}).get("slug") or f"issue-{payload['issue']['number']}"
print(f"codex/issue-{payload['issue']['number']}-{slug}")
PY
)"

repo_name="$(basename "${repo_root}")"

cd "${repo_root}"

if [[ "${mode}" == "inplace" ]]; then
  current_branch="$(git branch --show-current)"
  if [[ "${current_branch}" != "${branch_name}" ]]; then
    if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
      git checkout "${branch_name}" >/dev/null
    else
      git checkout -b "${branch_name}" >/dev/null
    fi
  fi

  BRANCH_NAME="${branch_name}" REPO_ROOT="${repo_root}" python3 <<'PY'
import json
import os

print(json.dumps({
    "ok": True,
    "mode": "inplace",
    "branch": os.environ["BRANCH_NAME"],
    "path": os.environ["REPO_ROOT"],
}))
PY
  exit 0
fi

if [[ "${mode}" != "worktree" ]]; then
  echo "invalid mode: ${mode}" >&2
  exit 1
fi

worktree_path="$(cd "${repo_root}/.." && pwd)/${repo_name}-issue-${issue_number}"

if [[ -d "${worktree_path}" ]]; then
  existing_branch="$(git -C "${worktree_path}" branch --show-current 2>/dev/null || true)"
  if [[ -n "${existing_branch}" && "${existing_branch}" != "${branch_name}" ]]; then
    echo "existing worktree at ${worktree_path} is on ${existing_branch}, expected ${branch_name}" >&2
    exit 1
  fi
else
  if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
    git worktree add "${worktree_path}" "${branch_name}" >/dev/null
  else
    base_ref="main"
    if ! git show-ref --verify --quiet "refs/heads/main"; then
      current_branch="$(git branch --show-current)"
      base_ref="${current_branch:-HEAD}"
    fi
    git worktree add -b "${branch_name}" "${worktree_path}" "${base_ref}" >/dev/null
  fi
fi

BRANCH_NAME="${branch_name}" WORKTREE_PATH="${worktree_path}" python3 <<'PY'
import json
import os

print(json.dumps({
    "ok": True,
    "mode": "worktree",
    "branch": os.environ["BRANCH_NAME"],
    "path": os.environ["WORKTREE_PATH"],
}))
PY
