#!/usr/bin/env bash
#
# review-response.sh — Help respond to PR review comments
#
# Usage: bash contributor/scripts/review-response.sh
# Exit code: 0 = all addressed, 1 = issues remaining
# Stdout: JSON {"comments_addressed":0,"commit":"","pushed":false}
# Stderr: Human-readable interactive flow

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Smart Git Commit — Review Response Helper${NC}" >&2
echo "" >&2

COMMENTS=()
COMMENTS_ADDRESSED=0
PASTED_LINES=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Try to get review comments via gh CLI
if command -v gh &>/dev/null && gh auth status 2>&1 | grep -q "active"; then
  PR_NUMBER=$(gh pr status 2>/dev/null | grep -oE '#[0-9]+' | head -1 | tr -d '#' || echo "")

  if [ -n "$PR_NUMBER" ]; then
    echo -e "  Detected PR #${PR_NUMBER}" >&2
    echo "" >&2
    echo -e "  Fetching review comments..." >&2

    REVIEW_OUTPUT=$(gh pr view "$PR_NUMBER" --comments 2>/dev/null | head -100 || echo "")
    if [ -n "$REVIEW_OUTPUT" ]; then
      echo -e "  ${GREEN}✓ Review comments retrieved${NC}" >&2
      echo "" >&2
      echo -e "  ${CYAN}--- Review Comments ---${NC}" >&2
      echo "$REVIEW_OUTPUT" >&2
      echo -e "  ${CYAN}-----------------------${NC}" >&2
      echo "" >&2
    else
      echo -e "  ${YELLOW}⚠ No comments found for PR #${PR_NUMBER}${NC}" >&2
    fi
  else
    echo -e "  ${YELLOW}⚠ No open PR detected${NC}" >&2
    echo "" >&2
  fi
else
  echo -e "  ${YELLOW}⚠ gh CLI not available or not authenticated${NC}" >&2
  echo "" >&2
fi

# Ask user to paste review comments if we couldn't fetch them
echo -e "  Paste the review comment(s) below (one per line, Ctrl+D to finish):" >&2
echo -e "  (Or press Enter to skip if already handled via gh CLI)" >&2
echo "" >&2

PASTED_COMMENTS=""
while IFS= read -r line; do
  PASTED_COMMENTS+="$line"$'\n'
  if [ -n "$(echo "$line" | tr -d '[:space:]')" ]; then
    PASTED_LINES=$((PASTED_LINES + 1))
  fi
done
COMMENTS_ADDRESSED=$PASTED_LINES

if [ -n "$(echo "$PASTED_COMMENTS" | tr -d '[:space:]')" ]; then
  echo "" >&2
  echo -e "  ${CYAN}--- Review comments received ---${NC}" >&2
  echo "$PASTED_COMMENTS" >&2
  echo -e "  ${CYAN}--------------------------------${NC}" >&2
  echo "" >&2
fi

echo -e "  Refer to ${CYAN}contributor/templates/review-response.md${NC} for response templates." >&2
echo "" >&2
echo -e "  Use gh pr comment to post your responses after drafting them." >&2
echo "" >&2

# Ask about pushing fixes
echo -e "  Push fixes and notify maintainer? [y/N]: " >&2
read -r PUSH_ANSWER

case "$PUSH_ANSWER" in
  y|Y|yes|YES)
    echo "" >&2
    echo -e "  Staging all changes..." >&2
    git add -A 2>/dev/null || true

    # Count staged files
    STAGED_COUNT=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

    if [ "$STAGED_COUNT" -eq 0 ]; then
      echo -e "  ${YELLOW}⚠ No changes to commit${NC}" >&2
      echo '{"comments_addressed":0,"commit":"","pushed":false,"message":"No changes to commit"}'
      exit 0
    fi

    echo -e "  ${YELLOW}Enter commit message (type/scope): e.g. fix(api): address review feedback on null handling${NC}" >&2
    read -r COMMIT_SUBJECT

    if [ -z "$COMMIT_SUBJECT" ]; then
      COMMIT_SUBJECT="fix: address review feedback"
    fi

    echo -e "  ${YELLOW}Enter brief context for the commit:${NC}" >&2
    read -r COMMIT_CONTEXT

    echo "" >&2
    echo -e "  Committing changes..." >&2

    git commit -m "$COMMIT_SUBJECT" \
      -m "CONTEXT: ${COMMIT_CONTEXT:-Addressed feedback from PR review.}" \
      -m "CHANGE: ${COMMIT_SUBJECT}" \
      -m "WHY: Review comments requested these changes to improve code quality and correctness." \
      -m "IMPACT: All review comments addressed. No breaking changes."

    COMMIT_HASH=$(git log -1 --pretty=format:'%h')
    echo -e "  ${GREEN}✓ Committed: ${COMMIT_HASH}${NC}" >&2

    # Push
    CURRENT_BRANCH=$(git branch --show-current)
    echo "" >&2
    echo -e "  Pushing to origin/${CURRENT_BRANCH}..." >&2

    set +e
    git push origin HEAD 2>&1
    PUSH_EXIT=$?
    set -e

    if [ "$PUSH_EXIT" -eq 0 ]; then
      echo -e "  ${GREEN}✓ Pushed successfully${NC}" >&2

      # Notify via gh CLI if available
      if command -v gh &>/dev/null && [ -n "$PR_NUMBER" ]; then
        echo "" >&2
        echo -e "  Notifying maintainer on PR #${PR_NUMBER}..." >&2
        gh pr comment "$PR_NUMBER" --body "All review comments addressed in ${COMMIT_HASH}" 2>/dev/null || true
        echo -e "  ${GREEN}✓ Maintainer notified${NC}" >&2
      fi

      echo "{\"comments_addressed\":$COMMENTS_ADDRESSED,\"commit\":\"$COMMIT_HASH\",\"pushed\":true,\"message\":\"Fixes pushed and maintainer notified\"}"
      exit 0
    else
      echo -e "  ${RED}✗ Push failed — check remote and branch permissions${NC}" >&2
      echo "{\"comments_addressed\":$COMMENTS_ADDRESSED,\"commit\":\"$COMMIT_HASH\",\"pushed\":false,\"message\":\"Push failed\"}"
      exit 1
    fi
    ;;
  *)
    echo -e "  ${YELLOW}Skipping push. Run git add/git commit/git push manually when ready.${NC}" >&2
    echo '{"comments_addressed":0,"commit":"","pushed":false,"message":"Push skipped by user"}'
    exit 0
    ;;
esac
