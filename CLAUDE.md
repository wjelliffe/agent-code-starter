# CLAUDE.md

Generic project guidance for Claude Code.

## Core Workflow
1. Ensure clean tree.
2. Create/switch to a feature branch.
3. Plan work before coding.
4. Propose changes and wait for approval.
5. Implement in small, scoped commits.
6. Verify with approved checks.
7. Open PR with clear summary and test plan.

## Guardrails
- Never commit directly to `main`.
- Avoid destructive commands without explicit user approval.
- Keep edits tightly scoped to the request.

## Commands
Use slash-command specs in `.claude/commands` for SDLC automation.

