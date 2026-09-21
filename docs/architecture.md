# Architecture

Agent Code Starter separates agent judgment from deterministic mechanics.

## Skill layer

There are exactly four user-facing skills:

- `issues`
- `implement`
- `sdlc-do`
- `code-review`

`implement` and `sdlc-do` are explicit choices. There is no automatic risk router.

Both execution skills use one primary agent, forbid sub-agent orchestration, stop on failures instead of retrying autonomously, and allow at most one user-selected review invocation per execution.

`code-review` is one-shot and read-only. It cannot remediate findings or invoke another reviewer.

## Runtime layer

`runtime/` contains deterministic operations:

- issue normalization and writing
- request/issue context preparation
- branch/worktree creation
- check/test execution
- diff summarization
- DOR/DoD validation
- final commit/merge/PR operations

Runtime scripts execute with the target repository as the working directory. They must never infer the target repository from the plugin installation path.

## Target repository layer

Project repositories own project truth: architecture, domain invariants, product requirements, tests, deployment conventions, security constraints, and optional `.agent-code.json` overrides.

The plugin must not copy shared framework files into target repositories.
