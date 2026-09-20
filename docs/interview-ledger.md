# Interview ledger

Fork-local mechanism that stops long requirements interviews from losing their
own answers. Claude Code only.

## The problem it solves

Two distinct failures, often mistaken for one:

| Failure | Mechanism | Fixed by |
|---------|-----------|----------|
| Answers 1-5 stop binding by question 20 | Attention dilution - the answers are still in the transcript, but recent turns dominate | Re-injecting open items on every prompt, in the newest position |
| "We'll decide that later" never returns | Nothing tracks parked items | A `deferred` status that requires a trigger and rides along until resolved |
| `/clear`, compaction, a new session | The transcript is gone outright | The ledger is a file |

## Moving parts

| Piece | Role |
|-------|------|
| `.claude/context/interview.md` | The ledger itself, one active per project |
| `skills/keeping-an-interview-ledger/` | Entry format, statuses, the recap rule, the coverage gate, closing procedure |
| `hooks/interview-context` | `UserPromptSubmit` hook. Injects counts plus open and deferred items on every prompt while the ledger is active |
| `commands/interview-status.md` | `/superpowers:interview-status` |
| `commands/interview-close.md` | `/superpowers:interview-close` - runs the gate, folds results into `decisions.md` and `state.md` |
| `skills/brainstorming/SKILL.md` | Points at the ledger where the interview actually happens (upstream file, modified) |
| `skills/writing-plans/SKILL.md` | Coverage gate before a plan is written (upstream file, modified) |

## Entry format

```markdown
## Q07 [open] Rate limits
**Asked:** Per tenant or global?
```

Statuses: `[open]`, `[answered]`, `[deferred: <trigger>]`, `[superseded by Qnn]`.
The heading is what gets carried forward on each prompt, so it must read as the
question rather than as a label.

## What gets injected, and what does not

Every prompt, while `Status: active`:

- counts (`12 answered, 3 open, 1 deferred`)
- the open and deferred headings, capped (default 12) with the remainder
  disclosed
- a reminder to record answers as they land and to re-read the file before any
  spec, plan or summary

Answered bodies are **not** re-injected - they stay on disk. A long interview
therefore costs roughly a fixed few hundred tokens per turn rather than growing
with its own history.

## Unrecorded-answer detection

The hook keeps a per-project marker. If a prompt arrives and the ledger has not
changed since the previous prompt, the injected block says so: *"if that prompt
answered anything, record it before you respond"*. It is a nudge, not a block -
a hook cannot make the model write, only make forgetting visible.

## Knobs

| Variable | Default | Effect |
|----------|---------|--------|
| `SUPERPOWERS_INTERVIEW_MAX_ITEMS` | 12 | Open/deferred items carried per prompt |
| `SUPERPOWERS_INTERVIEW_STATE_DIR` | temp dir | Where the per-project marker lives (tests override it) |

The hook resolves the project as `${CLAUDE_PROJECT_DIR:-$PWD}`, stays silent
when there is no ledger or the ledger is closed, and always exits 0.

## Tests

```bash
bash tests/hooks/test-interview-ledger.sh
```

Covers silence without a ledger, silence when closed, open/deferred injection
with counts, answered bodies staying out, the cap and its disclosure, and all
three states of the unrecorded-answer warning.
