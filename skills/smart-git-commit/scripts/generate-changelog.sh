#!/usr/bin/env bash
#
# generate-changelog.sh — Auto-generate CHANGELOG.md from git history
#
# Parses the 5-part commit format (CONTEXT/CHANGE/WHY/IMPACT).
# Groups by type prefix with emoji sections.
# Prepends to CHANGELOG.md (creates if missing).
#
# Usage: bash scripts/generate-changelog.sh
# Stdout: JSON {version, entries_added, sections[]}
# Stderr: Human-readable progress

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Smart Git Commit — Changelog Generator${NC}" >&2
echo "" >&2

# Get last tag or first commit
FROM_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "NONE")

if [ "$FROM_TAG" = "NONE" ]; then
  TAG_RANGE=""
  VERSION="0.1.0"
  echo -e "${YELLOW}No tags found. Starting from first commit.${NC}" >&2
else
  TAG_RANGE="${FROM_TAG}..HEAD"
  VERSION="${FROM_TAG#v}"
  echo -e "${CYAN}Range: ${FROM_TAG} → HEAD${NC}" >&2
fi

# Get commits with full body (for 5-part format parsing)
if [ -z "${TAG_RANGE:-}" ]; then
  COMMITS=$(git log --pretty=format:"%H|%s|%b" 2>/dev/null || echo "")
else
  COMMITS=$(git log "$TAG_RANGE" --pretty=format:"%H|%s|%b" 2>/dev/null || echo "")
fi

if [ -z "$COMMITS" ]; then
  echo -e "${YELLOW}No new commits since ${FROM_TAG}.${NC}" >&2
  echo "{\"version\":\"$VERSION\",\"entries_added\":0,\"sections\":[],\"message\":\"No new commits\"}"
  exit 0
fi

# Group commits by type
declare -A GROUPS
SECTIONS_ORDER=()

# Define section mapping
add_to_group() {
  local type="$1"
  local data="$2"
  local section_name=""

  case "$type" in
    feat*) section_name="Features" ;;
    fix*) section_name="Bug Fixes" ;;
    perf*) section_name="Performance" ;;
    security*) section_name="Security" ;;
    refactor*) section_name="Refactoring" ;;
    test*) section_name="Tests" ;;
    docs*) section_name="Documentation" ;;
    chore|chore*) section_name="Maintenance" ;;
    *) section_name="Other" ;;
  esac

  # Check for breaking change
  if echo "$data" | grep -qi "BREAKING CHANGE"; then
    section_name="Breaking Changes"
  fi

  if [ -z "${GROUPS[$section_name]:-}" ]; then
    GROUPS[$section_name]=""
    SECTIONS_ORDER+=("$section_name")
  fi
  GROUPS[$section_name]+="$data"$'\n'
}

# Parse each commit
ENTRIES_ADDED=0
while IFS= read -r line; do
  [ -z "$line" ] && continue

  hash=$(echo "$line" | cut -d'|' -f1)
  subject=$(echo "$line" | cut -d'|' -f2)
  body=$(echo "$line" | cut -d'|' -f3-)

  # Extract type prefix
  type=$(echo "$subject" | sed 's/([^)]*)//g' | sed 's/!.*//' | awk '{print $1}' | tr -d ':')
  scope=$(echo "$subject" | grep -oE '\([^)]+\)' | tr -d '()')

  # Extract 5-part format fields
  context=$(echo "$body" | grep "^CONTEXT:" | sed 's/^CONTEXT: *//' | tr -d '\n' | head -c 120)
  change=$(echo "$body" | grep "^CHANGE:" | sed 's/^CHANGE: *//' | tr -d '\n' | head -c 120)

  # Build entry line
  entry=""
  if [ -n "$scope" ]; then
    entry="  - **${scope}**: ${change:-$subject}"
  else
    entry="  - ${change:-$subject}"
  fi

  # Add context as subtext
  if [ -n "$context" ]; then
    entry+=" (CONTEXT: ${context})"
  fi

  add_to_group "$type" "$entry"
  ENTRIES_ADDED=$((ENTRIES_ADDED + 1))
done <<< "$COMMITS"

# Version bump logic
if [ -n "${GROUPS["Breaking Changes"]:-}" ]; then
  MAJOR=$(( ${VERSION%%.*} + 1 ))
  VERSION="${MAJOR}.0.0"
elif [ -n "${GROUPS["Features"]:-}" ]; then
  MAJOR="${VERSION%%.*}"
  MINOR=$(( ${VERSION#*.} % 1000 + 1 ))
  VERSION="${MAJOR}.${MINOR}.0"
else
  MAJOR="${VERSION%%.*}"
  MINOR=$(echo "$VERSION" | cut -d. -f2)
  PATCH=$(echo "$VERSION" | cut -d. -f3)
  PATCH=${PATCH:-0}
  PATCH=$((PATCH + 1))
  VERSION="${MAJOR}.${MINOR}.${PATCH}"
fi

# Emoji mapping
declare -A EMOJIS
EMOJIS["Breaking Changes"]="💥"
EMOJIS["Features"]="✨"
EMOJIS["Bug Fixes"]="🐛"
EMOJIS["Performance"]="⚡"
EMOJIS["Security"]="🔐"
EMOJIS["Refactoring"]="♻️"
EMOJIS["Tests"]="🧪"
EMOJIS["Documentation"]="📚"
EMOJIS["Maintenance"]="🔧"
EMOJIS["Other"]="📝"

# Generate changelog content
DATE=$(date +%Y-%m-%d)
CHANGELOG="## [${VERSION}] — ${DATE}\n\n"

for section in "${SECTIONS_ORDER[@]}"; do
  entries="${GROUPS[$section]}"
  if [ -n "$entries" ]; then
    emoji="${EMOJIS[$section]:-📝}"
    CHANGELOG+="### ${emoji} ${section}\n"
    CHANGELOG+="${entries}\n"
  fi
done

# Prepend to CHANGELOG.md
if [ -f "CHANGELOG.md" ]; then
  # Remove existing header if present
  EXISTING=$(tail -n +3 CHANGELOG.md 2>/dev/null || true)
  printf "# Changelog\n\n%b%s\n" "$CHANGELOG" "$EXISTING" > CHANGELOG.md
else
  printf "# Changelog\n\n%b" "$CHANGELOG" > CHANGELOG.md
fi

echo -e "${GREEN}CHANGELOG.md updated — v${VERSION}${NC}" >&2
echo "{\"version\":\"$VERSION\",\"entries_added\":$ENTRIES_ADDED,\"sections\":[\"$(echo "${SECTIONS_ORDER[*]}" | sed 's/ /","/g')\"],\"message\":\"CHANGELOG.md updated to v${VERSION}\"}"
