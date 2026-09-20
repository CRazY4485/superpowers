#!/usr/bin/env bash
# Check that this machine can actually run the framework, and say which
# mechanisms are inactive if it cannot.
#
#   bash scripts/doctor.sh
#
# Run it on a new device after installing the plugin. Everything here fails
# quietly in normal use, which is exactly why it needs a loud check.

set -uo pipefail

NODE_BIN="${SUPERPOWERS_NODE_BIN:-node}"
problems=0

ok()   { printf '  [ ok ] %s\n' "$1"; }
bad()  { printf '  [FAIL] %s\n' "$1"; problems=$((problems + 1)); }
warn() { printf '  [warn] %s\n' "$1"; }

echo "Prerequisites"

if command -v git >/dev/null 2>&1; then
    ok "git - $(git --version | head -1)"
else
    bad "git not found. Without it there is no marketplace clone, no checkpoints, no gates"
fi

if command -v bash >/dev/null 2>&1; then
    ok "bash - ${BASH_VERSION:-unknown}"
else
    bad "bash not found. On Windows install Git for Windows; hooks/run-hook.cmd needs it"
fi

if command -v "$NODE_BIN" >/dev/null 2>&1; then
    ok "node - $("$NODE_BIN" --version 2>/dev/null)"
else
    bad "node not found (looked for '${NODE_BIN}'). Set SUPERPOWERS_NODE_BIN if it lives elsewhere."
    printf '         Silently inactive without it: the destructive-command guard,\n'
    printf '         the commit gates (secrets, conflict markers, test integrity,\n'
    printf '         decision records), the subagent brief check, the research nudge,\n'
    printf '         and the TDD loop budget.\n'
fi

for tool in awk sed grep cksum find date; do
    command -v "$tool" >/dev/null 2>&1 && ok "$tool" || bad "$tool not found - core hook plumbing needs it"
done

echo
echo "Installation"

if command -v claude >/dev/null 2>&1; then
    ok "claude CLI on PATH"
    if claude plugin list 2>/dev/null | grep -q "superpowers@superpowers-personal"; then
        ok "plugin installed: superpowers@superpowers-personal"
        claude plugin list 2>/dev/null | grep -A2 "superpowers@superpowers-personal" \
            | sed 's/^/        /'
    else
        bad "plugin not installed. Run: claude plugin marketplace add CRazY4485/superpowers && claude plugin install superpowers@superpowers-personal"
    fi
else
    warn "claude CLI not on PATH - cannot check the installed plugin from here"
fi

echo
echo "Optional"

if claude mcp list 2>/dev/null | grep -qi playwright; then
    ok "Playwright MCP present - the research policy can be followed as written"
else
    warn "Playwright MCP not detected. The research skill still applies, but browsing falls back to plain fetch, which returns an empty shell on JavaScript-rendered documentation"
fi

echo
if [ "$problems" -eq 0 ]; then
    echo "No problems found."
else
    echo "${problems} problem(s) found - the mechanisms listed above are not protecting anything until they are fixed."
    exit 1
fi
