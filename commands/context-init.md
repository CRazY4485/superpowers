---
description: Set up .claude/context/ for this project so future sessions start warm
---

Set up durable project context for the project in the current working directory,
using the `superpowers:maintaining-project-context` skill.

1. Invoke the skill and follow it.
2. If `.claude/context/` already exists, do not overwrite it - report what is
   there, reconcile it against the repo, and fix whatever is stale instead.
3. Otherwise create `.claude/context/` with `project.md`, `state.md` and
   `decisions.md` from the skill's `templates/`.
4. Fill them from what the project actually is: read the build/test config, the
   README, the recent `git log`, and the directory layout. Never leave template
   placeholders behind, and never invent a command you have not seen.
5. Ask your human partner for anything only they can answer - the current goal,
   constraints, decisions already made outside this repo - and put their answers
   in the right file.
6. Show them the three files and ask whether to commit them.

$ARGUMENTS
