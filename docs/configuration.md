# Configuration

Agent Code Starter should need no project-local framework files in the common case.

When deterministic overrides are useful, create `.agent-code` at the target repository root.

```text
trunk_branch=main
branch_prefix=agent/
check=npm run lint
check=npm run typecheck
test=npm test
```

## Fields

- `trunk_branch`: optional trunk branch override.
- `branch_prefix`: optional branch namespace; defaults to `agent/`.
- `check`: repeatable static/type/lint/build command.
- `test`: repeatable test command.

Configured commands run from the repository root in declaration order.

The format is intentionally line-oriented rather than JSON so ACS can read it natively from Bash and PowerShell without adding a parser/runtime dependency.

## Auto-detection

Without configured commands, verification looks for conventional JavaScript/TypeScript, Python, Go, and Rust project signals and only invokes a language runtime when that target repository actually uses it.

A project with no detectable command reports `ACS_STATUS=NONE_FOUND`; that is not silently promoted to a verified pass.

## Workflow policy

Review count, remediation count, and SDLC transitions are not configurable. They are product invariants enforced by the deterministic state machine.
