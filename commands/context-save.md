---
description: Write the current session's state and decisions into .claude/context/
---

Bring this project's context files up to date right now, using the
`superpowers:maintaining-project-context` skill.

1. Rewrite `.claude/context/state.md` so it describes where the work actually
   stands: what is in flight, what just finished, the exact next action, open
   questions, and the active branch or plan.
2. Append any decision made since the last entry to `.claude/context/decisions.md`
   - decision, why, what was rejected, implications. Do not edit past entries.
3. Correct `.claude/context/project.md` if anything in it turned out to be wrong,
   or if a new gotcha, command, or convention is worth recording.
4. If the files do not exist yet, run `/superpowers:context-init` instead.
5. Report in one or two lines what you changed. Do not claim more than you wrote.

$ARGUMENTS
