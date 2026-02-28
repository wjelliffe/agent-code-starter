---
name: sdlc-do
description: Orchestrate end-to-end issue delivery in strict Two-Gate Mode.
metadata:
  short-description: Run start/pull/docs/implement/commit with two approvals
---

# SDLC Do (Orchestrator)

Execute the end-to-end issue workflow in strict Two-Gate Mode.

## Usage

- `/sdlc-do #62`
- `/sdlc-do 62`

## Required Input

- Issue number is required. If missing, ask once and stop.

## Preflight Worktree Isolation (Required)

Before running workflow steps, ensure execution is in an issue-isolated worktree.

- Repository root: detect with `git rev-parse --show-toplevel`
- Repository name: basename of repository root
- Worktree path: `../<repo-name>-issue-<num>`
- Branch name: `codex/issue-<num>-<slug>`
- Base branch/ref: `origin/main` (fallback `main` if `origin/main` is unavailable)

Behavior:

- If already inside the matching worktree and on the matching branch, continue.
- If not, create/switch to the target worktree before Step 1.
- If target worktree exists, reuse only when branch matches and working tree is clean.
- If target worktree exists but is dirty or on a mismatched branch, stop and ask user how to proceed.
- Never force-delete worktrees, never reset hard, and never discard uncommitted changes.

## Worktree Activation (Required)

After preflight and before any workflow step:

- `cd` into the issue worktree path.
- Verify active branch equals the expected issue branch.
- If not on the expected issue branch, switch to it explicitly before proceeding.
- Confirm active worktree path + branch to the user in a status update.

## Workflow Sequence

1. Preflight worktree isolation
2. Worktree activation (cd + branch verification/switch)
3. `/start #<num>`
4. `/pull #<num>`
5. `/docs #<num>`
6. `/implement #<num>`
7. `/commit #<num>`
8. Local closeout by default: merge into local trunk (`main`/`master`), delete issue branch/worktree, do not push

## Two-Gate Mode (Required)

Only two approvals are allowed in this flow:

1. Gate 1: Plan Approval
2. Gate 2: Final Code Approval (before commit/push)

Do not ask for intermediate approvals unless blocked.

## Orchestration Behavior

- Pass the same issue number to all steps.
- Proceed autonomously between gates.
- Interrupt only for gate approval, missing input, or blocker decision.
- Default closeout after Gate 2 approval is local integration only: commit, merge to local trunk, branch cleanup, no remote push.

## Pre-Commit Diff Presentation (Required)

Before Gate 2 approval prompt, always present a concrete diff review package:

- `git status --short`
- `git diff --stat`
- changed file list with openable file paths (so the user can inspect in Codex editor)
- concise summary of what changed and why
- any verification commands run and outcomes

Do not ask for final approval until this diff package is shown.

## Gate Prompts

Use exact prompts:

- `Plan ready. Reply: "Approved. Implement."`
- `Final diff ready. Reply: "Approved. Commit and merge." or "Approved. Push to branch."`

Interpretation:
- `Approved. Commit and merge.` => commit + local merge + cleanup, no push.
- `Approved. Push to branch.` => commit + push branch.

## Revision Loops

- Gate 1 feedback: revise plan and return to Gate 1.
- Gate 2 feedback: revise implementation and return to Gate 2.

## Output

After each step provide status, touched files, and blockers. End with branch, commit hash, AC coverage, and suggested next command `/ship`.

## Rules

- Respect repo approval and safety rules.
- Do not run tests/install unless explicitly requested.
- Do not force push unless explicitly requested.
- Never push during default closeout unless user explicitly asked to push.
