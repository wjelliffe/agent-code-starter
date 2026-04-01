---
name: implement
description: Use when the user wants a quick direct change without the full issue-driven SDLC flow.
metadata:
  short-description: Execution-only fast path
---

# Implement

Use this skill for small direct changes when the user does not want the full DOR/DOD flow.

Resolve `<workspace-root>` from the active repository, typically with `git rev-parse --show-toplevel`.

## Use It When

- `/implement #62`
- `/implement fix this quickly`
- `/implement make the change on main`

## Runtime References

- `run_checks.sh`
- `summarize_diff.sh`

## Flow

1. Read the local context.
2. Reuse a matching `.tmp` issue artifact if it already exists.
3. Present a small execution plan.
4. Stop for approval before edits.
5. Implement directly in the current repo and current branch.
6. Run checks and summarize the diff.

## Rules

- Do not create worktrees.
- Do not orchestrate the full SDLC flow.
- No issue is required.
- If the current branch is `main`, stay on `main`.
- Commit only if the user explicitly asks.
- A direct commit to `main` is allowed for this fast path when explicitly requested.
