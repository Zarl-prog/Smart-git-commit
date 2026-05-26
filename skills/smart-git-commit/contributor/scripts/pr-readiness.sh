#!/usr/bin/env bash
#
# pr-readiness.sh — Full pre-PR checklist runner
#
# Usage: bash contributor/scripts/pr-readiness.sh
# Exit code: 0 = ready, 1 = blocking issues found
# Stdout: JSON {"ready":true|false,"blocking":[],"warnings":[]}
# Stderr: Human-readable color checklist

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Smart Git Commit — PR Readiness Check${NC}" >&2
echo "" >&2

BLOCKING=()
WARNINGS=()
ALL_PASSED=true

# CHECK 1: Tests pass
echo -e "  [1/7] Checking tests..." >&2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$SCRIPT_DIR/../scripts/detect-test-runner.sh" ]; then
  TEST_RESULT=$(bash "$SCRIPT_DIR/../scripts/detect-test-runner.sh" 2>/dev/null || echo '{"status":"not_found"}')
  TEST_STATUS=$(echo "$TEST_RESULT" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "not_found")

  if [ "$TEST_STATUS" = "pass" ]; then
    TEST_COUNT=$(echo "$TEST_RESULT" | grep -o '"test_count":[0-9]*' | cut -d: -f2 || echo "all")
    echo -e "  ${GREEN}✓ Tests pass${NC}" >&2
  elif [ "$TEST_STATUS" = "not_found" ]; then
    echo -e "  ${YELLOW}⚠ No test runner detected — skipping${NC}" >&2
    WARNINGS+=("No test runner detected — verify manually before submitting")
  else
    echo -e "  ${RED}✗ Tests failed — run test suite and fix failures first${NC}" >&2
    BLOCKING+=("Tests failed — run the test suite and fix failures first")
    ALL_PASSED=false
  fi
else
  echo -e "  ${YELLOW}⚠ No test detection script found — verify manually${NC}" >&2
  WARNINGS+=("No test detection script found — verify manually")
fi

# CHECK 2: No secrets
echo -e "  [2/7] Scanning for secrets..." >&2
if [ -f "$SCRIPT_DIR/../scripts/scan-secrets.sh" ]; then
  set +e
  bash "$SCRIPT_DIR/../scripts/scan-secrets.sh" > /dev/null 2>&1
  SCAN_EXIT=$?
  set -e

  if [ "$SCAN_EXIT" -eq 0 ]; then
    echo -e "  ${GREEN}✓ No secrets found${NC}" >&2
  else
    echo -e "  ${RED}✗ Secrets detected in diff${NC}" >&2
    BLOCKING+=("Secrets detected in diff — run scan-secrets.sh and fix before submitting")
    ALL_PASSED=false
  fi
else
  echo -e "  ${YELLOW}⚠ No scan-secrets.sh found — skipping${NC}" >&2
  WARNINGS+=("No scan-secrets.sh found — recommend manual secret check")
fi

# CHECK 3: Not on main/master/develop
echo -e "  [3/7] Checking target branch..." >&2
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ] || [ "$CURRENT_BRANCH" = "develop" ] || [ "$CURRENT_BRANCH" = "dev" ]; then
  echo -e "  ${RED}✗ On protected branch: ${CURRENT_BRANCH}${NC}" >&2
  BLOCKING+=("On protected branch '$CURRENT_BRANCH' — create a feature branch first")
  ALL_PASSED=false
else
  echo -e "  ${GREEN}✓ On feature branch: ${CURRENT_BRANCH}${NC}" >&2
fi

# CHECK 4: Fork synced
echo -e "  [4/7] Checking fork sync status..." >&2
if git remote -v 2>/dev/null | grep -q "^upstream"; then
  set +e
  FORK_RESULT=$(bash "$SCRIPT_DIR/scripts/fork-check.sh" 2>/dev/null || echo '{"status":"conflict"}')
  set -e
  FORK_STATUS=$(echo "$FORK_RESULT" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "unknown")

  if [ "$FORK_STATUS" = "synced" ]; then
    echo -e "  ${GREEN}✓ Fork is synced with upstream${NC}" >&2
  elif [ "$FORK_STATUS" = "behind" ]; then
    echo -e "  ${RED}✗ Fork is behind upstream — run fork-check.sh to rebase${NC}" >&2
    BLOCKING+=("Fork is behind upstream — run fork-check.sh to rebase first")
    ALL_PASSED=false
  else
    echo -e "  ${RED}✗ Fork sync check failed — run fork-check.sh${NC}" >&2
    BLOCKING+=("Fork sync check failed — run fork-check.sh and resolve conflicts first")
    ALL_PASSED=false
  fi
