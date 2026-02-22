# SDLC Do (Orchestrator)

Execute the end-to-end issue workflow in strict Two-Gate Mode.

## Usage

- `/sdlc-do #62`
- `/sdlc-do 62`

## Required Input

- Issue number is required. If missing, ask once and stop.

## Workflow Sequence

1. `/start #<num>`
2. `/pull #<num>`
3. `/docs #<num>`
4. `/implement #<num>`
5. `/commit #<num>`

## Two-Gate Mode (Required)

Only two approvals are allowed in this flow:

1. **Gate 1 — Plan Approval**
2. **Gate 2 — Final Code Approval (before commit/push)**

Do not ask for intermediate approvals between those gates unless blocked by missing input or a hard error.

## Orchestration Behavior

- Pass the same issue number to all commands that accept issue input.
- Proceed autonomously through each step between gates.
- Only interrupt user when:
  - Gate 1 or Gate 2 approval is required
  - required input is missing
  - a blocker/error needs a decision

## Step-by-step Expectations

### Step 1: Branch setup
- Ensure clean tree
- Sync main
- Create issue-based branch

### Step 2: Pull issue locally
- Fetch GitHub issue
- Create/update `docs/issues/ISSUE-<num>.md`

### Step 3: Docs
- Draft docs/spec changes needed for issue execution

### Step 4: Implementation
- Draft implementation plan and proposed file changes
- **Stop at Gate 1** for plan approval
- After Gate 1 approval, apply docs/code changes and stay scoped to issue AC
- Present final diff and summary
- **Stop at Gate 2** for final approval

### Step 5: Commit
- Remove `docs/issues/ISSUE-<num>.md` if present
- Commit with `Fixes #<num>` only after Gate 2 approval

## Gate Prompts

Use exact, concise prompts:

- Gate 1:
  - `Plan ready. Reply: \"Approved plan. implement now.\"`
- Gate 2:
  - `Final diff ready. Reply: \"Approved final. commit and push.\" or \"Approved final. commit only.\"`

## Revision Loops

- If user requests plan changes at Gate 1:
  - revise plan
  - return to Gate 1
- If user requests code changes at Gate 2:
  - revise implementation
  - return to Gate 2

## Output

After each step, provide concise progress update:
- status
- files touched
- blockers (if any)

Final summary:
- branch
- commit hash
- AC coverage status
- suggested next command: `/ship`

## Rules

- Respect repo approval-gate and safety instructions.
- Do not run tests/install unless explicitly requested.
- Do not force push unless explicitly requested.
- In `/sdlc-do`, enforce Two-Gate Mode as the controlling workflow.
