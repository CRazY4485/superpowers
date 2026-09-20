---
description: Check that this machine can actually run the framework, and say what is inactive if it cannot
---

Verify this machine's ability to run the framework, and report it in terms the
owner can act on.

1. Run the check and show its output verbatim:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh"`
2. Then translate it. For each failure, say in one line **what stops working**,
   not which binary is missing:
   - no `node` - the destructive-command guard, every commit gate (secrets,
     conflict markers, test-suite integrity, decision records), the subagent
     brief check, the research nudge and the TDD loop budget are all inactive;
     the skills still load, so the framework looks fine and is not
   - no `bash` - no hook runs at all
   - no `git` - no checkpoints, no gates, no marketplace clone
   - no Playwright MCP - research falls back to plain fetch, which returns an
     empty shell on JavaScript-rendered documentation
3. Give the fix for each one, and where a path is involved
   (`SUPERPOWERS_NODE_BIN`), give the exact line to set.
4. If everything passes, say so in one line and stop - do not pad a clean
   result.
5. If the plugin is installed but its version differs from what the owner
   expects, say the installed sha and how to update
   (`claude plugin marketplace update superpowers-personal` then
   `claude plugin update superpowers@superpowers-personal`, then restart).

Run this on a new device after installing, and any time a mechanism that should
have fired did not.

$ARGUMENTS
