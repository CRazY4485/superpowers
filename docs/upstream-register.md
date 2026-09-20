# Upstream register

This fork tracks `obra/superpowers` for one purpose: **pulling its fixes into the
fork**. The original is never installed or used as the framework - the only thing
installed anywhere is this fork.

Most of what the fork adds are new files, which never conflict. The cost is the
handful of **upstream files it modifies**: every upstream release can collide
there. That cost is the entire reason this register exists - and if the decision
is ever made to stop merging upstream at all, the register, the sync script and
the `upstream` remote should be deleted rather than kept for a merge that will
not come.

## The register is derived, not stored

```bash
bash scripts/upstream-register.sh          # the list, with a rule per file
bash scripts/upstream-register.sh --full   # plus the exact lines the fork added
```

It reads `git diff --numstat upstream/main`, so it cannot go stale: a file that
stops differing drops out by itself, and a file that starts differing appears
without anyone remembering to add it. `scripts/sync-upstream.ps1` prints it
before it merges, so the conflicts about to happen are named in advance.

`--full` prints the added lines for each file. During a conflict those lines
are the recipe: take upstream's version of the file, then put them back.

## Resolution rules

| File | Rule | Why |
|------|------|-----|
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | **Keep ours** | Fork identity: the personal marketplace name, and no `version` field so Claude Code tracks the plugin by commit sha. Upstream's change here is a version bump we do not want |
| `hooks/hooks.json` | **Union** | It is a list of registrations, not prose. Keep every upstream entry and every fork entry |
| `hooks/session-start` | **Take upstream, re-apply our block** | The fork appends a project-context block at one point; upstream owns the rest |
| `.gitattributes`, `.gitignore` | **Union** | The fork only adds entries of its own |
| `skills/*/SKILL.md` | **Take upstream wholesale, re-insert the fork pointers** | Upstream skill prose is tuned against evals. Hand-merging it loses that tuning silently. Our changes are short pointer paragraphs - put them back on top |

The last rule is the important one. Where this fork touches an upstream skill,
it only ever *adds a pointer* to a fork skill: `brainstorming` points at the
interview ledger and at reconciling decisions, `test-driven-development` points
at keeping tests honest, `systematic-debugging` at investigating with git
history, and so on. None of it edits upstream's reasoning. That is deliberate,
and it is what makes "take theirs, re-add ours" a safe rule rather than a
judgement call every release.

## If a rule stops fitting

Change the rule here, then resolve. Improvising per file is how a fork becomes
unmergeable: three releases later nobody can say whether a difference is a
decision or an accident.

## Keeping the cost down

- Prefer a **new file** over an edit to an upstream file. A new skill, hook or
  command costs nothing at merge time.
- When an upstream file must change, make the change **small, additive and
  self-contained** - a paragraph, a list entry, a registration - never a
  rewrite of a section.
- If the fork ever needs to edit upstream reasoning rather than point at it,
  that is a signal to detach from upstream deliberately rather than to keep
  paying for the merge.
