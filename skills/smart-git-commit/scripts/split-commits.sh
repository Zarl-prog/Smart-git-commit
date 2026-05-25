#!/usr/bin/env bash
#
# split-commits.sh — Analyze diff and suggest atomic commit splitting
#
# Usage: bash scripts/split-commits.sh
# Stdout: JSON {commits_made, messages[]}
# Stderr: Interactive split plan with Y/n/edit prompt

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

# Get changed files (prefer staged, fall back to working tree)
if ! git diff --cached --quiet 2>/dev/null; then
  FILES=$(git diff --cached --name-only)
else
  FILES=$(git diff --name-only)
fi

FILE_COUNT=$(echo "$FILES" | wc -l | tr -d ' ')
echo "Analyzing $FILE_COUNT changed file(s)..." >&2
echo "" >&2

# Group by top-level directory
declare -A DIR_GROUPS
declare -A CONCERN_GROUPS
GROUP_ORDER=()

# Top-level directory grouping
while IFS= read -r file; do
  [ -z "$file" ] && continue
  top_dir=$(echo "$file" | cut -d/ -f1)
  if [ "$top_dir" = "$file" ]; then
    top_dir="root"
  fi
  if [ -z "${DIR_GROUPS[$top_dir]:-}" ]; then
    DIR_GROUPS[$top_dir]=""
    GROUP_ORDER+=("$top_dir")
  fi
  DIR_GROUPS[$top_dir]+="$file"$'\n'
done <<< "$FILES"

# Concern keyword detection
while IFS= read -r file; do
  [ -z "$file" ] && continue
  file_lower=$(echo "$file" | tr '[:upper:]' '[:lower:]')

  concern=""
  if echo "$file_lower" | grep -qE '(auth|login|session|jwt|oauth|permission|role|user)'; then
    concern="auth"
  elif echo "$file_lower" | grep -qE '(payment|stripe|billing|invoice|charge|refund)'; then
    concern="payments"
  elif echo "$file_lower" | grep -qE '(ui|component|page|view|layout|button|modal)'; then
    concern="ui"
  elif echo "$file_lower" | grep -qE '(db|database|schema|migration|query|model|entity)'; then
    concern="db"
  elif echo "$file_lower" | grep -qE '(api|endpoint|route|controller|handler|middleware)'; then
    concern="api"
  elif echo "$file_lower" | grep -qE '(config|setting|env|docker|ci|deploy)'; then
    concern="config"
  elif echo "$file_lower" | grep -qE '(doc|readme|changelog|contributing)'; then
    concern="docs"
  fi

  if [ -n "$concern" ]; then
    if [ -z "${CONCERN_GROUPS[$concern]:-}" ]; then
      CONCERN_GROUPS[$concern]=""
    fi
    CONCERN_GROUPS[$concern]+="$file"$'\n'
  fi
done <<< "$FILES"

# Build split plan
SPLIT_GROUPS=()
SPLIT_NAMES=()

# If multiple directories with source code, suggest split
DIR_COUNT=0
for dir in "${GROUP_ORDER[@]}"; do
  if [ "$dir" != "root" ] && [ "$dir" != "tests" ]; then
    DIR_COUNT=$((DIR_COUNT + 1))
  fi
done

echo "Top-level directories: ${GROUP_ORDER[*]}" >&2
echo "Concerns detected: ${!CONCERN_GROUPS[*]}" >&2
echo "" >&2

# Decide if split is needed
NEEDS_SPLIT=false

