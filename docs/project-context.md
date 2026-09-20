# Project context preservation

Fork-local mechanism that carries a project's working context across sessions,
compactions and machines. Upstream Superpowers has no equivalent; this is
Claude Code only.

## What it does

Each project that opts in keeps three files in `<project>/.claude/context/`:

| File | Holds | Written |
|------|-------|---------|
| `project.md` | Stack, commands, conventions, environment quirks | Rarely |
| `state.md` | Where the work stands, next step, open questions | Overwritten as work moves |
| `decisions.md` | Decisions with reasoning and rejected alternatives | Appended, never edited |

A project opts in simply by having the directory. Projects without it behave
exactly as before - nothing is injected, nothing is nudged.

## Moving parts

| Piece | Role |
|-------|------|
| `skills/maintaining-project-context/` | Tells the agent what belongs in each file, when to write, and what never to write (secrets). Includes `templates/` |
| `hooks/project-context` | Collects the block that gets injected. Prints nothing when the project has no context directory |
| `hooks/session-start` | Appends that block to the superpowers bootstrap it already injects |
| `hooks/context-nudge` | `Stop` hook. Injects a reminder when `state.md` has fallen behind the work |
| `commands/context-init.md` | `/superpowers:context-init` - create and fill the three files |
| `commands/context-save.md` | `/superpowers:context-save` - bring them up to date now |

The `SessionStart` matcher is `startup|clear|compact`, so the context is
re-injected after a compaction - the moment the in-conversation history is
gone. That is the main reason this works at all: `PostCompact` cannot inject
context, but `SessionStart` with the `compact` matcher can.

## What gets injected

`project.md` and `state.md` are injected in full (truncated at a cap, with the
truncation disclosed). `decisions.md` is *summarised* - entry count plus the
three most recent headings - so a long decision log never dominates the
session budget. The agent reads the file when the reasoning matters.

Any other `*.md` in the directory is listed by name only.

## Staleness nudge

`hooks/context-nudge` runs on `Stop` and says nothing unless:

- `.claude/context/state.md` exists, **and**
- commits have landed since `state.md` was last written, or the working tree
  has been dirty and `state.md` untouched for longer than the dirty threshold.

A nudge is throttled per project directory, so a stale file reminds once per
throttle window rather than once per turn. The hook never blocks - the turn
ends either way, and the reminder lands in the next one.

## Knobs

| Variable | Default | Effect |
|----------|---------|--------|
| `SUPERPOWERS_CONTEXT_MAX_PROFILE` | 3000 | Max bytes of `project.md` injected |
| `SUPERPOWERS_CONTEXT_MAX_STATE` | 4000 | Max bytes of `state.md` injected |
| `SUPERPOWERS_CONTEXT_DECISIONS` | 3 | Recent decision headings listed |
| `SUPERPOWERS_NUDGE_THROTTLE_SECONDS` | 1800 | Minimum gap between nudges |
| `SUPERPOWERS_NUDGE_DIRTY_SECONDS` | 5400 | Dirty-tree age before nudging |
| `SUPERPOWERS_NUDGE_STATE_DIR` | temp dir | Where throttle markers live (tests override it) |

Both hooks resolve the project as `${CLAUDE_PROJECT_DIR:-$PWD}` and always
exit 0: a broken context file can never break a session.

## Tests

```bash
bash tests/hooks/test-project-context.sh
bash tests/hooks/test-session-start.sh
```

The first covers collection, decision summarisation, truncation, the
SessionStart integration (with and without context files), and every branch of
the nudge including throttling. JSON assertions live in the `.cjs` helpers
beside it - the repo's `package.json` sets `"type": "module"`, so plain `.js`
helpers would be loaded as ESM and fail.
