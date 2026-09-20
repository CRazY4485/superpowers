#!/usr/bin/env bash
# Print the register of upstream files this fork has modified, with the
# resolution rule for each, and the exact lines we added.
#
#   scripts/upstream-register.sh [--full]
#
# The list is derived from git, not stored, so it cannot go stale: a file that
# stops differing from upstream drops out on its own. --full also prints the
# added lines for each file - during a conflict those lines are the recipe for
# re-applying the fork's change on top of upstream's version.
#
# Files this fork added outright never conflict and are not listed.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${SUPERPOWERS_UPSTREAM_REF:-upstream/main}"
FULL=0
[ "${1:-}" = "--full" ] && FULL=1

git -C "$REPO_ROOT" rev-parse -q --verify "$BASE" >/dev/null 2>&1 || {
    echo "upstream ref '$BASE' not found - run: git fetch upstream" >&2
    exit 1
}

rule_for() {
    case "$1" in
        .claude-plugin/*)
            printf 'keep ours - fork identity: personal marketplace name, no version field' ;;
        hooks/hooks.json)
            printf 'union - keep every upstream registration and every fork one; this file is a list, not prose' ;;
        hooks/session-start)
            printf 'take upstream, re-apply the appended project-context block' ;;
        .gitattributes | .gitignore)
            printf 'union - the fork only adds entries of its own' ;;
        skills/*/SKILL.md)
            printf 'take upstream wholesale, re-insert the fork pointer paragraphs; never hand-merge upstream skill prose' ;;
        *)
            printf 'review by hand' ;;
    esac
}

printf 'Upstream files this fork has modified (base: %s)\n' "$BASE"
printf 'Files the fork added outright are omitted: they never conflict.\n\n'

count=0
while IFS=$'\t' read -r added removed path; do
    [ -n "${path:-}" ] || continue
    # Only files that exist upstream can conflict on merge. ls-tree avoids the
    # "ref:path" form entirely: on Git Bash a ref containing a slash makes
    # "upstream/main:path" look like a POSIX path list, and the argument is
    # rewritten before git ever sees it.
    # </dev/null: anything inside a read loop that touches stdin eats the list.
    [ -n "$(git -C "$REPO_ROOT" ls-tree -r --name-only "$BASE" -- "$path" </dev/null 2>/dev/null)" ] || continue
    count=$((count + 1))
    printf '  %-48s +%-4s -%-4s %s\n' "$path" "$added" "$removed" "$(rule_for "$path")"

    if [ "$FULL" = "1" ]; then
        printf '\n'
        git -C "$REPO_ROOT" diff "$BASE" -- "$path" \
            | grep -E '^\+' | grep -v '^\+\+\+' | sed 's/^+/      | /'
        printf '\n'
    fi
done < <(git -C "$REPO_ROOT" diff --numstat "$BASE" -- . ':(exclude)plugin-evals' 2>/dev/null)

printf '\n%s upstream file(s) carry fork changes.\n' "$count"
printf 'On a merge conflict, resolve by the rule above - and if a rule no longer fits,\n'
printf 'change the rule in docs/upstream-register.md rather than improvising per file.\n'

exit 0
