---
name: implement
description: Use when implementing one clear GitHub issue or direct request with minimal overhead; this is the default delivery path unless material risk or ambiguity requires sdlc-do.
---

# Implement

Execute one bounded change cheaply without sacrificing correctness.

Bundled runtime lives at `../../runtime/` relative to this `SKILL.md`. Resolve that path from the installed skill file; run runtime commands with the target repository as the working directory. Invoke bundled shell helpers through `bash` (for example, `bash <plugin-root>/runtime/start_worktree.sh ...`) because plugin packaging may not preserve executable bits.

## 1. Read before editing

For an issue, load the issue, comments, parent/child context, dependencies, acceptance criteria, and test intent. For a direct request, inspect the relevant code and project instructions.

Use `route.py` as an advisory risk signal. Escalate to `sdlc-do` before editing when the work materially involves auth/authz, security controls, secrets/tokens, migrations/backfills, data integrity, transactions/concurrency, payments, production infrastructure, coupled subsystems, an unclear approach, or an explicit strict/TDD request.

Do not escalate ordinary work merely because the repository is important.

## 2. Create a safe branch

Use `start_worktree.sh <work-key> inplace <context-path>`. Never implement directly on trunk. If the working tree is dirty and safe isolation cannot be established, stop rather than overwrite unrelated work.

## 3. Execution preview

State briefly:

- intended change
- likely files
- relevant verification

Do not add a plan-approval gate on the fast path.

## 4. Implement

Follow existing architecture and domain semantics. Make the smallest change that satisfies the request.

If you encounter a bug, failed test, or unexpected behavior whose cause is not already proven, use `systematic-debugging` before patching.

Add or update targeted tests when behavior, invariants, regressions, authorization, or error paths warrant them. Fast path does not require ceremonial test-first work for mechanical changes.

## 5. Verify

Run `run_checks.sh`. Run `run_tests.sh` when tests exist, behavior changed, the issue requires tests, or a regression is being fixed.

Invoke `verify` before saying the work is ready. A `none-found` test result means no tests were found; never describe it as tests passing.

Summarize the diff with `summarize_diff.sh`.

## 6. Final gate

Present:

- `Execute code review.`
- `Commit and merge.`
- `Commit and push up as Pull Request.`

If review is selected, invoke `code-review`. Fix blocking findings, re-run relevant verification, and re-review before offering finalization again.

Finalize only through `finalize_work.sh`.

## Rules

- One bounded delivery unit only.
- No mandatory subagents.
- No speculative framework work.
- Preserve project-specific instructions and invariants.
- Do not claim success from code inspection alone.
