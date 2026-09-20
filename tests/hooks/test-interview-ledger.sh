#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/interview-context"

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
        printf '%s\n' "$value" | sed 's/^/      /' | head -10
    fi
}

make_project() {
    local dir="$TEST_ROOT/$1"
    mkdir -p "$dir/.claude/context"
    printf '%s\n' "$dir"
}

run_hook() {
    CLAUDE_PROJECT_DIR="$1" \
    SUPERPOWERS_INTERVIEW_STATE_DIR="$2" \
    bash "$HOOK"
}

write_ledger() {
    local dir="$1" status="$2"
    {
        echo "# Interview: import pipeline"
        echo "Status: $status"
        echo "Started: 2026-09-20"
        echo
        echo "## Q01 [answered] Target database"
        echo "**Asked:** Which database should the pipeline write to?"
        echo "**Answer:** \"Postgres, we already run it for billing\""
        echo
        echo "## Q02 [deferred: the API contract is fixed] Retry limits"
        echo "**Asked:** How many retries before giving up?"
        echo
        echo "## Q03 [open] Auth model"
        echo "**Asked:** Which identity provider issues the tokens?"
        echo
        echo "## Q04 [answered] Schedule"
        echo "**Answer:** \"hourly is enough, ANSWERED_BODY_MARKER\""
    } > "$dir/.claude/context/interview.md"
}

echo "Interview ledger injection"

# --- no ledger -> silence ----------------------------------------------------
bare="$(make_project bare)"
output="$(run_hook "$bare" "$TEST_ROOT/state-bare")"
assert_empty "no ledger file emits nothing" "$output"

# --- closed ledger -> silence ------------------------------------------------
closed="$(make_project closed)"
write_ledger "$closed" "closed"
output="$(run_hook "$closed" "$TEST_ROOT/state-closed")"
assert_empty "closed ledger emits nothing" "$output"

# --- active ledger: open and deferred items are carried forward --------------
active="$(make_project active)"
write_ledger "$active" "active"
output="$(run_hook "$active" "$TEST_ROOT/state-active")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-prompt-context.cjs" \
    "Q03" "Auth model" "Q02" "Retry limits" "the API contract is fixed" \
    "2 answered" "1 open" "1 deferred" \
    "superpowers:keeping-an-interview-ledger"; then
    pass "open and deferred items are injected with counts"
else
    fail "open and deferred items are injected with counts"
    printf '%s\n' "$output" | sed 's/^/      /'
fi

if printf '%s' "$output" | node "$SCRIPT_DIR/assert-prompt-context.cjs" --absent \
    "ANSWERED_BODY_MARKER"; then
    pass "answered bodies are not re-injected"
else
    fail "answered bodies are not re-injected"
fi

# --- cap on how many items ride along ----------------------------------------
many="$(make_project many)"
{
    echo "# Interview: big one"
    echo "Status: active"
    for i in $(seq 1 20); do
        printf '## Q%02d [open] Question number %02d\n' "$i" "$i"
    done
} > "$many/.claude/context/interview.md"
output="$(SUPERPOWERS_INTERVIEW_MAX_ITEMS=5 run_hook "$many" "$TEST_ROOT/state-many")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-prompt-context.cjs" \
    "Question number 01" "15 more in the file"; then
    pass "item list is capped and the remainder is disclosed"
else
    fail "item list is capped and the remainder is disclosed"
    printf '%s\n' "$output" | sed 's/^/      /'
fi

if printf '%s' "$output" | node "$SCRIPT_DIR/assert-prompt-context.cjs" --absent \
    "Question number 06"; then
    pass "items past the cap are left out"
else
    fail "items past the cap are left out"
fi

# --- unrecorded-answer warning ------------------------------------------------
echo
echo "Unrecorded answer detection"
warn="$(make_project warn)"
write_ledger "$warn" "active"
warn_state="$TEST_ROOT/state-warn"

output="$(run_hook "$warn" "$warn_state")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-prompt-context.cjs" --absent \
    "not changed since"; then
    pass "first prompt of a session does not warn"
else
    fail "first prompt of a session does not warn"
fi

output="$(run_hook "$warn" "$warn_state")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-prompt-context.cjs" \
    "not changed since"; then
    pass "a prompt arriving with an untouched ledger warns"
else
    fail "a prompt arriving with an untouched ledger warns"
    printf '%s\n' "$output" | sed 's/^/      /'
fi

sleep 1
write_ledger "$warn" "active"
output="$(run_hook "$warn" "$warn_state")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-prompt-context.cjs" --absent \
    "not changed since"; then
    pass "recording an answer clears the warning"
else
    fail "recording an answer clears the warning"
    printf '%s\n' "$output" | sed 's/^/      /'
fi

echo
if [ "$FAILURES" -eq 0 ]; then
    echo "All interview ledger tests passed"
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
