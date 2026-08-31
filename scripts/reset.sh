#!/usr/bin/env bash
# Reset this testbed to its pristine pre-test state, so the gh-issue-flow plugin
# can be exercised against it again from a clean slate.
#
#   scripts/reset.sh --dry-run    # print every mutation, change nothing
#   scripts/reset.sh              # do it
#
# Idempotent: safe to run twice. Reads state back rather than trusting exit
# codes — `gh` exits 0 on operations the server rejected.
set -euo pipefail

REPO="${TESTBED_REPO:-chalosalvador/claude-workflows-testbed}"
OWNER="${TESTBED_OWNER:-chalosalvador}"
BOARD="${TESTBED_BOARD:-1}"
DRY=""; [ "${1:-}" = "--dry-run" ] && DRY="echo [dry-run]"

say() { printf '\n== %s\n' "$1"; }

say "1. Close any open PRs and delete their branches"
for n in $(gh pr list --repo "$REPO" --state open --json number --jq '.[].number'); do
  $DRY gh pr close "$n" --repo "$REPO" --delete-branch
done
# Feature branches can outlive their PR (delete_branch_on_merge is off here).
for b in $(gh api "repos/$REPO/branches" --jq '.[].name' | grep -v '^main$' || true); do
  $DRY gh api -X DELETE "repos/$REPO/git/refs/heads/$b"
done

say "2. Revert the tracked fixture back to its broken state"
# Issue #3 is only reproducible while the README disagrees with ci.yml.
if grep -q 'ruff pytest &&' README.md 2>/dev/null; then
  # NB: no `sed -i.bak`. On BOTH BSD and GNU sed, `sed -i.bak README.md` writes
  # README.md.bak — not README.bak — so the obvious cleanup silently misses it and
  # this script (which pushes straight to main) commits the stray file. That
  # happened: README.md.bak was tracked on main until it was removed by hand.
  # A temp file is portable and leaves nothing behind.
  _edit() { local t; t=$(mktemp); sed "$1" README.md > "$t" && mv "$t" README.md; }
  $DRY _edit 's|^pip install -e \. ruff pytest &&.*|pip install -e . \&\& pytest tests/ -q|'
  $DRY _edit '/^Run the same gate CI runs:$/,+1d'
  $DRY git commit -qam "chore: reset README fixture to its pre-fix state"
  $DRY git push -q origin main
else
  echo "   README already in its pre-fix state"
fi

say "3. Reopen closed issues and strip every triage verdict"
STRIP="triaged,agent-ready,agent-wip,agent-blocked,agent-authored,bug,enhancement,improvement,question,duplicate,effort:easy,effort:medium,effort:hard,area:core,area:docs,blocked,epic"
for n in $(gh issue list --repo "$REPO" --state all --json number --jq '.[].number' | sort -n); do
  state=$(gh issue view "$n" --repo "$REPO" --json state --jq .state)
  [ "$state" = "CLOSED" ] && $DRY gh issue reopen "$n" --repo "$REPO"
  # --remove-label tolerates labels the issue does not carry
  $DRY gh issue edit "$n" --repo "$REPO" --remove-label "$STRIP" 2>/dev/null || true
done

say "4. Clear the board's Status, Priority and Track"
PROJ_ID=$(gh project view "$BOARD" --owner "$OWNER" --format json --jq '.id')
FIELDS=$(gh project field-list "$BOARD" --owner "$OWNER" --format json)
for f in Status Priority Track; do
  fid=$(echo "$FIELDS" | jq -r --arg n "$f" '.fields[]|select(.name==$n).id')
  [ -z "$fid" ] && continue
  # NB: do not append >/dev/null here — under --dry-run it swallows the echo and
  # 18 pending mutations render as an empty section, i.e. as "nothing to do".
  gh project item-list "$BOARD" --owner "$OWNER" --limit 1000 --format json --jq '.items[].id' |
    while read -r item; do
      if [ -n "$DRY" ]; then
        echo "[dry-run] gh project item-edit --id $item --field-id $fid --clear   ($f)"
      else
        gh project item-edit --project-id "$PROJ_ID" --id "$item" --field-id "$fid" --clear >/dev/null
      fi
    done
done

[ -n "$DRY" ] && { echo; echo "dry run — nothing changed"; exit 0; }

say "5. Read the state back (board writes are eventually consistent — poll)"
for i in $(seq 1 6); do
  open=$(gh issue list --repo "$REPO" --state open --json number --jq 'length')
  lbl=$(gh issue list --repo "$REPO" --state open --json labels --jq '[.[].labels[].name]|length')
  set=$(gh project item-list "$BOARD" --owner "$OWNER" --limit 1000 --format json \
          --jq '[.items[]|select(.status != null or .priority != null)]|length')
  printf '   open=%s  triage-labels=%s  board-fields-set=%s\n' "$open" "$lbl" "$set"
  [ "$lbl" = "0" ] && [ "$set" = "0" ] && break
  sleep 5
done

echo
if [ "$lbl" = "0" ] && [ "$set" = "0" ] && [ "$open" -gt 0 ]; then
  echo "RESET OK — $open open issues, no triage verdicts, board fields clear."
else
  echo "RESET INCOMPLETE — see the counts above; re-run, or fix by hand." >&2
  exit 1
fi
