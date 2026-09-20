#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LINT="$REPO_ROOT/hooks/decision-lint"
GATE="$REPO_ROOT/hooks/decision-gate"

FAILURES=0
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

assert_contains() {
    local description="$1" haystack="$2" needle="$3"
    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        pass "$description"
    else
        fail "$description"
        echo "      expected to find: $needle"
        printf '%s\n' "$haystack" | sed 's/^/        /' | head -12
    fi
}

assert_empty() {
    local description="$1" value="$2"
    if [ -z "$(printf '%s' "$value" | tr -d '[:space:]')" ]; then
        pass "$description"
    else
        fail "$description"
        printf '%s\n' "$value" | sed 's/^/        /' | head -12
    fi
}

write_file() {
    mkdir -p "$(dirname "$1")"
    cat > "$1"
}

echo "Decision record linter"

good="$TEST_ROOT/good.md"
write_file "$good" <<'EOF'
# Decisions

## D0001 | 2026-01-05 | superseded | scope: storage/database
**Decision:** Use SQLite for the first release.
**Why:** One machine, one writer, no operations budget in month one.
**Evidence:** owner interview Q4, 2026-01-05; docs/specs/2026-01-04-storage.md
**Rejected:** Postgres - nothing to run it on yet.

## D0002 | 2026-03-11 | active | scope: storage/database
**Decision:** Move to Postgres before the multi-user release.
**Why:** Two writers appeared in the plan, and SQLite's single-writer lock is the constraint that breaks.
**Evidence:** measured 4 write conflicts/min in the load run, 2026-03-10; decision D0001
**Supersedes:** D0001
EOF
output="$(bash "$LINT" "$good" 2>&1 || true)"
assert_empty "a well-formed decision log lints clean" "$output"

missing="$TEST_ROOT/missing.md"
write_file "$missing" <<'EOF'
## D0003 | 2026-04-01 | active | scope: auth/session
**Decision:** Sessions expire after 15 minutes.
EOF
output="$(bash "$LINT" "$missing" 2>&1 || true)"
assert_contains "a decision with no Why is an error" "$output" "D0003"
assert_contains "the missing field is named" "$output" "Why"
assert_contains "missing Evidence is reported too" "$output" "Evidence"

assumed="$TEST_ROOT/assumed.md"
write_file "$assumed" <<'EOF'
## D0004 | 2026-04-02 | active | scope: auth/tokens
**Decision:** Store refresh tokens in local storage.
**Why:** It is probably what the front end expects.
**Evidence:** I assume the mobile client does the same.
EOF
output="$(bash "$LINT" "$assumed" 2>&1 || true)"
assert_contains "evidence that is an assumption is an error" "$output" "D0004"
assert_contains "the reason says it is an assumption" "$output" "assumption"

dupes="$TEST_ROOT/dupes.md"
write_file "$dupes" <<'EOF'
## D0005 | 2026-04-03 | active | scope: api/versioning
**Decision:** Version the API in the path.
**Why:** Clients pin a version and upgrade deliberately.
**Evidence:** owner requirement, 2026-04-03

## D0005 | 2026-04-04 | active | scope: api/errors
**Decision:** Errors carry a machine-readable code.
**Why:** The owner's dashboard needs to group failures without parsing prose.
**Evidence:** owner interview Q9, 2026-04-04
EOF
output="$(bash "$LINT" "$dupes" 2>&1 || true)"
assert_contains "a duplicate decision id is an error" "$output" "duplicate"

dangling="$TEST_ROOT/dangling.md"
write_file "$dangling" <<'EOF'
## D0006 | 2026-04-05 | active | scope: billing/currency
**Decision:** Store amounts in minor units as integers.
**Why:** Binary floating point cannot represent money exactly.
**Evidence:** docs/ARCHITECTURAL_CONSTITUTION.md, Time Units and Precision
**Supersedes:** D0099
EOF
output="$(bash "$LINT" "$dangling" 2>&1 || true)"
assert_contains "superseding a decision that does not exist is an error" "$output" "D0099"

stale_status="$TEST_ROOT/stale-status.md"
write_file "$stale_status" <<'EOF'
## D0007 | 2026-04-06 | active | scope: billing/rounding
**Decision:** Round half up, two digits, at the boundary.
**Why:** Matches what the accountant reconciles against.
**Evidence:** owner message, 2026-04-06

## D0008 | 2026-04-07 | active | scope: billing/rounding-new
**Decision:** Round half even, two digits, at the boundary.
**Why:** The payment processor rounds half even and the totals must agree.
**Evidence:** processor documentation, checked 2026-04-07
**Supersedes:** D0007
EOF
output="$(bash "$LINT" "$stale_status" 2>&1 || true)"
assert_contains "a superseded decision still marked active is an error" "$output" "D0007"

