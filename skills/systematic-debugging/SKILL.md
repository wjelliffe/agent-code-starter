---
name: systematic-debugging
description: Use when a bug, test failure, flaky behavior, unexpected state, or production symptom appears and the root cause is not already proven.
---

# Systematic Debugging

Do not patch symptoms before proving the cause.

## 1. Reproduce

Capture the smallest reliable reproduction, the expected behavior, the actual behavior, and the exact failing evidence. If the problem cannot be reproduced, gather observability before changing logic.

## 2. Trace

Follow the data/state backward from the failure:

- where did the bad value/state first appear?
- which boundary should have prevented it?
- what invariant was violated?
- is the symptom caused by stale data, concurrency, configuration, environment, or code?

Read the owning code path, not only the line that throws.

## 3. Hypothesize

State one falsifiable root-cause hypothesis and the observation that would disprove it. Run the cheapest discriminating check.

Do not stack speculative changes. If two fix attempts fail for the same assumed cause, stop and re-open the diagnosis.

## 4. Fix and prove

Make the smallest fix at the layer that owns the invariant. Add a regression test when the failure is behaviorally testable.

Verify:

- the original reproduction no longer fails
- the regression test fails without the fix when practical
- relevant surrounding tests/checks still pass
- no new unsafe state is introduced

Hand off to `verify` before declaring the bug fixed.
