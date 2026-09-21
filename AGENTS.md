# Agent Code Starter contributor guidance

This repository is the source for an installable coding-agent plugin.

## Architecture

- `skills/` is the single source of truth for agent behavior.
- `runtime/` contains deterministic Git, GitHub, validation, and issue helpers.
- Target application repositories must not receive copied Agent Code Starter skills or runtime files.
- Project-specific architecture, invariants, commands, and policy stay in the target repository.
- `.agent-code.json` is the optional target-repository override surface.

## Product principles

- Default to the lean `implement` path.
- Escalate to `sdlc-do` when risk or ambiguity justifies the ceremony.
- Evidence before completion claims.
- Root cause before bug fixes.
- Review the real code and current trunk, not only descriptions.
- Keep important invariants in the service/data layer rather than relying on UI-only enforcement.
- Avoid mandatory subagent orchestration for ordinary changes.

## Changes to this repository

- Keep skills harness-agnostic; reference actions and bundled runtime rather than hard-coding one agent product's tool names.
- Add or update tests when changing skill contracts or runtime behavior.
- Keep plugin versions in Codex and Claude manifests synchronized.
- Never restore per-project propagation scripts as the normal installation model.
