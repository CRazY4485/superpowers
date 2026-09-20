#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GATE="$REPO_ROOT/hooks/commit-gate"
BRANCH_GUARD="$REPO_ROOT/hooks/branch-guard"

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
    git -C "$dir" init -q -b main
    git -C "$dir" config user.email "test@example.com"
    git -C "$dir" config user.name "Test"
    echo "one" > "$dir/a.txt"
    git -C "$dir" add -A
    git -C "$dir" commit -q -m "init"
    printf '%s\n' "$dir"
}

run_gate() {
    printf '%s' "$2" | CLAUDE_PROJECT_DIR="$1" bash "$GATE"
}

commit_payload() {
    printf '{"tool_name":"Bash","tool_input":{"command":"git commit -m \\"work\\""}}'
}

echo "Commit gate"

# --- clean commit -------------------------------------------------------------
ok="$(new_repo ok)"
echo "harmless change" >> "$ok/a.txt"
git -C "$ok" add -A
output="$(run_gate "$ok" "$(commit_payload)")"
assert_empty "an ordinary commit passes without comment" "$output"

# --- nothing staged -----------------------------------------------------------
nothing="$(new_repo nothing)"
output="$(run_gate "$nothing" "$(commit_payload)")"
assert_empty "no staged content means nothing to check" "$output"

# --- non-commit command -------------------------------------------------------
other="$(new_repo other)"
echo "x" >> "$other/a.txt"
git -C "$other" add -A
output="$(run_gate "$other" '{"tool_name":"Bash","tool_input":{"command":"git status"}}')"
assert_empty "a non-commit command is ignored" "$output"

# --- high confidence secret ---------------------------------------------------
secret="$(new_repo secret)"
printf 'aws_key = "AKIAIOSFODNN7EXAMPLE"\n' > "$secret/config.py"  # pragma: allowlist secret
git -C "$secret" add -A
output="$(run_gate "$secret" "$(commit_payload)")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" --deny "config.py" "AWS access key"; then
    pass "an AWS key in the staged diff blocks the commit"
else
    fail "an AWS key in the staged diff blocks the commit"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

key="$(new_repo privatekey)"
printf -- '-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEA\n' > "$key/id_rsa"
git -C "$key" add -A
output="$(run_gate "$key" "$(commit_payload)")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" --deny "id_rsa"; then
    pass "a private key block blocks the commit"
else
    fail "a private key block blocks the commit"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

# --- explicit allowlist pragma ---------------------------------------------------
allowed="$(new_repo allowlisted)"
printf 'example_key = "AKIAIOSFODNN7EXAMPLE"  # pragma: allowlist secret\n' > "$allowed/fixture.py"
git -C "$allowed" add -A
output="$(run_gate "$allowed" "$(commit_payload)")"
assert_empty "a line marked with the allowlist pragma is not blocked" "$output"

# --- weak signal warns but does not block --------------------------------------
weak="$(new_repo weak)"
printf 'password = get_from_vault()\npassword="hunter2"\n' > "$weak/settings.py"
git -C "$weak" add -A
output="$(run_gate "$weak" "$(commit_payload)")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "settings.py"; then
    pass "a password assignment warns without blocking"
else
    fail "a password assignment warns without blocking"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

# --- conflict markers -----------------------------------------------------------
conflict="$(new_repo conflict)"
{
    echo "line"
    echo "<<<<<<< HEAD"
    echo "ours"
    echo "======="
    echo "theirs"
    echo ">>>>>>> feature"
} > "$conflict/merged.txt"
git -C "$conflict" add -A
output="$(run_gate "$conflict" "$(commit_payload)")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" --deny "merged.txt" "conflict marker"; then
    pass "unresolved conflict markers block the commit"
else
    fail "unresolved conflict markers block the commit"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

# --- large file ------------------------------------------------------------------
large="$(new_repo large)"
head -c 300000 /dev/urandom > "$large/blob.bin"
git -C "$large" add -A
output="$(SUPERPOWERS_COMMIT_MAX_FILE_BYTES=100000 run_gate "$large" "$(commit_payload)")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "blob.bin"; then
    pass "an oversized staged file is called out"
else
    fail "an oversized staged file is called out"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

echo
echo "Branch guard"

run_branch_guard() {
    CLAUDE_PROJECT_DIR="$1" \
    SUPERPOWERS_BRANCH_GUARD_STATE_DIR="$2" \
    bash "$BRANCH_GUARD" <<< "$3"
}

edit_payload() {
    printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$1"
}

onmain="$(new_repo onmain)"
state="$TEST_ROOT/branch-state"
output="$(run_branch_guard "$onmain" "$state" "$(edit_payload "$onmain/a.txt")")"
if printf '%s' "$output" | node "$SCRIPT_DIR/assert-pretooluse.cjs" "main"; then
    pass "editing on the default branch is called out"
else
    fail "editing on the default branch is called out"
    printf '%s\n' "$output" | sed 's/^/        /'
fi

output="$(run_branch_guard "$onmain" "$state" "$(edit_payload "$onmain/a.txt")")"
assert_empty "the branch warning is throttled after the first edit" "$output"

onbranch="$(new_repo onbranch)"
git -C "$onbranch" checkout -q -b feature/work
output="$(run_branch_guard "$onbranch" "$TEST_ROOT/branch-state-2" "$(edit_payload "$onbranch/a.txt")")"
assert_empty "editing on a feature branch says nothing" "$output"

plain="$TEST_ROOT/plain"
mkdir -p "$plain"
output="$(run_branch_guard "$plain" "$TEST_ROOT/branch-state-3" "$(edit_payload "$plain/a.txt")")"
assert_empty "outside a git repo the branch guard is silent" "$output"

echo
if [ "$FAILURES" -eq 0 ]; then
    echo "All commit gate and branch guard tests passed"
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
