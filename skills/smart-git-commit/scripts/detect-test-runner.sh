#!/usr/bin/env bash
#
# detect-test-runner.sh — Auto-detect and run the project's test suite
#
# Usage: bash scripts/detect-test-runner.sh
# Exit code: 0 always (caller decides whether to block on "fail" or "not_found")
# Stdout: JSON {runner, status, test_count, failures[]}
# Stderr: Human-readable progress

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Smart Git Commit — Test Runner${NC}" >&2
echo "" >&2

detect_and_run() {
  local runner="not_found"
  local cmd=""
  local name=""

  # Detection order from Prompt.txt
  if [ -f "package.json" ]; then
    local test_script
    test_script=$(grep -E '"test"' package.json 2>/dev/null || true)
    if [ -n "$test_script" ]; then
      runner="npm"
      cmd="npm test 2>&1"
      name="npm test"
    fi
  fi

  if [ "$runner" = "not_found" ] && ([ -f "pytest.ini" ] || grep -q '\[tool.pytest' pyproject.toml 2>/dev/null); then
    runner="pytest"
    cmd="python -m pytest --tb=short -q 2>&1"
    name="pytest"
  fi

  if [ "$runner" = "not_found" ] && [ -f "Cargo.toml" ]; then
    runner="cargo"
    cmd="cargo test 2>&1"
    name="Cargo"
  fi

  if [ "$runner" = "not_found" ] && [ -f "go.mod" ]; then
    runner="go"
    cmd="go test ./... 2>&1"
    name="Go test"
  fi

  if [ "$runner" = "not_found" ] && [ -f "Makefile" ] && grep -q "^test:" Makefile 2>/dev/null; then
    runner="make"
    cmd="make test 2>&1"
    name="Make test"
  fi

  if [ "$runner" = "not_found" ] && [ -f ".rspec" ]; then
    runner="rspec"
    cmd="bundle exec rspec 2>&1"
    name="RSpec"
  fi

  if [ "$runner" = "not_found" ] && [ -f "mix.exs" ]; then
    runner="mix"
    cmd="mix test 2>&1"
    name="Mix"
  fi

  if [ "$runner" = "not_found" ] && ([ -f "build.gradle" ] || [ -f "build.gradle.kts" ]); then
    runner="gradle"
    cmd="./gradlew test 2>&1"
    name="Gradle"
  fi

  if [ "$runner" = "not_found" ]; then
    echo -e "${YELLOW}No test runner detected.${NC}" >&2
    echo '{"runner":"not_found","status":"not_found","test_count":0,"failures":[],"message":"No test runner detected"}'
    return 0
  fi

  echo -e "${CYAN}Detected: ${name}${NC}" >&2
  echo "Running tests..." >&2
  echo "" >&2

  set +e
  OUTPUT=$(eval "$cmd" 2>&1)
  local exit_code=$?
  set -e

  # Parse pass/fail counts
  TEST_COUNT=0
  FAILURES_ARR=()

  # Try to extract test count (handles various output formats)
  local count_match
  count_match=$(echo "$OUTPUT" | grep -oiE '(tests?: |test count: |[0-9]+ passed|[0-9]+ failed|[0-9]+ tests?,[0-9]+ failures?)' | head -3 | tr '\n' ' ' || echo "0")
  TEST_COUNT="$count_match"

  if [ "$exit_code" -ne 0 ]; then
    # Extract failing test names
    while IFS= read -r line; do
      local fail_line
      fail_line=$(echo "$line" | grep -oiE '(FAIL|FAILED|ERROR|failure)[^:]*:[[:space:]]*test_[a-zA-Z0-9_]+|[0-9]+\)[[:space:]]+[a-zA-Z0-9_]+' | head -1 || true)
      if [ -n "$fail_line" ]; then
        local test_name
        test_name=$(echo "$fail_line" | sed 's/^[^:]*: *//' | sed 's/^[0-9]*) *//' | tr -d '"' | xargs)
        FAILURES_ARR+=("$test_name")
      fi
    done <<< "$OUTPUT"
  fi

  # Build failures JSON array
  FAILURES_JSON="["
  FIRST=true
  for f in "${FAILURES_ARR[@]}"; do
    if [ "$FIRST" = true ]; then
      FIRST=false
    else
      FAILURES_JSON+=","
    fi
    FAILURES_JSON+="\"$f\""
  done
  FAILURES_JSON+="]"

  if [ "$exit_code" -eq 0 ]; then
    echo -e "${GREEN}All tests passed${NC}" >&2
    echo "{\"runner\":\"$runner\",\"status\":\"pass\",\"test_count\":$([ "$TEST_COUNT" -gt 0 ] 2>/dev/null && echo "$TEST_COUNT" || echo 0),\"failures\":[],\"message\":\"All tests passed\"}"
  else
    echo -e "${RED}Tests failed${NC}" >&2
    echo "$OUTPUT" | tail -10 >&2
    echo "{\"runner\":\"$runner\",\"status\":\"fail\",\"test_count\":0,\"failures\":$FAILURES_JSON,\"message\":\"Tests failed\"}"
  fi
}

detect_and_run
exit 0
