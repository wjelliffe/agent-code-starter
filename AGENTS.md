# AGENTS.md

These instructions apply to all AI agents in this repository.

## Approval Gate (Required)
- Always propose code/doc changes before editing files.
- Wait for explicit approval (for example: "approved") before edits.
- Batch related edits when practical.

## Scope and Safety
- Do not run destructive commands (for example: `rm`, `git reset --hard`) unless explicitly requested.
- Do not edit files outside this repo without approval.
- Avoid unrelated edits.

## Collaboration
- Prefer minimal, incremental changes.
- Preserve existing behavior unless explicitly asked to change it.
- If requirements are ambiguous, ask clarifying questions.

## Quality
- Keep style consistent with existing code.
- Add brief comments only for non-obvious logic.

## Testing
- Suggest relevant checks after changes.
- Do not run installs/tests unless requested or approved.

## Database Workflow (Project-specific)
- If this project uses a database migration system, always commit schema + migration together.
- Keep seed/reference data idempotent.
- Document production-safe vs local-only seed flows.

## Tech Stack (Fill Per Project)
- Framework: <fill>
- Language: <fill>
- Database: <fill>
- Deployment: <fill>

