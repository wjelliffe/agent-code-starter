#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: ./bootstrap_codex_project.sh <target-folder> [--with-github]

Creates or updates a sibling project with the Codex-oriented starter files.

Arguments:
  target-folder   Folder name or path for a project that lives beside this repo.

Options:
  --with-github   Also copy .github/workflows/deploy-template.yml.

Behavior:
  - copies CODEX.md
  - copies .gitignore
  - copies agentic-scripts/
  - removes AGENTS.md from the target if it exists
  - does not copy starter .git/, .tmp/, or agent-specific docs
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parent_dir="$(cd "${script_dir}/.." && pwd)"
target_arg="$1"
shift

copy_github="false"
for arg in "$@"; do
  case "${arg}" in
    --with-github) copy_github="true" ;;
    *)
      echo "unknown option: ${arg}" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "${target_arg}" = /* ]]; then
  target_dir="${target_arg}"
else
  target_dir="${parent_dir}/${target_arg}"
fi

target_dir="$(cd "$(dirname "${target_dir}")" && pwd)/$(basename "${target_dir}")"

mkdir -p "${target_dir}"
mkdir -p "${target_dir}/agentic-scripts"

cp "${script_dir}/CODEX.md" "${target_dir}/CODEX.md"
cp "${script_dir}/.gitignore" "${target_dir}/.gitignore"
rm -f "${target_dir}/AGENTS.md"

find "${target_dir}/agentic-scripts" -mindepth 1 -maxdepth 1 -type f -delete
cp "${script_dir}/agentic-scripts/"*.sh "${target_dir}/agentic-scripts/"
chmod +x "${target_dir}/agentic-scripts/"*.sh

if [[ "${copy_github}" == "true" ]]; then
  mkdir -p "${target_dir}/.github/workflows"
  cp "${script_dir}/.github/workflows/deploy-template.yml" "${target_dir}/.github/workflows/deploy-template.yml"
fi

TARGET_DIR="${target_dir}" COPY_GITHUB="${copy_github}" python3 <<'PY'
import json
import os

target_dir = os.environ["TARGET_DIR"]
copy_github = os.environ["COPY_GITHUB"] == "true"

files = [
    "CODEX.md",
    ".gitignore",
    "agentic-scripts/get_issue.sh",
    "agentic-scripts/run_checks.sh",
    "agentic-scripts/start_worktree.sh",
    "agentic-scripts/summarize_diff.sh",
    "agentic-scripts/validate_dod.sh",
]

if copy_github:
    files.append(".github/workflows/deploy-template.yml")

print(json.dumps({
    "ok": True,
    "target_dir": target_dir,
    "copied": files,
    "removed": ["AGENTS.md"],
}, indent=2))
PY
