# Smart Git Commit — Test Suite

This directory contains test scenarios and fixtures for validating the
Smart Git Commit skill. Tests are designed to be run manually or via automation.

## Test Methodology

The skill is tested via **simulation** — we simulate git states (staged diffs,
commit histories, branch states) and verify that the skill's scripts and
decision logic produce the expected outputs.

## Running Tests

### 1. Syntax Check (All Scripts)

```bash
bash -n scripts/scan-secrets.sh
bash -n scripts/detect-test-runner.sh
bash -n scripts/split-commits.sh
bash -n scripts/generate-changelog.sh
bash -n scripts/create-pr.sh
```

All should exit with code 0 and produce no output.

### 2. Manual Scenario Tests

Use the test fixtures in `fixtures/` to test specific behaviors:

```bash
# Test: Secret detection
git init --template= test_repo
cp fixtures/secret-diff.txt test_repo/diff.txt
cd test_repo
# Apply the diff and run scan-secrets.sh
cd ..

# Test: Mixed concern splitting
cp fixtures/mixed-diff.txt test_repo/diff.txt
# Apply the diff and run split-commits.sh
```

### 3. Smoke Test (Against Real Repo)

```bash
cd /path/to/any/repo
# Stage some changes
git add -A
# Run the scan
bash /path/to/scripts/scan-secrets.sh
# Run the split analyzer
bash /path/to/scripts/split-commits.sh
```

## Test Scenarios

See `test-scenarios.md` for 7 detailed test scenarios covering:

1. Single clean commit (happy path)
2. Mixed concerns — should split into 3
3. Secret found in diff — must block
4. Tests fail — must not commit
5. Release tagging flow
6. Hotfix directly from main (edge case)
7. Breaking change — must include footer + major bump

## Fixtures

| File | Purpose |
|------|---------|
| `fixtures/mixed-diff.txt` | Git diff with 3 mixed concerns (feat, fix, docs) |
| `fixtures/secret-diff.txt` | Git diff containing a fake API key for testing scan |
