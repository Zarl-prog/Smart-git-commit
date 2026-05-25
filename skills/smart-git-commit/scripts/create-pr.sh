#!/usr/bin/env bash
#
# create-pr.sh — Create a draft PR with rich body from commit data
#
# Usage: bash scripts/create-pr.sh [--draft] [--base <branch>]
# Requires: gh CLI (GitHub CLI)
# Stdout: JSON {pr_url, pr_number, draft}
# Stderr: Human-readable progress

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Smart Git Commit — PR Creator${NC}" >&2
echo "" >&2

# Check dependencies
if ! command -v gh &>/dev/null; then
  echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}" >&2
  echo "Install: https://cli.github.com/" >&2
  echo '{"status":"error","message":"gh CLI not installed"}' >&2
  exit 1
fi

# Check gh auth
if ! gh auth status 2>&1 | grep -q "active"; then
  echo -e "${RED}Error: Not authenticated with GitHub CLI.${NC}" >&2
  echo "Run: gh auth login" >&2
  echo '{"status":"error","message":"Not authenticated with gh CLI"}' >&2
  exit 1
fi

# Parse args
IS_DRAFT=true
BASE_BRANCH="main"

while [ $# -gt 0 ]; do
  case "$1" in
    --no-draft) IS_DRAFT=false; shift;;
    --base) BASE_BRANCH="$2"; shift 2;;
    *) shift;;
  esac
done

# Get branch info
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -z "$BRANCH" ]; then
  echo -e "${RED}Error: Not on any branch.${NC}" >&2
  echo '{"status":"error","message":"Not on a branch"}' >&2
  exit 1
fi

# Auto-detect base branch from branch prefix
if echo "$BRANCH" | grep -qE "^hotfix/|^release/"; then
  BASE_BRANCH="main"
  echo -e "${YELLOW}Detected $BRANCH — targeting main branch.${NC}" >&2
elif echo "$BRANCH" | grep -qE "^feature/|^feat/|^fix/|^chore/|^docs/"; then
  BASE_BRANCH="develop"
  echo -e "${CYAN}Detected $BRANCH — targeting develop branch.${NC}" >&2
fi

if [ "$BRANCH" = "$BASE_BRANCH" ] || [ "$BRANCH" = "develop" ]; then
  echo -e "${YELLOW}Warning: On $BRANCH branch. Feature branches are preferred.${NC}" >&2
fi

# Get recent commits
COMMITS=$(git log --oneline -5 2>/dev/null || echo "")
if [ -z "$COMMITS" ]; then
  echo -e "${YELLOW}No recent commits found.${NC}" >&2
fi

# Extract PR title from most significant commit
PR_TITLE=$(git log -1 --format="%s" 2>/dev/null || echo "Update from $BRANCH")

# Build PR body
PR_BODY="# What changed and why\n\n"
PR_BODY+="## Commits in this PR\n\n"

while IFS= read -r line; do
  if [ -n "$line" ]; then
    hash=$(echo "$line" | awk '{print $1}')
    subject=$(echo "$line" | cut -d' ' -f2-)
    # Try to extract CONTEXT/WHY from commit body
    body=$(git log -1 --format="%b" "$hash" 2>/dev/null || echo "")
    context=$(echo "$body" | grep "^CONTEXT:" | sed 's/^CONTEXT: *//' || echo "")
    why=$(echo "$body" | grep "^WHY:" | sed 's/^WHY: *//' || echo "")

    PR_BODY+="### \`$subject\`\n"
    [ -n "$context" ] && PR_BODY+="**Context:** $context\n"
    [ -n "$why" ] && PR_BODY+="**Why:** $why\n"
    PR_BODY+="\n"
  fi
done <<< "$COMMITS"

# Add checklist
PR_BODY+="## Checklist\n\n"
PR_BODY+="- [ ] Tests pass\n"
PR_BODY+="- [ ] No secrets in diff\n"
PR_BODY+="- [ ] Breaking changes documented\n"
PR_BODY+="- [ ] Related issue linked\n\n"

# Add reviewer notes section
PR_BODY+="## Notes for reviewer\n\n"
PR_BODY+="<!-- Add context for the reviewer -->\n"

# Write body to temp file
TMP_BODY=$(mktemp)
printf "%b" "$PR_BODY" > "$TMP_BODY"

# Build gh command
GH_CMD="gh pr create --title \"$PR_TITLE\" --body-file \"$TMP_BODY\" --base \"$BASE_BRANCH\""
if [ "$IS_DRAFT" = true ]; then
  GH_CMD+=" --draft"
fi

echo -e "Creating PR from ${CYAN}$BRANCH${NC} → ${CYAN}$BASE_BRANCH${NC}..." >&2
echo "" >&2

set +e
PR_OUTPUT=$(eval "$GH_CMD" 2>&1)
EXIT_CODE=$?
set -e

rm -f "$TMP_BODY"

if [ $EXIT_CODE -ne 0 ]; then
  echo -e "${RED}Failed to create PR:${NC}" >&2
  echo "$PR_OUTPUT" >&2
  echo "{\"status\":\"error\",\"message\":\"PR creation failed\",\"error\":\"$(echo "$PR_OUTPUT" | head -1 | sed 's/"/\\"/g')\"}"
  exit 1
fi

echo -e "${GREEN}PR created: ${PR_OUTPUT}${NC}" >&2
echo "{\"status\":\"success\",\"pr_url\":\"$(echo "$PR_OUTPUT" | tr -d '[:space:]')\",\"draft\":$IS_DRAFT,\"message\":\"PR created successfully\"}"
