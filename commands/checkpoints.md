---
description: List the working-tree checkpoints for this repo and how to restore one
---

Show the checkpoints this plugin has saved for the current repository.

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/hooks/git-checkpoint" list 20` from the
   project directory.
2. For each checkpoint, say when it was taken and what it was taken for (the
   label: `turn` for an end-of-turn snapshot, `pre-destructive` for one taken
   in front of a risky command).
3. If your human partner names something they lost, find which checkpoint holds
   it - `git diff HEAD <sha>` and `git show <sha>:<path>` - and show them the
   content before restoring anything.
4. Restore only what they ask for, narrowest first: one file with
   `git checkout <sha> -- <path>`. Restoring the whole tree overwrites current
   edits, so checkpoint the current state first and say so.
5. If there are no checkpoints, say why that can be: the tree has been clean,
   this is not a git repo, or the session has not ended a turn yet.

See `superpowers:recovering-work-with-git` for the full recovery ladder.

$ARGUMENTS
