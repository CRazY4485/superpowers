#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COLLECTOR="$REPO_ROOT/hooks/project-context"
NUDGE="$REPO_ROOT/hooks/context-nudge"
SESSION_START="$REPO_ROOT/hooks/session-start"

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
        echo "    expected to find: $needle"
    fi
}

assert_not_contains() {
    local description="$1" haystack="$2" needle="$3"
    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        fail "$description"
        echo "    expected NOT to find: $needle"
    else
        pass "$description"
    fi
}

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
    mkdir -p "$dir"
    printf '%s\n' "$dir"
}

make_context() {
    mkdir -p "$1/.claude/context"
}

git_init() {
    git -C "$1" init -q
    git -C "$1" config user.email "test@example.com"
    git -C "$1" config user.name "Test"
}

git_commit_all() {
    git -C "$1" add -A
    git -C "$1" commit -q -m "$2"
}

# git_commit_all_at <dir> <message> <when>
git_commit_all_at() {
    local stamp
    stamp=$(date -d "$3" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || printf '%s' "$3")
    git -C "$1" add -A
    GIT_AUTHOR_DATE="$stamp" GIT_COMMITTER_DATE="$stamp" git -C "$1" commit -q -m "$2"
}

# age_file <path> <when>
age_file() {
    touch -d "$2" "$1" 2>/dev/null || touch -t 200001010000 "$1"
}

echo "Project context collector"

# --- no context directory -> silence ---------------------------------------
bare="$(make_project bare)"
output="$(CLAUDE_PROJECT_DIR="$bare" bash "$COLLECTOR")"
assert_empty "no .claude/context directory emits nothing" "$output"

# --- project.md + state.md are injected in full -----------------------------
full="$(make_project full)"
make_context "$full"
printf '# Project profile\nStack: Node 22, Postgres 16.\nTest command: npm test\n' \
    > "$full/.claude/context/project.md"
printf '# Current state\nWorking on: the import pipeline.\nNext: wire retries into the fetch loop.\n' \
    > "$full/.claude/context/state.md"
output="$(CLAUDE_PROJECT_DIR="$full" bash "$COLLECTOR")"
assert_contains "block is tagged" "$output" "<PROJECT_CONTEXT"
assert_contains "block is closed" "$output" "</PROJECT_CONTEXT>"
assert_contains "project.md content injected" "$output" "Stack: Node 22, Postgres 16."
assert_contains "state.md content injected" "$output" "wire retries into the fetch loop"
assert_contains "names the maintaining skill" "$output" "superpowers:maintaining-project-context"

# --- decisions.md is summarised, not inlined --------------------------------
decisions="$(make_project decisions)"
make_context "$decisions"
printf '# Current state\nNothing in flight.\n' > "$decisions/.claude/context/state.md"
{
    echo "## 2026-01-05 - Chose Postgres over SQLite"
    echo "Body that must not be inlined: CONCURRENCY_ARGUMENT"
    echo
    echo "## 2026-02-11 - Dropped the queue worker"
    echo "Body that must not be inlined: LATENCY_ARGUMENT"
    echo
    echo "## 2026-03-02 - Pinned Node 22"
    echo "Body that must not be inlined: LTS_ARGUMENT"
    echo
    echo "## 2026-04-09 - Moved secrets to 1Password"
    echo "Body that must not be inlined: ROTATION_ARGUMENT"
} > "$decisions/.claude/context/decisions.md"
output="$(CLAUDE_PROJECT_DIR="$decisions" bash "$COLLECTOR")"
assert_contains "decision count reported" "$output" "4 entries"
assert_contains "most recent decision listed" "$output" "Moved secrets to 1Password"
assert_contains "third-most-recent decision listed" "$output" "Dropped the queue worker"
assert_not_contains "oldest decision heading not listed" "$output" "Chose Postgres over SQLite"
assert_not_contains "decision bodies are not inlined" "$output" "ROTATION_ARGUMENT"
assert_contains "points at the decisions file" "$output" ".claude/context/decisions.md"

