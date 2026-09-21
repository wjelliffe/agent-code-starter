# Agent Code Starter contributor guidance

Agent Code Starter is an installable coding-agent plugin built around one rule:

> The orchestrator belongs in deterministic code. The model is a bounded worker.

## Architecture

- Four judgment skills: `issues`, `plan`, `implement`, `code-review`.
- One workflow facade: `sdlc-do`.
- Each skill owns its deterministic helpers under `skills/<name>/scripts/`.
- Runtime helpers ship in Bash and PowerShell pairs; ACS has no Python/Node runtime dependency.
- `sdlc-do/scripts/sdlc.*` owns the finite lifecycle and persisted state.
- Target repositories own product truth and may optionally provide `.agent-code` overrides.
- Do not copy ACS framework scripts into target repositories.

## Product principles

- One task stays one task.
- Planning, implementation, acceptance assessment, and code review consume model judgment.
- Git, GitHub writes, verification commands, workflow state, and transition limits are deterministic.
- `implement` is the bounded fast path.
- `sdlc-do` drives one bounded feature to `DONE` or `BLOCKED` after one plan approval gate.
- SDLC review is bounded to two passes with at most one remediation pass.
- The final review cannot recurse into another remediation cycle.
- Prefer a fresh review context; do not turn the system into an agent team.
- Evidence before completion claims.

## Changes to this repository

- Keep `sdlc-do/SKILL.md` thin; orchestration logic belongs in `sdlc.*`.
- Do not add routing that silently upgrades `implement` into another workflow.
- Do not add runtime dependencies just to parse configuration/state.
- Keep Bash and PowerShell behavior equivalent.
- Add regression coverage for every state transition or deterministic safety rule you change.
- Keep Codex and Claude plugin versions synchronized.
