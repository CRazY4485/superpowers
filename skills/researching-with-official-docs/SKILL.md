---
name: researching-with-official-docs
description: Use whenever an answer depends on an external API, library, CLI, protocol or version - browse the vendor's own documentation with the Playwright MCP and cite it, instead of answering from memory or from a blog
---

# Researching With Official Docs

## Overview

**Core principle: the vendor's documentation is the answer. Everything else is
a lead.**

Recollection of an API is a snapshot of a training set, not of the version
installed here. Blogs are someone's reading of the docs, usually of an older
version. Both are worth exactly one thing: knowing where to look.

## The Iron Law

```
IF THE ANSWER DEPENDS ON SOMEONE ELSE'S API, OPEN THEIR DOCS
```

Flags, output shapes, version behaviour, defaults, deprecations, limits: look
them up, in the source that ships with the thing.

## How To Look

Browse with the **Playwright MCP**, not a plain fetch:

```
browser_navigate  https://<official domain>/<path>
browser_evaluate  () => extract just the part you need
```

Why the browser: modern documentation renders in JavaScript, and a plain fetch
of such a page returns an empty shell. A real browser sees what a reader sees.

Why `browser_evaluate` over a full snapshot: a docs page's accessibility tree
runs to hundreds of kilobytes. Pull the section, the table, or the code block
you came for - `document.querySelector(...)`, the headings list, the fenced
code under a heading - and leave the rest on the page.

Close what you opened (`browser_close`) when the research is done. The snapshot
files the MCP writes belong in `.gitignore` (`.playwright-mcp/`), not in the
project's history.

## Source Order

| Rank | Source | Use for |
|------|--------|---------|
| 1 | Official documentation site | Behaviour, flags, shapes, limits |
| 2 | The project's own repository | What the docs left out: source, CHANGELOG, release notes, issues |
| 3 | Official blog / release announcements | Why something changed, and when |
| 4 | Community: Stack Overflow, blogs, forums | Leads and workarounds - verify against 1-3 before using |

Never let rank 4 become the answer. If a workaround exists only in a forum
post, say so explicitly when you use it.

## Reporting What You Found

- **Cite the page**, by URL, in the answer. "Per the hooks reference at
  code.claude.com/docs/en/hooks, `PreCompact` cannot inject context."
- **Quote the shape**, not your paraphrase of it, when exactness matters -
  JSON schemas, flag names, exit codes.
- **Date the finding** when the thing moves fast. Docs change; a claim from
  today's page is not a claim about last year's version.
- **Record it** if it will matter again: a line in
  `.claude/context/project.md` for an environment fact, an entry in
  `decisions.md` when it settled a choice.

## Red Flags - STOP

| Thought | Reality |
|---------|---------|
| "I know this API" | You know a version of it. Which one shipped here? |
| "The first search result says..." | That is a lead. Open the docs it was summarising. |
| "The docs are probably out of date" | Then read the repo's CHANGELOG. Do not substitute memory for either. |
| "It's a small detail, no need to check" | Small details are exactly what memory gets wrong: flag spellings, defaults, exit codes. |
| "The fetch came back empty, I'll go from what I remember" | Empty means JavaScript. Open it in the browser. |
| "I'll cite it if they ask" | An uncited claim is indistinguishable from a guess. |
