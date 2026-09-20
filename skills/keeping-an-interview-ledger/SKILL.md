---
name: keeping-an-interview-ledger
description: Use when a requirements interview, brainstorm or Q&A runs past a handful of questions, or whenever something is postponed with "we'll decide later" - records every answer verbatim in .claude/context/interview.md so answer 3 still binds at question 20 and parked items come back
---

# Keeping An Interview Ledger

## Overview

**Core principle: an answer you did not write down is an answer you will
paraphrase, then lose.**

Two different failures, one cure:

| Failure | What it looks like | Why memory cannot fix it |
|---------|--------------------|--------------------------|
| Dilution | Answers 1-5 are still in the transcript at question 20, but the recent turns dominate and the early constraints quietly stop binding | Old turns lose weight; nothing re-states them |
| Parked items | "We'll decide that later" is said once and never returns | Nothing is tracking it, so nothing brings it back |

The ledger fixes both because its open and deferred items are re-injected on
every prompt - always in the newest position - while answered entries stay on
disk and out of the way.

## The Ledger

One active ledger per project: `.claude/context/interview.md`.

```markdown
# Interview: <topic>
Status: active
Started: YYYY-MM-DD

## Q01 [answered] Target database
**Asked:** Which database should the import pipeline write to?
**Answer:** "Postgres, we already run it for billing"
**Recorded:** YYYY-MM-DD HH:MM

## Q02 [deferred: the API contract is fixed] Retry limits
**Asked:** How many retries before giving up?

## Q03 [open] Auth model
**Asked:** Which identity provider issues the tokens?
```

The heading line is what gets carried forward, so it must read as the question,
not as a label. Statuses:

| Status | Meaning |
|--------|---------|
| `[open]` | Asked, or needs asking. Rides along on every prompt |
| `[answered]` | Has a verbatim answer. Stays in the file |
| `[deferred: <trigger>]` | Postponed, with the condition that reopens it. Rides along |
| `[superseded by Qnn]` | Replaced by a later answer. Never deleted |

## The Iron Law

```
RECORD THE ANSWER BEFORE YOU RESPOND TO IT
```

Not at the end of the interview. Not "once we have a few". The turn in which
the answer arrives is the only turn where you have it exactly.

## Rules

- **Verbatim first.** Quote your human partner's own words. Add your reading of
  them underneath if it helps - never instead of them. Constraints hide in
  phrasing, and paraphrase is where they die.
- **Number, never renumber.** `Q07` means the same thing tomorrow. You and your
  partner both refer to entries by number.
- **A deferral needs a trigger.** `[deferred: after the pricing call]` is a
  commitment. `[deferred]` alone is a leak. If nobody can say what reopens it,
  it is open, not deferred.
- **Supersede, never overwrite.** New answer, new entry, old one marked
  `[superseded by Qnn]`. The path matters as much as the destination.
- **Your own open questions count.** Something you need but have not asked yet
  goes in as `[open]` the moment you notice it.
- **No secrets.** Credentials, tokens and private URLs never go in - the file
  gets committed.

## Recap Every Five Answers

After roughly every five recorded answers, replay them: a numbered list of
one-line summaries, then "correct anything I got wrong". This costs a few lines
and catches drift while it is still one answer wide instead of twenty.

## Coverage Gate

**Before producing any spec, plan, design or final summary**, re-read the whole
ledger - not your memory of it - and account for every entry:

1. Reflected in the artifact, or
2. Explicitly listed in it as deferred, with the trigger, or
3. Obsolete, with the reason stated.

An open entry means the artifact is not ready. Say which entries are open and
ask; do not quietly decide them yourself, and do not let a long interview end
in an artifact that answers only the last five questions.

## Closing An Interview

When the work the interview fed is settled:

1. Move each decision worth keeping into `.claude/context/decisions.md`
   (decision, why, rejected alternatives).
2. Move every still-deferred item into the "Open questions" section of
   `.claude/context/state.md`, with its trigger.
3. Set `Status: closed` in the ledger and, if you want the history,
   move it to `.claude/context/interviews/YYYY-MM-DD-<topic>.md`.

A closed ledger stops riding along on prompts. Closing is a deliberate act -
never let it happen by neglect.

## Red Flags - STOP

| Thought | Reality |
|---------|---------|
| "I'll write all the answers up at the end" | At the end you have summaries of summaries. Record on arrival. |
| "I remember what they said" | You remember your paraphrase of it. |
| "That was a small aside, not an answer" | Asides are where constraints hide. |
| "We'll come back to it" | Only if it is written with a trigger. |
| "The spec covers the important ones" | Every entry gets accounted for, or the gate is not done. |
| "It's still in the conversation above" | Above is where attention goes to die - and `/clear` kills it outright. |
| "They will remind me if I miss something" | They asked you to keep track. That is the job. |
