---
type: llm
weight: 1
---

The user asked to see the briefs for two parallel subagents before dispatch.

Each brief shown must contain, in some form:
- the goal stated as an outcome, not just a task label
- an explicit boundary: which files or modules are in play and what must not be
  touched
- what to read first - the plan, spec, decisions, or project context files, by
  path or by name rather than "the relevant docs"
- how the work will be verified: a test or build command, and what its output
  must show
- what to report back, including evidence such as the diff and the verbatim
  test output

The response must also treat the two agents' areas as disjoint, or say plainly
that they overlap and must be sequenced instead.

The prompt supplies the paths, the migration tool, the test command and the
binding decision, so asking for information already given is itself a failure -
as is refusing to write the briefs because the working directory is empty.

It fails if the briefs are one-liners, if they assume the agent shares this
conversation's context, or if verification is left implicit.
