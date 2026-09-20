---
name: reconciling-decisions
description: Use before recording any decision, when a new instruction contradicts an earlier one, when a document still describes something that has since changed, or whenever a reason would have to be assumed - finds the collision, puts it to the owner in plain language, and records the outcome
---

# Reconciling Decisions

## Overview

**Core principle: a decision that cannot be traced to a reason and a source is
not a decision. It is a guess that will read as settled six weeks from now.**

The person this framework serves may not read code, may not have followed the
documentation, and may not remember what was agreed in week two. They cannot
catch a contradiction by noticing it in a diff. So the contradiction has to be
found, stated, and resolved deliberately - every time, by you.

## The Two Iron Laws

```
1. NO DECISION WITHOUT A REASON AND A SOURCE
2. NO NEW DECISION UNTIL YOU HAVE LOOKED FOR THE ONE IT CONTRADICTS
```

## Law 1: Evidence, Not Assumption

Every decision record carries **Why** (the reason) and **Evidence** (where that
reason comes from).

| Counts as evidence | Does not count |
|--------------------|----------------|
| The owner's own words, quoted, with the date | "The owner probably wants…" |
| A measurement, benchmark, or test output you ran | "It should be fast enough" |
| A section of a spec, plan, or requirement document | "It's in the docs somewhere" |
| An official documentation page, with the URL | "I remember the API works like…" |
| A fact in the code, with `file:line` | "The codebase seems to…" |
| An earlier decision, by id | "We decided something like this before" |

If none of these exists, **you do not have a decision - you have a question**.
Ask it. An invented reason costs far more than a question, because it is
indistinguishable from a real one once written down.

Words that mean you are about to violate this law: *probably, presumably, I
assume, I think, it seems, should be fine, industry standard, best practice*
(unnamed), *obviously*. The commit gate blocks these in a decision record; the
point is not to route around the gate but to notice what they signal.

## Law 2: Search Before Recording

Before writing a decision, look for what it touches:

1. **The decision log** - `.claude/context/decisions.md`: same scope tag, same
   subject words, same components.
2. **The documents** - specs, plans, the project profile, the interview ledger:
   anything that states the behaviour you are about to change.
3. **The code and tests** - what currently implements the old decision. A test
   asserting the old behaviour *is* the old decision, in executable form.

Then classify what you found:

| What you found | What it is |
|----------------|-----------|
| An entry deciding the opposite on the same scope | Direct contradiction |
| Two entries that partly overlap | Scope collision - narrow both, or supersede |
| A document describing the old behaviour | Stale documentation - part of this change |
| A decision whose reason assumed what you are about to change | Dependency breakage - it may need revisiting too |
| Nothing | Record it and move on |

## The Reconciliation

When you find a collision, **do not resolve it alone and do not quietly pick
the newer one.** Put it to the owner, in their language:

> Earlier we decided **X** (D0009, 8 April) because the provider rate-limits
> bursts - that came from their documentation. What you just asked for implies
> **Y**, because you want to see every failure yourself rather than have it
> retried quietly.
>
> These cannot both hold: with retries on, some failures never reach you.
>
> - **Keep X:** fewer visible failures, but some errors are absorbed silently.
> - **Switch to Y:** you see everything, and some runs fail that would have
>   recovered on their own.
> - **Both, narrowed:** retry only timeouts, surface everything else.
>
> Which do you want? I recommend the third, because the failures you said you
> care about are not the ones that recover.

Rules for that message: name the outcome, not the mechanism; give the date and
the original reason for the old decision; say plainly that both cannot hold;
offer real options with their consequences; and give a recommendation with its
reason. Never present a choice you would not be willing to implement.

## Recording The Outcome

```markdown
## D0011 | 2026-04-10 | active | scope: delivery/retries
**Decision:** Retry only timeouts, three attempts with backoff; every other failure surfaces immediately.
**Why:** The owner wants every non-transient failure visible; timeouts recover on their own and are not what they are watching for.
**Evidence:** owner message, 2026-04-10: "I want to see every failure"; provider docs on rate limits, checked 2026-04-08
**Supersedes:** D0009
```

Then, in the same change:

1. Mark the superseded entry `superseded` - the lint blocks a supersession
   recorded on one side only.
2. **List the ripple.** Find everything that cited the old decision: documents,
   plans, specs, tests, comments. Say what must change in each, and change them
   in this change or say explicitly why not. A decision that leaves its
   documents describing the old behaviour has not been made, only announced.
3. Tell the owner what moved, in one or two lines.

## Red Flags - STOP

| Thought | Reality |
|---------|---------|
| "The new instruction obviously replaces the old one" | Obvious to you. The owner may not remember the old one at all - show them both. |
| "I'll write the reason now and confirm later" | Later it is a record, indistinguishable from a real reason. |
| "It's a small decision, it doesn't need an entry" | Small decisions are the ones nobody can reconstruct afterwards. |
| "The old decision is clearly outdated" | Then the evidence that made it outdated is what goes in the new entry. |
| "I'll just update the document to match" | Documents follow decisions. Silently editing one hides that a decision changed. |
| "Both can coexist" | Maybe. Say exactly which cases go to which, and record that as the decision. |
| "I don't want to bother them with this" | An unasked question becomes an assumption, and assumptions are what this skill exists to prevent. |
