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
- `/sdlc-do #62 mode=worktree`
- `/sdlc-do #62 mode=inplace`

## Required Input

- Issue number is required. If missing, ask once and stop.
- Execution mode is optional:
  - default: `inplace`
  - optional override: `inplace`

## Execution Mode (Required)

### mode=worktree (opt-in)
- Use issue-isolated worktree/branch.
- Create/reuse/switch to `../<repo-name>-issue-<num>` and `codex/issue-<num>-<slug>`.
- Best for parallel thread execution.

### mode=inplace (default)
- Do not create/switch worktree.
- Stay in current opened repository/workspace.
- Create/switch only a local issue branch in-place (`codex/issue-<num>-<slug>`).
- Best for sequential work where user wants editor/git visibility in a single workspace.

## Preflight Worktree Isolation (Conditional)

Apply this section only when `mode=worktree`.

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

## Activation (Required)

After preflight and before any workflow step:

- In `worktree` mode: `cd` into issue worktree path, verify/switch to expected issue branch.
- In `inplace` mode: verify current cwd is the user-requested repo/workspace, then verify/switch to expected issue branch in-place.
- Confirm active path + branch + mode to the user in a status update.

## Workflow Sequence

1. Determine execution mode (`inplace` default or `worktree` override)
2. Preflight + activation according to mode
3. `/start #<num>`
4. `/pull #<num>`
5. `/docs #<num>`
6. `/implement #<num>`
7. `/commit #<num>`
8. Local closeout by default:
   - `worktree`: merge into local trunk, delete issue branch/worktree, do not push
   - `inplace`: merge/fast-forward in-place branch flow, then delete the issue branch locally; try `git branch -d` first and if blocked by upstream-merge safety after explicit commit+merge approval, use `git branch -D`; do not push unless requested

## Child Skill Invocation Rules

- Always invoke: `start`, `pull`, `docs`, `implement`, `commit`.
- `start` behavior is mode-dependent:
  - In `worktree` mode, run inside issue worktree branch context.
  - In `inplace` mode, run in current workspace branch context.
- Do not invoke any worktree-management subflow when `mode=inplace`.

## Two-Gate Mode (Required)

Only two approvals are allowed in this flow:

1. Gate 1: Plan Approval
2. Gate 2: Final Code Approval (before commit/push)

Do not ask for intermediate approvals unless blocked.

## Orchestration Behavior

- Pass the same issue number to all steps.
- Proceed autonomously between gates.
- Interrupt only for gate approval, missing input, or blocker decision.
- Default closeout after Gate 2 approval is local integration only and no remote push.

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
- `Approved. Commit and merge.` => commit + local merge/cleanup, no push; in `mode=inplace`, delete the issue branch after merge, try `git branch -d` first, and if blocked by upstream-merge safety, use `git branch -D`.
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
- In `mode=inplace`, after explicit commit+merge approval, force-delete the local issue branch only when safe delete is blocked solely by upstream-merge safety.
- Never push during default closeout unless user explicitly asked to push.
