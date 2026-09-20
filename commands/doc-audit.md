---
description: Audit this project's specs, plans and generated documents for sediment
---

Audit the documents this project has accumulated, using
`superpowers:reworking-earlier-stages` for anything that needs to move backwards.

1. Run both checks and report them verbatim:
   `bash "${CLAUDE_PLUGIN_ROOT}/hooks/doc-lint" .` - the metadata
   `bash "${CLAUDE_PLUGIN_ROOT}/hooks/doc-drift" .` - the metadata against what
   the repository actually did (a source that moved after its derivative, an
   active document the work has passed by, a delivery naming a commit nobody
   made, a resume pointer aimed at finished work, paths that have been renamed
   away)
2. Then look for what the linter cannot see:
   - documents whose text still describes behaviour that a later decision
     changed, even though their `decisions:` list looks clean,
   - plans marked `active` whose work is plainly finished - the branch is
     merged, the tasks are in the history,
   - specs nothing ever derived a plan from, and plans nothing ever delivered,
   - two documents describing the same area with different answers.
3. Report grouped as: **must fix** (missing or wrong metadata), **needs the
   owner's decision** (documents that appear to be dead but were never marked),
   and **stale content** (text contradicted by a decision in force).
4. Propose the status change for each one, with what it should point at. Do not
   mark anything `abandoned` or `superseded` on your own - that is a stage
   change, and it needs the owner and a decision entry. When a document's
   premise has died rather than merely aged, run `/superpowers:rework` on it
   instead of proposing a status in passing.
5. Say plainly how many documents there are and how many are still `active`. An
   owner who cannot read code should be able to tell from your answer whether
   this project's documentation is a map or a pile.

$ARGUMENTS
