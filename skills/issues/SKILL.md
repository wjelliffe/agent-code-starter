---
name: issues
description: Use when turning product or engineering input into actionable GitHub issues, including bugs, tasks, user stories, and epics with child stories.
metadata:
  short-description: Lean issue-definition workflow
---

# Issues

Turn rough product or engineering input into development-ready GitHub issue drafts with only the discovery needed to make the work actionable.

Bundled deterministic helpers live at `../../runtime/` relative to this skill. Run them with the target repository as the working directory.

## Flow

1. Inspect the request, referenced project docs, and relevant existing issues.
2. Classify as `bug`, `task`, `user_story`, or `epic`.
3. Ask questions only when a missing answer materially changes scope, acceptance criteria, dependencies, or architecture.
4. Draft the smallest useful issue structure.
   - bug/task/story: one issue
   - epic: one parent issue plus separate child stories
5. Make acceptance criteria testable.
6. Validate Definition of Ready proportionally to issue size.
7. Present the proposed issue(s).
8. Require the single approval gate before writing through deterministic runtime helpers.

## Runtime

Use only:
- `classify_issue_input.sh`
- `draft_issue_bundle.sh`
- `validate_dor.sh`
- `write_issues.sh`

## Rules

- No sub-agents or orchestration.
- Keep discovery conditional.
- Keep issue structure proportional.
- Parent epics are planning containers, not implementation units.
- Do not manufacture multi-issue trees for work that fits in one issue.
