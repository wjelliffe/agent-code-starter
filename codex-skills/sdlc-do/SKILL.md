---
name: sdlc-do
description: Use when a GitHub issue or direct request should be executed with a fast-first approach that escalates into a full two-gate SDLC delivery flow only when needed.
metadata:
  short-description: Definition of Done engine
---

# SDLC Do

Use this skill for implementation delivery from request through closeout. Start with a FAST attempt, and escalate into the full two-gate SDLC flow only when direct execution is no longer the cheapest safe path.

## Use It When

- plain-language implementation requests that clearly match this workflow
- `/sdlc-do #62`
- `$sdlc-do #62` in Codex threads
- `/sdlc-do implement this request`
- `/sdlc-do #62 mode=worktree`
- `/sdlc-do #62 mode=inplace`

## Inputs

- GitHub issue number or direct freeform request
- Execution mode is optional. Default to `inplace`. Use `worktree` only when the user explicitly wants isolation.

Resolve `<workspace-root>` from the active repository, typically with `git rev-parse --show-toplevel`.

## Runtime References

Use `get_issue.sh` only when the input is a GitHub issue reference rather than a direct freeform request.

- `get_issue.sh`
- `prepare_sdlc_context.sh`
- `start_worktree.sh`
- `run_checks.sh`
- `run_tests.sh`
- `summarize_diff.sh`
- `validate_dod.sh`
- `finalize_work.sh`

## Gates

- Gate 1: approve the plan (only after FAST failure)
- Gate 2: approve the finished work before finalization

## Flow

0. Pre-Execution (FAST Attempt)

Before entering the full SDLC flow, attempt a FAST execution pass.

### FAST Attempt

1. Interpret the request minimally.
2. Identify the smallest likely file set.
3. Attempt direct implementation.
4. Run the cheapest meaningful verification available, preferring targeted checks or targeted tests over broad suites.
5. Summarize diff.

### FAST Success

If the change:
- is clearly correct
- passes checks/tests (if applicable)
- does not involve schema, API contracts, or cross-cutting concerns
- does not introduce hidden uncertainty that would likely require plan-first execution

→ Skip Steps 1–8 and go directly to Step 10 (finalization gate)

Do not generate a plan when FAST succeeds.
Do not run `validate_dod.sh` when FAST succeeds.

### FAST Failure

FAST has failed if any of the following are true:

- the request is ambiguous or incomplete
- the change spans multiple files or systems unexpectedly
- checks/tests fail and root cause is not obvious
- the change impacts:
  - schema
  - migrations
  - API contracts
  - auth
  - permissions
  - billing
  - deployment behavior
- implementation requires a design decision

If FAST fails:
- briefly state why FAST was insufficient
- proceed to Step 1 below

---

1. Normalize the work context into `.tmp`.
2. Build the plan in the skill.
3. Gate 1 plan must include:
   - intended files or areas to modify
   - test strategy first
   - whether TDD is required, preferred, or not practical
   - verification plan
   - risks, assumptions, and dependencies
4. Prepare `inplace` or `worktree` execution context.
5. Write tests first whenever practical, then implement.
6. Run checks and tests.
7. Perform a code review pass in the skill.
8. If checks, tests, or review fail, loop back through implementation.
9. Summarize diff and validate DOD.
10. Gate 2 presents exactly:
   - `Commit and merge.`
   - `Commit and push up as Pull Request.`
11. Finalize with the runtime script.

## Rules

- FAST failure alone does not require a user approval gate; it only triggers the full SDLC flow.
- When FAST succeeds, skip Gate 1 entirely and proceed directly to the finalization gate.
- Use at most two approvals: Gate 1 only after FAST failure, and Gate 2 for finalization.
- `inplace` means branch from trunk in the current worktree.
- `worktree` means isolated branch/worktree for parallel work.
- Planning, TDD judgment, review, and failure interpretation stay in the skill.
- Deterministic execution belongs in `<workspace-root>/agentic-scripts`.
- Run `validate_dod.sh` only after FAST failure, within the full SDLC flow.
- Do not broaden repository inspection beyond the smallest likely file set unless FAST failure conditions are met.
- Do not normalize the full work context into `.tmp` until FAST has failed.
- In FAST, do not run a broad test suite when a targeted check or targeted test can provide sufficient confidence.