# --- oversized files are truncated ------------------------------------------
big="$(make_project big)"
make_context "$big"
{
    echo "# Current state"
    echo "HEAD_MARKER"
    for i in $(seq 1 400); do
        echo "Filler line $i: ................................................................"
    done
    echo "TAIL_MARKER"
} > "$big/.claude/context/state.md"
output="$(CLAUDE_PROJECT_DIR="$big" bash "$COLLECTOR")"
assert_contains "start of oversized file is kept" "$output" "HEAD_MARKER"
assert_not_contains "end of oversized file is dropped" "$output" "TAIL_MARKER"
assert_contains "truncation is disclosed" "$output" "truncated"
if [ "${#output}" -le 12000 ]; then
    pass "collector output stays under the size cap"
else
    fail "collector output stays under the size cap (was ${#output} chars)"
fi

# --- reality check: state.md versus what the repo actually did ---------------
echo
echo "Reality check against the repo"

drift="$(make_project drift)"
git_init "$drift"
make_context "$drift"
printf '# Current state\nNext: something already finished\n' > "$drift/.claude/context/state.md"
age_file "$drift/.claude/context/state.md" "2 hours ago"
echo "one" > "$drift/a.txt"
git_commit_all "$drift" "FIRST_DRIFT_COMMIT"
echo "two" > "$drift/b.txt"
git_commit_all "$drift" "SECOND_DRIFT_COMMIT"
output="$(CLAUDE_PROJECT_DIR="$drift" bash "$COLLECTOR")"
assert_contains "reality check section present" "$output" "reality check"
assert_contains "commit count since state.md reported" "$output" "2 commits since state.md was written"
assert_contains "recent commit subject listed" "$output" "SECOND_DRIFT_COMMIT"
assert_contains "asks for reconciliation" "$output" "Reconcile"

insync="$(make_project insync)"
git_init "$insync"
make_context "$insync"
echo "code" > "$insync/a.txt"
git_commit_all "$insync" "initial"
printf '# Current state\nfresh\n' > "$insync/.claude/context/state.md"
output="$(CLAUDE_PROJECT_DIR="$insync" bash "$COLLECTOR")"
assert_contains "in-sync repo reported as such" "$output" "no commits since state.md was written"

dirtytree="$(make_project dirtytree)"
git_init "$dirtytree"
make_context "$dirtytree"
echo "code" > "$dirtytree/a.txt"
echo "code" > "$dirtytree/b.txt"
git_commit_all "$dirtytree" "initial"
printf '# Current state\nfresh\n' > "$dirtytree/.claude/context/state.md"
echo "changed" >> "$dirtytree/a.txt"
output="$(CLAUDE_PROJECT_DIR="$dirtytree" bash "$COLLECTOR")"
assert_contains "uncommitted work reported" "$output" "1 tracked file with uncommitted changes"

output="$(CLAUDE_PROJECT_DIR="$full" bash "$COLLECTOR")"
assert_not_contains "no reality check outside a git repo" "$output" "reality check"

# --- session-start injects the collected context ----------------------------
echo
echo "SessionStart integration"
session="$(make_project session)"
make_context "$session"
printf '# Current state\nUNIQUE_STATE_MARKER\n' > "$session/.claude/context/state.md"
output="$(CLAUDE_PLUGIN_ROOT="$REPO_ROOT" CLAUDE_PROJECT_DIR="$session" bash "$SESSION_START")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-session-context.cjs" UNIQUE_STATE_MARKER; then
    pass "session-start embeds project context alongside the bootstrap"
else
    fail "session-start embeds project context alongside the bootstrap"
fi

noctx="$(make_project noctx)"
output="$(CLAUDE_PLUGIN_ROOT="$REPO_ROOT" CLAUDE_PROJECT_DIR="$noctx" bash "$SESSION_START")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-session-context.cjs" --absent PROJECT_CONTEXT; then
    pass "session-start is unchanged for projects without context files"
