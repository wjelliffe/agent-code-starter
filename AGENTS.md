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
- start: Initialize a new feature or bugfix branch following the repo workflow. (file: /Users/willj/repos/agent-code-starter/codex-skills/start/SKILL.md)
- pull: Fetch a GitHub issue and materialize it into a local execution doc. (file: /Users/willj/repos/agent-code-starter/codex-skills/pull/SKILL.md)
- docs: Capture required documentation updates for the current issue. (file: /Users/willj/repos/agent-code-starter/codex-skills/docs/SKILL.md)
- implement: Implement an issue in scoped, approval-gated steps. (file: /Users/willj/repos/agent-code-starter/codex-skills/implement/SKILL.md)
- commit: Commit issue work with issue-closing reference and local issue-doc cleanup. (file: /Users/willj/repos/agent-code-starter/codex-skills/commit/SKILL.md)
- issues: Turn an approved implementation plan into detailed GitHub issues. (file: /Users/willj/repos/agent-code-starter/codex-skills/issues/SKILL.md)
- ship: Create a PR from the current branch and close resolved issues. (file: /Users/willj/repos/agent-code-starter/codex-skills/ship/SKILL.md)
- sdlc-do: Orchestrate end-to-end issue delivery in strict Two-Gate Mode. (file: /Users/willj/repos/agent-code-starter/codex-skills/sdlc-do/SKILL.md)
- closeout: Disabled command for this repository. (file: /Users/willj/repos/agent-code-starter/codex-skills/closeout/SKILL.md)

### How to use skills
- Discovery: The list above is the skills available in this repository.
- Trigger rules: If the user names a skill (with `$skill-name`, `/skill-name`, or plain text) OR the task clearly matches a skill description, use that skill for the turn.
- Missing/blocked: If a named skill path cannot be read, say so briefly and continue with the best fallback.
- Coordination: If multiple skills apply, use the minimal set and state the execution order.
- Context hygiene: Load only the files required to complete the active request.
