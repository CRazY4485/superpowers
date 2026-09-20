#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DRIFT="$REPO_ROOT/hooks/doc-drift"

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

commit_at() {
    local dir="$1" message="$2" when="$3" stamp
    stamp=$(date -d "$when" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || printf '%s' "$when")
    git -C "$dir" add -A
    GIT_AUTHOR_DATE="$stamp" GIT_COMMITTER_DATE="$stamp" git -C "$dir" commit -q -m "$message"
}

new_project() {
    local dir="$TEST_ROOT/$1"
    mkdir -p "$dir/.claude/context" "$dir/docs/superpowers/specs" "$dir/docs/superpowers/plans" "$dir/src"
    git -C "$dir" init -q -b main
    git -C "$dir" config user.email "test@example.com"
    git -C "$dir" config user.name "Test"
    echo "code" > "$dir/src/app.py"
    commit_at "$dir" "init" "10 days ago"
    printf '%s\n' "$dir"
}

spec_with() {
    printf -- '---\nstatus: %s\ncreated: 2026-01-01\ndecisions: D0001\n---\n\n# Spec\n' "$1"
}

plan_with() {
    printf -- '---\nstatus: %s\ncreated: 2026-01-02\nderived-from: docs/superpowers/specs/2026-01-01-a-design.md\ndecisions: D0001\n%s---\n\n# Plan\n' "$1" "${2:-}"
}

echo "Document drift against history"

# --- outside a git repo ---------------------------------------------------------
plain="$TEST_ROOT/plain"
mkdir -p "$plain/docs/superpowers/plans"
output="$(bash "$DRIFT" "$plain" 2>&1 || true)"
assert_empty "outside a git repo the check stays silent" "$output"

# --- the spec moved after the plan was written -------------------------------------
moved="$(new_project moved)"
spec_with active > "$moved/docs/superpowers/specs/2026-01-01-a-design.md"
commit_at "$moved" "write the spec" "8 days ago"
plan_with active > "$moved/docs/superpowers/plans/2026-01-02-a.md"
commit_at "$moved" "write the plan" "7 days ago"
printf -- '---\nstatus: active\ncreated: 2026-01-01\ndecisions: D0001\n---\n\n# Spec\n\nThe totals arrive as decimal strings.\n' \
    > "$moved/docs/superpowers/specs/2026-01-01-a-design.md"
commit_at "$moved" "correct the spec: totals are decimal strings" "2 days ago"
output="$(bash "$DRIFT" "$moved" 2>&1 || true)"
assert_contains "a plan is told its spec moved underneath it" "$output" "2026-01-02-a.md"
assert_contains "the commit that moved the spec is named" "$output" "correct the spec"

# --- the ordinary case ---------------------------------------------------------------
ordered="$(new_project ordered)"
spec_with active > "$ordered/docs/superpowers/specs/2026-01-01-a-design.md"
commit_at "$ordered" "write the spec" "5 days ago"
plan_with active > "$ordered/docs/superpowers/plans/2026-01-02-a.md"
commit_at "$ordered" "write the plan" "4 days ago"
output="$(SUPERPOWERS_DOC_STALE_COMMITS=99 bash "$DRIFT" "$ordered" 2>&1 || true)"
assert_empty "a plan written after its spec is silent" "$output"

# --- delivered-by must name a commit that exists ---------------------------------------
badsha="$(new_project badsha)"
spec_with active > "$badsha/docs/superpowers/specs/2026-01-01-a-design.md"
plan_with delivered "delivered-by: deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
" > "$badsha/docs/superpowers/plans/2026-01-02-a.md"
commit_at "$badsha" "claim delivery" "3 days ago"
output="$(SUPERPOWERS_DOC_STALE_COMMITS=99 bash "$DRIFT" "$badsha" 2>&1 || true)"
assert_contains "a delivered-by that is not in history is an error" "$output" "deadbeef"

goodsha="$(new_project goodsha)"
spec_with active > "$goodsha/docs/superpowers/specs/2026-01-01-a-design.md"
commit_at "$goodsha" "write the spec" "3 days ago"
real_sha=$(git -C "$goodsha" rev-parse HEAD)
plan_with delivered "delivered-by: ${real_sha}
" > "$goodsha/docs/superpowers/plans/2026-01-02-a.md"
commit_at "$goodsha" "mark delivered" "2 days ago"
output="$(SUPERPOWERS_DOC_STALE_COMMITS=99 bash "$DRIFT" "$goodsha" 2>&1 || true)"
assert_empty "a delivered-by naming a real commit is silent" "$output"

# --- an active plan the repo has moved past ---------------------------------------------
stale="$(new_project stale)"
spec_with active > "$stale/docs/superpowers/specs/2026-01-01-a-design.md"
commit_at "$stale" "write the spec" "6 days ago"
plan_with active > "$stale/docs/superpowers/plans/2026-01-02-a.md"
commit_at "$stale" "write the plan" "6 days ago"
for i in 1 2 3; do
    echo "change $i" >> "$stale/src/app.py"
    commit_at "$stale" "work $i" "$((5 - i)) days ago"
done
output="$(SUPERPOWERS_DOC_STALE_COMMITS=2 bash "$DRIFT" "$stale" 2>&1 || true)"
assert_contains "an untouched active plan with work moving past it is flagged" "$output" "2026-01-02-a.md"
assert_contains "the flag counts the commits since" "$output" "commits"

# --- state.md pointing at a finished plan --------------------------------------------------
pointer="$(new_project pointer)"
spec_with active > "$pointer/docs/superpowers/specs/2026-01-01-a-design.md"
plan_with delivered "delivered-by: HEAD
" > "$pointer/docs/superpowers/plans/2026-01-02-a.md"
printf '# Current state\n\n## Where things live\n- Active plan: docs/superpowers/plans/2026-01-02-a.md\n' \
    > "$pointer/.claude/context/state.md"
commit_at "$pointer" "finish the plan" "1 day ago"
output="$(SUPERPOWERS_DOC_STALE_COMMITS=99 bash "$DRIFT" "$pointer" 2>&1 || true)"
assert_contains "state.md pointing at a delivered plan is flagged" "$output" "state.md"

# --- a document naming a file that no longer exists --------------------------------------
renamed="$(new_project renamed)"
spec_with active > "$renamed/docs/superpowers/specs/2026-01-01-a-design.md"
printf -- '---\nstatus: active\ncreated: 2026-01-02\nderived-from: docs/superpowers/specs/2026-01-01-a-design.md\ndecisions: D0001\n---\n\n# Plan\n\nEdit `src/moved_away.py` to add the guard.\n' \
    > "$renamed/docs/superpowers/plans/2026-01-02-a.md"
commit_at "$renamed" "write the plan" "1 day ago"
output="$(SUPERPOWERS_DOC_STALE_COMMITS=99 bash "$DRIFT" "$renamed" 2>&1 || true)"
assert_contains "a path the document names that no longer exists is flagged" "$output" "src/moved_away.py"

echo
if [ "$FAILURES" -eq 0 ]; then
    echo "All document drift tests passed"
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
