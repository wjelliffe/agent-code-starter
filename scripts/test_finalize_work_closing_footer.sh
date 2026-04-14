#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)"
script_path="${repo_root}/agentic-scripts/finalize_work.sh"

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

remote_repo="${tmpdir}/remote.git"
main_repo="${tmpdir}/main"
feature_repo="${tmpdir}/feature"
stub_bin="${tmpdir}/bin"
gh_log="${tmpdir}/gh.log"
context_path="${feature_repo}/context.json"

git init --bare "${remote_repo}" >/dev/null
git clone "${remote_repo}" "${main_repo}" >/dev/null 2>&1
git -C "${main_repo}" config user.name "Codex Test"
git -C "${main_repo}" config user.email "codex@example.com"
printf "seed\n" > "${main_repo}/README.md"
git -C "${main_repo}" add README.md
git -C "${main_repo}" commit -m "seed" >/dev/null
git -C "${main_repo}" push -u origin main >/dev/null 2>&1 || git -C "${main_repo}" push -u origin master >/dev/null
git -C "${main_repo}" branch -M main >/dev/null 2>&1 || true
git -C "${main_repo}" push -u origin main >/dev/null 2>&1 || true

git -C "${main_repo}" worktree add -b codex/test-closing-footer "${feature_repo}" main >/dev/null
git -C "${feature_repo}" config user.name "Codex Test"
git -C "${feature_repo}" config user.email "codex@example.com"

mkdir -p "${stub_bin}"
cat > "${stub_bin}/gh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "${gh_log}"
exit 99
EOF
chmod +x "${stub_bin}/gh"

cat > "${context_path}" <<'EOF'
{
  "title": "Finish issue-based work",
  "summary": "Finalize the implementation in merge mode.",
  "issue_number": 41,
  "closing_issue_number": 41,
  "execution_role": "standalone_issue",
  "epic_registry_path": null
}
EOF

printf "change\n" >> "${feature_repo}/README.md"

(
  cd "${feature_repo}"
  PATH="${stub_bin}:$PATH" "${script_path}" merge "${context_path}" >/dev/null
)

commit_body="$(git -C "${main_repo}" log -1 --pretty=%B)"
if [[ "${commit_body}" != *"Fixes #41"* ]]; then
  echo "expected commit body to contain Fixes #41" >&2
  exit 1
fi

if [[ -s "${gh_log}" ]]; then
  echo "expected no gh commands during merge finalization" >&2
  cat "${gh_log}" >&2
  exit 1
fi

echo "ok: finalize_work.sh merge adds Fixes footer without gh issue actions"
