#!/usr/bin/env bash
#
# generate-changelog.sh — Auto-generate CHANGELOG.md from git history
#
# Usage: bash scripts/generate-changelog.sh [from-tag]
#   If from-tag is omitted, uses the last git tag.
#   If no tags exist, uses the first commit.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  Smart Git Commit — Changelog Generator"
echo "=========================================="
echo ""

# ------------------------------------------------------------------
# 1. Determine tag range
# ------------------------------------------------------------------
FROM_TAG="${1:-}"

if [ -z "$FROM_TAG" ]; then
  # Try to get the last tag
  FROM_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
fi

if [ -z "$FROM_TAG" ]; then
  # No tags — use first commit
  FROM_TAG=$(git rev-list --max-parents=0 HEAD 2>/dev/null || echo "")
  if [ -z "$FROM_TAG" ]; then
    echo -e "${RED}No commits found in this repository.${NC}"
    exit 1
  fi
  TAG_RANGE="$FROM_TAG..HEAD"
  VERSION="0.1.0"
  echo -e "${YELLOW}No tags found. Using first commit as base.${NC}"
else
  TAG_RANGE="${FROM_TAG}..HEAD"
  # Extract version from tag (strip 'v' prefix)
  VERSION="${FROM_TAG#v}"
  echo -e "${CYAN}Range: ${FROM_TAG} → HEAD${NC}"
fi

echo ""

# ------------------------------------------------------------------
# 2. Extract commits by type
# ----------------------------------------------------------------->
COMMITS=$(git log "$TAG_RANGE" --oneline --no-decorate 2>/dev/null || echo "")

if [ -z "$COMMITS" ]; then
  echo -e "${YELLOW}No new commits since ${FROM_TAG}.${NC}"
  exit 0
fi

echo "Found $(echo "$COMMITS" | wc -l) commit(s) to include."
echo ""

# Categorize commits
FEATURES=$(git log "$TAG_RANGE" --oneline --grep="^feat" 2>/dev/null || echo "")
BUGFIXES=$(git log "$TAG_RANGE" --oneline --grep="^fix" 2>/dev/null || echo "")
PERF=$(git log "$TAG_RANGE" --oneline --grep="^perf" 2>/dev/null || echo "")
SECURITY=$(git log "$TAG_RANGE" --oneline --grep="^security" 2>/dev/null || echo "")
CHORES=$(git log "$TAG_RANGE" --oneline --grep="^chore" 2>/dev/null || echo "")
DOCS=$(git log "$TAG_RANGE" --oneline --grep="^docs" 2>/dev/null || echo "")
TESTS=$(git log "$TAG_RANGE" --oneline --grep="^test" 2>/dev/null || echo "")
REFACTOR=$(git log "$TAG_RANGE" --oneline --grep="^refactor" 2>/dev/null || echo "")

# Check for breaking changes
BREAKING=$(git log "$TAG_RANGE" --oneline --grep="BREAKING CHANGE" 2>/dev/null || echo "")
if [ -n "$BREAKING" ]; then
  MAJOR=$(echo "${VERSION%%.*}" || echo "0")
  MAJOR=$((MAJOR + 1))
  VERSION="${MAJOR}.0.0"
elif [ -n "$FEATURES" ]; then
  # Bump minor
  MAJOR="${VERSION%%.*}"
  MINOR_PATCH="${VERSION#*.}"
  MINOR="${MINOR_PATCH%%.*}"
  PATCH="${MINOR_PATCH#*.}"
  PATCH="${PATCH%%.*}"
  if [ -z "$PATCH" ]; then PATCH="0"; fi
  MINOR=$((MINOR + 1))
  VERSION="${MAJOR}.${MINOR}.0"
else
  # Bump patch
  MAJOR="${VERSION%%.*}"
  MINOR_PATCH="${VERSION#*.}"
  MINOR="${MINOR_PATCH%%.*}"
  PATCH="${MINOR_PATCH#*.}"
  PATCH="${PATCH%%.*}"
  if [ -z "$PATCH" ]; then PATCH="0"; fi
  PATCH=$((PATCH + 1))
  VERSION="${MAJOR}.${MINOR}.${PATCH}"
fi

# ------------------------------------------------------------------
# 3. Generate changelog content
# ------------------------------------------------------------------
DATE=$(date +%Y-%m-%d)
CHANGELOG="## [${VERSION}] - ${DATE}\n\n"

# Breaking changes section
if [ -n "$BREAKING" ]; then
  CHANGELOG+="### ⚠️ Breaking Changes\n\n"
  while IFS= read -r line; do
    commit_msg=$(echo "$line" | sed 's/^[a-f0-9]\{7,9\} //')
    CHANGELOG+="- ${commit_msg}\n"
  done <<< "$BREAKING"
  CHANGELOG+="\n"
fi

