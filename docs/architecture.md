# Architecture

Agent Code Starter separates judgment from deterministic mechanics.

## Plugin layer

`skills/` contains portable workflows. Skills decide **what should happen**: fast vs strict execution, when debugging is required, what evidence a review needs, and when work can be considered complete.

The skills intentionally avoid mandatory session-start injection. Installing the plugin makes the skills discoverable; ordinary coding conversations are not forced through a heavyweight framework.

## Runtime layer

`runtime/` contains deterministic operations used by skills:

- issue normalization and issue writing
- request/issue context preparation
- branch/worktree creation
- check/test execution
- diff summarization
- DOR/DoD validation
- final commit/merge/PR operations
- advisory risk routing

Runtime scripts execute with the target repository as the working directory. They must never infer the target repository from the plugin's installation path.

## Target repository layer

Project repositories own project truth:

- architecture
- domain model and invariants
- product requirements
- test and deployment conventions
- security constraints
- optional `.agent-code.json` overrides

The plugin must not spray or synchronize shared framework files into those repositories.

## Execution modes

### implement

Optimized for ordinary feature work and bug fixes. It minimizes planning overhead while still requiring branch isolation, relevant verification, and fresh evidence before completion.

### sdlc-do

Used when failure is expensive or the implementation is unclear. It adds a plan gate, worktree isolation, stronger testing expectations, mandatory review, and full verification.

Subagents and parallelism are optional execution tools, not a default workflow requirement.
