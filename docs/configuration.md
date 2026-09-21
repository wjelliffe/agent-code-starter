# Configuration

Agent Code Starter should need no project-local framework files in the common case.

When a repository needs explicit deterministic overrides, create `.agent-code.json` at the repository root.

```json
{
  "trunk_branch": "main",
  "branch_prefix": "agent/",
  "commands": {
    "checks": ["npm run lint", "npm run typecheck"],
    "tests": ["npm test"]
  }
}
```

## Fields

- `trunk_branch`: optional trunk branch override.
- `branch_prefix`: optional branch namespace.
- `commands.checks`: explicit static/type/lint/build commands.
- `commands.tests`: explicit test commands.

Commands are repository-controlled configuration and run from the repository root.

Review behavior is intentionally not configured here. `implement` and `sdlc-do` do not self-review. After creating a PR, invoke `code-review` separately in another AI/session when independent review is wanted.

## Auto-detection

Without explicit commands, runtime looks for conventional JavaScript/TypeScript, Python, Go, and Rust project signals.

A project with no detectable test command reports `none-found`, not `pass`.