# Features
if [ -n "$FEATURES" ]; then
  CHANGELOG+="### 🚀 Features\n\n"
  while IFS= read -r line; do
    commit_msg=$(echo "$line" | sed 's/^[a-f0-9]\{7,9\} //')
    CHANGELOG+="- ${commit_msg}\n"
  done <<< "$FEATURES"
  CHANGELOG+="\n"
fi

# Bug Fixes
if [ -n "$BUGFIXES" ]; then
  CHANGELOG+="### 🐛 Bug Fixes\n\n"
  while IFS= read -r line; do
    commit_msg=$(echo "$line" | sed 's/^[a-f0-9]\{7,9\} //')
    CHANGELOG+="- ${commit_msg}\n"
  done <<< "$BUGFIXES"
  CHANGELOG+="\n"
fi

# Performance
if [ -n "$PERF" ]; then
  CHANGELOG+="### ⚡ Performance\n\n"
  while IFS= read -r line; do
    commit_msg=$(echo "$line" | sed 's/^[a-f0-9]\{7,9\} //')
    CHANGELOG+="- ${commit_msg}\n"
  done <<< "$PERF"
  CHANGELOG+="\n"
fi

# Security
if [ -n "$SECURITY" ]; then
  CHANGELOG+="### 🔒 Security\n\n"
  while IFS= read -r line; do
    commit_msg=$(echo "$line" | sed 's/^[a-f0-9]\{7,9\} //')
    CHANGELOG+="- ${commit_msg}\n"
  done <<< "$SECURITY"
  CHANGELOG+="\n"
fi

# Refactor
if [ -n "$REFACTOR" ]; then
  CHANGELOG+="### 🔧 Refactoring\n\n"
  while IFS= read -r line; do
    commit_msg=$(echo "$line" | sed 's/^[a-f0-9]\{7,9\} //')
    CHANGELOG+="- ${commit_msg}\n"
  done <<< "$REFACTOR"
  CHANGELOG+="\n"
fi

# Tests
if [ -n "$TESTS" ]; then
  CHANGELOG+="### 🧪 Tests\n\n"
  while IFS= read -r line; do
    commit_msg=$(echo "$line" | sed 's/^[a-f0-9]\{7,9\} //')
    CHANGELOG+="- ${commit_msg}\n"
  done <<< "$TESTS"
  CHANGELOG+="\n"
fi

# Documentation
if [ -n "$DOCS" ]; then
  CHANGELOG+="### 📖 Documentation\n\n"
  while IFS= read -r line; do
    commit_msg=$(echo "$line" | sed 's/^[a-f0-9]\{7,9\} //')
    CHANGELOG+="- ${commit_msg}\n"
  done <<< "$DOCS"
  CHANGELOG+="\n"
fi

# Chores / Maintenance
if [ -n "$CHORES" ]; then
  CHANGELOG+="### 🛠 Maintenance\n\n"
  while IFS= read -r line; do
    commit_msg=$(echo "$line" | sed 's/^[a-f0-9]\{7,9\} //')
    CHANGELOG+="- ${commit_msg}\n"
  done <<< "$CHORES"
  CHANGELOG+="\n"
fi

# ------------------------------------------------------------------
# 4. Prepend to CHANGELOG.md (or create new)
# ------------------------------------------------------------------
CHANGELOG="# Changelog\n\n${CHANGELOG}"

if [ -f "CHANGELOG.md" ]; then
  # Read existing content (skip first line which is "# Changelog")
  EXISTING=$(tail -n +3 CHANGELOG.md 2>/dev/null || true)
  echo -e "${CHANGELOG}${EXISTING}" > CHANGELOG.md
else
  echo -e "${CHANGELOG}" > CHANGELOG.md
fi

echo -e "${GREEN}✅ CHANGELOG.md updated${NC}"
echo "   Version: v${VERSION}"
echo "   Date: ${DATE}"
echo ""

# Show summary
echo "Summary of changes:"
[ -n "$BREAKING" ] && echo "   ⚠️  Breaking: $(echo "$BREAKING" | wc -l)"
[ -n "$FEATURES" ] && echo "   🚀 Features: $(echo "$FEATURES" | wc -l)"
[ -n "$BUGFIXES" ] && echo "   🐛 Fixes: $(echo "$BUGFIXES" | wc -l)"
[ -n "$PERF" ] && echo "   ⚡ Performance: $(echo "$PERF" | wc -l)"
[ -n "$SECURITY" ] && echo "   🔒 Security: $(echo "$SECURITY" | wc -l)"
[ -n "$REFACTOR" ] && echo "   🔧 Refactor: $(echo "$REFACTOR" | wc -l)"
[ -n "$TESTS" ] && echo "   🧪 Tests: $(echo "$TESTS" | wc -l)"
[ -n "$DOCS" ] && echo "   📖 Docs: $(echo "$DOCS" | wc -l)"
[ -n "$CHORES" ] && echo "   🛠 Chores: $(echo "$CHORES" | wc -l)"

echo ""
echo "=========================================="
