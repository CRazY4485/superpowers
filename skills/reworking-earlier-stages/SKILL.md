---
name: reworking-earlier-stages
description: Use the moment you discover that an earlier stage was wrong - a spec that cannot be built, a plan whose premise changed, a decision that turns out false - so going back leaves a record instead of quietly rewriting what was agreed
---

# Reworking Earlier Stages

## Overview

**Core principle: going back is a state change, not an embarrassment. What
makes it damage is doing it silently.**

Work moves forward through stages - questions, decisions, spec, plan, tasks -
and sometimes stage four proves stage two wrong. That is normal. What corrupts
a project is the quiet version: the spec gets edited in place, the plan derived
from it keeps its old text, tasks already delivered still rest on the dead
premise, and nobody can say afterwards which version anything was built
against.

## The Iron Law

```
NO BACKWARD MOVE WITHOUT A RECORDED REASON AND A RIPPLE LIST
```

## The Five Things A Backward Move Produces

1. **The trigger, with evidence.** What was discovered, and how you know -
   a measurement, an error, an owner correction, a document that contradicts
   it. "It felt wrong" is not a trigger; see
   `superpowers:reconciling-decisions` on what counts as evidence.
2. **Status changes on the artifacts.** The invalidated document is marked -
   `superseded` when a replacement exists, `invalidated` when its premise died,
   `abandoned` when the work stops - and every status names what moved it.
3. **The fate of delivered work.** List what was already built on the dead
   premise, by commit. Then put the choice to the owner: keep it (still
   correct), revert it (wrong), or leave it with a follow-up. That is their
   call, with consequences stated, not yours.
4. **A decision entry.** The rework itself goes in `decisions.md` with the
   trigger as its evidence. Without it, six weeks later nobody can say why
   there is a version two.
5. **A resume point.** `state.md` says which stage the work re-entered and what
   the next action is. A backward move that leaves "Next" pointing at the dead
   plan sends the following session straight back into the wall.

## Marking The Artifacts

| Situation | Status | Points at |
|-----------|--------|-----------|
| A new document replaces this one | `superseded` | `superseded-by: <path>` |
| Its premise died; no replacement yet | `invalidated` | `invalidated-by: D####` |
| The work stops entirely | `abandoned` | `abandoned-by: D####` |
| Still the current truth | `active` | - |

**Living documents are edited; dated artifacts are not.** A project profile or
an architecture overview describes now, so wrong content is removed and
replaced. A spec or plan named for the day it was written is a record of what
was agreed then - it gets a status, never a retroactive edit. Rewriting a dated
artifact to match today is how a project loses the ability to explain itself.

## Propagating

Follow the links, in this order, and report what you find before changing
anything:

1. **Decisions** the dead premise rests on - are any of them now wrong too?
   Each one gets its own supersession.
2. **Documents** whose `derived-from` names the invalidated artifact, and any
   whose `decisions:` list includes a decision that just changed.
3. **Tests**, which encode the old behaviour in executable form. A test
   asserting a retired rule is not a failing test to fix - it is part of the
   ripple, and retiring it needs the same explicit agreement
   (`superpowers:keeping-tests-honest`).
4. **Code** built on the premise, by commit.

`bash hooks/doc-lint <project>` finds the document half mechanically: it flags
every active document whose decisions are no longer in force.

## Telling The Owner

They do not read code and may not remember the earlier stage. One short
message, in their terms:

> The plan we agreed on Tuesday assumed the provider returns totals in minor
> units. It does not - it returns decimal strings, which I hit while writing
> task 3. Two of the five tasks are already built and are still correct; task 3
> and the two after it are not.
>
> I have marked the plan invalidated and recorded why (D0023). What I need from
> you: do we convert at the boundary and keep the internal rule, or change the
> internal rule? The first is smaller and keeps decision D0006 intact.

## Red Flags - STOP

| Thought | Reality |
|---------|---------|
| "I'll just fix the spec quietly, nobody read it yet" | The plan derived from it did. Fix it as a stage change. |
| "It's easier to start a new plan and forget the old one" | An `active` plan nobody abandoned is a landmine for the next session. Mark it. |
| "The delivered tasks are probably fine" | Probably is not evidence. List them and check, or say plainly that you did not. |
| "I'll tell them once I know the full fix" | They can only choose while there is still a choice. Tell them at the discovery. |
| "This is my mistake, I should absorb it" | Absorbing it means hiding a premise change from the person paying for the outcome. |
| "The test is failing because the spec changed, so I'll delete it" | That is a ripple item, and it needs the same agreement as everything else. |
