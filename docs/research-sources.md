# Research sources

Fork-local rule: anything that depends on someone else's API, library, CLI or
version is answered from **the vendor's own documentation**, read in a real
browser - not from recollection, and not from a blog.

## Why the browser

Modern documentation renders in JavaScript. A plain fetch of such a page
returns an empty shell, and an agent that treats that emptiness as "nothing
found" falls back on memory - which is a snapshot of a training set, not of the
version installed here. The Playwright MCP (`browser_navigate`, then a targeted
`browser_evaluate`) sees what a reader sees.

`browser_evaluate` rather than a full snapshot: a docs page's accessibility tree
runs to hundreds of kilobytes. Pull the section, table or code block you came
for and leave the rest on the page.

## The mechanism

| Piece | Role |
|-------|------|
| `skills/researching-with-official-docs` | The method: how to look, the source order, how to report and record what was found |
| `hooks/research-nudge` | `PreToolUse` on `WebFetch\|WebSearch`. Points at the browser and the official domain, once per hour per project. Never blocks - a static page is sometimes cheaper to fetch |
| `plugin-evals/official-docs` | Measures the failure mode: confident API specifics with no verification path fails; checking or naming the official source passes |

## Source order

1. Official documentation site - behaviour, flags, shapes, limits.
2. The project's own repository - source, CHANGELOG, release notes, issues.
3. Official blog and release announcements - why something changed, and when.
4. Community (Stack Overflow, blogs, forums) - **leads to verify**, never the
   answer. If a workaround exists only in a forum post, say so when using it.

## Reporting

Cite the page by URL. Quote shapes exactly when exactness matters - JSON
schemas, flag names, exit codes. Date the finding when the thing moves fast.
Record it in `.claude/context/` if it will matter again.

This was not an abstract rule during this fork's own development: the hook that
counts failing test runs was emitting a payload the harness silently discarded,
and the reason was one line in the official hooks reference about matching the
event name. Reading it took a minute; guessing would have cost the mechanism.

## Housekeeping

The Playwright MCP writes `page-*.yml` snapshots into the working directory.
`.playwright-mcp/` belongs in `.gitignore` - a 650KB accessibility dump has no
business in a project's history.
