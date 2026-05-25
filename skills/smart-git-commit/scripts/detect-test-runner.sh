#!/usr/bin/env bash
#
# detect-test-runner.sh — Auto-detect and run the project's test suite
#
# Usage: bash scripts/detect-test-runner.sh
# Exit code: 0 = all tests passed, 1 = tests failed
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
  local runner=""
  local cmd=""
  local name=""

  if [ -f "package.json" ]; then
    if grep -q '"jest"' package.json 2>/dev/null; then
      runner="jest"; cmd="npx jest --no-cache 2>&1"; name="Jest"
    elif grep -q '"vitest"' package.json 2>/dev/null; then
      runner="vitest"; cmd="npx vitest run 2>&1"; name="Vitest"
    elif grep -q '"mocha"' package.json 2>/dev/null; then
      runner="mocha"; cmd="npx mocha 2>&1"; name="Mocha"
    else
      runner="npm"; cmd="npm test 2>&1"; name="npm test"
    fi
  elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
    runner="pytest"; cmd="python -m pytest --tb=short -q 2>&1"; name="pytest"
  elif [ -f "Cargo.toml" ]; then
    runner="cargo"; cmd="cargo test 2>&1"; name="Cargo"
  elif [ -f "go.mod" ]; then
    runner="go"; cmd="go test ./... 2>&1"; name="Go test"
  elif [ -f "Makefile" ] && grep -q "^test:" Makefile 2>/dev/null; then
    runner="make"; cmd="make test 2>&1"; name="Make test"
  elif [ -f ".rspec" ] || [ -f "spec/spec_helper.rb" ]; then
    runner="rspec"; cmd="bundle exec rspec 2>&1"; name="RSpec"
  elif [ -f "mix.exs" ]; then
    runner="mix"; cmd="mix test 2>&1"; name="Mix"
  elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    runner="gradle"; cmd="./gradlew test 2>&1"; name="Gradle"
  elif [ -f "pom.xml" ]; then
    runner="maven"; cmd="mvn test 2>&1"; name="Maven"
  elif [ -f "CMakeLists.txt" ] && grep -q "enable_testing\\|add_test" CMakeLists.txt 2>/dev/null; then
    runner="ctest"; cmd="ctest --output-on-failure 2>&1"; name="CTest"
  else
    echo -e "${YELLOW}No test runner detected.${NC}" >&2
    echo "{\"runner\":null,\"status\":\"not_found\",\"test_count\":0,\"failures\":[],\"message\":\"No test runner detected\"}"
    return 0
  fi

  echo -e "${CYAN}Detected: ${name}${NC}" >&2
  echo "Running tests..." >&2
  echo "" >&2

  set +e
  OUTPUT=$(eval "$cmd" 2>&1)
  local exit_code=$?
  set -e

  # Try to extract test count
  TEST_COUNT=$(echo "$OUTPUT" | grep -oiE "(tests:|test count:|[0-9]+ passed|[0-9]+ failed)" | head -3 | tr '\n' ' ' || echo "unknown")
  FAILURES=$(echo "$OUTPUT" | grep -iE "(FAIL|ERROR|failure|failed)" | head -5 | sed 's/"/\\"/g' | paste -sd ',' - 2>/dev/null || echo "")

  # Build failures JSON array
  FAILURES_JSON="[]"
  if [ "$exit_code" -ne 0 ] && [ -n "$FAILURES" ]; then
    FAILURES_JSON="[\"$(echo "$FAILURES" | sed 's/,/","/g')\"]"
  fi

  if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}All tests passed${NC}" >&2
    echo "{\"runner\":\"$runner\",\"status\":\"pass\",\"test_count\":\"$TEST_COUNT\",\"failures\":[],\"message\":\"All tests passed\"}"
  else
    echo -e "${RED}Tests failed (exit code: $exit_code)${NC}" >&2
    echo "$OUTPUT" | tail -20 >&2
    echo "{\"runner\":\"$runner\",\"status\":\"fail\",\"test_count\":\"$TEST_COUNT\",\"failures\":$FAILURES_JSON,\"message\":\"Tests failed — commit blocked\"}"
    exit 1
  fi
}

detect_and_run
