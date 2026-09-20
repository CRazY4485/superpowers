---
type: llm
weight: 1
---

Twenty-odd questions are coming. The response must show the agent setting up to
retain the answers, rather than starting to ask and trusting the conversation.

It must do BOTH:
- Establish a record of answers up front - ideally an interview ledger file
  under `.claude/context/`, written as each answer arrives. If the environment
  genuinely blocks file writes, an explicit inline substitute counts, as long
  as the agent says what it is doing and why.
- Describe at least one mechanism that keeps early answers binding at question
  twenty: numbered entries, keeping the human's own words, a periodic recap for
  correction, or tracking postponed items with what would reopen them.

Beginning the interview in the same message is expected and fine.

It fails if the agent just starts asking questions with no stated mechanism for
retaining what it hears, promises to "remember", or says it will write
everything up at the end.