else
    fail "session-start is unchanged for projects without context files"
fi

# --- Stop-hook staleness nudge ----------------------------------------------
echo
echo "Stop hook staleness nudge"
nudge_state="$TEST_ROOT/nudge-state"

run_nudge() {
    CLAUDE_PROJECT_DIR="$1" \
    SUPERPOWERS_NUDGE_STATE_DIR="$nudge_state" \
    bash "$NUDGE"
}

optout="$(make_project nudge-optout)"
git_init "$optout"
echo "code" > "$optout/file.txt"
git_commit_all "$optout" "initial"
output="$(run_nudge "$optout")"
assert_empty "project without context files is never nudged" "$output"

fresh="$(make_project nudge-fresh)"
git_init "$fresh"
make_context "$fresh"
echo "code" > "$fresh/file.txt"
git_commit_all "$fresh" "initial"
printf '# Current state\nup to date\n' > "$fresh/.claude/context/state.md"
output="$(run_nudge "$fresh")"
assert_empty "fresh state.md produces no nudge" "$output"

stale="$(make_project nudge-stale)"
git_init "$stale"
make_context "$stale"
printf '# Current state\nwritten before the work\n' > "$stale/.claude/context/state.md"
touch -d '2 hours ago' "$stale/.claude/context/state.md" 2>/dev/null \
    || touch -t 200001010000 "$stale/.claude/context/state.md"
echo "code" > "$stale/file.txt"
git_commit_all "$stale" "work done after the context was written"
output="$(run_nudge "$stale")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-stop-nudge.cjs"; then
    pass "state.md older than the last commit triggers a Stop nudge"
else
    fail "state.md older than the last commit triggers a Stop nudge"
    printf '%s\n' "$output" | sed 's/^/      /'
fi

output="$(run_nudge "$stale")"
assert_empty "nudge is throttled on the immediately following turn" "$output"

# Uncommitted edits made after state.md was written count as drift; edits made
# before it do not, however old the working tree is.
run_nudge_dirty() {
    CLAUDE_PROJECT_DIR="$1" \
    SUPERPOWERS_NUDGE_STATE_DIR="$2" \
    SUPERPOWERS_NUDGE_DIRTY_SECONDS=0 \
    bash "$NUDGE"
}

edited="$(make_project nudge-edited)"
git_init "$edited"
make_context "$edited"
echo "code" > "$edited/a.txt"
git_commit_all_at "$edited" "initial" "2 hours ago"
printf '# Current state\nwritten, then the file changed\n' > "$edited/.claude/context/state.md"
age_file "$edited/.claude/context/state.md" "1 hour ago"
echo "more code" >> "$edited/a.txt"
output="$(run_nudge_dirty "$edited" "$TEST_ROOT/nudge-state-edited")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-stop-nudge.cjs"; then
    pass "edits made after state.md was written trigger a nudge"
else
    fail "edits made after state.md was written trigger a nudge"
    printf '%s\n' "$output" | sed 's/^/      /'
fi

predated="$(make_project nudge-predated)"
git_init "$predated"
make_context "$predated"
echo "code" > "$predated/a.txt"
git_commit_all_at "$predated" "initial" "2 hours ago"
echo "more code" >> "$predated/a.txt"
age_file "$predated/a.txt" "90 minutes ago"
printf '# Current state\nwritten after the edits, so it already covers them\n' \
    > "$predated/.claude/context/state.md"
age_file "$predated/.claude/context/state.md" "1 hour ago"
output="$(run_nudge_dirty "$predated" "$TEST_ROOT/nudge-state-predated")"
assert_empty "edits older than state.md do not trigger a nudge" "$output"

echo
if [ "$FAILURES" -eq 0 ]; then
    echo "All project-context tests passed"
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
