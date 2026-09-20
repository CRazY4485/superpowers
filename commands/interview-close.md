---
description: Close the interview ledger and fold its results into the project context
---

Close out `.claude/context/interview.md`, using the
`superpowers:keeping-an-interview-ledger` skill's closing procedure.

1. Run the coverage gate first: every entry reflected, explicitly deferred, or
   obsolete with a reason. Report anything still open and stop if your human
   partner has not settled it.
2. Append each decision worth keeping to `.claude/context/decisions.md` -
   decision, why, rejected alternatives.
3. Move every still-deferred item, with its trigger, into the "Open questions"
   section of `.claude/context/state.md`.
4. Set `Status: closed` in the ledger, and move it to
   `.claude/context/interviews/YYYY-MM-DD-<topic>.md` if the history is worth
   keeping.
5. Report what moved where, in two or three lines.

$ARGUMENTS
