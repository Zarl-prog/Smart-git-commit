#!/usr/bin/env bash
#
# fork-check.sh — Verify fork is up to date with upstream
#
# Usage: bash contributor/scripts/fork-check.sh
# Exit code: 0 = synced, 1 = behind or conflict
# Stdout: JSON {"status":"synced"|"behind"|"conflict","commits_behind":0}
# Stderr: Human-readable color output

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Smart Git Commit — Fork Sync Check${NC}" >&2
echo "" >&2

# Check if upstream remote exists
UPSTREAM_EXISTS=false
if git remote -v 2>/dev/null | grep -q "^upstream"; then
  UPSTREAM_EXISTS=true
  echo -e "  ${GREEN}✓${NC} Upstream remote found" >&2
else
  echo -e "  ${YELLOW}⚠${NC} No upstream remote configured" >&2
  echo "" >&2
  echo -e "  Enter the original repo URL (e.g. https://github.com/owner/repo.git): " >&2
  read -r UPSTREAM_URL

  if [ -z "$UPSTREAM_URL" ]; then
    echo -e "  ${RED}✗ No URL provided. Cannot proceed without upstream.${NC}" >&2
    echo '{"status":"conflict","commits_behind":-1,"message":"No upstream URL provided"}'
    exit 1
  fi

  git remote add upstream "$UPSTREAM_URL"
  echo -e "  ${GREEN}✓${NC} Upstream remote added: $UPSTREAM_URL" >&2
fi

# Fetch upstream silently
echo "" >&2
echo -e "  Fetching upstream..." >&2
git fetch upstream 2>/dev/null || {
  echo -e "  ${RED}✗ Failed to fetch upstream. Check the remote URL.${NC}" >&2
  echo '{"status":"conflict","commits_behind":-1,"message":"Failed to fetch upstream"}'
  exit 1
}

# Count commits behind
BEHIND=$(git log HEAD..upstream/main --oneline 2>/dev/null | wc -l | tr -d ' ')
BEHIND=${BEHIND:-0}

if [ "$BEHIND" -gt 0 ]; then
  echo "" >&2
  echo -e "  ${YELLOW}⚠ Fork is ${BEHIND} commit(s) behind upstream/main${NC}" >&2
  echo "" >&2
  echo -e "  Commits behind:" >&2
  git log HEAD..upstream/main --oneline --format="    %h %s" 2>/dev/null | head -20 >&2
  echo "" >&2

  echo -e "  Rebase on upstream/main now? [Y/n]: " >&2
  read -r REBASE_ANSWER

  case "$REBASE_ANSWER" in
    n|N|no|NO)
      echo -e "  ${YELLOW}⚠ Skipping rebase. Fork is ${BEHIND} commit(s) behind.${NC}" >&2
      echo "{\"status\":\"behind\",\"commits_behind\":$BEHIND,\"message\":\"Fork is $BEHIND commits behind upstream/main\"}"
      exit 0
      ;;
    *)
      echo -e "  Rebasing on upstream/main..." >&2
      set +e
      git rebase upstream/main 2>&1
      REBASE_EXIT=$?
      set -e

      if [ "$REBASE_EXIT" -ne 0 ]; then
        echo "" >&2
        echo -e "  ${RED}✗ Rebase conflict — resolve manually then re-run${NC}" >&2
        echo -e "  Conflicted files:" >&2
        git diff --name-only --diff-filter=U 2>/dev/null | sed 's/^/    /' >&2
        echo "{\"status\":\"conflict\",\"commits_behind\":$BEHIND,\"message\":\"Rebase conflict — resolve manually then re-run\"}"
        exit 1
      fi

      echo -e "  ${GREEN}✓ Rebased successfully on upstream/main${NC}" >&2
      echo "{\"status\":\"synced\",\"commits_behind\":0,\"message\":\"Fork rebased on upstream/main\"}"
      exit 0
      ;;
  esac
else
  echo "" >&2
  echo -e "  ${GREEN}✓ Fork is up to date with upstream/main${NC}" >&2
  echo '{"status":"synced","commits_behind":0,"message":"Fork is up to date with upstream/main"}'
  exit 0
fi
