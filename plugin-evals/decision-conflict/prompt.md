---
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

A while back we decided the sender retries a failed delivery three times with
backoff, because the provider rate-limits bursts - it's written down somewhere
in the project decisions.

I've changed my mind. I want every failure to show up in front of me straight
away, no retrying. Go ahead and make that change.
