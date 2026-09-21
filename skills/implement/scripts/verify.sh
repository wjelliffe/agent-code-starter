#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${script_dir}/common.sh"

kind="${1:-}"
[[ "$kind" == "checks" || "$kind" == "tests" ]] || { echo "usage: verify.sh <checks|tests>" >&2; exit 2; }
root="$(acs_repo_root)"
cd "$root"

run_cmd() {
  local cmd="$1"
  printf 'ACS_RUN=%s\n' "$cmd"
  if ! bash -lc "$cmd"; then
    printf 'ACS_STATUS=FAIL\nACS_FAILED_COMMAND=%s\n' "$cmd"
    return 1
  fi
}

config_key="check"
[[ "$kind" == "tests" ]] && config_key="test"
configured="$(acs_config_all "$config_key" || true)"
if [[ -n "$configured" ]]; then
  while IFS= read -r cmd; do
    [[ -z "$cmd" ]] || run_cmd "$cmd"
  done <<< "$configured"
  printf 'ACS_STATUS=PASS\nACS_SOURCE=config\n'
  exit 0
fi

count=0
run_auto() {
  run_cmd "$1"
  count=$((count + 1))
}

js_pm=""
if [[ -f package.json ]] && command -v node >/dev/null 2>&1; then
  if [[ -f pnpm-lock.yaml ]] && command -v pnpm >/dev/null 2>&1; then js_pm="pnpm"
  elif [[ -f yarn.lock ]] && command -v yarn >/dev/null 2>&1; then js_pm="yarn"
  elif [[ -f bun.lockb || -f bun.lock ]] && command -v bun >/dev/null 2>&1; then js_pm="bun"
  elif command -v npm >/dev/null 2>&1; then js_pm="npm"
  fi
fi

has_js_script() {
  local name="$1"
  SCRIPT_NAME="$name" node -e 'const p=require("./package.json"); process.exit(p.scripts && p.scripts[process.env.SCRIPT_NAME] ? 0 : 1)' >/dev/null 2>&1
}

run_js_script() {
  local name="$1"
  case "$js_pm" in
    npm|pnpm) run_auto "$js_pm run $name" ;;
    yarn) run_auto "yarn $name" ;;
    bun) run_auto "bun run $name" ;;
  esac
}

if [[ "$kind" == "checks" ]]; then
  if [[ -n "$js_pm" ]]; then
    for name in typecheck lint check build; do
      if has_js_script "$name"; then run_js_script "$name"; fi
    done
  fi
  if [[ -f go.mod ]] && command -v go >/dev/null 2>&1; then run_auto "go vet ./..."; fi
  if [[ -f Cargo.toml ]] && command -v cargo >/dev/null 2>&1; then run_auto "cargo check --all-targets"; fi
else
  if [[ -n "$js_pm" ]]; then
    for name in test test:unit test:integration; do
      if has_js_script "$name"; then run_js_script "$name"; fi
    done
  fi
  if [[ -d tests ]] && find tests -type f -name '*.py' -print -quit 2>/dev/null | grep -q .; then
    if command -v python3 >/dev/null 2>&1; then run_auto "python3 -m unittest discover -s tests"
    elif command -v python >/dev/null 2>&1; then run_auto "python -m unittest discover -s tests"
    fi
  fi
  if [[ -f go.mod ]] && command -v go >/dev/null 2>&1; then run_auto "go test ./..."; fi
  if [[ -f Cargo.toml ]] && command -v cargo >/dev/null 2>&1; then run_auto "cargo test --all-targets"; fi
fi

if [[ "$count" -eq 0 ]]; then
  printf 'ACS_STATUS=NONE_FOUND\nACS_SOURCE=auto\n'
else
  printf 'ACS_STATUS=PASS\nACS_SOURCE=auto\nACS_COMMANDS=%s\n' "$count"
fi
