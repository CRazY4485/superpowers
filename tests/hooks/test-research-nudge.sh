#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/research-nudge"

FAILURES=0
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

assert_empty() {
    local description="$1" value="$2"
    if [ -z "$(printf '%s' "$value" | tr -d '[:space:]')" ]; then
        pass "$description"
    else
        fail "$description"
        printf '%s\n' "$value" | sed 's/^/        /' | head -10
    fi
}

run_hook() {
    printf '%s' "$2" | SUPERPOWERS_RESEARCH_STATE_DIR="$1" CLAUDE_PROJECT_DIR="$TEST_ROOT" bash "$HOOK"
}

echo "Research source nudge"

state="$TEST_ROOT/state"

output="$(run_hook "$state" '{"tool_name":"WebFetch","tool_input":{"url":"https://example.com/docs"}}')"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "Playwright" "official"; then
    pass "a WebFetch call is pointed at the browser and official docs"
else
    fail "a WebFetch call is pointed at the browser and official docs"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

output="$(run_hook "$state" '{"tool_name":"WebFetch","tool_input":{"url":"https://example.com/other"}}')"
assert_empty "the reminder is throttled after the first call" "$output"

output="$(run_hook "$TEST_ROOT/state-search" '{"tool_name":"WebSearch","tool_input":{"query":"claude code hooks"}}')"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "Playwright"; then
    pass "a WebSearch call is pointed at the browser too"
else
    fail "a WebSearch call is pointed at the browser too"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

output="$(run_hook "$TEST_ROOT/state-other" '{"tool_name":"Read","tool_input":{"file_path":"a.txt"}}')"
assert_empty "other tools are ignored" "$output"

output="$(run_hook "$TEST_ROOT/state-mcp" '{"tool_name":"mcp__plugin_playwright_playwright__browser_navigate","tool_input":{"url":"https://example.com"}}')"
assert_empty "using the browser itself is never nudged" "$output"

echo
if [ "$FAILURES" -eq 0 ]; then
    echo "All research nudge tests passed"
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
