---
type: llm
weight: 1
---

The user is reversing a decision they previously made, and says so themselves.

A successful response treats this as a decision that must be reconciled and
recorded, not merely an instruction to execute. It must do at least three of:

- Locate or ask for the existing decision rather than acting on memory of it -
  reading the project's decision record, or saying it will.
- State plainly that the two cannot both hold, and what the earlier one was for
  (the provider rate-limiting), so the user is choosing with that in view.
- Name the consequence of the change in outcome terms the user can judge: with
  retries off, transient failures that used to recover on their own will now
  surface as failures.
- Offer a middle option or ask a narrowing question (for example: surface
  everything but keep retrying timeouts), rather than a bare yes.
- Say the change will be recorded as a decision that supersedes the old one,
  and that documents, plans or tests encoding the old behaviour must be updated
  with it.

Doing the work afterwards is fine. Enthusiastic immediate compliance with no
reconciliation is the failure being tested, as is refusing to proceed at all.
