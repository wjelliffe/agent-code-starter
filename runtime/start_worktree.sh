#!/usr/bin/env bash
set -euo pipefail

work_key="${1:-}"
mode="${2:-inplace}"
context_path="${3:-}"

if [[ -z "${work_key}" ]]; then
  echo "usage: $0 <work-key> [inplace|worktree] [context-json]" >&2
  exit 1
fi
if [[ "${mode}" != "inplace" && "${mode}" != "worktree" ]]; then
  echo "invalid mode: ${mode}" >&2
  exit 1
fi
command -v git >/dev/null 2>&1 || { echo "git is required" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required" >&2; exit 1; }

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "${repo_root}" ]] || { echo "start_worktree.sh must be executed inside the target git repository" >&2; exit 1; }

if [[ -n "${context_path}" && ! -f "${context_path}" ]]; then
  echo "context file not found: ${context_path}" >&2
  exit 1
fi

slug="$(
WORK_KEY="${work_key}" python3 <<'PY'
import os, re
value = re.sub(r"[^a-z0-9]+", "-", os.environ["WORK_KEY"].strip().lower()).strip("-")
print(value or "work")
PY
)"

prefix="$(cd "${repo_root}" && python3 "${script_dir}/config.py" get branch_prefix)"
branch_name="${prefix}${slug}"
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

cd "${repo_root}"
current_branch="$(git branch --show-current)"

if [[ "${mode}" == "inplace" ]]; then
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "refusing inplace setup with a dirty working tree" >&2
    exit 1
  fi

  if [[ "${current_branch}" != "${branch_name}" ]]; then
    if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
      git checkout "${branch_name}" >/dev/null
    else
      git show-ref --verify --quiet "refs/heads/${trunk_branch}" || { echo "trunk branch not found: ${trunk_branch}" >&2; exit 1; }
      git checkout "${trunk_branch}" >/dev/null
      git checkout -b "${branch_name}" >/dev/null
    fi
  fi

  BRANCH_NAME="${branch_name}" REPO_ROOT="${repo_root}" TRUNK_BRANCH="${trunk_branch}" python3 <<'PY'
import json, os
print(json.dumps({
    "ok": True,
    "mode": "inplace",
    "branch": os.environ["BRANCH_NAME"],
    "path": os.environ["REPO_ROOT"],
    "trunk_branch": os.environ["TRUNK_BRANCH"],
}))
PY
  exit 0
fi

repo_name="$(basename "${repo_root}")"
worktree_path="$(cd "${repo_root}/.." && pwd)/${repo_name}-${slug}"

if [[ -d "${worktree_path}" ]]; then
  existing_branch="$(git -C "${worktree_path}" branch --show-current 2>/dev/null || true)"
  [[ "${existing_branch}" == "${branch_name}" ]] || {
    echo "existing worktree at ${worktree_path} is on ${existing_branch}, expected ${branch_name}" >&2
    exit 1
  }
else
  if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
    git worktree add "${worktree_path}" "${branch_name}" >/dev/null
  else
    git show-ref --verify --quiet "refs/heads/${trunk_branch}" || { echo "trunk branch not found: ${trunk_branch}" >&2; exit 1; }
    git worktree add -b "${branch_name}" "${worktree_path}" "${trunk_branch}" >/dev/null
  fi
fi

BRANCH_NAME="${branch_name}" WORKTREE_PATH="${worktree_path}" TRUNK_BRANCH="${trunk_branch}" python3 <<'PY'
import json, os
print(json.dumps({
    "ok": True,
    "mode": "worktree",
    "branch": os.environ["BRANCH_NAME"],
    "path": os.environ["WORKTREE_PATH"],
    "trunk_branch": os.environ["TRUNK_BRANCH"],
}))
PY
