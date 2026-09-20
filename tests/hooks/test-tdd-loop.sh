#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOOP="$REPO_ROOT/hooks/tdd-loop"
SUBAGENT="$REPO_ROOT/hooks/subagent-streak"

FAILURES=0
TEST_ROOT="$(mktemp -d)"
STATE="$TEST_ROOT/state"
trap 'rm -rf "$TEST_ROOT"' EXIT

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

assert_empty() {
    local description="$1" value="$2"
    if [ -z "$(printf '%s' "$value" | tr -d '[:space:]')" ]; then
        pass "$description"
    else
        fail "$description"
        printf '%s\n' "$value" | sed 's/^/        /' | head -8
    fi
}

assert_says() {
    local description="$1" payload="$2" needle="$3"
    if printf '%s' "$payload" | node "$SCRIPT_DIR/assert-posttooluse.cjs" "$needle"; then
        pass "$description"
    else
        fail "$description"
        printf '%s\n' "$payload" | sed 's/^/        /' | head -8
    fi
}

# run_event <event> <command> <output>
run_event() {
    node -e '
const [event, command, output] = process.argv.slice(1);
process.stdout.write(JSON.stringify({
  hook_event_name: event,
  tool_name: "Bash",
  tool_input: { command },
  tool_response: { stdout: output, stderr: "" }
}));' "$1" "$2" "$3" | SUPERPOWERS_TDD_STATE_DIR="$STATE" \
        SUPERPOWERS_TDD_SOFT_LIMIT=3 SUPERPOWERS_TDD_HARD_LIMIT=5 \
        CLAUDE_PROJECT_DIR="$TEST_ROOT" bash "$LOOP"
}

fail_run() { run_event "PostToolUseFailure" "$1" "1 failed, 4 passed"; }
pass_run() { run_event "PostToolUse" "$1" "5 passed in 0.31s"; }

echo "TDD loop budget"

output="$(run_event PostToolUse "ls -la" "a.txt")"
assert_empty "a command that is not a test run is ignored" "$output"

output="$(fail_run "pytest -q tests/import")"
assert_empty "the first failing run says nothing" "$output"
output="$(fail_run "pytest -q tests/import")"
assert_empty "the second failing run says nothing" "$output"

output="$(fail_run "pytest -q tests/import")"
assert_says "the soft limit names the streak" "$output" "3"
assert_says "the soft limit raises the possibility that the test is wrong" "$output" "test itself"

output="$(fail_run "pytest -q tests/import")"
assert_says "past the soft limit it keeps saying so" "$output" "4"

output="$(fail_run "pytest -q tests/import")"
assert_says "the hard limit says to stop and report" "$output" "Stop"
assert_says "the hard limit names who must hear about it" "$output" "human partner"

output="$(pass_run "pytest -q tests/import")"
assert_empty "a passing run says nothing" "$output"
output="$(fail_run "pytest -q tests/import")"
assert_empty "and it reset the streak" "$output"

output="$(fail_run "npm test")"
assert_empty "a different command keeps its own streak" "$output"

echo
echo "Subagent handback"

run_subagent() {
    printf '{"hook_event_name":"SubagentStop","agent_type":"general-purpose","agent_id":"a1","last_assistant_message":"%s"}' "$1" \
        | SUPERPOWERS_TDD_STATE_DIR="$STATE" SUPERPOWERS_TDD_SOFT_LIMIT=3 \
          CLAUDE_PROJECT_DIR="$TEST_ROOT" bash "$SUBAGENT"
}

# Build a live streak, then let the subagent finish on top of it.
for _ in 1 2 3; do fail_run "pytest -q tests/import" > /dev/null; done
output="$(run_subagent "Implemented the validation, tests are green.")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-subagentstop.cjs" "consecutive failing runs" "pytest"; then
    pass "a subagent that ends on an unresolved streak is reported to its dispatcher"
else
    fail "a subagent that ends on an unresolved streak is reported to its dispatcher"
    printf '%s\n' "$output" | sed 's/^/        /' | head -8
fi

output="$(run_subagent "Done.")"
assert_empty "the report is not repeated for the next subagent" "$output"

echo
if [ "$FAILURES" -eq 0 ]; then
    echo "All tdd loop tests passed"
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
