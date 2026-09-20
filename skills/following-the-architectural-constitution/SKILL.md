---
name: following-the-architectural-constitution
description: Use before writing or reviewing any production code - the binding coding standard (Clean Code, SOLID, DRY, KISS, separation of concerns, determinism, error handling, naming, comments, security, testing) and what to do when a rule cannot be met
---

# Following The Architectural Constitution

## Overview

**Core principle: the standard is binding, and non-compliance is a defect - not
a matter of taste and not a style preference.**

The full text lives beside this skill: **`ARCHITECTURAL_CONSTITUTION.md`**.
Read it before writing code in a project that adopts it, and read the relevant
section again before a review. It is the single source of truth for
architectural and coding decisions; this skill is only the way in.

## When It Binds

Every change to production code: new modules, edits to existing ones, and the
code a subagent is briefed to write. It does not govern agent workflow - that is
the superpowers process skills - and it does not govern project facts like
stack versions or numeric budgets, which live in the project's own context.

## The Shape Of It

| Section | The rule it enforces |
|---------|---------------------|
| Clean Code · SOLID · DRY · KISS | One thing per function, one reason to change per module, one authoritative representation per piece of knowledge, simplest solution that fully satisfies the requirement |
| Separation of Concerns | Presentation, logic and data access stay apart; business logic imports no framework, driver or vendor client; cross-cutting concerns are wrapped, never inlined |
| Deterministic Code | Same inputs, same outputs; every non-deterministic dependency - clock, randomness, filesystem, network, environment - is injected so a test can control it |
| Modular Structure · Portability | Public APIs only, no circular dependencies, thin entry points; no hardcoded paths, no OS-specific shell calls in application code, UTF-8 and LF |
| Naming | Descriptive, one word per concept across the whole system, units in the name |
| Error Handling & Logging | Nothing swallowed, boundaries validated, structured logs with a propagated `run_id`, secrets never logged |
| Time, Units, Precision | UTC, explicit timezones, typed durations, no binary floating point for money, explicit rounding |
| Concurrency & Resource Lifecycle | No unbounded wait, queue or retry; retries only where idempotent; every resource released on every path |
| Configuration · Security | Config bound in one unit and validated at startup; least privilege; fail closed; parameterised queries; pinned, audited dependencies |
| Interfaces & Compatibility | A public interface changes only deliberately, with a version marker and a migration path |
| Code Comments | Comment the why; document purpose, parameters, returns, side effects and error cases on every public function |
| Testing Standards | Every behaviour change ships with a test; deterministic; one behaviour per test; boundaries and failure paths, not only the happy path |

## The Deviation Procedure

A rule that cannot be met is not a rule to ignore quietly.

1. **Stop before writing the non-compliant code.** Say which rule is in the way
   and why the straightforward compliant version does not work here.
2. **Take it to the owner** in outcome language: what the rule protects, what
   breaking it costs, and what you propose instead.
3. **Record the decision** with `superpowers:reconciling-decisions` - the
   deviation, its reason, its evidence, and its scope. An unrecorded deviation
   becomes the codebase's new habit.
4. **Bound it.** A deviation applies to the named case, not to everything that
   resembles it.

## Reading It Well

- **Length limits are smell signals, not instructions.** The document says so
  explicitly: 20/40 lines for functions, 800 for files. Splitting to satisfy a
  count produces shallow helpers that scatter the logic - worse than the long
  function was. Extraction is justified by cohesion, never by length.
- **The generality test applies to the document itself**: a rule belongs in it
  only if it would still be correct on a different project in a different
  domain. Project facts belong in the project's context files.
- **Never weaken a test, a type check, or a linter rule to make a change pass.**
  The document names this as a violation regardless of how small the change
  looks; `superpowers:keeping-tests-honest` is the procedure when the pressure
  arrives.

## Red Flags - STOP

| Thought | Reality |
|---------|---------|
| "This is a small script, the standard is overkill" | Small scripts become the thing everything depends on. Decide deliberately, with the owner. |
| "I'll clean it up in a follow-up" | The follow-up competes with the next feature and loses. |
| "The existing code does it this way" | Then either the standard or the code is wrong. Say which, out loud. |
| "I'll split this function to get under 20 lines" | Splitting for a count scatters logic. Extract for cohesion or justify the length in one sentence. |
| "It needs the clock/network directly, injecting it is ceremony" | That is exactly the line between testable and untestable code. |
| "I'll add the docstring at the end" | The checklist is part of the change, not a chore after it. |
| "No time to record the deviation" | An unrecorded deviation is indistinguishable from an accident. |
