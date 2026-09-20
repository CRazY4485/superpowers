#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LINT="$REPO_ROOT/hooks/doc-lint"

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

new_project() {
    local dir="$TEST_ROOT/$1"
    mkdir -p "$dir/.claude/context" "$dir/docs/superpowers/specs" "$dir/docs/superpowers/plans"
    cat > "$dir/.claude/context/decisions.md" <<'EOF'
# Decisions

## D0001 | 2026-01-05 | superseded | scope: storage/database
**Decision:** Use SQLite for the first release.
**Why:** One machine, one writer.
**Evidence:** owner interview Q4, 2026-01-05

## D0002 | 2026-03-11 | active | scope: storage/database
**Decision:** Move to Postgres.
**Why:** Two writers appeared in the plan.
**Evidence:** measured 4 write conflicts/min, 2026-03-10
**Supersedes:** D0001
EOF
    printf '%s\n' "$dir"
}

echo "Project document linter"

# --- a well-formed pair --------------------------------------------------------
good="$(new_project good)"
cat > "$good/docs/superpowers/specs/2026-03-12-storage-design.md" <<'EOF'
---
status: active
created: 2026-03-12
decisions: D0002
---

# Storage design
EOF
cat > "$good/docs/superpowers/plans/2026-03-13-storage.md" <<'EOF'
---
status: active
created: 2026-03-13
derived-from: docs/superpowers/specs/2026-03-12-storage-design.md
decisions: D0002
---

# Storage plan
EOF
output="$(bash "$LINT" "$good" 2>&1 || true)"
assert_empty "a well-formed spec and plan lint clean" "$output"

# --- missing status ------------------------------------------------------------
nostatus="$(new_project nostatus)"
printf 'doc-convention-since: 2026-01-01
' > "$nostatus/.claude/context/project.md"
cat > "$nostatus/docs/superpowers/plans/2026-03-13-import.md" <<'EOF'
# Import plan

No front matter at all.
EOF
output="$(bash "$LINT" "$nostatus" 2>&1 || true)"
assert_contains "a document with no status is an error" "$output" "2026-03-13-import.md"
assert_contains "the missing field is named" "$output" "status"

# --- status outside the vocabulary ----------------------------------------------
badstatus="$(new_project badstatus)"
cat > "$badstatus/docs/superpowers/plans/2026-03-14-import.md" <<'EOF'
---
status: in-progress
created: 2026-03-14
decisions: D0002
---
EOF
output="$(bash "$LINT" "$badstatus" 2>&1 || true)"
assert_contains "a status outside the vocabulary is an error" "$output" "in-progress"

# --- terminal states must point at something --------------------------------------
terminal="$(new_project terminal)"
cat > "$terminal/docs/superpowers/plans/2026-03-15-a.md" <<'EOF'
---
status: delivered
created: 2026-03-15
decisions: D0002
---
EOF
cat > "$terminal/docs/superpowers/specs/2026-03-16-b.md" <<'EOF'
---
status: superseded
created: 2026-03-16
decisions: D0002
---
EOF
cat > "$terminal/docs/superpowers/plans/2026-03-17-c.md" <<'EOF'
---
status: invalidated
created: 2026-03-17
decisions: D0002
---
EOF
output="$(bash "$LINT" "$terminal" 2>&1 || true)"
assert_contains "delivered without delivered-by is an error" "$output" "delivered-by"
assert_contains "superseded without superseded-by is an error" "$output" "superseded-by"
assert_contains "invalidated without invalidated-by is an error" "$output" "invalidated-by"

# --- derivation link must resolve --------------------------------------------------
broken="$(new_project broken)"
cat > "$broken/docs/superpowers/plans/2026-03-18-import.md" <<'EOF'
---
status: active
created: 2026-03-18
derived-from: docs/superpowers/specs/2026-03-01-nonexistent.md
decisions: D0002
---
EOF
output="$(bash "$LINT" "$broken" 2>&1 || true)"
assert_contains "a derived-from that does not resolve is an error" "$output" "2026-03-01-nonexistent.md"

# --- decisions must exist in the ledger ---------------------------------------------
dangling="$(new_project dangling)"
cat > "$dangling/docs/superpowers/specs/2026-03-19-x.md" <<'EOF'
---
status: active
created: 2026-03-19
decisions: D0002, D0404
---
EOF
output="$(bash "$LINT" "$dangling" 2>&1 || true)"
assert_contains "a decision id that is not in the ledger is an error" "$output" "D0404"

# --- an active document resting on a superseded decision ------------------------------
stale="$(new_project stale)"
cat > "$stale/docs/superpowers/specs/2026-03-20-y.md" <<'EOF'
---
status: active
created: 2026-03-20
decisions: D0001
---
EOF
output="$(bash "$LINT" "$stale" 2>&1 || true)"
assert_contains "an active document built on a superseded decision is flagged" "$output" "D0001"
assert_contains "the flag asks for rework rather than failing hard" "$output" "WARN"

# --- a plan with no derivation and no decisions ----------------------------------------
untethered="$(new_project untethered)"
cat > "$untethered/docs/superpowers/plans/2026-03-21-z.md" <<'EOF'
---
status: active
created: 2026-03-21
---
EOF
output="$(bash "$LINT" "$untethered" 2>&1 || true)"
assert_contains "a plan with no derived-from is flagged" "$output" "derived-from"

# --- documents that predate the convention -------------------------------------
legacy="$(new_project legacy)"
for d in 2026-01-05 2026-01-06 2026-01-07; do
    printf '# Old plan

No front matter, written before the convention existed.
'         > "$legacy/docs/superpowers/plans/${d}-old.md"
done
output="$(bash "$LINT" "$legacy" 2>&1 || true)"
if printf '%s' "$output" | grep -q '^ERROR'; then
    fail "pre-existing documents are not reported as errors"
    printf '%s
' "$output" | sed 's/^/        /' | head -5
else
    pass "pre-existing documents are not reported as errors"
fi
assert_contains "they are summarised in one line instead" "$output" "3 document"
assert_contains "the summary says how to adopt the convention" "$output" "doc-convention-since"

# --- once adopted, later documents must comply ------------------------------------
adopted="$(new_project adopted)"
printf 'doc-convention-since: 2026-02-01
' > "$adopted/.claude/context/project.md"
printf '# Old plan
' > "$adopted/docs/superpowers/plans/2026-01-20-old.md"
printf '# New plan
' > "$adopted/docs/superpowers/plans/2026-03-20-new.md"
output="$(bash "$LINT" "$adopted" 2>&1 || true)"
assert_contains "a document created after adoption must carry the front matter" "$output" "2026-03-20-new.md"
if printf '%s' "$output" | grep -q '2026-01-20-old.md'; then
    fail "a document created before adoption is left alone"
else
    pass "a document created before adoption is left alone"
fi

echo
if [ "$FAILURES" -eq 0 ]; then
    echo "All document lint tests passed"
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
