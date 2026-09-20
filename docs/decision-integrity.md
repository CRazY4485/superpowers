# Decision integrity

Fork-local mechanism for the failure that hurts an owner who does not read
code: decisions that contradict each other, documents that still describe what
changed, and reasons that were never really reasons.

## The record format

Decisions live in `.claude/context/decisions.md` (or `memory-bank/decisions/`,
`docs/decisions/` if the project uses those), one entry per decision:

```markdown
## D0011 | 2026-04-10 | active | scope: delivery/retries
**Decision:** Retry only timeouts, three attempts with backoff; every other failure surfaces immediately.
**Why:** The owner wants every non-transient failure visible; timeouts recover on their own.
**Evidence:** owner message, 2026-04-10: "I want to see every failure"; provider docs on rate limits, checked 2026-04-08
**Supersedes:** D0009
```

The heading is machine-checkable: id, date, status (`active` / `superseded` /
`withdrawn`), and a scope path. The scope is what makes collisions findable.

## What the linter checks

`hooks/decision-lint <file>...` prints `ERROR`/`WARN` lines and exits non-zero
on any error.

| Finding | Level | Why it matters |
|---------|-------|----------------|
| Missing `**Decision:**`, `**Why:**` or `**Evidence:**` | ERROR | A decision with no stated reason cannot be reviewed, only obeyed |
| Evidence that is an assumption (`probably`, `I assume`, `I think`, `seems`, `should be fine`) | ERROR | An invented reason is indistinguishable from a real one once written |
| Duplicate id | ERROR | References stop resolving |
| `Supersedes:` pointing at an id that does not exist | ERROR | Dangling history |
| Superseded decision still marked `active` | ERROR | Supersession recorded on one side only - both readings survive |
| Two `active` decisions on the same scope | WARN | Either one is wrong or the scopes are narrower than they look |
| Marked `superseded` with nothing superseding it | WARN | Status without a successor |

`hooks/decision-gate` runs the linter on staged decision files at commit time:
**deny** on any ERROR, **warn** on WARN.

## What the linter cannot check

Two decisions can contradict each other in substance while their scope tags
differ; a decision's premise can be destroyed by a later, unrelated-looking
change; a document can quietly keep describing superseded behaviour. That is
`skills/reconciling-decisions`: search before recording, classify what you
found, put the collision to the owner in outcome language with both reasons and
dates, offer options with consequences, then record the supersession *and the
ripple* - the documents, plans and tests that still encode the old decision.

`/superpowers:decision-audit` runs both halves over a project: the structural
check verbatim, then the semantic sweep.

## Tests

```bash
bash tests/hooks/test-decision-lint.sh
```

15 assertions: a clean log, each error class, the overlap warning, and the gate
denying, warning, and staying silent.

The `decision-conflict` eval measures the behaviour: told "I've changed my mind,
make the change", the agent must find the earlier decision, say the two cannot
both hold, name the consequence in the owner's terms, and record a supersession
rather than silently complying.
