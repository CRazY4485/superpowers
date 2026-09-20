---
name: recovering-work-with-git
description: Use before any command that can discard work (reset --hard, checkout --, clean, rebase, amend, force push), when work seems lost, or when deciding how often to commit - covers checkpoints, the recovery ladder, and which undo is safe on which history
---

# Recovering Work With Git

## Overview

**Core principle: every state worth returning to must exist somewhere before
you leave it.**

Two separate safety nets, and they do different jobs:

| Net | Covers | Who creates it |
|-----|--------|----------------|
| Commits | Deliberate, meaningful states, kept forever, shared | You, at every green point |
| Checkpoints (`refs/superpowers/checkpoints/`) | Whatever is in the working tree right now, uncommitted and untracked included | The plugin, each turn and before destructive commands |

Checkpoints are a floor, not a substitute. They are local, pruned, and invisible
to your human partner. Anything that matters gets a commit.

## Commit Cadence

Commit at every state you would be annoyed to lose:

- Each time the test suite goes green.
- Each finished task in a plan, before starting the next.
- Before any refactor, dependency change, or large mechanical edit.
- Before running anything on this page's destructive list.

A commit message says **why**, in the imperative: "Guard uploads against empty
MIME types" - not "changed upload.ts". If the why takes a paragraph, write the
paragraph; future readers are rebuilding your reasoning, not your diff.

Never bundle unrelated changes into one commit. When you notice two reasons in
one diff, stage them separately.

## Before Anything Destructive

These discard work that is not in a commit:

```
git reset --hard / --merge / --keep      git checkout -- <path> / .
git restore <path>                       git clean -f / -fd / -fdx
git stash drop / clear / pop             git branch -D
git rebase                               git commit --amend
git push --force
```

Before running one:

1. State what will be lost, out loud, in one line.
2. Confirm a checkpoint exists (the guard hook writes one, and says so in the
   tool context - read it, do not assume).
3. If the command touches history your human partner may already have pulled,
   **stop and ask** instead. Rewriting shared history is their decision, never
   yours.

## Choosing The Right Undo

| Situation | Use | Never |
|-----------|-----|-------|
| Bad commit, already pushed or shared | `git revert <sha>` | `reset --hard` then force push |
| Bad commit, local and unpushed | `git reset --soft HEAD~1` (keeps the work) | `reset --hard` as a reflex |
| Wrong file edit, not committed | `git checkout <checkpoint-sha> -- <path>` | `checkout -- .` across the whole tree |
| Experiment went nowhere | Branch off, keep it; delete the branch later | Throwing the tree away |
| Want the tree from 20 minutes ago | The checkpoint refs | Undo in the editor |

`--soft` keeps your work staged; `--hard` deletes it. When you catch yourself
typing `--hard`, say why out loud first.

## The Recovery Ladder

Work through it in order; stop at the first rung that has what you need.

1. **Checkpoints** - `git for-each-ref refs/superpowers/checkpoints` or
   `/superpowers:checkpoints`. Covers uncommitted and untracked files.
   Inspect with `git diff HEAD <sha>`, take one file with
   `git checkout <sha> -- <path>`.
2. **Reflog** - `git reflog` finds commits orphaned by reset, rebase or a
   deleted branch. Recover with `git branch rescue <sha>`.
3. **Stash list** - `git stash list`, then `git stash show -p <entry>`.
4. **Dangling objects** - `git fsck --lost-found` as a last resort.

Report what you recovered and from where. A silent recovery hides a near-miss
your human partner should know about.

## Red Flags - STOP

| Thought | Reality |
|---------|---------|
| "I'll clean up the tree first, then look" | Cleaning is what destroys the evidence. Checkpoint, then look. |
| "It's just untracked junk" | Untracked is exactly what `clean -fd` deletes forever and what no commit holds. |
| "Force push is fine, it's my branch" | Fine only if nobody else pulled it. If you are not sure, ask. |
| "I'll amend instead of a new commit" | Amend rewrites. On anything pushed, that is a rewrite of shared history. |
| "The checkpoint hook has me covered" | Checkpoints are pruned and local. Commit the things that matter. |
| "Reset --hard is the quick way back" | It is the quick way to lose the last hour. `--soft` first, always. |
| "I'll commit once it all works" | Then the one state you can return to is the one before you started. |
