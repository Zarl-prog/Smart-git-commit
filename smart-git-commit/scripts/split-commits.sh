#!/usr/bin/env bash
#
# split-commits.sh — Analyze and suggest atomic commit splitting
#
# Usage: bash scripts/split-commits.sh
# This script analyzes the current diff and suggests how to split
# changes into atomic commits grouped by concern.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  Smart Git Commit — Atomic Split"
echo "=========================================="
echo ""

# ------------------------------------------------------------------
# 1. Check for changes
# ------------------------------------------------------------------
if git diff --cached --quiet 2>/dev/null; then
  echo "No staged changes found."
  echo ""
  echo "Checking working tree changes instead..."
  echo ""
fi

if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
  echo -e "${YELLOW}No changes detected in working tree or staging area.${NC}"
  exit 0
fi

# ------------------------------------------------------------------
# 2. Show diff summary grouped by directory
# ------------------------------------------------------------------
echo "📂 Changed files:"
echo ""

# Show files grouped by top-level directory
if git diff --cached --quiet 2>/dev/null; then
  # No staged changes, use working tree
  FILES=$(git diff --name-only 2>/dev/null)
else
  FILES=$(git diff --cached --name-only 2>/dev/null)
fi

declare -A DIR_MAP
while IFS= read -r file; do
  dir=$(dirname "$file" | cut -d'/' -f1)
  if [ "$dir" = "." ]; then dir="/ (root)"; fi
  DIR_MAP["$dir"]+="$file|"
done <<< "$FILES"

for dir in "${!DIR_MAP[@]}"; do
  echo "  ${dir}/"
  IFS='|' read -ra files <<< "${DIR_MAP[$dir]}"
  for f in "${files[@]}"; do
    [ -n "$f" ] && echo "    - $f"
  done
  echo ""
done

# ------------------------------------------------------------------
# 3. Suggest concerns
# ------------------------------------------------------------------
echo "--- Analyzing concerns ---"
echo ""

# Check for common patterns
CONCERNS=()

# Check for test files
if echo "$FILES" | grep -qiE "(test|spec|__tests__)" 2>/dev/null; then
  CONCERNS+=("Testing (test)")
fi

# Check for config files
if echo "$FILES" | grep -qiE "(\.env|\.json|\.yaml|\.yml|\.toml|Dockerfile|Makefile|\.gitignore)" 2>/dev/null; then
  CONCERNS+=("Configuration (chore)")
fi

# Check for docs
if echo "$FILES" | grep -qiE "(\.md|README|CHANGELOG|docs/)" 2>/dev/null; then
  CONCERNS+=("Documentation (docs)")
fi

# Check for migrations
if echo "$FILES" | grep -qiE "(migration|migrate|schema)" 2>/dev/null; then
  CONCERNS+=("Database / Migration")
fi

# If we have source files, suggest split by directory
SOURCE_FILES=$(echo "$FILES" | grep -vE "(test|spec|\.md|Dockerfile|Makefile|\.gitignore|\.json|\.yaml|\.yml|\.toml)" 2>/dev/null || true)
if [ -n "$SOURCE_FILES" ]; then
  SOURCE_DIRS=$(dirname "$SOURCE_FILES" 2>/dev/null | sort -u | head -10)
  for dir in $SOURCE_DIRS; do
    TOP=$(echo "$dir" | cut -d'/' -f1)
    if [ "$TOP" != "." ]; then
      CONCERNS+=("${TOP} changes (feat/fix)")
    fi
  done
fi

# Remove duplicates
IFS=$'\n' CONCERNS=($(printf "%s\n" "${CONCERNS[@]}" | sort -u))
unset IFS

echo "I see $(echo "$FILES" | wc -l) file(s) changed across ${#CONCERNS[@]} concern(s):"
for c in "${CONCERNS[@]}"; do
  echo "  - $c"
done
echo ""

# ------------------------------------------------------------------
# 4. Suggest split plan
# ------------------------------------------------------------------
echo "--- Suggested split plan ---"
echo ""

if [ ${#CONCERNS[@]} -le 1 ]; then
  echo -e "${GREEN}Single concern detected — one commit is fine.${NC}"
  echo "Suggested: git add the files and commit."
  exit 0
fi

echo -e "${CYAN}I recommend splitting into ${#CONCERNS[@]} atomic commits:${NC}"
echo ""

COUNT=1
for c in "${CONCERNS[@]}"; do
  echo "  Commit $COUNT: $c"
  COUNT=$((COUNT + 1))
done

echo ""
echo "Order suggestion: chore → docs → test → feat/fix (dependencies first)"
echo ""
echo -e "${YELLOW}Do you want to proceed with this split plan? (Y/n)${NC}"
read -r response
if [ "$response" = "n" ] || [ "$response" = "N" ]; then
  echo "Manual split mode: Use 'git add -p <file>' to stage partial hunks."
  echo "Reference: references/atomic-commit-patterns.md"
fi

echo ""
echo "=========================================="
