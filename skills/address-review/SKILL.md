---
name: address-review
description: Use when a pull request has review comments or requested changes that need to be evaluated, fixed when valid, verified, and answered without blindly accepting technically incorrect feedback.
---

# Address Review

Treat review feedback as technical input, not commands to agree with performatively.

## Flow

1. Fetch the PR, all conversation comments, review submissions, inline comments, and current CI.
2. Read the underlying issue/requirements and the changed code before judging a comment.
3. For each unresolved finding, classify it:
   - valid and blocking
   - valid but non-blocking
   - already addressed
   - incorrect / based on a false assumption
   - requires product/architecture clarification
4. Fix valid findings at the owning layer. Keep fixes scoped.
5. For technically incorrect feedback, preserve the correct implementation and respond with concise evidence rather than making a harmful change.
6. Re-run the checks/tests that cover every amended area.
7. Re-run `code-review` when the fixes are substantive or touched security/data/invariants.
8. Respond to review threads with what changed or why the code stands.

Do not mark feedback addressed solely because code changed. Verification must cover the specific concern.
