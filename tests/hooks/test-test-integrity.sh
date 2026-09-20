#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/test-integrity"

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
        printf '%s\n' "$value" | sed 's/^/        /' | head -12
    fi
}

new_repo() {
    local dir="$TEST_ROOT/$1"
    mkdir -p "$dir/tests" "$dir/src"
    git -C "$dir" init -q -b main
    git -C "$dir" config user.email "test@example.com"
    git -C "$dir" config user.name "Test"
    {
        echo "def test_rejects_zero_quantity():"
        echo "    assert validate(0) is False"
        echo "    assert error_of(0) == 'quantity must be positive'"
        echo ""
        echo "def test_accepts_one():"
        echo "    assert validate(1) is True"
    } > "$dir/tests/test_orders.py"
    echo "def validate(q): return q > 0" > "$dir/src/orders.py"
    git -C "$dir" add -A
    git -C "$dir" commit -q -m "init"
    printf '%s\n' "$dir"
}

run_hook() {
    printf '{"tool_name":"Bash","tool_input":{"command":"git commit -m work"}}' \
        | CLAUDE_PROJECT_DIR="$1" bash "$HOOK"
}

echo "Test integrity gate"

# --- honest change ------------------------------------------------------------
honest="$(new_repo honest)"
{
    echo "def test_rejects_zero_quantity():"
    echo "    assert validate(0) is False"
    echo "    assert error_of(0) == 'quantity must be positive'"
    echo ""
    echo "def test_accepts_one():"
    echo "    assert validate(1) is True"
    echo ""
    echo "def test_rejects_negative():"
    echo "    assert validate(-3) is False"
} > "$honest/tests/test_orders.py"
git -C "$honest" add -A
output="$(run_hook "$honest")"
assert_empty "adding a test says nothing" "$output"

# --- skip marker added ---------------------------------------------------------
skipped="$(new_repo skipped)"
{
    echo "import pytest"
    echo ""
    echo "@pytest.mark.skip(reason='flaky')"
    echo "def test_rejects_zero_quantity():"
    echo "    assert validate(0) is False"
    echo "    assert error_of(0) == 'quantity must be positive'"
    echo ""
    echo "def test_accepts_one():"
    echo "    assert validate(1) is True"
} > "$skipped/tests/test_orders.py"
git -C "$skipped" add -A
output="$(run_hook "$skipped")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" --deny "test_orders.py" "skip"; then
    pass "a newly skipped test blocks the commit"
else
    fail "a newly skipped test blocks the commit"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

# --- focusing one test hides the rest --------------------------------------------
focused="$(new_repo focused)"
mkdir -p "$focused/tests"
{
    echo "describe('orders', () => {"
    echo "  it.only('rejects zero', () => { expect(validate(0)).toBe(false); });"
    echo "});"
} > "$focused/tests/orders.test.js"
git -C "$focused" add -A
output="$(run_hook "$focused")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" --deny "orders.test.js"; then
    pass "an .only() focus blocks the commit"
else
    fail "an .only() focus blocks the commit"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

# --- deleting a test -------------------------------------------------------------
deleted="$(new_repo deleted)"
{
    echo "def test_rejects_zero_quantity():"
    echo "    assert validate(0) is False"
    echo "    assert error_of(0) == 'quantity must be positive'"
} > "$deleted/tests/test_orders.py"
git -C "$deleted" add -A
output="$(run_hook "$deleted")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" --deny "test_orders.py"; then
    pass "a net loss of test functions blocks the commit"
else
    fail "a net loss of test functions blocks the commit"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

# --- renaming a test is not a loss ------------------------------------------------
renamed="$(new_repo renamed)"
{
    echo "def test_rejects_zero_quantity_with_message():"
    echo "    assert validate(0) is False"
    echo "    assert error_of(0) == 'quantity must be positive'"
    echo ""
    echo "def test_accepts_one():"
    echo "    assert validate(1) is True"
} > "$renamed/tests/test_orders.py"
git -C "$renamed" add -A
output="$(run_hook "$renamed")"
assert_empty "renaming a test is not treated as deleting one" "$output"

# --- assertions quietly dropped ----------------------------------------------------
weakened="$(new_repo weakened)"
{
    echo "def test_rejects_zero_quantity():"
    echo "    assert validate(0) is False"
    echo ""
    echo "def test_accepts_one():"
    echo "    assert validate(1) is True"
} > "$weakened/tests/test_orders.py"
git -C "$weakened" add -A
output="$(run_hook "$weakened")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "test_orders.py" "assertion"; then
    pass "dropping assertions warns without blocking"
else
    fail "dropping assertions warns without blocking"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

# --- an explicit, justified change -------------------------------------------------
justified="$(new_repo justified)"
{
    echo "import pytest"
    echo ""
    echo "@pytest.mark.skip(reason='endpoint retired in decision 0012')  # pragma: test-change retired feature, owner approved"
    echo "def test_rejects_zero_quantity():"
    echo "    assert validate(0) is False"
    echo "    assert error_of(0) == 'quantity must be positive'"
    echo ""
    echo "def test_accepts_one():"
    echo "    assert validate(1) is True"
} > "$justified/tests/test_orders.py"
git -C "$justified" add -A
output="$(run_hook "$justified")"
assert_empty "a line carrying the test-change pragma is allowed through" "$output"

# --- production code is not policed by this gate -------------------------------------
source_only="$(new_repo source-only)"
echo "def validate(q): return True" > "$source_only/src/orders.py"
git -C "$source_only" add -A
output="$(run_hook "$source_only")"
assert_empty "changes outside test files are ignored" "$output"

echo
if [ "$FAILURES" -eq 0 ]; then
    echo "All test integrity tests passed"
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
