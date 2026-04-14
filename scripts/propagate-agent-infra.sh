#!/usr/bin/env bash
set -euo pipefail

# propagate-agent-infra.sh
#
# Sync shared agentic-scripts and/or Claude command mirrors from a canonical
# source repo into one or more target repos, and optionally sync Codex skills
# into the active Codex skills directory.
#
# Features:
# - prompts if flags are omitted
# - skips repos with local changes by default
# - copies only when changes are detected
# - stages, commits, and optionally pushes
#
# Example:
#   ./propagate-agent-infra.sh \
#     --repos "ch-trips,neurofork-vps,bis-www-site" \
#     --sync-scripts yes \
#     --sync-claude yes \
#     --sync-global-codex yes \
#     --commit yes \
#     --push no

#######################################
# Defaults
#######################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPOS_ROOT="$(cd "${SOURCE_ROOT}/.." && pwd)"
GLOBAL_CODEX_ROOT="${CODEX_HOME:-${HOME}/.codex}"
GLOBAL_CODEX_SKILLS_DIR="${GLOBAL_CODEX_ROOT}/skills"

REPOS_CSV=""
SYNC_SCRIPTS=""
SYNC_CLAUDE=""
SYNC_GLOBAL_CODEX=""
DO_COMMIT=""
DO_PUSH=""
DRY_RUN=""
SKIP_DIRTY=""

COMMIT_MESSAGE="feat(agentic): update shared agent infrastructure"

#######################################
# Helpers
#######################################

usage() {
  cat <<EOF
Usage:
  $0 [options]

Options:
  --source-root <path>         Canonical source repo root. Default: parent of this script
  --repos-root <path>          Parent directory containing peer repos. Default: parent of source repo
  --repos "<a,b,c>"            Comma-separated repo directory names. If omitted, prompt.
  --sync-scripts <yes|no>      Sync agentic-scripts into target repos
  --sync-claude <yes|no>       Sync .claude/commands into target repos
  --sync-global-codex <yes|no> Sync codex-skills into \$CODEX_HOME/skills or ~/.codex/skills
  --commit <yes|no>            Auto-commit repo changes
  --push <yes|no>              Auto-push after commit
  --skip-dirty <yes|no>        Skip repos with local changes. Default: yes
  --message "<msg>"            Commit message
  --dry-run <yes|no>           Show what would change without writing
  --help                       Show this help

Examples:
  $0 --repos "ch-trips,neurofork-vps" --sync-scripts yes --sync-claude yes --sync-global-codex yes --commit yes --push no
  $0
EOF
}

prompt_yes_no() {
  local prompt="$1"
  local default="$2"
  local value

  while true; do
    read -r -p "${prompt} [${default}]: " value
    value="${value:-$default}"
    case "$(lower "$value")" in
      y|yes) echo "yes"; return ;;
      n|no)  echo "no"; return ;;
      *) echo "Please enter yes or no." ;;
    esac
  done
}

trim() {
  local var="$1"
  echo "$(echo "$var" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
}

lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

path_is_safe_global_codex_dir() {
  local path="$1"
  [[ "$path" == "${GLOBAL_CODEX_SKILLS_DIR}" ]]
}

require_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    echo "Required directory not found: $path" >&2
    exit 1
  fi
}

sync_dir_if_changed() {
  local src="$1"
  local dest="$2"
  local dry_run="$3"
  local diff_output

  mkdir -p "$dest"

  diff_output="$(rsync -ani --delete "$src"/ "$dest"/)"
  if [[ -z "$diff_output" ]]; then
    return 1
  fi

  if [[ "$dry_run" == "yes" ]]; then
    printf '%s\n' "$diff_output"
  else
    rsync -a --delete "$src"/ "$dest"/
  fi

  return 0
}

repo_is_dirty() {
  local repo_path="$1"
  (
    cd "$repo_path"
    [[ -n "$(git status --porcelain)" ]]
  )
}