else
  echo -e "  ${YELLOW}⚠ No upstream remote — skipping fork sync check${NC}" >&2
  WARNINGS+=("No upstream remote configured — fork sync not verified")
fi

# CHECK 5: CONTRIBUTING.md check
echo -e "  [5/7] Checking CONTRIBUTING.md..." >&2
if [ -f "CONTRIBUTING.md" ]; then
  echo -e "  ${GREEN}✓ CONTRIBUTING.md found${NC}" >&2
  echo "" >&2
  echo -e "  Key rules from CONTRIBUTING.md:" >&2
  head -50 CONTRIBUTING.md 2>/dev/null | while IFS= read -r line; do
    echo -e "    $line" >&2
  done
  echo "" >&2
  WARNINGS+=("CONTRIBUTING.md found — ensure all rules are followed")
else
  echo -e "  ${YELLOW}⚠ No CONTRIBUTING.md found in repo${NC}" >&2
fi

# CHECK 6: Issue linked
echo -e "  [6/7] Checking for linked issue..." >&2
ISSUE_NUM=$(echo "$CURRENT_BRANCH" | grep -oE '[0-9]+' | head -1 || echo "")
if [ -n "$ISSUE_NUM" ]; then
  echo -e "  ${GREEN}✓ Issue referenced in branch name: #${ISSUE_NUM}${NC}" >&2
else
  echo -e "  ${YELLOW}⚠ No issue number found in branch name${NC}" >&2
  WARNINGS+=("No issue number found in branch name — consider linking an issue in the PR body")
fi

# CHECK 7: Diff is not empty
echo -e "  [7/7] Checking diff contents..." >&2
DIFF_STATS=$(git diff origin/main..HEAD --stat 2>/dev/null | wc -l | tr -d ' ' || echo "0")
if [ "$DIFF_STATS" -gt 0 ]; then
  echo -e "  ${GREEN}✓ Diff contains changes${NC}" >&2
else
  DIFF_STATS=$(git diff --stat 2>/dev/null | wc -l | tr -d ' ' || echo "0")
  if [ "$DIFF_STATS" -gt 0 ]; then
    echo -e "  ${GREEN}✓ Unstaged changes found${NC}" >&2
  else
    echo -e "  ${YELLOW}⚠ No changes detected in diff${NC}" >&2
    WARNINGS+=("No changes detected — ensure you've made changes before submitting")
  fi
fi

# Build JSON output
BLOCKING_JSON="["
FIRST=true
for item in "${BLOCKING[@]}"; do
  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    BLOCKING_JSON+=","
  fi
  BLOCKING_JSON+="\"$item\""
done
BLOCKING_JSON+="]"

WARNINGS_JSON="["
FIRST=true
for item in "${WARNINGS[@]}"; do
  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    WARNINGS_JSON+=","
  fi
  WARNINGS_JSON+="\"$item\""
done
WARNINGS_JSON+="]"

echo "" >&2
if [ "$ALL_PASSED" = true ]; then
  echo -e "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  echo -e "  ${GREEN}  READY TO SUBMIT${NC}" >&2
  echo -e "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  echo "{\"ready\":true,\"blocking\":$BLOCKING_JSON,\"warnings\":$WARNINGS_JSON}"
  exit 0
else
  echo -e "  ${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  echo -e "  ${RED}  BLOCKING ISSUES FOUND${NC}" >&2
  echo -e "  ${RED}  Fix all ✗ items before submitting${NC}" >&2
  echo -e "  ${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  for item in "${BLOCKING[@]}"; do
    echo -e "  ${RED}✗${NC} $item" >&2
  done
  echo "{\"ready\":false,\"blocking\":$BLOCKING_JSON,\"warnings\":$WARNINGS_JSON}"
  exit 1
fi
