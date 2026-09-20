#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENGINE="$REPO_ROOT/hooks/git-checkpoint"
TURN_HOOK="$REPO_ROOT/hooks/checkpoint-turn"
GUARD="$REPO_ROOT/hooks/git-guard"

FAILURES=0
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

assert_equal() {
    local description="$1" actual="$2" expected="$3"
    if [ "$actual" = "$expected" ]; then
        pass "$description"
    else
        fail "$description"
        echo "      expected: $expected"
        echo "      actual:   $actual"
    fi
}

assert_contains() {
    local description="$1" haystack="$2" needle="$3"
    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        pass "$description"
    else
        fail "$description"
        echo "      expected to find: $needle"
        printf '%s\n' "$haystack" | sed 's/^/        /' | head -10
    fi
}

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
    printf '%s\n' "$dir"
}

seed_commit() {
    echo "one" > "$1/a.txt"
    git -C "$1" add -A
    git -C "$1" commit -q -m "init"
}

checkpoint_count() {
    git -C "$1" for-each-ref --format='%(refname)' refs/superpowers/checkpoints 2>/dev/null | wc -l | tr -d ' '
}

latest_checkpoint() {
    git -C "$1" for-each-ref --sort=-refname --format='%(objectname)' \
        refs/superpowers/checkpoints 2>/dev/null | head -1
}

snapshot() {
    CLAUDE_PROJECT_DIR="$1" bash "$ENGINE" snapshot "${2:-test}"
}

echo "Checkpoint engine"

# --- outside a git repo ------------------------------------------------------
plain="$TEST_ROOT/plain"
mkdir -p "$plain"
output="$(CLAUDE_PROJECT_DIR="$plain" bash "$ENGINE" snapshot outside)"
assert_empty "outside a git repo the engine stays silent" "$output"

# --- clean tree --------------------------------------------------------------
clean="$(new_repo clean)"
seed_commit "$clean"
output="$(snapshot "$clean")"
assert_empty "a clean tree produces no checkpoint" "$output"
assert_equal "no ref written for a clean tree" "$(checkpoint_count "$clean")" "0"

# --- dirty tree --------------------------------------------------------------
dirty="$(new_repo dirty)"
seed_commit "$dirty"
printf 'ignored.log\n' > "$dirty/.gitignore"
git -C "$dirty" add -A
git -C "$dirty" commit -q -m "ignore rules"
echo "two" >> "$dirty/a.txt"
echo "fresh" > "$dirty/new.txt"
echo "secret" > "$dirty/ignored.log"
status_before="$(git -C "$dirty" status --porcelain)"

output="$(snapshot "$dirty" "dirty-case")"
assert_contains "snapshot reports the ref it wrote" "$output" "refs/superpowers/checkpoints/"
assert_equal "one checkpoint ref exists" "$(checkpoint_count "$dirty")" "1"

sha="$(latest_checkpoint "$dirty")"
tracked_content="$(git -C "$dirty" show "$sha:a.txt")"
assert_contains "modified tracked file is captured" "$tracked_content" "two"
assert_contains "untracked file is captured" "$(git -C "$dirty" ls-tree --name-only "$sha")" "new.txt"

if git -C "$dirty" ls-tree --name-only "$sha" | grep -qx "ignored.log"; then
    fail "ignored files stay out of the checkpoint"
else
    pass "ignored files stay out of the checkpoint"
fi

assert_equal "working tree and index are untouched" "$(git -C "$dirty" status --porcelain)" "$status_before"
assert_equal "the branch gains no commit" "$(git -C "$dirty" rev-list --count HEAD)" "2"

# --- deduplication -----------------------------------------------------------
output="$(snapshot "$dirty" "same-again")"
assert_empty "an unchanged tree produces no second checkpoint" "$output"
assert_equal "ref count unchanged after a no-op snapshot" "$(checkpoint_count "$dirty")" "1"

echo "three" >> "$dirty/a.txt"
output="$(snapshot "$dirty" "after-change")"
assert_contains "a changed tree produces a new checkpoint" "$output" "refs/superpowers/checkpoints/"
assert_equal "second checkpoint recorded" "$(checkpoint_count "$dirty")" "2"

# --- repository with no commits yet ------------------------------------------
unborn="$(new_repo unborn)"
echo "first draft" > "$unborn/draft.txt"
output="$(snapshot "$unborn" "unborn")"
assert_contains "a repo without commits can still be checkpointed" "$output" "refs/superpowers/checkpoints/"

