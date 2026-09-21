---
name: issues
description: Use when turning product or engineering input into actionable GitHub issues, including bugs, tasks, user stories, and epics with child stories.
metadata:
  short-description: Turn rough work into ready issues
---

# Issues

Turn rough product or engineering input into the smallest useful set of development-ready GitHub issues.

Deterministic GitHub operations live in `scripts/`. Use `.sh` on Bash-compatible hosts and `.ps1` on PowerShell hosts. Run them from the target repository.

## Flow

1. Inspect the request, relevant project docs, and existing issues only as needed.
2. Classify the work as a bug, task, user story, or epic.
3. Ask only questions that materially change scope, acceptance criteria, dependencies, or architecture.
4. Draft proportional issue structure:
   - bug/task/story: one issue
   - epic: one parent plus independently executable child stories
5. Make acceptance criteria testable.
6. Validate the body with `scripts/validate-dor.*`.
7. Present the draft and get one approval before writing.
8. Create issues with `scripts/create-issue.*`; link epic children with `scripts/link-sub-issue.*`.

Use `scripts/get-issue.*` whenever another ACS workflow needs deterministic issue retrieval.

## Contract

- Keep one task one task.
- Parent epics are planning containers, not implementation units.
- Do not manufacture issue trees for work that fits in one issue.
- The model decides what the issue means. Scripts perform the GitHub writes.
