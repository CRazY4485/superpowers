---
description: Audit this project's decisions for contradictions, stale references and missing justification
---

Audit the decision record for the project in the current working directory,
using `superpowers:reconciling-decisions`.

1. Run the structural check first and report it verbatim:
   `bash "${CLAUDE_PLUGIN_ROOT}/hooks/decision-lint" .claude/context/decisions.md`
   (add `memory-bank/decisions/*.md` or `docs/decisions/*.md` if the project
   uses those.)
2. Then read the entries and look for what a linter cannot see:
   - two active decisions that contradict each other in substance even though
     their scope tags differ,
   - a decision whose stated reason no longer holds because a later decision
     changed the premise it rested on,
   - decisions the documents, plans, specs or tests still contradict - search
     for each decision's subject across `docs/`, `.claude/context/`, and the
     test suite,
   - entries whose Evidence names a source that does not exist or no longer
     says what is claimed. Check the ones that matter.
3. Report findings grouped as: **must fix** (unjustified, duplicated, or
   contradictory), **needs the owner's decision** (genuine collisions), and
   **stale references** (documents describing superseded behaviour).
4. For each collision, write the reconciliation message the skill describes -
   both decisions in plain language, why they cannot both hold, the options
   with consequences, and your recommendation. Do not resolve it yourself.
5. Change nothing without the owner's answer, except obvious clerical fixes
   (a supersession marked on one side only), which you may fix and report.

$ARGUMENTS
