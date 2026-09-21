# Architecture

Agent Code Starter separates scarce model judgment from cheap deterministic execution.

## Primitive map

| Primitive | ACS use |
|---|---|
| Command | Optional host-specific invocation ergonomics only |
| Skill | Bounded unit of model judgment |
| Agent | Fresh isolated reviewer context when the host supports it |
| Script | Deterministic execution |
| Workflow | Finite state machine composing bounded capabilities |
| Hook | Optional future guardrail; never required for correctness |
| Plugin | Installable Agent Code Starter product |
| Marketplace | Distribution only |

## Four skills

- `issues`: requirements shaping and issue design.
- `plan`: read-only technical design for one bounded change.
- `implement`: one bounded coding/remediation pass.
- `code-review`: one skeptical read-only review pass.

A skill starts with a recognizable goal, exercises bounded judgment, produces an artifact/result, and stops.

## One workflow

`sdlc-do` is conceptually a workflow, even though it is packaged as a skill so hosts can discover/invoke it.

Its `SKILL.md` is a facade over `skills/sdlc-do/scripts/sdlc.sh` and `sdlc.ps1`. Those controllers persist state under the repository's Git common directory and own legal transitions.

```text
PLAN_REQUIRED
  ↓ approval
IMPLEMENT_REQUIRED
  ↓
VERIFY_REQUIRED
  ↓
CREATE_PR_REQUIRED
  ↓
REVIEW_1_REQUIRED
  ├─ approve → MERGE_REQUIRED → DONE
  └─ blockers → REMEDIATE_REQUIRED
                    ↓
               REVERIFY_REQUIRED
                    ↓
               REVIEW_2_REQUIRED
                ├─ approve → MERGE_REQUIRED → DONE
                └─ blockers → BLOCKED
```

There is no transition from `REVIEW_2_REQUIRED` back to remediation.

## Runtime placement

Deterministic helpers live beside their owning skills:

- issue helpers under `skills/issues/scripts/`
- plan validation under `skills/plan/scripts/`
- Git/worktree/test/finalization helpers under `skills/implement/scripts/`
- review evidence/validation/posting under `skills/code-review/scripts/`
- lifecycle state under `skills/sdlc-do/scripts/`

The plugin ships both Bash and PowerShell implementations. No Python or Node runtime is required by ACS itself.

Target repositories are never expected to contain copied ACS framework directories.

## State and progress

The SDLC controller stores primitive fields as files under the Git common directory. It intentionally avoids JSON/schema/runtime dependencies.

`status` emits enough progress for a lightweight runner to continue without reconstructing lifecycle history from the conversation.

## Reviewer isolation

Independent review is valuable; generalized multi-agent orchestration is not required.

When the host supports isolated workers, `sdlc-do` should use a fresh reviewer for `REVIEW_1_REQUIRED` and `REVIEW_2_REQUIRED`. The deterministic state machine still controls the number of review passes and whether remediation is permitted.
