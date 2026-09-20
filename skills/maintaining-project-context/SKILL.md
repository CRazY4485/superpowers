---
name: maintaining-project-context
description: Use when starting work in a project, whenever a decision or milestone lands, and before a session ends or compacts - keeps .claude/context/ current so the next session resumes without rediscovering the project
---

# Maintaining Project Context

## Overview

**Core principle: the next session starts cold. Write for it, not for yourself.**

Every session loses everything that was not written down. Compaction loses it
mid-session. Context files are the only thing that survives both.

Context lives in `<project>/.claude/context/`:

| File | Holds | Write pattern |
|------|-------|---------------|
| `project.md` | Stack, build/test/run commands, conventions, environment quirks | Rare. Correct it when it turns out to be wrong |
| `state.md` | Where the work stands, what is next, open questions, blockers | Overwrite. Keep it a snapshot, not a log |
| `decisions.md` | Decisions, why, what was rejected | Append only. Never rewrite past entries |

`project.md` and `state.md` are injected into every session automatically.
`decisions.md` is summarised at session start - read the file when a decision's
reasoning matters.

## The Iron Law

```
IF IT WOULD COST THE NEXT SESSION TIME TO REDISCOVER IT, WRITE IT DOWN NOW
```

Not at the end of the session. Now, while it is true.

## When To Write

| Trigger | File | What goes in |
|---------|------|--------------|
| A decision lands (approach, library, schema, trade-off) | `decisions.md` | The decision, why, what you rejected and why |
| A task or plan step finishes | `state.md` | New position, next step |
| Your human partner states a constraint, preference, or environment fact | `project.md` | The fact, phrased as a rule |
| You lost time to a gotcha (flaky command, required env var, platform quirk) | `project.md` | The gotcha and the workaround |
| Work stops, or context is about to compact | `state.md` | Exactly where to pick up |
| Plan or spec written | `state.md` | Path to the plan, current step |
| No context files exist yet | all three | Offer to create them from the templates in `templates/` |

## Writing Rules

- **state.md is a snapshot.** Overwrite it. If it grows past ~40 lines, settled
  material belongs in `decisions.md` or `project.md`, or belongs deleted.
- **decisions.md is append-only.** One entry per decision:
  `## YYYY-MM-DD - <the decision>` followed by `**Why:**`, `**Rejected:**`,
  `**Implications:**`. Superseding a decision means a new entry that names the
  old one, never an edit to history.
- **Facts, not narration.** "Auth: JWT in an HttpOnly cookie, 15 min expiry"
  beats "we discussed auth and agreed on an approach".
- **Never write secrets.** No tokens, keys, passwords, or private URLs. These
  files get committed.
- **Do not restate what the code or git log already says clearly.** Context
  files carry what is *not* in the repo: intent, constraints, rejected paths.
- **Reality wins.** When a file contradicts what you find, fix the file first,
  then carry on. Say what you corrected.

## Reading Rules

- Injected context is what an earlier session believed. Before acting on a
  claim that matters, confirm it against the repo (`git log`, tests, the file
  itself).
- A `state.md` older than the last commits is suspect. Reconcile it before
  trusting its "next step".

## Red Flags - STOP

| Thought | Reality |
|---------|---------|
| "I'll update the context at the end" | Sessions end without warning. Write it when it happens. |
| "My human partner already knows this" | The next session does not, and neither will you. |
| "It's in the conversation" | The conversation dies at compaction. |
| "The code documents itself" | Code shows what, not why or what was rejected. |
| "Nothing important happened" | A finished step and a discarded approach are both important. |
| "I'll write it all up properly later" | Later is a session that no longer has the facts. |
| "The file is out of date, I'll ignore it" | Fix it. A wrong file is worse than no file. |

## Setting A Project Up

Create `.claude/context/` and fill the three files from `templates/` - with
what the project actually is, discovered by looking, never with placeholders.
Commit them: context that is not committed does not survive a new clone or a
second machine.

If the project should not carry these files in version control, add
`.claude/context/` to `.gitignore` and say so in `project.md`.
