#!/usr/bin/env bash
#
# branch-name.sh — Enforce branch naming conventions for contributors
#
# Usage: bash contributor/scripts/branch-name.sh
# Exit code: 0 = valid, 1 = invalid/fixed
# Stdout: JSON {"status":"valid"|"invalid"|"fixed","branch":"","renamed_from":""}
# Stderr: Human-readable color output

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Smart Git Commit — Branch Name Enforcer${NC}" >&2
echo "" >&2

# Get current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -z "$CURRENT_BRANCH" ]; then
  echo -e "  ${RED}✗ Not on any branch (detached HEAD?)${NC}" >&2
  echo '{"status":"invalid","branch":"","renamed_from":"","message":"Not on any branch"}'
  exit 1
fi

echo -e "  Current branch: ${CYAN}${CURRENT_BRANCH}${NC}" >&2
echo "" >&2

# Check if on a protected branch (main, master, develop, dev)
PROTECTED_BRANCHES=("main" "master" "develop" "dev")
for pb in "${PROTECTED_BRANCHES[@]}"; do
  if [ "$CURRENT_BRANCH" = "$pb" ]; then
    echo -e "  ${RED}✗ Cannot contribute from the '${pb}' branch.${NC}" >&2
    echo -e "  Contributors must create a feature branch first." >&2
    echo "" >&2

    echo -e "  Enter correct branch name (e.g. feat/234-add-oauth-login): " >&2
    read -r NEW_BRANCH

    if [ -z "$NEW_BRANCH" ]; then
      echo -e "  ${RED}✗ No branch name provided.${NC}" >&2
      echo '{"status":"invalid","branch":"'$CURRENT_BRANCH'","renamed_from":"","message":"No branch name provided"}'
      exit 1
    fi

    # Validate branch name pattern
    if ! echo "$NEW_BRANCH" | grep -qE '^(feat|fix|docs|chore|perf|refactor|test|security)\/[0-9]*-?[a-z0-9-]+$'; then
      echo -e "  ${RED}✗ Invalid branch name: '${NEW_BRANCH}'${NC}" >&2
      echo -e "  Pattern must be: <type>/<issue-number>-<short-description>" >&2
      echo -e "  Valid types: feat, fix, docs, chore, perf, refactor, test, security" >&2
      echo '{"status":"invalid","branch":"'$NEW_BRANCH'","renamed_from":"","message":"Invalid branch name format"}'
      exit 1
    fi

    # Stash uncommitted changes if any
    HAS_CHANGES=false
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
      HAS_CHANGES=true
      echo -e "  Stashing uncommitted changes..." >&2
      git stash push -m "auto-stash before branch rename" 2>/dev/null || true
    fi

    git checkout -b "$NEW_BRANCH" 2>/dev/null

    if [ "$HAS_CHANGES" = true ]; then
      echo -e "  Restoring stashed changes..." >&2
      git stash pop 2>/dev/null || true
    fi

    echo -e "  ${GREEN}✓ Created and switched to: ${NEW_BRANCH}${NC}" >&2
    echo "{\"status\":\"fixed\",\"branch\":\"$NEW_BRANCH\",\"renamed_from\":\"$CURRENT_BRANCH\",\"message\":\"Branch created and switched\"}"
    exit 0
  fi
done

# Validate branch name pattern
if echo "$CURRENT_BRANCH" | grep -qE '^(feat|fix|docs|chore|perf|refactor|test|security)\/[0-9]*-?[a-z0-9-]+$'; then
  echo -e "  ${GREEN}✓ Branch name follows convention: ${CURRENT_BRANCH}${NC}" >&2
  echo "{\"status\":\"valid\",\"branch\":\"$CURRENT_BRANCH\",\"renamed_from\":\"\",\"message\":\"Branch name is valid\"}"
  exit 0
else
  echo -e "  ${RED}✗ Invalid branch name: ${CURRENT_BRANCH}${NC}" >&2
  echo -e "  Pattern must be: <type>/<issue-number>-<short-description>" >&2
  echo -e "  Valid types: feat, fix, docs, chore, perf, refactor, test, security" >&2
  echo "" >&2

  echo -e "  Enter correct branch name (e.g. feat/234-add-oauth-login): " >&2
  read -r NEW_BRANCH

  if [ -z "$NEW_BRANCH" ]; then
    echo -e "  ${RED}✗ No branch name provided.${NC}" >&2
    echo '{"status":"invalid","branch":"'$CURRENT_BRANCH'","renamed_from":"","message":"No branch name provided"}'
    exit 1
  fi

  if ! echo "$NEW_BRANCH" | grep -qE '^(feat|fix|docs|chore|perf|refactor|test|security)\/[0-9]*-?[a-z0-9-]+$'; then
    echo -e "  ${RED}✗ Invalid branch name: '${NEW_BRANCH}'${NC}" >&2
    echo "{\"status\":\"invalid\",\"branch\":\"$NEW_BRANCH\",\"renamed_from\":\"$CURRENT_BRANCH\",\"message\":\"Invalid branch name format\"}"
    exit 1
  fi

  # Stash uncommitted changes if any
  HAS_CHANGES=false
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    HAS_CHANGES=true
    echo -e "  Stashing uncommitted changes..." >&2
    git stash push -m "auto-stash before branch rename" 2>/dev/null || true
  fi

  git checkout -b "$NEW_BRANCH" 2>/dev/null

  if [ "$HAS_CHANGES" = true ]; then
    echo -e "  Restoring stashed changes..." >&2
    git stash pop 2>/dev/null || true
  fi

  echo -e "  ${GREEN}✓ Created and switched to: ${NEW_BRANCH}${NC}" >&2
  echo "{\"status\":\"fixed\",\"branch\":\"$NEW_BRANCH\",\"renamed_from\":\"$CURRENT_BRANCH\",\"message\":\"Branch created and switched\"}"
  exit 0
fi