commit_and_push_repo() {
  local repo_path="$1"
  local message="$2"
  local do_commit="$3"
  local do_push="$4"
  shift 4
  local paths=("$@")

  if [[ "$do_commit" != "yes" ]]; then
    echo "Skipping commit for $(basename "$repo_path")"
    return
  fi

  (
    cd "$repo_path"
    git add "${paths[@]}" 2>/dev/null || true

    if git diff --cached --quiet -- "${paths[@]}"; then
      echo "No staged changes in $(basename "$repo_path")"
      return
    fi

    git commit -m "$message"
    echo "Committed in $(basename "$repo_path")"

    if [[ "$do_push" == "yes" ]]; then
      git push
      echo "Pushed $(basename "$repo_path")"
    fi
  )
}

sync_global_codex_skills() {
  local source_skills_dir="$1"
  local global_skills_dir="$2"
  local dry_run="$3"

  if ! path_is_safe_global_codex_dir "$global_skills_dir"; then
    echo "Refusing to sync global Codex skills to unexpected path: $global_skills_dir" >&2
    exit 1
  fi

  if [[ ! -d "$source_skills_dir" ]]; then
    echo "Source skills directory not found: $source_skills_dir" >&2
    exit 1
  fi

  if ! find "$source_skills_dir" -mindepth 1 -maxdepth 1 -type d | grep -q .; then
    echo "No custom skill directories found in: $source_skills_dir" >&2
    exit 1
  fi

  mkdir -p "$global_skills_dir"

  echo "Syncing selected custom Codex skills to: $global_skills_dir"

  for skill_dir in "$source_skills_dir"/*; do
    [[ -d "$skill_dir" ]] || continue

    local skill_name
    skill_name="$(basename "$skill_dir")"

    # Safety: never touch hidden/system dirs from source
    [[ "$skill_name" == .* ]] && continue

    local dest="${global_skills_dir}/${skill_name}"
    mkdir -p "$dest"

    local diff_output
    diff_output="$(rsync -ani "$skill_dir"/ "$dest"/)"
    if [[ -z "$diff_output" ]]; then
      echo "No global Codex skill changes for ${skill_name}"
      continue
    fi

    if [[ "$dry_run" == "yes" ]]; then
      printf '%s\n' "$diff_output"
    else
      rsync -a "$skill_dir"/ "$dest"/
    fi
  done
}

#######################################
# Parse args
#######################################

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-root)
      SOURCE_ROOT="$2"
      shift 2
      ;;
    --repos-root)
      REPOS_ROOT="$2"
      shift 2
      ;;
    --repos)
      REPOS_CSV="$2"
      shift 2
      ;;
    --sync-scripts)
      SYNC_SCRIPTS="$(lower "$2")"
      shift 2
      ;;
    --sync-claude)
      SYNC_CLAUDE="$(lower "$2")"
      shift 2
      ;;
    --sync-global-codex)
      SYNC_GLOBAL_CODEX="$(lower "$2")"
      shift 2
      ;;
    --commit)
      DO_COMMIT="$(lower "$2")"
      shift 2
      ;;
    --push)
      DO_PUSH="$(lower "$2")"
      shift 2
      ;;
    --skip-dirty)
      SKIP_DIRTY="$(lower "$2")"
      shift 2
      ;;
    --message)
      COMMIT_MESSAGE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="$(lower "$2")"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

#######################################
# Validate source paths
#######################################

SOURCE_SCRIPTS_DIR="${SOURCE_ROOT}/agentic-scripts"
SOURCE_CLAUDE_COMMANDS_DIR="${SOURCE_ROOT}/.claude/commands"
SOURCE_SKILLS_DIR="${SOURCE_ROOT}/codex-skills"

if [[ -z "$SYNC_SCRIPTS" ]]; then
  SYNC_SCRIPTS="$(prompt_yes_no "Sync agentic-scripts into target repos?" "yes")"
fi

if [[ -z "$SYNC_CLAUDE" ]]; then
  SYNC_CLAUDE="$(prompt_yes_no "Sync .claude/commands into target repos?" "yes")"
fi

if [[ -z "$SYNC_GLOBAL_CODEX" ]]; then
  SYNC_GLOBAL_CODEX="$(prompt_yes_no "Sync codex-skills into ${GLOBAL_CODEX_SKILLS_DIR}?" "yes")"
fi

if [[ -z "$DO_COMMIT" ]]; then
  DO_COMMIT="$(prompt_yes_no "Auto-commit repo changes?" "yes")"
fi

if [[ -z "$DO_PUSH" ]]; then
  DO_PUSH="$(prompt_yes_no "Auto-push after commit?" "no")"
fi

if [[ -z "$SKIP_DIRTY" ]]; then
  SKIP_DIRTY="$(prompt_yes_no "Skip repos with local changes?" "yes")"
fi

if [[ -z "$DRY_RUN" ]]; then
  DRY_RUN="$(prompt_yes_no "Dry run only?" "no")"
fi

if [[ "$SYNC_SCRIPTS" == "yes" ]]; then
  require_dir "$SOURCE_SCRIPTS_DIR"
fi

if [[ "$SYNC_CLAUDE" == "yes" ]]; then
  require_dir "$SOURCE_CLAUDE_COMMANDS_DIR"
fi

if [[ "$SYNC_GLOBAL_CODEX" == "yes" ]]; then
  require_dir "$SOURCE_SKILLS_DIR"
fi

#######################################
# Resolve repo list
#######################################

if [[ -z "$REPOS_CSV" ]]; then
  echo "Available repos under ${REPOS_ROOT}:"
  find "$REPOS_ROOT" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort
  echo
  read -r -p "Enter comma-separated repo names to update: " REPOS_CSV
fi

IFS=',' read -r -a RAW_REPOS <<< "$REPOS_CSV"
TARGET_REPOS=()

for raw in "${RAW_REPOS[@]}"; do
  repo_name="$(trim "$raw")"
  [[ -z "$repo_name" ]] && continue
  TARGET_REPOS+=("$repo_name")
done

if [[ ${#TARGET_REPOS[@]} -eq 0 ]]; then
  echo "No repos selected." >&2
  exit 1
fi

#######################################
# Sync global Codex skills
#######################################

if [[ "$SYNC_GLOBAL_CODEX" == "yes" ]]; then
  sync_global_codex_skills "$SOURCE_SKILLS_DIR" "$GLOBAL_CODEX_SKILLS_DIR" "$DRY_RUN"
fi

#######################################
# Sync target repos
#######################################

for repo_name in "${TARGET_REPOS[@]}"; do
  repo_path="${REPOS_ROOT}/${repo_name}"

  if [[ ! -d "$repo_path/.git" ]]; then
    echo "Skipping ${repo_name}: not a git repo at ${repo_path}"
    continue
  fi

  if [[ "$SKIP_DIRTY" == "yes" ]] && repo_is_dirty "$repo_path"; then
    echo "Skipping ${repo_name}: repo has local changes"
    continue
  fi

  echo
  echo "=== Syncing ${repo_name} ==="

  changed_paths=()

  if [[ "$SYNC_SCRIPTS" == "yes" ]]; then
    echo "Syncing agentic-scripts -> ${repo_path}/agentic-scripts"
    if sync_dir_if_changed "$SOURCE_SCRIPTS_DIR" "${repo_path}/agentic-scripts" "$DRY_RUN"; then
      changed_paths+=("agentic-scripts")
    else
      echo "No agentic-scripts changes for ${repo_name}"
    fi
  fi

  if [[ "$SYNC_CLAUDE" == "yes" ]]; then
    echo "Syncing .claude/commands -> ${repo_path}/.claude/commands"
    if sync_dir_if_changed "$SOURCE_CLAUDE_COMMANDS_DIR" "${repo_path}/.claude/commands" "$DRY_RUN"; then
      changed_paths+=(".claude/commands")
    else
      echo "No .claude/commands changes for ${repo_name}"
    fi
  fi

  if [[ "$DRY_RUN" == "no" && ${#changed_paths[@]} -gt 0 ]]; then
    commit_and_push_repo "$repo_path" "$COMMIT_MESSAGE" "$DO_COMMIT" "$DO_PUSH" "${changed_paths[@]}"
  elif [[ "$DRY_RUN" == "no" ]]; then
    echo "No changes to commit for ${repo_name}"
  fi
done

echo
echo "Done."
