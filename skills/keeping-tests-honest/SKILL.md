---
name: keeping-tests-honest
description: Use when a test fails and the change under work is what made it fail, when tempted to skip, delete, loosen or focus a test, or when asked to "just make it pass" - keeps the suite a statement about behaviour rather than a formality
---

# Keeping Tests Honest

## Overview

**Core principle: a failing test is evidence about the change. It is not an
obstacle in front of the change.**

The suite exists so that someone who cannot read the code - your human partner,
the owner of this project - can still know whether it works. Every weakening
transfers risk from you to them, silently, while the output still says green.
That is why this is not a style question.

## The Iron Law

```
THE CODE MOVES TO SATISFY THE TEST. THE TEST DOES NOT MOVE TO SATISFY THE CODE.
```

The only exception is a test that is **wrong about the desired behaviour** - and
that is a decision your human partner makes, with the reason recorded, never one
you make alone in the middle of a task.

## Forbidden Without An Explicit, Recorded Decision

| Move | What it really does |
|------|---------------------|
| `@skip`, `@ignore`, `xfail`, `it.skip` | Turns a failure into silence |
| `.only`, `fit`, `fdescribe` | Hides every other test in the file |
| Deleting the failing test | Removes the evidence rather than the defect |
| Removing an assertion | Narrows what the test proves, invisibly |
| Loosening a comparison (exact → approximate, `==` → `>=`, widening a tolerance) | Makes the test pass for values it was written to reject |
| Catching the exception the test asserts on | Converts a failure into a pass |
| Asserting on a value copied from the current (broken) output | Freezes the bug as the specification |
| `--no-verify`, disabling a linter or type rule to get past a gate | Removes the check instead of the cause |

The commit gate blocks the mechanical ones. It is a net, not a substitute for
the judgement: the gate cannot see a tolerance widened from `1e-9` to `1.0`.

## When A Test Fails

1. **Read the failure.** The message and the diff between expected and actual
   are the two facts you have. Quote them.
2. **Decide which is wrong: the code or the expectation.** Say which, out loud,
   before you touch either.
3. **If the code is wrong:** fix the code. The test stays exactly as it is.
4. **If the expectation is wrong:** stop and put the case to your human partner
   in plain language - what the test currently demands, what you believe the
   behaviour should be, and the evidence for that belief (a requirement, a spec
   section, a decision record, an official document). Change the test only
   after they agree, and record the decision.
5. **If you cannot tell:** you are missing information, not permission. Say what
   you would need to decide.

Never reach step 3 or 4 by guessing. "This assertion is probably too strict" is
an assumption, and an assumption is not a reason.

## Retiring A Test Legitimately

A behaviour really can be retired. When it is:

- The removal is its own change, not a passenger inside a feature commit.
- The commit message names the decision that retired the behaviour.
- The line carries `pragma: test-change <reason>` so the record shows a decision
  rather than a quiet deletion.

## Red Flags - STOP

| Thought | Reality |
|---------|---------|
| "This test is flaky" | Then it is a defect of its own. Diagnose it; do not skip it as a side effect of another task. |
| "The test is too strict" | Compared to what? Name the requirement that says so. |
| "I'll skip it for now and come back" | Nobody comes back. Green suites are not revisited. |
| "It's testing implementation detail anyway" | Maybe. Say that to your human partner and let them decide, in its own change. |
| "Just make it pass" (asked directly) | Answer the request: make the code pass it. If they mean "change the test", have them say so explicitly. |
| "I'll assert on what it returns now" | That writes the current bug into the specification. |
| "The old expected value must be stale" | Find out. `git log -p` on the test says when and why it was written. |
| "One assertion less won't matter" | It is the assertion that was about to catch something. |
