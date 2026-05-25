#!/usr/bin/env bash
#
# create-pr.sh — Create a draft PR with rich body using templates/pr-body.md
#
# Usage: bash scripts/create-pr.sh
# Requires: gh CLI (GitHub CLI)
# Stdout: JSON {pr_url, pr_number, draft, branch}
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
  echo '{"error":"gh CLI not found"}'
  exit 1
fi

# Check authentication
if ! gh auth status 2>&1 | grep -q "active"; then
  echo -e "${RED}Error: Not authenticated with GitHub CLI.${NC}" >&2
  echo "Run: gh auth login" >&2
  echo '{"error":"gh not authenticated"}'
  exit 1
fi

# Get branch info
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -z "$BRANCH" ]; then
  echo -e "${RED}Error: Not on any branch.${NC}" >&2
  echo '{"error":"Not on a branch"}'
  exit 1
fi

if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ] || [ "$BRANCH" = "develop" ]; then
  echo -e "${YELLOW}Warning: On $BRANCH branch. Feature branches are preferred.${NC}" >&2
fi

# Get commits since origin/main
COMMITS=$(git log --oneline origin/main..HEAD 2>/dev/null | head -10 || echo "")
LAST_MSG=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "")

# Build PR title from most significant commit subject
PR_TITLE="$LAST_MSG"
if [ -z "$PR_TITLE" ]; then
  PR_TITLE="Update from $BRANCH"
fi

# Extract CONTEXT, CHANGE, WHY from commits
CONTEXT_FIELDS=""
CHANGE_FIELDS=""
WHY_FIELDS=""

while IFS= read -r commit_line; do
  [ -z "$commit_line" ] && continue
  hash=$(echo "$commit_line" | awk '{print $1}')
  subject=$(echo "$commit_line" | cut -d' ' -f2-)

  body=$(git log -1 --format="%b" "$hash" 2>/dev/null || echo "")
  context=$(echo "$body" | grep "^CONTEXT:" | sed 's/^CONTEXT: *//' | tr '\n' ' ' | head -c 200 || true)
  change=$(echo "$body" | grep "^CHANGE:" | sed 's/^CHANGE: *//' | tr '\n' ' ' | head -c 200 || true)
  why=$(echo "$body" | grep "^WHY:" | sed 's/^WHY: *//' | tr '\n' ' ' | head -c 200 || true)
  impact=$(echo "$body" | grep "^IMPACT:" | sed 's/^IMPACT: *//' | tr '\n' ' ' | head -c 200 || true)

  if [ -n "$context" ]; then
    CONTEXT_FIELDS+="- **${subject}**: ${context}"$'\n'
  fi
  if [ -n "$change" ]; then
    CHANGE_FIELDS+="- **${subject}**: ${change}"$'\n'
  fi
  if [ -n "$why" ]; then
    WHY_FIELDS+="- **${subject}**: ${why}"$'\n'
  fi
done <<< "$COMMITS"

# Read PR template
TEMPLATE_PATH="skills/smart-git-commit/templates/pr-body.md"
if [ ! -f "$TEMPLATE_PATH" ]; then
  echo -e "${YELLOW}Warning: PR template not found at $TEMPLATE_PATH. Using inline body.${NC}" >&2
  TMP_BODY=$(mktemp)
  cat > "$TMP_BODY" <<- PRBODY
## What changed and why

$CHANGE_FIELDS

## Context

$CONTEXT_FIELDS

## How to test

1.
2.
3.

## Impact

$impact

## Checklist

- [ ] Tests pass locally
- [ ] No secrets or credentials in the diff
- [ ] Docs updated if behavior changed
- [ ] Breaking changes documented
- [ ] Issue linked (Closes #N)

## Notes for reviewer

<!-- Trade-offs made, things to look closely at, follow-up tickets -->
PRBODY
else
  # Fill template with commit data
  TMP_BODY=$(mktemp)
  cp "$TEMPLATE_PATH" "$TMP_BODY"

  # Replace placeholders with actual content
  if [ -n "$CHANGE_FIELDS" ]; then
    if command -v sed &>/dev/null; then
      # Use temporary file for cross-platform sed
      content="$CHANGE_FIELDS"
      awk -v r="$content" '{gsub(/<!-- Paste the CHANGE and WHY from your commit messages here -->/, r)}1' "$TMP_BODY" > "${TMP_BODY}.tmp" && mv "${TMP_BODY}.tmp" "$TMP_BODY"
    fi
  fi
  if [ -n "$CONTEXT_FIELDS" ]; then
    if command -v sed &>/dev/null; then
      content="$CONTEXT_FIELDS"
      awk -v r="$content" '{gsub(/<!-- Paste the CONTEXT from your commit messages — what existed before -->/, r)}1' "$TMP_BODY" > "${TMP_BODY}.tmp" && mv "${TMP_BODY}.tmp" "$TMP_BODY"
    fi
  fi
fi

# Create PR as draft
echo -e "Creating PR from ${CYAN}$BRANCH${NC} → ${CYAN}main${NC}..." >&2
echo "" >&2

set +e
PR_OUTPUT=$(gh pr create --title "$PR_TITLE" --body-file "$TMP_BODY" --draft 2>&1)
EXIT_CODE=$?
set -e

rm -f "$TMP_BODY"

if [ $EXIT_CODE -ne 0 ]; then
  echo -e "${RED}Failed to create PR:${NC}" >&2
  echo "$PR_OUTPUT" >&2
  echo "{\"error\":\"PR creation failed\",\"message\":\"$(echo "$PR_OUTPUT" | head -1 | sed 's/"/\\"/g')\"}"
  exit 1
fi

# Extract PR number and URL
PR_URL=$(echo "$PR_OUTPUT" | tr -d '[:space:]')
PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$' || echo 0)

echo -e "${GREEN}PR created: ${PR_URL}${NC}" >&2
echo "{\"pr_url\":\"$PR_URL\",\"pr_number\":$PR_NUMBER,\"draft\":true,\"branch\":\"$BRANCH\"}"
