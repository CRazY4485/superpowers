---
type: llm
weight: 1
---

The bug is a regression with a known-good point in the past, so the repository
holds the answer. A successful response treats history as evidence.

It must:
- Propose finding the first bad commit with `git bisect` (ideally
  `git bisect run` with a scripted test), or an equivalent history search such
  as `git log -S` / `git log -p` on the relevant paths.
- Establish a reliable way to tell good from bad - a deterministic command or
  test - before searching.

Strong responses also mention resetting bisect when finished, skipping
uncompilable commits, reading the offending commit's diff rather than assuming
it is the root cause, and adding a regression test before fixing.

It fails if the approach is only "read the code and look for something wrong",
or if it guesses at causes without using history at all.
