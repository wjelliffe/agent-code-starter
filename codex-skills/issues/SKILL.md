---
name: issues
description: Use when rough work needs a Definition of Ready pass that turns it into execution-ready stories or GitHub issues.
metadata:
  short-description: Definition of Ready engine
---

# Issues

Use this skill to produce execution-ready work. It is a Definition of Ready pass, not an implementation flow.

## Use It For

- turning a rough request, spec, or plan into small executable stories
- normalizing issue context before implementation
- checking whether a story is ready for `/sdlc-do` or `/implement`
- optionally drafting GitHub issues after the work passes DOR

## Inputs

Use the lightest available source of truth:

1. current conversation context
2. referenced local plan/spec files
3. GitHub issue context normalized by `<workspace-root>/agentic-scripts/get_issue.sh <num>` into `<workspace-root>/.tmp/issue-<num>.json`

Resolve `<workspace-root>` from the active repository, typically with `git rev-parse --show-toplevel`.

All agents working the same task should read the same structured `.tmp` artifact from that workspace.

## Workflow

1. Gather the request, constraints, dependencies, and success conditions.
2. If the source is a GitHub issue, run `<workspace-root>/agentic-scripts/get_issue.sh <num>` and read `<workspace-root>/.tmp/issue-<num>.json`.
3. Break the work into the smallest executable stories that do not need more planning.
4. For each story, include:
   - problem / objective
   - value
   - scope
   - non-goals
   - dependencies
   - constraints
   - acceptance criteria
   - edge cases / risks
   - test intent
   - implementation hints (optional)
5. Run the DOR checklist against each story.
6. If any checklist item fails, revise the story instead of handing off vague work.
7. Stop after presenting execution-ready stories. Only create GitHub issues if the user explicitly asks.

## DOR Checklist

- problem is clear
- scope is bounded
- acceptance criteria are concrete
- dependencies known
- constraints known
- testability defined
- risks identified
- story is small and executable
- no additional planning required

## Rules

- Do reasoning here. Do not implement here.
- Deterministic execution belongs in `<workspace-root>/agentic-scripts`, not in the skill body.
- Do not write transient planning material into `docs/` or any tracked scratch file.
- Keep outputs compact and execution-ready.
- If GitHub issue creation is requested, present the exact drafts first and wait for approval.
