#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/brief-check"

FAILURES=0

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

assert_empty() {
    local description="$1" value="$2"
    if [ -z "$(printf '%s' "$value" | tr -d '[:space:]')" ]; then
        pass "$description"
    else
        fail "$description"
        printf '%s\n' "$value" | sed 's/^/        /' | head -12
    fi
}

run_hook() {
    printf '%s' "$1" | bash "$HOOK"
}

payload() {
    node -e '
const prompt = process.argv[1];
process.stdout.write(JSON.stringify({
  tool_name: process.argv[2] || "Agent",
  tool_input: { description: "do the thing", prompt, subagent_type: "general-purpose" }
}));' "$1" "${2:-Agent}"
}

complete_brief=$(cat <<'EOF'
Goal: make the CSV importer reject rows whose quantity is zero or negative,
so the owner stops seeing phantom orders in the daily report.

Read first: .claude/context/project.md for the stack and the test command,
.claude/context/decisions.md entry D0006 on minor-unit amounts, and
docs/superpowers/plans/2026-09-20-import.md task 3.

Scope: src/import/rows.py and its test only. Do not touch the CLI, the
schedulers, or any other module; if the change seems to require it, stop and
report instead.

Acceptance: a new test in tests/import/test_rows.py fails before the change and
passes after it; the full suite passes with `pytest -q`; no existing test is
skipped or weakened.

Report back: the diff you made, the test output verbatim, and anything you
found that was out of scope.
EOF
)

echo "Subagent brief check"

output="$(run_hook "$(payload "$complete_brief")")"
assert_empty "a complete brief passes without comment" "$output"

missing_acceptance=$(cat <<'EOF2'
Goal: make the CSV importer reject rows whose quantity is zero or negative, so
the owner stops seeing phantom orders in the daily report.

Read first: .claude/context/project.md for the stack, .claude/context/decisions.md
entry D0006, and docs/superpowers/plans/2026-09-20-import.md task 3.

Scope: src/import/rows.py only. Do not touch the CLI or the schedulers; if the
change seems to require it, stop and report instead.

Report back: the diff you made and anything you found that was out of bounds.
EOF2
)
output="$(run_hook "$(payload "$missing_acceptance")")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "verif"; then
    pass "a brief with no way to verify the work is flagged"
else
    fail "a brief with no way to verify the work is flagged"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

missing_scope=$(cat <<'EOF3'
Goal: make the CSV importer reject rows whose quantity is zero or negative, so
the owner stops seeing phantom orders in the daily report.

Read first: .claude/context/project.md for the stack, .claude/context/decisions.md
entry D0006, and docs/superpowers/plans/2026-09-20-import.md task 3.

Acceptance: a new test fails before the change and passes after it, and the full
suite passes with `pytest -q`.

Report back: the diff you made and the test output, word for word.
EOF3
)
output="$(run_hook "$(payload "$missing_scope")")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "scope"; then
    pass "a brief with no scope boundary is flagged"
else
    fail "a brief with no scope boundary is flagged"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

thin="Fix the importer bug."
output="$(run_hook "$(payload "$thin")")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "cold"; then
    pass "a one-line brief is flagged as starting the agent cold"
else
    fail "a one-line brief is flagged as starting the agent cold"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

output="$(run_hook "$(payload "$thin" "Read")")"
assert_empty "other tools are ignored" "$output"

echo
if [ "$FAILURES" -eq 0 ]; then
    echo "All brief check tests passed"
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
