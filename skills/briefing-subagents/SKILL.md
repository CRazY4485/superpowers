---
name: briefing-subagents
description: Use before dispatching any subagent or parallel agent - a subagent starts with none of this conversation, so the brief must carry the goal, the boundary, what to read, how to verify, and what to report back
---

# Briefing Subagents

## Overview

**Core principle: whatever the brief leaves out, the subagent invents.**

It does not have the conversation where the boundary was set, the plan step it
belongs to, the decisions that constrain it, or the owner to ask. It has the
text you send and the repository. A thin brief does not produce less work - it
produces confident work in the wrong direction, which costs more to unpick than
to have written properly.

## The Five Parts

A brief that is missing one of these is incomplete:

| Part | What it must say | Failure when missing |
|------|------------------|----------------------|
| **Goal** | The outcome, in terms of behaviour, and who it is for | The agent optimises for the literal words and misses the point |
| **Boundary** | Which files or modules are in play, and explicitly what not to touch | Unbounded diffs, refactors nobody asked for |
| **Inputs to read first** | The plan step, the spec section, the binding decisions, `.claude/context/project.md` for the stack and commands | Reinvented conventions, contradicted decisions |
| **Acceptance** | The command that proves it worked and what its output must show | "Done" reported from having finished, not from evidence |
| **Report format** | The diff, the verbatim output of the verification, and anything found out of scope | Results you cannot check, findings lost |

## Rules

- **Name files, not topics.** "Read the import plan" is a search task; the path
  is one line and removes it.
- **State the boundary as a prohibition**, not only as a target: "only
  `src/import/rows.py` and its test; do not touch the CLI or the schedulers".
- **Carry the binding constraints in the brief itself** - the decision ids, the
  standard (`superpowers:following-the-architectural-constitution`), the
  test-honesty rule. A subagent cannot be assumed to load what this session
  loaded.
- **Hand over the verification command, not a description of it.** `pytest -q`,
  `npm test`, the exact invocation from `.claude/context/project.md`.
- **Say what to do when the task turns out to be wrong.** "If the change seems
  to require touching X, stop and report instead" prevents the helpful
  overreach that is otherwise inevitable.
- **Ask for evidence back**, so the report can be checked rather than believed:
  the diff, and the test output word for word.
- **One task per agent.** A brief with two goals produces a report you cannot
  attribute.

## Parallel Dispatch

- Give each agent a **disjoint** boundary. Two agents editing one file is a
  merge conflict you created deliberately.
- Repeat the shared context in every brief. There is no shared memory between
  them; the cost of repetition is tokens, and the cost of omission is rework.
- Say in each brief that other agents are working in parallel and which areas
  are theirs, so an agent that wants to reach outside its boundary stops
  instead.

## After The Report

Verify before you believe: read the diff yourself, and re-run the verification
command rather than trusting the quoted output
(`superpowers:verification-before-completion`). An agent reporting success is
evidence that it finished, not that it worked.

## Red Flags - STOP

| Thought | Reality |
|---------|---------|
| "The agent can figure out the context" | It will invent it, plausibly, and you will not see where. |
| "I'll keep the brief short to save tokens" | The rework costs more than the brief by an order of magnitude. |
| "It knows the conventions, they're in the repo" | Only if you say which file. Otherwise it copies whatever it opens first. |
| "I'll check the result and fix it after" | Then you are doing the work twice, the second time from a worse starting point. |
| "Both agents need to touch that file, it'll be fine" | It will not. Split the boundary or run them in sequence. |
| "It said it passed" | Re-run it. That is a thirty-second check against an unbounded cost. |
