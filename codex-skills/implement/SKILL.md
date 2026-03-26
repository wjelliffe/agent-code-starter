---
name: implement
description: Use when the user wants a quick direct change without the full issue-driven SDLC flow.
metadata:
  short-description: Execution-only fast path
---

# Implement

Use this skill for small direct changes when the user does not want the full DOR/DOD flow.

Resolve `<workspace-root>` from the active repository, typically with `git rev-parse --show-toplevel`.

## Usage

- `/implement #62`
- `/implement 62`
- `/implement fix this quickly`
- `/implement make the change on main`

## Workflow

1. Read the local context.
2. If a matching `<workspace-root>/.tmp/issue-<num>.json` already exists, use it. Do not fetch or normalize issue context unless the user asks.
3. Define a small execution plan with files, risks, and verification.
4. Stop for approval before edits.
5. Implement directly in the current repo and current branch.
6. Run `<workspace-root>/agentic-scripts/run_checks.sh`.
7. Run `<workspace-root>/agentic-scripts/summarize_diff.sh`.
8. Stop and report results.

## Rules

- Do not create worktrees.
- Do not orchestrate the full SDLC flow.
- No issue is required.
- If the current branch is `main`, stay on `main`.
- Commit only if the user explicitly asks.
- If the user explicitly asks for a commit while on `main`, a direct commit to `main` is allowed for this fast path.
- Respect repo approval-gate and safety rules.
