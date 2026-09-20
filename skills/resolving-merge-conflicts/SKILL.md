---
name: resolving-merge-conflicts
description: Use when a merge, rebase, cherry-pick or stash pop reports conflicts - resolves them by reconstructing both intentions instead of picking a side, and verifies the result before it is committed
---

# Resolving Merge Conflicts

## Overview

**Core principle: a conflict is two intentions that met in one place. Text is
the symptom.**

`--ours` and `--theirs` are not resolutions. They are coin flips that happen to
compile. A resolution is the version that satisfies what both changes were for.

## See What You Are Merging

```bash
git status                       # which files, which operation
git log --merge -p -- <path>     # the commits on each side, for that file
git diff --base -- <path>        # what each side changed relative to the base
```

Turn on three-way markers once, permanently:

```bash
git config --global merge.conflictStyle zdiff3
```

Without the base section you are guessing which side added a line and which
side deleted it. With it, the middle block shows what was there before.

## The Procedure

1. **Name both intentions.** For each side: which commit, and what was it
   trying to achieve? If you cannot say, read the commit message and its diff
   before touching the file.
2. **Decide per hunk, not per file.** One file can need this side's error
   handling and that side's signature.
3. **Write the resolution.** Often it is neither side verbatim: both changes
   applied together, reconciled by hand.
4. **Delete every marker** - `<<<<<<<`, `=======`, `>>>>>>>`. The commit gate
   blocks a commit that still contains them, but do not rely on it.
5. **Run the tests**, all of them. A conflict resolution is new code that no
   one has ever run, and its two halves were each tested only in isolation.
6. **Stage and continue**: `git add <paths>` then `git merge --continue`,
   `git rebase --continue`, or `git cherry-pick --continue`.

## Special Cases

| Case | Do |
|------|-----|
| Lockfiles (`package-lock.json`, `poetry.lock`, `Cargo.lock`) | Do not hand-merge. Take either side, then regenerate with the package manager and commit the result |
| Generated files | Same: resolve by regenerating from source |
| A whole file added on both sides | Read both. Usually one is a rename - use `git log --follow` to find out |
| Formatting-only conflict | Take the side that matches the project's formatter, then run it |
| The same conflict on every rebase | `git config --global rerere.enabled true` - git replays your earlier resolution |
| You do not understand either side | `git merge --abort`. Aborting is free; a wrong resolution is a bug nobody will look for |

## Before Committing The Merge

- No markers anywhere: `git diff --cached | grep -nE '^\+(<<<<<<<|>>>>>>>)'`
- Full test suite green - not the subset you think is affected.
- The merge commit message says what was reconciled if anything was subtle.
- If you rewrote someone else's intent to make the merge work, say so to your
  human partner. That is a decision, not a merge.

## Red Flags - STOP

| Thought | Reality |
|---------|---------|
| "I'll take theirs, mine was small" | Small and unimportant are different things. Read what yours did. |
| "`-X ours` will clear this up" | It resolves every conflict the same way, including the ones you have not looked at. |
| "It compiles, so it merged" | Compiling proves syntax. The two behaviours are what conflicted. |
| "I'll fix the tests after the merge lands" | Then the merge is what broke them, and it is already in history. |
| "The conflict is only in a lockfile" | Hand-edited lockfiles produce installs nobody can reproduce. Regenerate. |
| "I'll resolve it now and understand it later" | Later, the markers are gone and both intentions are invisible. |
