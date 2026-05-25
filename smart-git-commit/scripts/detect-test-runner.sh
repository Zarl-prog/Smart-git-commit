#!/usr/bin/env bash
#
# detect-test-runner.sh — Auto-detect and run the project's test suite
#
# Usage: bash scripts/detect-test-runner.sh
# Exit code: 0 = all tests passed, 1 = tests failed or error
#
# Supports: npm, pytest, cargo, go, make, rspec, mix

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  Smart Git Commit — Test Runner"
echo "=========================================="
echo ""

detect_and_run() {
  local runner=""
  local cmd=""
  local name=""

  # Order by likelihood / specificity
  if [ -f "package.json" ]; then
    # Check for specific test frameworks in package.json
    if grep -q '"jest"' package.json 2>/dev/null; then
      runner="jest"
      cmd="npx jest --no-cache 2>&1"
      name="Jest (Node.js)"
    elif grep -q '"mocha"' package.json 2>/dev/null; then
      runner="mocha"
      cmd="npx mocha 2>&1"
      name="Mocha (Node.js)"
    elif grep -q '"vitest"' package.json 2>/dev/null; then
      runner="vitest"
      cmd="npx vitest run 2>&1"
      name="Vitest (Node.js)"
    elif grep -q '"ava"' package.json 2>/dev/null; then
      runner="ava"
      cmd="npx ava 2>&1"
      name="AVA (Node.js)"
    elif grep -q '"scripts".*"test"' package.json 2>/dev/null; then
      runner="npm"
      cmd="npm test 2>&1"
      name="npm test (Node.js)"
    else
      runner="npm"
      cmd="npm test 2>&1"
      name="npm test (Node.js)"
    fi

  elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -f "setup.cfg" ] && grep -q "tool.pytest" pyproject.toml 2>/dev/null; then
    runner="pytest"
    cmd="python -m pytest --tb=short -q 2>&1"
    name="pytest (Python)"

  elif [ -f "Cargo.toml" ]; then
    runner="cargo"
    cmd="cargo test 2>&1"
    name="Cargo (Rust)"

  elif [ -f "go.mod" ]; then
    runner="go"
    cmd="go test ./... 2>&1"
    name="Go test"

  elif [ -f "Makefile" ] && grep -q "^test:" Makefile 2>/dev/null; then
    runner="make"
    cmd="make test 2>&1"
    name="Make test"

  elif [ -f ".rspec" ] || [ -f "spec/spec_helper.rb" ]; then
    runner="rspec"
    cmd="bundle exec rspec 2>&1"
    name="RSpec (Ruby)"

  elif [ -f "mix.exs" ]; then
    runner="mix"
    cmd="mix test 2>&1"
    name="Mix (Elixir)"

  elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    runner="gradle"
    cmd="./gradlew test 2>&1"
    name="Gradle (Java/Kotlin)"

  elif [ -f "pom.xml" ]; then
    runner="maven"
    cmd="mvn test 2>&1"
    name="Maven (Java)"

  elif [ -f "CMakeLists.txt" ] && grep -q "enable_testing\|add_test" CMakeLists.txt 2>/dev/null; then
    runner="ctest"
    cmd="ctest --output-on-failure 2>&1"
    name="CTest (C/C++)"

  else
    echo -e "${YELLOW}⚠  No test runner detected for this project.${NC}"
    echo ""
    echo "Common test runners checked:"
    echo "  - package.json  → npm test / jest / mocha / vitest"
    echo "  - pytest.ini    → pytest"
    echo "  - Cargo.toml    → cargo test"
    echo "  - go.mod        → go test"
    echo "  - Makefile      → make test"
    echo "  - .rspec        → rspec"
    echo "  - mix.exs       → mix test"
    echo "  - build.gradle  → gradlew test"
    echo "  - pom.xml       → mvn test"
    echo ""
    echo -e "${YELLOW}Do you want to proceed with the commit anyway? (y/N)${NC}"
    read -r response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
      echo -e "${RED}Commit aborted by user.${NC}"
      exit 1
    fi
    return 0
  fi

  echo -e "${CYAN}Detected: ${name}${NC}"
  echo "Running tests..."
  echo ""

  # Run the tests
  set +e
  eval "$cmd"
  local exit_code=$?
  set -e

  echo ""

  if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed${NC}"
    return 0
  else
    echo -e "${RED}❌ Tests failed (exit code: $exit_code)${NC}"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  1. Fix the failing tests, then try again"
    echo "  2. Commit anyway with 'WIP:' prefix (abandon test gate)"
    echo "  3. Abort the commit"
    echo ""
    echo -n "Choose (1/2/3): "
    read -r choice
    case "$choice" in
      2)
        echo -e "${YELLOW}Proceeding with WIP commit (test gate bypassed)${NC}"
        return 0
        ;;
      3)
        echo -e "${RED}Commit aborted.${NC}"
        exit 1
        ;;
      *)
        echo -e "${RED}Please fix the tests and try again.${NC}"
        exit 1
        ;;
    esac
  fi
}

detect_and_run
echo "=========================================="
