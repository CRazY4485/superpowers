---
description: Install the architectural constitution into this project and fill in its project-specific facts
---

Set this project up with the binding coding standard, using
`superpowers:following-the-architectural-constitution`.

1. If `docs/ARCHITECTURAL_CONSTITUTION.md` already exists, do not overwrite it.
   Compare it against the skill's copy, report the differences, and ask which
   should win - a divergence between the two is exactly the kind of collision
   `superpowers:reconciling-decisions` exists for.
2. Otherwise copy the skill's `ARCHITECTURAL_CONSTITUTION.md` to
   `docs/ARCHITECTURAL_CONSTITUTION.md`.
3. The document deliberately holds no project facts. Fill those into
   `.claude/context/project.md` by looking at the repository, and ask the owner
   for what only they know:
   - stack, language versions, supported operating systems
   - the build, test, lint and audit commands, per OS where they differ
   - the decimal/money representation, timezone handling, and any numeric
     budgets (startup time, memory, latency)
   - which interfaces are public, and what counts as a failure state
4. Record the adoption as a decision entry in `.claude/context/decisions.md`
   with today's date, the owner as evidence, and scope `process/standards`.
5. Tell the owner, in plain language, what changes for them: deviations now need
   their approval and a recorded reason.

$ARGUMENTS
