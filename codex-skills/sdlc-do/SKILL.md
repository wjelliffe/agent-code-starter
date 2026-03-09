---
name: sdlc-do
description: Deliver a GitHub issue end-to-end in one self-contained Two-Gate workflow.
metadata:
  short-description: Single-skill issue delivery with two approvals
---

# SDLC Do

Deliver an issue end to end without fanning out into `start`, `pull`, `docs`, `implement`, and `commit` unless the user explicitly asks for those skills separately.

## Usage

- `/sdlc-do #62`
- `/sdlc-do 62`
- `/sdlc-do #62 mode=worktree`
- `/sdlc-do #62 mode=inplace`

## Required Input

- Issue number is required. If missing, ask once and stop.
- Execution mode is optional. Default to `inplace`. Only use `worktree` when the user asks for issue isolation.

## Core Rules

- Exactly two approvals are allowed:
  - Gate 1: plan approval
  - Gate 2: final diff approval before commit or push
- Do not invoke child SDLC skills by default. Keep this workflow self-contained.
- Stay on the repo branch convention: `codex/issue-<num>-<slug>`.
- Do not create `docs/issues/ISSUE-<num>.md` unless the user asks for it or the issue is complex enough to need a durable checklist.
- Do not run installs or tests unless the user explicitly asks or repo instructions require it.
- Never reset hard, discard user changes, or force-delete a dirty worktree.

## Workflow Sequence

1. Resolve the issue number and execution mode.
2. Preflight branch context.
   - `inplace`: stay in the current repo, verify the tree is usable, and create or switch to `codex/issue-<num>-<slug>`.
   - `worktree`: create, reuse, or switch to `../<repo-name>-issue-<num>` on the same branch name.
   - Base from `origin/main` when available, otherwise `main`.
   - If the target worktree exists but is dirty or on the wrong branch, stop and ask how to proceed.
3. Fetch the issue once with `gh issue view <num> --json ...` and extract acceptance criteria, constraints, and open questions.
4. Build one scoped plan that covers code, docs, risks, and verification. Keep it concise and execution-ready.
5. Present Gate 1 with the exact prompt:
   - `Plan ready. Reply: "Approved. Implement."`
6. After approval, implement the full issue in one pass. Do not stop for extra approvals unless blocked.
7. Update docs that are actually affected by the change. Avoid standalone doc-only subflows unless the user asked for them.
8. Run only the verification the user asked for or that is already safe and available in the repo instructions.
9. Present the pre-commit diff package:
   - `git status --short`
   - `git diff --stat`
   - changed file list with absolute openable paths
   - concise summary of what changed and why
   - verification run and any gaps
10. Present Gate 2 with the exact prompt:
   - `Final diff ready. Reply: "Approved. Commit and merge." or "Approved. Push to branch."`
11. After approval, commit with a conventional subject and `Fixes #<num>` in the body.
12. Default closeout is local only:
   - `Approved. Commit and merge.`: commit, integrate locally, clean up the local issue branch when safe, and do not push.
   - `Approved. Push to branch.`: commit and push the branch.

## Pre-Commit Diff Presentation (Required)

Before Gate 2 approval prompt, always present a concrete diff review package:

- `git status --short`
- `git diff --stat`
- changed file list with openable file paths (so the user can inspect in Codex editor)
- concise summary of what changed and why
- any verification commands run and outcomes

Do not ask for final approval until this diff package is shown.

Interpretation:
- `Approved. Commit and merge.` => commit, locally integrate, and clean up without pushing.
- `Approved. Push to branch.` => commit and push the branch.

## Revision Loops

- Gate 1 feedback: revise plan and return to Gate 1.
- Gate 2 feedback: revise implementation and return to Gate 2.

## Output

After each step provide status, touched files, and blockers. End with branch, commit hash, AC coverage, and suggested next command `/ship`.

## Rules

- Respect repo approval and safety rules.
- Do not force push unless explicitly requested.
- In `mode=inplace`, after explicit commit+merge approval, use `git branch -d` first. Only use `git branch -D` when safe delete is blocked solely by upstream-merge safety.
- Never push during default closeout unless the user explicitly asked to push.
