# Coding standard and subagent briefs

Two mechanisms that answer the same question from different ends: what does the
code have to look like, and how does a second agent come to know that.

## The architectural constitution

`skills/following-the-architectural-constitution/ARCHITECTURAL_CONSTITUTION.md`
is the owner's document, shipped unchanged, with a mapping comment at the top
that translates the file paths it names onto this framework's
`.claude/context/` layout. It covers Clean Code, SOLID, DRY, KISS, separation of
concerns, determinism, modular structure and portability, naming, error
handling and logging, time/units/precision, concurrency and resource lifecycle,
configuration, security, interface compatibility, comments, dependencies,
observability, performance budgets and testing standards.

The skill beside it is the way in: when the standard binds, a section map, and
**the deviation procedure** - stop before writing the non-compliant code, take
it to the owner in outcome language, record the decision with its reason and
scope, and bound it to the named case. An unrecorded deviation becomes the
codebase's new habit.

`/superpowers:constitution-init` installs it into a project: copy the document
to `docs/`, fill the project facts it deliberately excludes into
`.claude/context/project.md`, and record the adoption as a decision.

Two rules from it that the framework enforces mechanically elsewhere: never
weaken a test to make a change pass (`hooks/test-integrity`), and never commit a
secret (`hooks/commit-gate`).

## Subagent briefs

A subagent starts with none of the dispatching session's context. Whatever the
brief leaves out, it invents - plausibly, and invisibly.

`skills/briefing-subagents` defines the five parts every brief carries: goal as
an outcome, an explicit boundary including what not to touch, the inputs to read
first named by path, the verification command and what its output must show, and
the report format including evidence. It also covers parallel dispatch: disjoint
boundaries, shared context repeated in each brief rather than assumed, and a
stated rule for what to do when the task turns out to need something outside the
boundary.

`hooks/brief-check` (PreToolUse on `Agent|Task`) reads the pending brief and
names what is missing from those five, plus a length floor. It never blocks -
some dispatches genuinely are one-liners over read-only work.

`dispatching-parallel-agents` and `subagent-driven-development` both point at
the skill at the moment the dispatch is composed.

## Tests

```bash
bash tests/hooks/test-brief-check.sh
```

5 assertions: a complete brief is silent, a missing verification path is named,
a missing boundary is named, a one-line brief is flagged as starting the agent
cold, and other tools are ignored.

The `subagent-brief` eval case asks for two parallel briefs to be shown before
dispatch and grades them against the five parts. It is written but not yet
scored - the run hit the account's session limit.
