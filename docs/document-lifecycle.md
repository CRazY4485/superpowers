# Document lifecycle

Fork-local mechanism for the sediment a framework like this produces in the
projects it works on: specs, plans and ledgers that accumulate with no way to
tell what is still true.

## The shape of the problem

The framework is a document generator. Left alone, a project ends up with
fifteen files under `docs/superpowers/plans/` and no way - for the owner or for
the next session - to tell the delivered from the abandoned from the current.
The most expensive case is not clutter but **the quiet backward move**: a spec
is edited in place when it turns out wrong, the plan derived from it keeps its
old text, and work already delivered still rests on the dead premise.

## Two kinds of document

| Kind | Examples | When it is wrong |
|------|----------|------------------|
| **Living** | project profile, architecture overview, current design | Edit it. Remove what no longer holds, write what does |
| **Dated artifact** | `2026-09-19-import-design.md`, a plan | Never retro-edit. It records what was agreed that day; give it a status instead |

Rewriting a dated artifact to match today is how a project loses the ability to
explain itself.

## Front matter

Every spec and plan is born with it, because the links cannot be reconstructed
afterwards:

```yaml
---
status: active
created: 2026-09-20
derived-from: docs/superpowers/specs/2026-09-19-import-design.md
decisions: D0006, D0011
---
```

| Status | Meaning | Must also carry |
|--------|---------|-----------------|
| `draft` | Being written | - |
| `active` | The current truth for its scope | - |
| `delivered` | The work it describes is in the history | `delivered-by:` commit or PR |
| `superseded` | A newer document replaced it | `superseded-by:` path |
| `invalidated` | Its premise died; no replacement yet | `invalidated-by:` D#### |
| `abandoned` | The work stopped | `abandoned-by:` D#### |

Every terminal and backward status points at something - a commit, a document,
or a decision. That is what keeps a stage change from happening silently.

## Decision numbers

Decision ids are spent, never recycled. `hooks/decision-lint` requires each new
entry's id to be greater than every id before it, and the commit gate refuses a
commit that removes an id already in history: a withdrawn decision keeps its
number and changes its status. Reusing a number would make every earlier
reference ambiguous, in documents nobody re-reads.

## Adoption boundary

The convention binds from the day a project adopts it, not retroactively.
`doc-convention-since: YYYY-MM-DD` in `.claude/context/project.md` (or
`SUPERPOWERS_DOC_SINCE`) sets that day:

- Documents dated before it are left alone.
- Documents dated on or after it must carry the front matter.
- With no adoption date set, pre-existing documents are not reported one by
  one - they collapse into a single line saying how many there are and how to
  adopt.

This was not theory. Running the linter on this repository produced 36 errors,
all of them upstream's own plans written long before the rule existed. A tool
that buries today's findings under a project's history does not get used.

## What the linter checks

`hooks/doc-lint <project-dir>`:

| Finding | Level |
|---------|-------|
| Framework document with no `status` | ERROR |
| `status` outside the vocabulary | ERROR |
| `delivered` / `superseded` / `invalidated` / `abandoned` with nothing to point at | ERROR |
| `superseded-by` or `derived-from` pointing at a file that does not exist | ERROR |
| `decisions:` naming an id that is not in the ledger | ERROR |
| An `active` document resting on a superseded or withdrawn decision | WARN - the rework signal |
| A plan with no `derived-from`, or an active spec/plan naming no decisions | WARN |

`/superpowers:doc-audit` runs it and then looks for what it cannot see:
documents whose prose contradicts a decision in force, plans whose work is
plainly finished, specs nothing derived from.

## Going backwards

`skills/reworking-earlier-stages` is the procedure: the trigger with evidence,
status changes on the artifacts, the fate of work already delivered put to the
owner as a choice, a decision entry recording the rework, and a resume point in
`state.md`. The ripple is followed in order - decisions, derived documents,
tests, code - and reported before anything changes.

## Tests

```bash
bash tests/hooks/test-doc-lint.sh
bash tests/hooks/test-decision-lint.sh
```

17 assertions for the document front matter, including both sides of the
adoption boundary, and 18 for the decision ledger, including the two number rules.

## Drift against history

`hooks/doc-lint` checks the metadata. `hooks/doc-drift <project-dir>` checks the
metadata against what the repository actually did - the quiet failures live
there, not in the front matter:

| Finding | Level |
|---------|-------|
| `delivered-by` names a commit that is not in this repository | ERROR |
| A document's `derived-from` source was committed *after* it - the spec moved underneath the plan | WARN |
| An `active` or `draft` document untouched while more than `SUPERPOWERS_DOC_STALE_COMMITS` commits (default 30) went past | WARN |
| `.claude/context/state.md` points at a plan that is delivered, superseded, abandoned or missing | WARN |
| A document names a backticked path that is in neither the working tree nor HEAD | WARN |

Silent outside a git repository.

The first one is the rework signal that metadata alone cannot produce: a spec
corrected on Thursday leaves every plan derived from it on Tuesday resting on
the old text, and nothing in either file says so.

## Walking the ripple

`/superpowers:rework <artifact>` drives the backward move end to end: state the
trigger with its evidence, run both checks, build the ripple list in order
(decisions, derived documents, tests, delivered commits), put the choice to the
owner in outcome language, and only then apply the marks and record the
decision. It never marks a document or retires a test on its own - clerical
fixes excepted, and reported.

`/superpowers:doc-audit` runs the same checks in survey mode, for when nothing
is known to be wrong yet.

## Tests

```bash
bash tests/hooks/test-doc-lint.sh     # metadata
bash tests/hooks/test-doc-drift.sh    # metadata against history
bash tests/hooks/test-decision-lint.sh
```

17 assertions for the document front matter, including both sides of the
adoption boundary; 10 for drift; 18 for the decision ledger, including the two
number rules.

The `stage-rework` eval measures the behaviour the hooks cannot: told mid-task
that the spec's assumption is false, the agent must name the evidence, mark the
spec and plan rather than editing them quietly, check what is already built on
the dead premise, and put the choice to the owner.
