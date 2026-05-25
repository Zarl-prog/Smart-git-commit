#!/usr/bin/env bash
#
# generate-changelog.sh — Auto-generate CHANGELOG.md from git history
#
# Usage: bash scripts/generate-changelog.sh [from-tag]
# Stdout: JSON {version, entries_added, sections{}}
# Stderr: Human-readable progress

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Smart Git Commit — Changelog Generator${NC}" >&2
echo "" >&2

# Determine tag range
FROM_TAG="${1:-}"
if [ -z "$FROM_TAG" ]; then
  FROM_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
fi

if [ -z "$FROM_TAG" ]; then
  FROM_TAG=$(git rev-list --max-parents=0 HEAD 2>/dev/null || echo "")
  if [ -z "$FROM_TAG" ]; then
    echo -e "${RED}No commits found.${NC}" >&2
    echo '{"version":"0.0.0","entries_added":0,"sections":{},"message":"No commits found"}'
    exit 1
  fi
  TAG_RANGE="$FROM_TAG..HEAD"
  VERSION="0.1.0"
  echo -e "${YELLOW}No tags. Using first commit as base.${NC}" >&2
else
  TAG_RANGE="${FROM_TAG}..HEAD"
  VERSION="${FROM_TAG#v}"
  echo -e "${CYAN}Range: ${FROM_TAG} → HEAD${NC}" >&2
fi

# Extract commits by type
COMMITS=$(git log "$TAG_RANGE" --oneline --no-decorate 2>/dev/null || echo "")
if [ -z "$COMMITS" ]; then
  echo -e "${YELLOW}No new commits since ${FROM_TAG}.${NC}" >&2
  echo "{\"version\":\"$VERSION\",\"entries_added\":0,\"sections\":{},\"message\":\"No new commits\"}"
  exit 0
fi

FEATURES=$(git log "$TAG_RANGE" --oneline --grep="^feat" 2>/dev/null || echo "")
BUGFIXES=$(git log "$TAG_RANGE" --oneline --grep="^fix\|^hotfix" 2>/dev/null || echo "")
PERF=$(git log "$TAG_RANGE" --oneline --grep="^perf" 2>/dev/null || echo "")
SECURITY=$(git log "$TAG_RANGE" --oneline --grep="^security" 2>/dev/null || echo "")
CHORES=$(git log "$TAG_RANGE" --oneline --grep="^chore" 2>/dev/null || echo "")
DOCS=$(git log "$TAG_RANGE" --oneline --grep="^docs" 2>/dev/null || echo "")
TESTS=$(git log "$TAG_RANGE" --oneline --grep="^test" 2>/dev/null || echo "")
REFACTOR=$(git log "$TAG_RANGE" --oneline --grep="^refactor" 2>/dev/null || echo "")
BREAKING=$(git log "$TAG_RANGE" --oneline --grep="BREAKING CHANGE" 2>/dev/null || echo "")
DEPS=$(git log "$TAG_RANGE" --oneline --grep="^deps\|^chore(deps)" 2>/dev/null || echo "")

# Version bump logic
if [ -n "$BREAKING" ]; then
  MAJOR=$(( ${VERSION%%.*} + 1 ))
  VERSION="${MAJOR}.0.0"
elif [ -n "$FEATURES" ]; then
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

# Generate changelog content
DATE=$(date +%Y-%m-%d)
CHANGELOG="## [${VERSION}] - ${DATE}\n\n"

declare -A SECTIONS
SECTIONS["breaking"]=""
SECTIONS["features"]=""
SECTIONS["fixes"]=""
SECTIONS["perf"]=""
SECTIONS["security"]=""
SECTIONS["refactor"]=""
SECTIONS["tests"]=""
SECTIONS["docs"]=""
SECTIONS["deps"]=""
SECTIONS["chores"]=""

add_section() {
  local name="$1"
  local commits="$2"
  local icon="$3"
  local title="$4"
  if [ -n "$commits" ]; then
    SECTIONS["$name"]="$icon $title\n"
    while IFS= read -r line; do
      commit_msg=$(echo "$line" | sed 's/^[a-f0-9]\{7,9\} //' | sed 's/"/\\"/g')
      SECTIONS["$name"]+="  - ${commit_msg}\n"
    done <<< "$commits"
    SECTIONS["$name"]+="\n"
  fi
}

add_section "breaking" "$BREAKING" "⚠️" "Breaking Changes"
add_section "features" "$FEATURES" "🚀" "Features"
add_section "fixes" "$BUGFIXES" "🐛" "Bug Fixes"
add_section "perf" "$PERF" "⚡" "Performance"
add_section "security" "$SECURITY" "🔒" "Security"
add_section "refactor" "$REFACTOR" "🔧" "Refactoring"
add_section "tests" "$TESTS" "🧪" "Tests"
add_section "docs" "$DOCS" "📖" "Documentation"
add_section "deps" "$DEPS" "📦" "Dependencies"
add_section "chores" "$CHORES" "🛠" "Maintenance"

for key in "breaking" "features" "fixes" "perf" "security" "refactor" "tests" "docs" "deps" "chores"; do
  CHANGELOG+="${SECTIONS[$key]}"
done

# Prepend to CHANGELOG.md
if [ -f "CHANGELOG.md" ]; then
  EXISTING=$(tail -n +3 CHANGELOG.md 2>/dev/null || true)
  printf "# Changelog\n\n%b%s\n" "$CHANGELOG" "$EXISTING" > CHANGELOG.md
else
  printf "# Changelog\n\n%b" "$CHANGELOG" > CHANGELOG.md
fi

echo -e "${GREEN}CHANGELOG.md updated (v${VERSION})${NC}" >&2

# Count entries
ENTRIES=0
for key in "${!SECTIONS[@]}"; do
  val="${SECTIONS[$key]}"
  if [ -n "$val" ]; then
    ENTRIES=$((ENTRIES + $(echo -e "$val" | grep -c "^-" 2>/dev/null || echo 0)))
  fi
done

# Build JSON
echo "{\"version\":\"$VERSION\",\"entries_added\":$ENTRIES,\"sections\":{},\"message\":\"CHANGELOG.md updated to v${VERSION}\"}"
