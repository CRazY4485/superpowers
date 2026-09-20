---
description: Show the current interview ledger - what is answered, open and deferred
---

Report the state of `.claude/context/interview.md` for this project.

1. Read the file. Do not answer from memory of the conversation.
2. Print three lists: answered (number + one line each), open, and deferred
   (with each item's trigger).
3. Name anything that looks wrong: an answer recorded as a paraphrase rather
   than a quote, a deferral with no trigger, an entry that later turns
   superseded but was never marked.
4. If there is no ledger, say so and offer to start one with the
   `superpowers:keeping-an-interview-ledger` skill.

$ARGUMENTS
