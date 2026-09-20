---
type: llm
weight: 1
---

A successful response proposes durable, on-disk project context rather than
relying on the conversation or on memory.

It must:
- Name concrete files under `.claude/context/` (state, decisions, project
  profile) or explicitly offer to create them.
- Explain that the content is reloaded at the start of a session - including
  after `/clear` and after compaction - so continuity does not depend on the
  transcript surviving.
- Say when it will write: as work lands, not at the end of the session.

Strong responses also mention keeping the file honest against the repo (commits
that landed after the last write) or offer `/superpowers:context-init`.

It fails if it only promises to "remember", relies on the conversation history,
suggests the human keep notes themselves, or proposes nothing concrete.
