---
name: verify
description: Use when implementation appears complete or before any commit, merge, pull request, or success claim; requires fresh evidence for checks, tests, requirements, and diff state.
---

# Verify

Evidence comes before completion claims.

## Required evidence

1. Re-read the issue/request and enumerate the requirements that changed code must satisfy.
2. Run the relevant check command(s) fresh.
3. Run the relevant test command(s) fresh.
4. Read the resulting status and exit code; do not infer success from partial output.
5. Inspect the current diff/status for unintended files and unresolved conflicts.
6. For PR work, inspect available CI results before claiming the branch is green.
7. Match each material acceptance criterion to code/test evidence or call out the gap.

Runtime verification reports three meaningful states:

- `pass` — commands ran and passed
- `fail` — at least one command ran and failed
- `none-found` — no applicable command was detected

`none-found` is never equivalent to "tests pass."

If evidence is incomplete, report the actual limitation. Do not use "should pass", "looks good", or similar language as a substitute for execution.
