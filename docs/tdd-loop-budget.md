# The TDD loop budget

Fork-local mechanism for two failures that feed each other: an agent that
retries the same failing test forever, and a test that was wrong to begin with.

## Why a budget

Implementation usually happens in a subagent. It runs the suite, fails, edits,
runs again - and the owner sees none of it, because they are not in that
transcript. An hour disappears into a loop that produced nothing, and the
pressure to make the test go away grows with every attempt, which is exactly
what `keeping-tests-honest` and the commit gate exist to resist.

Counting is the cheap part. `hooks/tdd-loop` runs on `PostToolUse` and
`PostToolUseFailure` for `Bash`/`PowerShell`, recognises a test-suite
invocation (pytest, unittest, npm/yarn/pnpm test, jest, vitest, mocha, go test,
cargo test, dotnet test, mvn, gradle, rspec, phpunit, ctest, tox, bats, a
`tests/*.sh` runner), and keeps a per-command streak of consecutive failures.

| Streak | What is injected |
|--------|------------------|
| 1-2 | nothing - this is ordinary red-green |
| `SUPERPOWERS_TDD_SOFT_LIMIT` (3) | Stop editing and diagnose: read the failure in full, form one hypothesis, and consider that the test itself may be wrong |
| `SUPERPOWERS_TDD_HARD_LIMIT` (6) | Stop entirely: report with the failure verbatim, the hypotheses tried, and which of code / test / spec / missing information is wrong |

A passing run clears the streak. The hook cannot stop an agent - it makes the
count visible while it still matters.

## Closing the visibility gap

`hooks/subagent-streak` runs on `SubagentStop`. If a subagent hands back while
a streak is unresolved, the **dispatcher** is told: how many consecutive
failures, on which command, and not to accept the report at face value - run
the suite yourself. The report fires once and clears, so the next subagent
starts clean.

This is the half that matters for an owner who does not read code: a subagent
can end with "implemented, tests green" over a streak of failures, and without
this nothing contradicts it.

## Tests that cannot fail

A wrongly written test is not a hypothetical. The commit gate flags the two
shapes that are visible in a diff:

| Finding | Level |
|---------|-------|
| A new test carrying no assertion at all | WARN - it passes whatever the code does |
| An assertion that is always true (`assert True`, `expect(true).toBe(true)`, `assertTrue(true)`) | WARN - it proves nothing |

The rest are not greppable - an expectation nobody agreed, an assertion on
internals, a value copied from the current output, a test that was never
observed failing. `skills/escalating-instead-of-looping` carries the honest
check for those: **break the implementation on purpose and run the test.** If
it still passes, the test is not testing what it claims. Take a checkpoint
first; restore afterwards.

And if the test turns out to be wrong, it is not fixed quietly: a test encodes
an agreement, so changing it is a decision for the owner
(`reconciling-decisions`), and if the spec behind it was wrong, a stage change
(`reworking-earlier-stages`).

## Knobs

| Variable | Default | Effect |
|----------|---------|--------|
| `SUPERPOWERS_TDD_SOFT_LIMIT` | 3 | Failures before the diagnose message |
| `SUPERPOWERS_TDD_HARD_LIMIT` | 6 | Failures before the stop-and-report message |
| `SUPERPOWERS_TDD_STATE_DIR` | temp dir | Where streak markers live |

## Tests

```bash
bash tests/hooks/test-tdd-loop.sh
bash tests/hooks/test-test-integrity.sh
```

13 assertions for the budget and the subagent report - non-test commands
ignored, silence below the limit, both thresholds, a green run resetting the
streak, separate streaks per command, and the handback report firing once. 10
for the integrity gate, including the two weak-test shapes.

The `loop-budget` eval measures the judgement: told the same assertion has
failed five times, the agent must stop the loop, read the evidence already in
the message, raise the possibility that the test or its spec is wrong with an
honest way to check, and escalate with substance - not propose a sixth edit.
