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

`hooks/git-guard` reads the pending command from the `Bash` or `PowerShell`
tool and matches it against two sets:

| Class | Patterns | When nothing is at risk |
|-------|----------|-------------------------|
| git | `reset --hard/--merge/--keep`, `checkout -- `, `restore`, `clean -f*`, `stash drop\|clear\|pop`, `branch -D`, `rebase`, `commit --amend`, `push --force` | Says so - knowing the operation is safe is worth a line |
| bulk delete | `rm -r*/-f*`, `shred`, `truncate -s`, `find … -delete`, `find … -exec rm`, `Remove-Item … -Recurse/-Force`, `Clear-Content`, `rmdir /s`, `del /s\|/q` | Stays silent - these are frequent, and narration would be noise |

A single-file `rm notes.txt` is deliberate and narrow, so it is not guarded;
recursive and forced deletes are the ones that take an afternoon with them.

On a match it takes a checkpoint and returns `additionalContext` naming the
sha and the three recovery commands. **It never blocks.** Blocking a deliberate
command is friction; losing uncommitted work is damage - the guard converts the
second into the first.

It needs `node` to parse the hook payload; without node it exits silently, so
the guard degrades to nothing rather than breaking the tool call.

## The commit nudge

`hooks/commit-nudge` runs on `Stop` and says nothing unless the working tree
has drifted from the last commit: at least `SUPERPOWERS_COMMIT_NUDGE_FILES`
files changed (default 5), or more than `SUPERPOWERS_COMMIT_NUDGE_AGE` seconds
since the last commit (default 2700) with the tree dirty. Untracked files count;
ignored files do not. Throttled per project, default 1800s.

It exists because checkpoints are a floor, not a record. The message says so:
commit what passes, in logical pieces, with messages that say why.

## The commit gate

`hooks/commit-gate` (PreToolUse, `Bash|PowerShell`) inspects the staged diff
whenever the command is a `git commit`. It is the one hook here that blocks,
because both things it blocks are expensive once they are in history:

| Finding | Action |
| --- | --- |
| Unresolved conflict markers in added lines | **deny** |
| AWS access key id, private key block, GitHub token, Slack token, `sk-` API key | **deny** |
| Credential-shaped literal (`password = "..."`) | warn |
| Staged file over `SUPERPOWERS_COMMIT_MAX_FILE_BYTES` (default 5 MB) | warn |

Findings are reported by name and location, never by value - echoing a secret
into the transcript is another copy of the secret.

A line carrying `pragma: allowlist secret` is skipped, the detect-secrets
convention. Fixtures and documentation examples need to contain things that
look like credentials; this is how they say so. The gate's own test suite uses
it, because a secret scanner's tests are made of fake secrets.

## The branch guard

`hooks/branch-guard` (PreToolUse, `Edit|Write|NotebookEdit`) speaks once per
hour per branch when an edit inside the project lands while HEAD is the
repository's default branch (from `origin/HEAD`, or `main`/`master`/`trunk`
when there is no remote). It never blocks: editing `main` directly is sometimes
exactly the request.

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
| `SUPERPOWERS_COMMIT_NUDGE_FILES` | 5 | Changed files before the commit nudge fires |
| `SUPERPOWERS_COMMIT_NUDGE_AGE` | 2700 | Seconds since the last commit before it fires |
| `SUPERPOWERS_COMMIT_NUDGE_THROTTLE` | 1800 | Minimum gap between commit nudges |

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
bash tests/hooks/test-commit-nudge.sh
```

33 assertions: silence outside a repo and on a clean tree, tracked and untracked
capture, `.gitignore` respected, index/worktree/branch left untouched,
deduplication, unborn HEAD, pruning, listing, the silent turn hook, and the
guard's cases for git commands, bulk deletes, PowerShell and the unguarded single-file rm. The commit nudge adds 7 more: non-repo, clean tree, small recent change, wide change, throttling, long-uncommitted work, and ignored files.
