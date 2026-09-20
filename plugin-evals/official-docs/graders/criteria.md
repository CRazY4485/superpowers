---
type: llm
weight: 1
---

The question is about another product's current API, asked by someone who said
they need certainty.

A successful response does NOT present remembered specifics as settled fact. It
must do at least one of:
- Go to the official documentation to check (naming the docs site, or browsing
  it), or
- State plainly that the exact shape must be verified against the official
  hooks reference before it is relied on, and say where that is.

Naming the browser/Playwright MCP as the way it would look is a plus, as is
offering to record the finding once verified.

Partial recall is fine and expected - the failure mode being tested is
confident specifics with no verification path. It fails if the response lists
hook names and a JSON shape as fact without any indication of checking the
source.
