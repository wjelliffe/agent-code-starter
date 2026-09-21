# Configuration

Agent Code Starter should need no project-local framework files in the common case.

When a repository needs explicit overrides, create `.agent-code.json` at the repository root.

```json
{
  "trunk_branch": "main",
  "branch_prefix": "agent/",
  "review_mode": "auto",
  "commands": {
    "checks": ["npm run lint", "npm run typecheck"],
    "tests": ["npm test"]
  }
}
```

## Fields

- `trunk_branch`: optional trunk branch override. If omitted, runtime detects `origin/HEAD` and falls back to `main`.
- `branch_prefix`: branch namespace for Agent Code Starter work. Default: `agent/`.
- `review_mode`: `auto`, `required`, or `optional`. `sdlc-do` always reviews regardless.
- `commands.checks`: explicit commands for static/type/lint/build checks. When present, these replace check auto-detection.
- `commands.tests`: explicit test commands. When present, these replace test auto-detection.

Commands are repository-controlled configuration and run from the repository root.

## Auto-detection

Without explicit commands, the runtime looks for conventional project signals:

- JavaScript/TypeScript: package scripts and the detected npm/pnpm/yarn/bun package manager
- Python: syntax compilation for checks; pytest when configured/available, otherwise unittest discovery when a tests directory exists
- Go: `go vet ./...` and `go test ./...`
- Rust: `cargo check --all-targets` and `cargo test --all-targets`

A project with no detectable test command reports `none-found`, not `pass`.
