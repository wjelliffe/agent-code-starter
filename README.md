# Agent Code Starter

Starter kit for AI-assisted software delivery with strict standards, approval gates, and SDLC command orchestration.

## Included

- `AGENTS.md` (repo-wide guardrails)
- `CLAUDE.md`, `CODEX.md`, `GEMINI.md` (agent guidance)
- `.claude/commands/*` (SDLC slash-command workflows)
- `.github/workflows/deploy-template.yml` (generic deploy template)

## SDLC Command Workflow

Slash commands live in `.claude/commands`.

### One-command execution

```text
/sdlc-do #<issue>
```

### Two-Gate Mode (`/sdlc-do`)

Only two approvals are expected:

1. Plan approval
   - `Approved plan. implement now.`
2. Final code approval (before commit/push)
   - `Approved final. commit and push.`
   - or `Approved final. commit only.`

If revisions are requested:
- plan revisions return to Gate 1
- code revisions return to Gate 2

### Step-by-step alternative

```text
/start #<issue>
/pull #<issue>
/docs #<issue>
/implement #<issue>
/commit #<issue>
/ship
```

## Quick Bootstrap Checklist

1. Set your project stack and deployment details in `AGENTS.md`.
2. Update any command text in `.claude/commands` for repo-specific conventions.
3. Replace deploy template workflow with your real CI/CD workflow.
4. Confirm labels expected by commands exist in GitHub (`gh label list`).

## Notes

- The local pulled issue mirror (`docs/issues/ISSUE-<n>.md`) is intentionally removed by `/commit` to avoid duplicating canonical issue content from GitHub.
- By default, commands preserve strict approval-gate behavior and avoid destructive actions.
