---
name: escalating-instead-of-looping
description: Use when the same test keeps failing after repeated attempts, when you are about to try one more edit and re-run, or when a subagent hands back over a failing suite - spends the attempt budget deliberately and escalates with evidence instead of grinding
---

# Escalating Instead Of Looping

## Overview

**Core principle: repetition is not progress. After the third identical
failure, the cheapest next step is almost never another edit.**

This matters most where nobody is watching. Implementation usually happens in a
subagent: it fails, edits, fails, edits, and the owner - who cannot read the
code and is not in that transcript - sees nothing until an hour is gone. The
loop also creates the pressure that `superpowers:keeping-tests-honest` exists to
resist: after the fifth failure, deleting the test starts to look like
engineering.

## The Budget

| Attempts on the same failing command | What it means |
|---|---|
| 1-2 | Normal red-green. Carry on |
| 3 | **Stop editing.** Diagnose: read the failure in full, form one hypothesis, and test *that* |
| 6 | **Stop entirely.** Report; do not run it again without new information |

The hook counts consecutive failing runs and says so at each threshold. It
cannot stop you - only make the count visible while it still matters.

## At The Third Failure

Stop and answer four questions, out loud:

1. **What does the failure actually say?** Quote it. Not your summary of it -
   the assertion, the expected and actual values, the line.
2. **What changed between attempts?** If the failure text is byte-identical
   across three attempts, your edits are not reaching the thing that fails.
3. **What is the smallest fact that would decide this?** A print of the real
   value, one isolated test run, the type of what came back. Get that fact
   before editing again (`superpowers:systematic-debugging`).
4. **Could the test be wrong?** Not "inconvenient" - wrong. The next section is
   how to tell, honestly.

## Is The Test Wrong?

Tests are written by the same fallible process as the code, so yes, sometimes.
The dishonest version of this question deletes the test; the honest version
checks it.

| Signal | What it suggests |
|--------|-----------------|
| The expected value appears nowhere in the spec, requirement, or decision record | The expectation was invented, not derived |
| The test asserts on internals - call counts, private attributes, mock arguments | It tests the implementation, not the behaviour; it will fail on every safe refactor |
| It was written after the code and never observed failing | It may pass for reasons unrelated to the behaviour |
| It passes when you break the code on purpose | It proves nothing. This is the decisive check |
| The expected value was copied from what the code printed | The bug is now the specification |
| It depends on real time, real network, or ordering | It is flaky, not failing - a defect of its own |

**The decisive check:** make the implementation wrong on purpose and run the
test. If it still passes, the test is not testing what it claims. Take a
checkpoint first (`superpowers:recovering-work-with-git`), and restore
afterwards.

**If the test turns out to be wrong, you do not fix it silently.** A test
encodes an agreement. Changing it is a decision - present what it currently
demands, what you believe it should demand, and the evidence, then let your
human partner decide (`superpowers:reconciling-decisions`). If the spec behind
it was wrong, that is a stage change:
`superpowers:reworking-earlier-stages`.

## What An Escalation Contains

Not "I am stuck". Four things, in the owner's language where possible:

1. **What was attempted**, as distinct hypotheses, not a narrative: "assumed the
   provider returns minor units; then assumed the adapter rounds; then checked
   the raw response".
2. **The failure, verbatim.** One block, not paraphrased.
3. **What you now believe is wrong**, and which of the four it is: the code, the
   test, the spec the test encodes, or missing information.
4. **The decision you need**, with options and their consequences. An
   escalation that asks nothing specific just moves the stuckness.

## If You Are A Subagent

You cannot ask your human partner, and your dispatcher only sees your closing
message. So the handback carries the escalation: what failed, verbatim; what
you tried; what you believe; what decision is needed. **Never report success
over a failing suite** - the dispatcher is told when a subagent ends on an
unresolved streak, and a false green costs more than a clear "blocked".

## Red Flags - STOP

| Thought | Reality |
|---------|---------|
| "One more small change and it'll pass" | You have said that three times. The next attempt is the same attempt. |
| "I'll try a different approach" (fifth time) | Trying things is not diagnosing. Get one fact first. |
| "The test must be broken" | Maybe. Prove it by breaking the code and watching the test still pass. |
| "I'll skip it and come back" | Skipping is the move this whole system is built to prevent. |
| "Escalating looks like failure" | An hour of invisible grinding looks worse, and costs more. |
| "I'll report it as done and flag it later" | A false green ends the review that would have caught it. |
| "My dispatcher will figure it out" | Your dispatcher gets one message. Make it the right one. |