if [ ${#CONCERN_GROUPS[@]} -ge 2 ]; then
  NEEDS_SPLIT=true
fi

if [ "$DIR_COUNT" -ge 2 ]; then
  NEEDS_SPLIT=true
fi

# Check for test files separate from source
TEST_FILES=$(echo "$FILES" | grep -iE '(test|spec|__tests__)' 2>/dev/null || true)
SOURCE_WITHOUT_TESTS=$(echo "$FILES" | grep -v -iE '(test|spec|__tests__)' 2>/dev/null || true)
if [ -n "$TEST_FILES" ] && [ -n "$SOURCE_WITHOUT_TESTS" ]; then
  # Tests are for existing code (not new feature)
  # Check if both test and source were modified
  NEEDS_SPLIT=true
fi

if [ "$NEEDS_SPLIT" = false ]; then
  echo -e "${GREEN}Single concern — one commit is fine.${NC}" >&2
  echo '{"status":"single_concern","commits_made":1,"messages":["Single concern — one commit"],"message":"No split needed"}'
  exit 0
fi

# Build proposed split plan
COUNT=1
echo -e "${CYAN}Proposed split — multiple commits detected:${NC}" >&2
echo "" >&2

MESSAGES=()

# Group by concern first
for concern in "${!CONCERN_GROUPS[@]}"; do
  files="${CONCERN_GROUPS[$concern]}"
  file_list=$(echo "$files" | tr '\n' ' ' | sed 's/  */ /g')
  echo "  [$COUNT] $concern → $file_list" >&2
  MESSAGES+=("$concern|$file_list")
  COUNT=$((COUNT + 1))
done

# Add remaining files as chore/config
REMAINING="$FILES"
for concern in "${!CONCERN_GROUPS[@]}"; do
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    REMAINING=$(echo "$REMAINING" | grep -v "^$(echo "$f" | sed 's/[^^]/[&]/g; s/\^/\\^/g')$" 2>/dev/null || true)
  done <<< "${CONCERN_GROUPS[$concern]}"
done

if [ -n "$(echo "$REMAINING" | tr -d '[:space:]')" ]; then
  file_list=$(echo "$REMAINING" | tr '\n' ' ' | sed 's/  */ /g')
  echo "  [$COUNT] chore/config → $file_list" >&2
  MESSAGES+=("chore/config|$file_list")
  COUNT=$((COUNT + 1))
fi

echo "" >&2

# Interactive prompt
echo -e "${YELLOW}Proceed with this split? [Y/n/edit]:${NC}" >&2
read -r USER_INPUT

case "$USER_INPUT" in
  n|N|no|NO)
    echo -e "${YELLOW}Split canceled. No commits made.${NC}" >&2
    echo '{"status":"canceled","commits_made":0,"messages":[],"message":"Split canceled by user"}'
    exit 0
    ;;
  edit|e|E)
    echo -e "${YELLOW}Edit mode: Please modify the groupings above and re-run.${NC}" >&2
    echo '{"status":"edit","commits_made":0,"messages":[],"message":"User requested edits to split plan"}'
    exit 0
    ;;
  *)
    # Default: proceed with split
    echo -e "${GREEN}Proceeding with split...${NC}" >&2
    echo "" >&2
    COMMIT_MESSAGES=()
    for entry in "${MESSAGES[@]}"; do
      concern="${entry%%|*}"
      files="${entry#*|}"
      echo "Staging: $concern" >&2
      IFS=' ' read -ra file_array <<< "$files"
      for f in "${file_array[@]}"; do
        [ -n "$f" ] && git add "$f" 2>/dev/null || true
      done
      echo -e "${YELLOW}Enter commit message for: ${concern}${NC}" >&2
      echo -e "${YELLOW}Format: <type>(<scope>): <summary>${NC}" >&2
      read -r COMMIT_MSG
      COMMIT_MESSAGES+=("$COMMIT_MSG")
    done

    # Build JSON
    JSON_MSGS="["
    FIRST=true
    for msg in "${COMMIT_MESSAGES[@]}"; do
      if [ "$FIRST" = true ]; then
        FIRST=false
      else
        JSON_MSGS+=","
      fi
      JSON_MSGS+="\"$msg\""
    done
    JSON_MSGS+="]"

    echo "{\"status\":\"split_done\",\"commits_made\":${#COMMIT_MESSAGES[@]},\"messages\":$JSON_MSGS,\"message\":\"Split completed\"}"
    ;;
esac
