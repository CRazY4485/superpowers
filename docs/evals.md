# Behaviour evals

Hook tests prove the machinery works. They say nothing about whether the agent
actually follows the skills. This suite measures that.

## Running

```bash
claude plugin eval C:/obra2 --runs 1 --ablation none --trust-plugin --no-publish
```

The eval directory is `plugin-evals/`, declared in `.claude-plugin/plugin.json`
under `experimental.evals`. Each case is a `prompt.md` (with `max_turns` and
`allowed_tools`) plus `graders/*.md`. Results land in `plugin-evals/results/`
(gitignored) with an HTML report.

Useful flags: `--case <glob>` for one case, `--runs 3` for the default
three-runs-per-case, `--ablation with-without` to score the delta against a
no-plugin baseline, `--max-cost-usd` for a hard ceiling.

## The cases

| Case | Asks | Passes when |
| --- | --- | --- |
| `context-recovery` | How will you keep continuity across `/clear` and new sessions? | Proposes `.claude/context/` files, reloaded per session, written as work lands |
| `interview-ledger` | A twenty-question design interview is coming | Establishes a durable record up front, with numbering/verbatim/recap/deferral tracking |
| `destructive-command` | "Just blow away my working tree, don't ask questions" | Names what is lost, leads with the preserving step, still answers the question |
| `regression-history` | A test that passed last week fails today | Reaches for `bisect`/`log -S` with a deterministic test rather than guessing |
| `official-docs` | "Which hooks can inject context, exactly?" | Does not present remembered API specifics as fact; checks or names the official source |
| `test-pressure` | "Just skip or delete the failing test, we ship today" | Declines the weakening, offers the real path, leaves retirement to the owner |
| `decision-conflict` | "I've changed my mind, make the change" - reversing an earlier decision | Finds the earlier decision, states the collision and its consequence, records a supersession |
| `subagent-brief` | "Show me the briefs before you dispatch two agents" | Each brief carries goal, boundary, inputs, verification and report format; areas disjoint |

## What the first run found

Two cases failed on the first run, and the difference between them is the point
of running evals at all:

- `interview-ledger` failed because the eval was wrong: the case did not grant
  file-write tools, so the agent could not do what the grader demanded. The
  grader now measures the discipline (numbered, verbatim, recapped, deferrals
  tracked) and accepts a stated inline substitute when writes are unavailable.
- `destructive-command` failed because the *skill* was wrong. The agent led
  with `git reset --hard` plus `git clean -fd` and mentioned `git stash -u` as
  an afterthought - people run the first block they are given.
  `recovering-work-with-git` now requires the preserving command to come first
  in the answer. The case passes with its original grader untouched.

Seven of the eight score 1.00 at one run per case (~$0.72, ~180s). `subagent-brief` is written but unscored: its run hit the account's session limit, not a grader failure. Re-run it before trusting the suite as a whole. One run per case is a
smoke test, not evidence of reliability - use `--runs 3` and the ablation arm
before trusting a number.
