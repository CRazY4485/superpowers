# Decisions

Append-only. Newest entries at the bottom. Never edit an old entry - supersede
it with a new one that names it, and mark the old one `superseded`.

Every entry needs a reason and a source: `hooks/decision-lint` blocks a commit
whose decisions have no **Why**, no **Evidence**, or evidence that is really an
assumption. See `superpowers:reconciling-decisions`.

## D0001 | YYYY-MM-DD | active | scope: <area>/<sub-area>
**Decision:** What was decided, in one line, in outcome terms.
**Why:** The reason that actually drove it.
**Evidence:** Where that reason comes from - the owner's words with a date, a measurement, a document section, an official page with its URL, or `file:line`.
**Rejected:** The alternatives and why each lost. *(optional)*
**Implications:** What this now forces or forbids. *(optional)*
**Supersedes:** D0000 *(optional - and mark D0000 `superseded` in its own heading)*
