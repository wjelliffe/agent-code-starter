---
name: issues
description: Use when turning product or engineering input into actionable GitHub issues, including bugs, tasks, user stories, and epics with child stories.
---

# Issues

Turn rough product or engineering input into development-ready GitHub issue drafts with only the discovery needed for the work to be actionable.

Bundled runtime lives at `../../runtime/` relative to this `SKILL.md`. Resolve that path from the installed skill file; run runtime commands with the target repository as the working directory. Invoke bundled shell helpers through `bash` (for example, `bash <plugin-root>/runtime/start_worktree.sh ...`) because plugin packaging may not preserve executable bits.

## Flow

1. Inspect the request, referenced project docs, and relevant existing issues.
2. Classify it as `bug`, `task`, `user_story`, or `epic` using runtime classification as an aid.
3. Ask questions only when a missing answer would materially change scope, acceptance criteria, dependencies, or architecture.
4. Draft the smallest useful issue structure.
   - bug/task/story: one issue
   - epic: one parent issue plus separate child story issues attached as GitHub sub-issues
5. Make acceptance criteria testable and keep implementation hints distinct from requirements.
6. Validate Definition of Ready proportionally to issue size.
7. Present the proposed issue(s) and require approval before writing them.
8. Write through the bundled runtime only after approval.

## Runtime

Use:

- `classify_issue_input.sh`
- `draft_issue_bundle.sh`
- `validate_dor.sh`
- `write_issues.sh`

## Rules

- Do not manufacture an epic for work that fits in one issue.
- Do not turn every ambiguity into a question; resolve low-cost implementation details later.
- Dependencies and constraints that affect execution belong in the issue.
- Parent epics are planning containers, not implementation units.
