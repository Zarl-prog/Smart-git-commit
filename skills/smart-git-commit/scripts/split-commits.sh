#!/usr/bin/env bash
#
# split-commits.sh — Analyze diff and suggest atomic commit splitting
#
# Usage: bash scripts/split-commits.sh
# Stdout: JSON {commits_made, status, messages[]}
# Stderr: Human-readable split plan

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Smart Git Commit — Atomic Split Analyzer${NC}" >&2
echo "" >&2

# Check for changes
if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
  echo -e "${YELLOW}No changes detected.${NC}" >&2
  echo '{"status":"no_changes","commits_made":0,"messages":[],"message":"No changes to split"}'
  exit 0
fi

# Get changed files
if git diff --cached --quiet 2>/dev/null; then
  FILES=$(git diff --name-only 2>/dev/null)
  echo "Analyzing working tree changes..." >&2
else
  FILES=$(git diff --cached --name-only 2>/dev/null)
  echo "Analyzing staged changes..." >&2
fi
echo "" >&2

FILE_COUNT=$(echo "$FILES" | wc -l)

# Group files by type
TEST_FILES=$(echo "$FILES" | grep -iE "(test|spec|__tests__)" 2>/dev/null || true)
CONFIG_FILES=$(echo "$FILES" | grep -iE "(\.env|\.json|\.yaml|\.yml|\.toml|Dockerfile|Makefile|\.gitignore|\bci\b)" 2>/dev/null || true)
DOC_FILES=$(echo "$FILES" | grep -iE "(\.md|README|CHANGELOG|docs/)" 2>/dev/null || true)
MIGRATION_FILES=$(echo "$FILES" | grep -iE "(migration|migrate|schema|alembic)" 2>/dev/null || true)
SOURCE_FILES=$(echo "$FILES" | grep -vE "(test|spec|\.md|Dockerfile|Makefile|\.gitignore|\.json|\.yaml|\.yml|\.toml)" 2>/dev/null || true)

# Build concern list
CONCERNS=()
declare -A CONCERN_FILES

if [ -n "$TEST_FILES" ]; then
  CONCERNS+=("testing")
  CONCERN_FILES["testing"]="$TEST_FILES"
fi
if [ -n "$CONFIG_FILES" ]; then
  CONCERNS+=("chore/config")
  CONCERN_FILES["chore/config"]="$CONFIG_FILES"
fi
if [ -n "$DOC_FILES" ]; then
  CONCERNS+=("docs")
  CONCERN_FILES["docs"]="$DOC_FILES"
fi
if [ -n "$MIGRATION_FILES" ]; then
  CONCERNS+=("migration")
  CONCERN_FILES["migration"]="$MIGRATION_FILES"
fi
if [ -n "$SOURCE_FILES" ]; then
  # Group source files by top-level directory
  DIRS=$(dirname "$SOURCE_FILES" 2>/dev/null | cut -d'/' -f1 | sort -u)
  for dir in $DIRS; do
    if [ "$dir" != "." ]; then
      CONCERNS+=("feat/fix: $dir")
      CONCERN_FILES["feat/fix: $dir"]=$(echo "$SOURCE_FILES" | grep "^$dir/" 2>/dev/null || true)
    fi
  done
fi

# Remove duplicate concerns
IFS=$'\n' CONCERNS=($(printf "%s\n" "${CONCERNS[@]}" | sort -u))
unset IFS

echo "Found $FILE_COUNT file(s) across ${#CONCERNS[@]} concern(s):" >&2
echo "" >&2

# Show split plan
if [ ${#CONCERNS[@]} -le 1 ]; then
  echo -e "${GREEN}Single concern — one commit is fine.${NC}" >&2
  echo '{"status":"single_concern","commits_made":1,"messages":["Single concern — one commit"],"message":"No split needed"}'
  exit 0
fi

echo -e "${CYAN}Suggested split: ${#CONCERNS[@]} atomic commits${NC}" >&2
echo "" >&2

COUNT=1
MESSAGES=()
for concern in "${CONCERNS[@]}"; do
  files="${CONCERN_FILES[$concern]}"
  file_list=$(echo "$files" | tr '\n' ' ')
  MESSAGES+=("Commit $COUNT: $concern ($(echo "$files" | wc -l) files)")
  echo "  $COUNT. $concern" >&2
  echo "     Files: $(echo "$files" | tr '\n' ' ')" >&2
  echo "" >&2
  COUNT=$((COUNT + 1))
done

# Build JSON
MESSAGES_JSON="["
FIRST=true
for msg in "${MESSAGES[@]}"; do
  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    MESSAGES_JSON+=","
  fi
  MESSAGES_JSON+="\"$msg\""
done
MESSAGES_JSON+="]"

echo "{\"status\":\"split_needed\",\"commits_made\":${#CONCERNS[@]},\"messages\":$MESSAGES_JSON,\"message\":\"Split into ${#CONCERNS[@]} atomic commits\"}"
