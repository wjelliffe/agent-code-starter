# Agent Code Starter contributor guidance

This repository is the source for an installable coding-agent plugin.

## Architecture

- `skills/` contains exactly four human-facing workflows: `issues`, `implement`, `sdlc-do`, and `code-review`.
- `runtime/` contains deterministic Git, GitHub, validation, test/check, and finalization mechanics.
- Project-specific architecture, invariants, commands, and policy stay in the target repository.
- `.agent-code.json` is the optional target-repository override surface.

## Product principles

- One task stays one task.
- One primary agent only; no sub-agent orchestration in implementation workflows.
- No automatic workflow escalation.
- No automatic retry loops.
- Code review is one-shot and never edits.
- Review blockers stop execution; remediation requires a new explicit user action.
- Deterministic work belongs in runtime helpers.
- Evidence before completion claims.
- Keep important invariants in the service/data layer rather than relying on UI-only enforcement.

## Changes to this repository

- Do not add new skills without a compelling reason and an explicit product decision.
- Do not reintroduce recursive review/fix/re-review behavior.
- Do not add routing that silently turns `implement` into `sdlc-do`.
- Add or update tests when changing skill contracts or runtime behavior.
- Keep plugin versions in Codex and Claude manifests synchronized.
