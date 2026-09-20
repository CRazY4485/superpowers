---
description: Walk the ripple when an earlier stage turns out wrong, and propose the marks
---

An earlier stage was found wrong. Drive the recorded backward move with
`superpowers:reworking-earlier-stages`. The argument names the artifact that is
wrong (a spec, a plan, or a decision id); if it is missing, ask which one.

1. **State the trigger and its evidence** in one or two lines: what was
   discovered, and how it is known. If the evidence is a measurement or an
   error, quote it. If it came from the owner, quote them with the date. Do not
   proceed on "it seems wrong".
2. **Run both checks and report them verbatim**:
   `bash "${CLAUDE_PLUGIN_ROOT}/hooks/doc-lint" .`
   `bash "${CLAUDE_PLUGIN_ROOT}/hooks/doc-drift" .`
3. **Build the ripple list**, in this order, and show it before changing
   anything:
   - decisions the dead premise rests on - each needs its own supersession;
   - documents whose `derived-from` names the artifact, and those whose
     `decisions:` include an affected id;
   - tests asserting the old behaviour, by file and test name;
   - commits that delivered work on the premise - `git log --oneline` over the
     paths involved.
4. **Put the choice to the owner** in outcome language: what is already built
   and still correct, what is built and now wrong, and the options for the
   wrong part (keep with a follow-up, revert, or rebuild). Recommend one, with
   the reason.
5. **After they answer**, apply the marks: statuses with what moved them
   (`invalidated-by`, `superseded-by`, `abandoned-by`), a decision entry
   recording the rework, and `state.md` updated with the stage re-entered and
   the next action.
6. Never mark a document or retire a test on your own. Clerical fixes - a
   supersession recorded on one side only, a pointer to a finished plan - you
   may fix, and say that you did.

$ARGUMENTS
