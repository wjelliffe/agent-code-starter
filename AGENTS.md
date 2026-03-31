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


## Skills
A skill is a set of local instructions to follow that is stored in a `SKILL.md` file.

### Available skills
- Global Codex skills are typically installed under `~/.codex/skills`.
- Repository-local skills may be added under `codex-skills/<skill-name>/SKILL.md` when a project needs custom behavior.

### How to use skills
- Discovery: Use globally installed skills by name, or add repo-local skills under `codex-skills/` when needed.
- Trigger rules: If the user names a skill (with `$skill-name`, `/skill-name`, or plain text) OR the task clearly matches a skill description, use that skill for the turn.
- Missing/blocked: If a named skill path cannot be read, say so briefly and continue with the best fallback.
- Coordination: If multiple skills apply, use the minimal set and state the execution order.
- Context hygiene: Load only the files required to complete the active request.