# --- pruning -----------------------------------------------------------------
pruned="$(new_repo pruned)"
seed_commit "$pruned"
for i in 1 2 3 4; do
    echo "change $i" >> "$pruned/a.txt"
    CLAUDE_PROJECT_DIR="$pruned" SUPERPOWERS_CHECKPOINT_KEEP=2 bash "$ENGINE" snapshot "loop-$i" > /dev/null
done
assert_equal "old checkpoints are pruned to the keep limit" "$(checkpoint_count "$pruned")" "2"

# --- listing -----------------------------------------------------------------
listing="$(CLAUDE_PROJECT_DIR="$dirty" bash "$ENGINE" list)"
assert_contains "list shows checkpoint shas" "$listing" "$(printf '%s' "$sha" | cut -c1-7)"
assert_contains "list shows labels" "$listing" "after-change"

echo
echo "Stop-hook wrapper"
turn="$(new_repo turn)"
seed_commit "$turn"
echo "work" >> "$turn/a.txt"
output="$(CLAUDE_PROJECT_DIR="$turn" bash "$TURN_HOOK")"
assert_empty "the turn hook prints nothing" "$output"
assert_equal "the turn hook still writes a checkpoint" "$(checkpoint_count "$turn")" "1"

echo
echo "Destructive-command guard"

run_guard() {
    printf '%s' "$2" | CLAUDE_PROJECT_DIR="$1" bash "$GUARD"
}

guarded="$(new_repo guarded)"
seed_commit "$guarded"
echo "unsaved work" >> "$guarded/a.txt"

output="$(run_guard "$guarded" '{"tool_name":"Bash","tool_input":{"command":"git status --short"}}')"
assert_empty "a harmless git command is not guarded" "$output"
assert_equal "no checkpoint for a harmless command" "$(checkpoint_count "$guarded")" "0"

output="$(run_guard "$guarded" '{"tool_name":"Read","tool_input":{"file_path":"a.txt"}}')"
assert_empty "non-Bash tools are ignored" "$output"

output="$(run_guard "$guarded" '{"tool_name":"Bash","tool_input":{"command":"git reset --hard HEAD~1"}}')"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "checkpoint" "git reset --hard"; then
    pass "a destructive command gets a checkpoint and an explanation"
else
    fail "a destructive command gets a checkpoint and an explanation"
    printf '%s\n' "$output" | sed 's/^/        /'
fi
assert_equal "the guard wrote a checkpoint before the command" "$(checkpoint_count "$guarded")" "1"

guard_sha="$(latest_checkpoint "$guarded")"
assert_contains "the unsaved work is inside that checkpoint" \
    "$(git -C "$guarded" show "$guard_sha:a.txt")" "unsaved work"

cleanrepo="$(new_repo guarded-clean)"
seed_commit "$cleanrepo"
output="$(run_guard "$cleanrepo" '{"tool_name":"Bash","tool_input":{"command":"git clean -fd"}}')"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "nothing uncommitted"; then
    pass "with a clean tree the guard says there is nothing to lose"
else
    fail "with a clean tree the guard says there is nothing to lose"
    printf '%s\n' "$output" | sed 's/^/        /'
fi
assert_equal "no checkpoint is written for a clean tree" "$(checkpoint_count "$cleanrepo")" "0"

echo
echo "Guard beyond git commands"

rmrepo="$(new_repo guard-rm)"
seed_commit "$rmrepo"
echo "in progress" >> "$rmrepo/a.txt"

output="$(run_guard "$rmrepo" '{"tool_name":"Bash","tool_input":{"command":"rm -rf build/"}}')"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "checkpoint" "rm -rf build/"; then
    pass "rm -rf is guarded like a destructive git command"
else
    fail "rm -rf is guarded like a destructive git command"
    printf '%s\n' "$output" | sed 's/^/        /'
fi
assert_equal "rm -rf produced a checkpoint" "$(checkpoint_count "$rmrepo")" "1"

echo "more work" >> "$rmrepo/a.txt"
output="$(run_guard "$rmrepo" '{"tool_name":"PowerShell","tool_input":{"command":"Remove-Item -Recurse -Force dist"}}')"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "checkpoint" "Remove-Item"; then
    pass "PowerShell recursive deletes are guarded too"
else
    fail "PowerShell recursive deletes are guarded too"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

output="$(run_guard "$rmrepo" '{"tool_name":"Bash","tool_input":{"command":"rm notes.txt"}}')"
assert_empty "a plain single-file rm is not guarded" "$output"

quiet="$(new_repo guard-rm-clean)"
seed_commit "$quiet"
output="$(run_guard "$quiet" '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/scratch-dir"}}')"
assert_empty "with nothing to lose a non-git delete stays silent" "$output"

echo
if [ "$FAILURES" -eq 0 ]; then
    echo "All git checkpoint tests passed"
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