overlap="$TEST_ROOT/overlap.md"
write_file "$overlap" <<'EOF'
## D0009 | 2026-04-08 | active | scope: delivery/retries
**Decision:** Retry three times with exponential backoff.
**Why:** The downstream service rate-limits bursts.
**Evidence:** provider docs, checked 2026-04-08

## D0010 | 2026-04-09 | active | scope: delivery/retries
**Decision:** Never retry automatically; surface the failure.
**Why:** The owner wants to see every failure rather than have it hidden.
**Evidence:** owner message, 2026-04-09
EOF
output="$(bash "$LINT" "$overlap" 2>&1 || true)"
assert_contains "two active decisions on one scope are flagged" "$output" "delivery/retries"
assert_contains "the overlap asks for reconciliation, not a hard error" "$output" "WARN"

nonmonotonic="$TEST_ROOT/nonmonotonic.md"
write_file "$nonmonotonic" <<'EOF'
## D0007 | 2026-05-01 | active | scope: api/limits
**Decision:** Cap page size at 200.
**Why:** Larger pages time out against the report query.
**Evidence:** measured 12s at 500 rows, 2026-05-01

## D0005 | 2026-05-02 | active | scope: api/sorting
**Decision:** Sort by created_at descending by default.
**Why:** The owner reads newest first.
**Evidence:** owner message, 2026-05-02
EOF
output="$(bash "$LINT" "$nonmonotonic" 2>&1 || true)"
assert_contains "a decision id that goes backwards is an error" "$output" "D0005"
assert_contains "the reason names the ordering rule" "$output" "increase"

echo
echo "Decision gate"

new_repo() {
    local dir="$TEST_ROOT/$1"
    mkdir -p "$dir/.claude/context"
    git -C "$dir" init -q -b main
    git -C "$dir" config user.email "test@example.com"
    git -C "$dir" config user.name "Test"
    echo "code" > "$dir/a.txt"
    git -C "$dir" add -A
    git -C "$dir" commit -q -m init
    printf '%s\n' "$dir"
}

run_gate() {
    printf '{"tool_name":"Bash","tool_input":{"command":"git commit -m work"}}' \
        | CLAUDE_PROJECT_DIR="$1" bash "$GATE"
}

clean="$(new_repo clean)"
cp "$good" "$clean/.claude/context/decisions.md"
git -C "$clean" add -A
output="$(run_gate "$clean")"
assert_empty "a clean decision log commits without comment" "$output"

broken="$(new_repo broken)"
cp "$missing" "$broken/.claude/context/decisions.md"
git -C "$broken" add -A
output="$(run_gate "$broken")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" --deny "D0003"; then
    pass "an unjustified decision blocks the commit"
else
    fail "an unjustified decision blocks the commit"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

warned="$(new_repo warned)"
cp "$overlap" "$warned/.claude/context/decisions.md"
git -C "$warned" add -A
output="$(run_gate "$warned")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "delivery/retries"; then
    pass "an unreconciled overlap warns without blocking"
else
    fail "an unreconciled overlap warns without blocking"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

removed="$(new_repo removed)"
removable="$TEST_ROOT/removable.md"
write_file "$removable" <<'EOF'
## D0020 | 2026-06-01 | active | scope: ui/theme
**Decision:** Ship a single light theme.
**Why:** One theme to maintain until there is demand for more.
**Evidence:** owner message, 2026-06-01

## D0021 | 2026-06-02 | active | scope: ui/locale
**Decision:** Dates render in the viewer's locale.
**Why:** The owner and the accountant are in different regions.
**Evidence:** owner message, 2026-06-02
EOF
cp "$removable" "$removed/.claude/context/decisions.md"
git -C "$removed" add -A
git -C "$removed" commit -q -m "record decisions"
# Delete D0020 outright - nothing references it, so only the reuse rule can catch this.
awk '/^## D0020/{skip=1} /^## D0021/{skip=0} !skip' "$removable" > "$removed/.claude/context/decisions.md"
git -C "$removed" add -A
output="$(run_gate "$removed")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" --deny "D0020"; then
    pass "deleting a decision id from the log blocks the commit"
else
    fail "deleting a decision id from the log blocks the commit"
    printf '%s
' "$output" | sed 's/^/        /'
fi

untouched="$(new_repo untouched)"
echo "change" >> "$untouched/a.txt"
git -C "$untouched" add -A
output="$(run_gate "$untouched")"
assert_empty "a commit that touches no decision file is ignored" "$output"

echo
if [ "$FAILURES" -eq 0 ]; then
    echo "All decision lint tests passed"
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
