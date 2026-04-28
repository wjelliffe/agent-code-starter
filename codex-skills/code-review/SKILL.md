---
name: code-review
description: Perform a skeptical review of the current diff against the issue/request. No edits.
metadata:
  short-description: Skeptical pre-commit review
---

# Code Review

Perform a code review of what's changed. Skeptical review only. Inspect the diff against the issue.

Look for:
- missed acceptance criteria
- edge cases
- broken existing behavior
- missing targeted tests
- scope creep

Return:
APPROVE or BLOCKERS ONLY.

Do not modify files.