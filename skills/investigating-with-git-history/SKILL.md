---
name: investigating-with-git-history
description: Use when something worked before and does not now, when you need to know why a line exists, or when a bug's origin is unclear - turns git history into evidence with bisect, log -S, log -p and blame instead of guessing at causes
---

# Investigating With Git History

## Overview

**Core principle: the repository already recorded the answer. Read it before
theorising.**

A regression has a first bad commit. A baffling line has an author, a date, and
a diff that explains it. Both are cheaper to look up than to reason about, and
looking them up produces evidence rather than a hypothesis.

This is the history half of `superpowers:systematic-debugging`: use it in Phase
1, where that skill says to check recent changes.

## Pick The Right Tool

| Question | Command |
|----------|---------|
| When did this break? | `git bisect` (below) |
| Which commit introduced or removed this string? | `git log -S'<string>' --oneline` |
| How did this file get like this? | `git log -p -- <path>` |
| Who wrote this line, and in which commit? | `git blame -L <start>,<end> -- <path>` |
| Why is this line here? | `git log -1 <sha-from-blame>` - read the message, then its full diff |
| What changed between working and broken? | `git diff <good>..<bad> -- <paths>` |
| Was this line moved rather than written? | `git log --follow -p -- <path>`, `git blame -C -C` |
| What did the tree look like then? | `git show <sha>:<path>` |

`git log -S` (pickaxe) is the one most often forgotten and most often decisive:
it finds the commit where a symbol, flag or error string appeared or vanished.

## Bisect, Properly

Bisect is not a last resort. Two known points and one command that answers
"broken or not" turn an open-ended hunt into a handful of automatic steps.

```bash
git bisect start
git bisect bad                      # current state, or a known bad sha
git bisect good <sha>               # last state you know worked
git bisect run <command>            # exits 0 = good, non-zero = bad
git bisect reset                    # ALWAYS, when finished
```

Rules that make it work:

- **The test command must be deterministic** and must fail *only* on this bug.
  Write it first, verify it fails on the bad commit and passes on the good one,
  then hand it to bisect. A flaky command produces a confident wrong answer.
- **Exit 125** from the command tells bisect to skip an uncompilable commit.
- **Reset when done**, before doing anything else. Leaving the repo in a
  detached bisect state is how the next hour gets confusing.
- The result is the **first bad commit**, not necessarily the root cause. Read
  its diff - the cause may be an interaction it triggered.

## Using What You Find

1. State the finding as evidence: "`a1b2c3d`, 2026-04-11, introduced the early
   return that skips validation when the cache is warm."
2. Decide deliberately between `git revert <sha>` (published history, restores
   the previous behaviour) and a forward fix (when the commit also carries
   wanted changes). Do not reach for `reset --hard`; see
   `superpowers:recovering-work-with-git`.
3. Write the finding into the project's context: a one-line entry in
   `.claude/context/decisions.md` if it explains a design choice, or the
   regression's cause in the bug's own notes.
4. Add the regression test before the fix. TDD applies to history-found bugs
   exactly as it does to new ones.

## Red Flags - STOP

| Thought | Reality |
|---------|---------|
| "It probably broke in the refactor" | Probably is not evidence. `git bisect run` gives you the sha. |
| "Bisect is too slow for this" | With a scripted test it is log2(n) runs. Twenty commits is five runs. |
| "I'll just read the recent commits" | Reading is scanning; `log -S` searches the content you actually care about. |
| "Blame only tells me who" | Blame gives you the sha. The sha gives you the message and the diff, which tell you why. |
| "The line looks wrong, I'll delete it" | Lines that look pointless are usually load-bearing. Find the commit that added it first. |
| "I'll finish bisect later" | An abandoned bisect leaves a detached HEAD. `git bisect reset` before anything else. |
