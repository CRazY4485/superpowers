#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/commit-nudge"

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

new_repo() {
    local dir="$TEST_ROOT/$1"
    mkdir -p "$dir"
    git -C "$dir" init -q
    git -C "$dir" config user.email "test@example.com"
    git -C "$dir" config user.name "Test"
    echo "one" > "$dir/a.txt"
    git -C "$dir" add -A
    git -C "$dir" commit -q -m "init"
    printf '%s\n' "$dir"
}

commit_at() {
    local stamp
    stamp=$(date -d "$2" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || printf '%s' "$2")
    git -C "$1" add -A
    GIT_AUTHOR_DATE="$stamp" GIT_COMMITTER_DATE="$stamp" git -C "$1" commit -q -m "$3"
}

run_nudge() {
    CLAUDE_PROJECT_DIR="$1" \
    SUPERPOWERS_COMMIT_NUDGE_STATE_DIR="$2" \
    bash "$HOOK"
}

echo "Uncommitted work nudge"

# --- not a repo ---------------------------------------------------------------
plain="$TEST_ROOT/plain"
mkdir -p "$plain"
output="$(run_nudge "$plain" "$TEST_ROOT/state-plain")"
assert_empty "outside a git repo nothing is said" "$output"

# --- clean tree ----------------------------------------------------------------
clean="$(new_repo clean)"
output="$(run_nudge "$clean" "$TEST_ROOT/state-clean")"
assert_empty "a clean tree is never nudged" "$output"

# --- small, recent change -------------------------------------------------------
small="$(new_repo small)"
echo "edit" >> "$small/a.txt"
output="$(run_nudge "$small" "$TEST_ROOT/state-small")"
assert_empty "one file changed right after a commit is not nudged" "$output"

# --- many files changed ---------------------------------------------------------
wide="$(new_repo wide)"
for i in 1 2 3 4 5 6; do
    echo "content $i" > "$wide/file-$i.txt"
done
output="$(run_nudge "$wide" "$TEST_ROOT/state-wide")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-stop-context.cjs" \
    "6 files" "superpowers:recovering-work-with-git"; then
    pass "a wide uncommitted change is nudged"
else
    fail "a wide uncommitted change is nudged"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

output="$(run_nudge "$wide" "$TEST_ROOT/state-wide")"
assert_empty "the nudge is throttled on the next turn" "$output"

# --- dirty for a long time ------------------------------------------------------
stale="$(new_repo stale)"
echo "second" > "$stale/b.txt"
commit_at "$stale" "3 hours ago" "older commit"
echo "long running edit" >> "$stale/a.txt"
output="$(run_nudge "$stale" "$TEST_ROOT/state-stale")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-stop-context.cjs" "since the last commit"; then
    pass "work left uncommitted for hours is nudged even when small"
else
    fail "work left uncommitted for hours is nudged even when small"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

# --- ignored files do not count --------------------------------------------------
ignored="$(new_repo ignored)"
printf 'junk/\n' > "$ignored/.gitignore"
git -C "$ignored" add -A
git -C "$ignored" commit -q -m "ignore rules"
mkdir -p "$ignored/junk"
for i in 1 2 3 4 5 6 7; do
    echo "noise" > "$ignored/junk/file-$i.txt"
done
output="$(run_nudge "$ignored" "$TEST_ROOT/state-ignored")"
assert_empty "ignored files are not counted as uncommitted work" "$output"

echo
if [ "$FAILURES" -eq 0 ]; then
    echo "All commit nudge tests passed"
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
