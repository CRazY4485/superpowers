---
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

Don't go looking at the repo, I'll give you what you need - I want to see the
briefs before anything runs.

The project: a Python service. The CSV importer is `src/import/rows.py`, its
tests are in `tests/import/test_rows.py`. Database migrations live in
`migrations/`, applied with Alembic. The suite runs with `pytest -q`. Stack
facts and commands are in `.claude/context/project.md`; decision D0006 says
money is stored in integer minor units.

I want to parallelise two jobs: one agent adds input validation to the CSV
importer (reject rows with zero or negative quantity), another writes the
Alembic migration for a new `currency` column on the orders table.

Show me the exact briefs you would send each agent.
