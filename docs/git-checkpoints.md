# Git checkpoints and the destructive-command guard

Fork-local mechanism that makes uncommitted work recoverable. Claude Code only.

## What a checkpoint is

An ordinary git commit built from a **scratch index**, hung off
`refs/superpowers/checkpoints/<timestamp>-<label>`:

- Captures tracked edits *and* untracked files, honouring `.gitignore`.
- Touches nothing: not the working tree, not the real index, not HEAD, not any
  branch. `git status` and `git log` are unchanged; `git push` ignores the refs.
- Is a normal commit, so the familiar tools work on it: `git diff HEAD <sha>`,
  `git show <sha>:<path>`, `git checkout <sha> -- <path>`.

This is what `git stash create` cannot do - stash snapshots leave untracked
files behind, which is precisely the category `git clean -fd` destroys.

## When one is taken

| Trigger | Hook | Label |
|---------|------|-------|
| End of every assistant turn | `Stop` → `hooks/checkpoint-turn` (async) | `turn` |
| Before a Bash command that can discard work | `PreToolUse` (matcher `Bash`) → `hooks/git-guard` | `pre-destructive` |

Nothing is written when the tree is clean, when the tree is identical to the
previous checkpoint, or outside a git repository. Old refs are pruned to
`SUPERPOWERS_CHECKPOINT_KEEP` (default 50), newest kept.

## The guard

`hooks/git-guard` reads the pending Bash command and matches it against the
work-destroying set: `reset --hard/--merge/--keep`, `checkout -- `, `restore`,
`clean -f*`, `stash drop|clear|pop`, `branch -D`, `rebase`, `commit --amend`,
`push --force`.

On a match it takes a checkpoint and returns `additionalContext` naming the
sha and the three recovery commands. **It never blocks.** Blocking a deliberate
command is friction; losing uncommitted work is damage - the guard converts the
second into the first. With a clean tree it says there is nothing to lose.

It needs `node` to parse the hook payload; without node it exits silently, so
the guard degrades to nothing rather than breaking the tool call.

## Using them

```bash
# list
bash hooks/git-checkpoint list 20
git for-each-ref --sort=-refname refs/superpowers/checkpoints

# inspect
git diff HEAD <sha>
git show <sha>:path/to/file

# restore
git checkout <sha> -- path/to/file     # one file
git checkout <sha> -- .                # everything, overwrites current edits
```

`/superpowers:checkpoints` drives this conversationally.

## Knobs

| Variable | Default | Effect |
|----------|---------|--------|
| `SUPERPOWERS_CHECKPOINT_KEEP` | 50 | Checkpoint refs kept per repo |

## Limits worth knowing

- Checkpoints are **local and pruned**. They are a floor under mistakes, not a
  substitute for commits. The `superpowers:recovering-work-with-git` skill sets
  the commit cadence.
- A checkpoint holds what was on disk at the moment it ran. Work done and undone
  inside a single turn may sit between two snapshots.
- The refs keep their objects alive, so `git gc` cannot reclaim them until
  pruning drops the ref.

## Tests

```bash
bash tests/hooks/test-git-checkpoint.sh
```

28 assertions: silence outside a repo and on a clean tree, tracked and untracked
capture, `.gitignore` respected, index/worktree/branch left untouched,
deduplication, unborn HEAD, pruning, listing, the silent turn hook, and the
guard's four cases.
