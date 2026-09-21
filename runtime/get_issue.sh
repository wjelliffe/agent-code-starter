#!/usr/bin/env bash
set -euo pipefail

[[ "$#" -ge 1 ]] || { echo "usage: $0 <issue-number> [<issue-number> ...]" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "gh CLI is required" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required" >&2; exit 1; }

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "${repo_root}" ]] || { echo "get_issue.sh must run inside the target git repository" >&2; exit 1; }
tmp_dir="${repo_root}/.tmp"
mkdir -p "${tmp_dir}"
issue_numbers=("$@")

if [[ "${#issue_numbers[@]}" -eq 1 ]]; then
  output_path="${tmp_dir}/issue-${issue_numbers[0]}.json"
else
  joined="$(IFS=-; echo "${issue_numbers[*]}")"
  output_path="${tmp_dir}/issue-bundle-${joined}.json"
fi

repo_json="$(gh repo view --json nameWithOwner)"
raw_json="$(
python3 - "${issue_numbers[@]}" <<'PY'
import json, subprocess, sys
items = []
for number in sys.argv[1:]:
    proc = subprocess.run(
        ["gh", "issue", "view", number, "--json",
         "number,title,body,url,state,labels,assignees,author,comments"],
        capture_output=True, text=True,
    )
    if proc.returncode:
        raise SystemExit(proc.stderr.strip() or f"failed to read issue {number}")
    items.append(json.loads(proc.stdout))
print(json.dumps(items))
PY
)"

RAW="${raw_json}" REPO="${repo_json}" OUTPUT="${output_path}" python3 <<'PY'
import json, os, re, subprocess
from datetime import datetime, timezone

def slug(value):
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")

def sections(body):
    result = {"summary": []}
    current = "summary"
    for line in body.splitlines():
        match = re.match(r"^\s{0,3}#{1,6}\s+(.+?)\s*$", line)
        if match:
            current = slug(match.group(1)) or current
            result.setdefault(current, [])
        else:
            result.setdefault(current, []).append(line)
    return {k: "\n".join(v).strip() for k, v in result.items() if "\n".join(v).strip()}

def bullets(text):
    out = []
    for line in text.splitlines():
        match = re.match(r"^\s*[-*]\s+(?:\[[ xX]\]\s+)?(.+?)\s*$", line)
        if match:
            out.append(match.group(1).strip())
    return out

def api(path):
    proc = subprocess.run(["gh", "api", path], capture_output=True, text=True)
    if proc.returncode:
        if "404" in (proc.stderr or ""):
            return None
        raise SystemExit(proc.stderr.strip() or f"gh api failed: {path}")
    return json.loads(proc.stdout)

raw_items = json.loads(os.environ["RAW"])
repo = json.loads(os.environ["REPO"])["nameWithOwner"]
owner, name = repo.split("/", 1)
normalized = []

for raw in raw_items:
    body = raw.get("body") or ""
    sec = sections(body)
    acceptance_text = "\n".join(sec.get(k, "") for k in ("acceptance-criteria", "acceptance", "definition-of-done", "dod"))
    parent = api(f"repos/{owner}/{name}/issues/{raw['number']}/parent")
    children = api(f"repos/{owner}/{name}/issues/{raw['number']}/sub_issues") or []
    comments = [
        {
            "author": (comment.get("author") or {}).get("login"),
            "body": comment.get("body") or "",
            "created_at": comment.get("createdAt"),
            "url": comment.get("url"),
        }
        for comment in (raw.get("comments") or [])
    ]
    normalized.append({
        "issue_number": raw["number"],
        "slug": slug(raw.get("title") or f"issue-{raw['number']}"),
        "title": raw.get("title") or "",
        "problem": sec.get("problem", ""),
        "objective": sec.get("objective", raw.get("title") or ""),
        "scope": sec.get("scope", ""),
        "non_goals": bullets(sec.get("non-goals", "")),
        "dependencies": bullets(sec.get("dependencies", "")),
        "constraints": bullets(sec.get("constraints", "")),
        "acceptance_criteria": bullets(acceptance_text),
        "risks": bullets(sec.get("risks", "")) or bullets(sec.get("edge-cases-risks", "")),
        "test_intent": bullets(sec.get("test-intent", "")) or bullets(sec.get("test-plan", "")),
        "implementation_hints": bullets(sec.get("implementation-hints", "")),
        "comments": comments,
        "parent_issue": {
            "number": parent.get("number"),
            "title": parent.get("title"),
            "url": parent.get("html_url"),
        } if isinstance(parent, dict) else None,
        "sub_issues": [
            {"number": item.get("number"), "title": item.get("title"), "url": item.get("html_url")}
            for item in children
        ],
        "sections": sec,
    })

if len(normalized) == 1:
    norm = normalized[0]
else:
    nums = [item["issue_number"] for item in normalized]
    norm = {
        "issue_numbers": nums,
        "issue_number": nums[0],
        "slug": "issues-" + "-".join(str(n) for n in nums),
        "title": " + ".join(item["title"] for item in normalized),
        "objective": "\n".join("- " + item["objective"] for item in normalized if item["objective"]),
        "scope": "\n\n".join(item["scope"] for item in normalized if item["scope"]),
        "dependencies": list(dict.fromkeys(x for item in normalized for x in item["dependencies"])),
        "constraints": list(dict.fromkeys(x for item in normalized for x in item["constraints"])),
        "acceptance_criteria": list(dict.fromkeys(x for item in normalized for x in item["acceptance_criteria"])),
        "risks": list(dict.fromkeys(x for item in normalized for x in item["risks"])),
        "test_intent": list(dict.fromkeys(x for item in normalized for x in item["test_intent"])),
        "comments": [x for item in normalized for x in item["comments"]],
        "issues": normalized,
        "parent_issue": None,
        "sub_issues": [],
    }

payload = {
    "schema_version": 2,
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "source": "gh issue view",
    "repository": repo,
    "issue": raw_items[0],
    "issues": raw_items,
    "normalized": norm,
}
with open(os.environ["OUTPUT"], "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2, sort_keys=True)
    handle.write("\n")

print(json.dumps({
    "ok": True,
    "path": os.environ["OUTPUT"],
    "issue_numbers": [item["issue_number"] for item in normalized],
}))
PY
