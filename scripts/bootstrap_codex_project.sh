#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: ./bootstrap_codex_project.sh <target-folder> [options]

Creates or updates a sibling project with the Codex-oriented starter files.

Arguments:
  target-folder   Folder name or path for a project that lives beside this repo.

Options:
  --with-github         Copy .github/workflows/deploy-template.yml.
  --no-github           Do not copy .github/workflows/deploy-template.yml.
  --no-codex            Do not copy CODEX.md.
  --no-gitignore        Do not copy .gitignore.
  --no-agentic-scripts  Do not copy agentic-scripts/.
Behavior:
  - copies CODEX.md
  - copies .gitignore
  - copies agentic-scripts/
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
copy_codex="ask"
copy_gitignore="ask"
copy_scripts="ask"
github_flag="ask"
for arg in "$@"; do
  case "${arg}" in
    --with-github) copy_github="true"; github_flag="set" ;;
    --no-github) copy_github="false"; github_flag="set" ;;
    --no-codex) copy_codex="false" ;;
    --no-gitignore) copy_gitignore="false" ;;
    --no-agentic-scripts) copy_scripts="false" ;;
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

prompt_yes_no() {
  local prompt="$1"
  local default="$2"
  local reply
  local suffix="[Y/n]"
  if [[ "${default}" == "false" ]]; then
    suffix="[y/N]"
  fi
  while true; do
    printf "%s %s " "${prompt}" "${suffix}"
    read -r reply || reply=""
    reply="${reply:-}"
    if [[ -z "${reply}" ]]; then
      if [[ "${default}" == "true" ]]; then
        return 0
      fi
      return 1
    fi
    case "${reply}" in
      y|Y|yes|YES) return 0 ;;
      n|N|no|NO) return 1 ;;
    esac
  done
}

if [[ "${copy_codex}" == "ask" ]]; then
  if prompt_yes_no "Copy CODEX.md?" "true"; then
    copy_codex="true"
  else
    copy_codex="false"
  fi
fi

if [[ "${copy_gitignore}" == "ask" ]]; then
  if prompt_yes_no "Copy .gitignore?" "true"; then
    copy_gitignore="true"
  else
    copy_gitignore="false"
  fi
fi

if [[ "${copy_scripts}" == "ask" ]]; then
  if prompt_yes_no "Copy agentic-scripts/?" "true"; then
    copy_scripts="true"
  else
    copy_scripts="false"
  fi
fi

if [[ "${github_flag}" == "ask" ]]; then
  if prompt_yes_no "Copy GitHub workflow template?" "false"; then
    copy_github="true"
  else
    copy_github="false"
  fi
fi

mkdir -p "${target_dir}"

if [[ "${copy_codex}" == "true" ]]; then
  cp "${script_dir}/CODEX.md" "${target_dir}/CODEX.md"
fi

if [[ "${copy_gitignore}" == "true" ]]; then
  cp "${script_dir}/.gitignore" "${target_dir}/.gitignore"
fi

if [[ "${copy_scripts}" == "true" ]]; then
  mkdir -p "${target_dir}/agentic-scripts"
  find "${target_dir}/agentic-scripts" -mindepth 1 -maxdepth 1 -type f -delete
  cp "${script_dir}/agentic-scripts/"*.sh "${target_dir}/agentic-scripts/"
  chmod +x "${target_dir}/agentic-scripts/"*.sh
fi

if [[ "${copy_github}" == "true" ]]; then
  mkdir -p "${target_dir}/.github/workflows"
  cp "${script_dir}/.github/workflows/deploy-template.yml" "${target_dir}/.github/workflows/deploy-template.yml"
fi

TARGET_DIR="${target_dir}" COPY_GITHUB="${copy_github}" COPY_CODEX="${copy_codex}" COPY_GITIGNORE="${copy_gitignore}" COPY_SCRIPTS="${copy_scripts}" python3 <<'PY'
import json
import os

target_dir = os.environ["TARGET_DIR"]
copy_github = os.environ["COPY_GITHUB"] == "true"
copy_codex = os.environ["COPY_CODEX"] == "true"
copy_gitignore = os.environ["COPY_GITIGNORE"] == "true"
copy_scripts = os.environ["COPY_SCRIPTS"] == "true"

files = []

if copy_codex:
    files.append("CODEX.md")

if copy_gitignore:
    files.append(".gitignore")

if copy_scripts:
    files.extend([
        "agentic-scripts/classify_issue_input.sh",
        "agentic-scripts/draft_issue_bundle.sh",
        "agentic-scripts/finalize_work.sh",
        "agentic-scripts/get_issue.sh",
        "agentic-scripts/prepare_sdlc_context.sh",
        "agentic-scripts/run_checks.sh",
        "agentic-scripts/run_tests.sh",
        "agentic-scripts/start_worktree.sh",
        "agentic-scripts/summarize_diff.sh",
        "agentic-scripts/validate_dod.sh",
        "agentic-scripts/validate_dor.sh",
        "agentic-scripts/write_issues.sh",
    ])

if copy_github:
    files.append(".github/workflows/deploy-template.yml")

print(json.dumps({
    "ok": True,
    "target_dir": target_dir,
    "copied": files,
    "removed": [],
}, indent=2))
PY
