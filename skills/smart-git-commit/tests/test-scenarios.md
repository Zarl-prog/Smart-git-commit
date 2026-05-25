# Test Scenarios — Smart Git Commit Skill

## Scenario 1: Single Clean Commit (Happy Path)

**Goal:** Verify the skill handles a single-concern changeset without splitting.

**Setup:**
```bash
echo "console.log('hello')" > index.js
git add index.js
```

**Expected behavior:**
1. Phase 1 (diff analysis) identifies 1 file, single concern (feat/fix)
2. Phase 2 (security scan) passes — no secrets
3. Phase 3 (test gate) passes or warns with no runner
4. Phase 4 (split decision) → single concern, no split needed
5. Phase 5 (commit message) → constructs 5-part format
6. Phase 7 (execute) → `git commit` succeeds

**Pass criteria:**
- `bash scripts/split-commits.sh` exits with `"status":"single_concern"`
- `bash scripts/scan-secrets.sh` exits 0

---

## Scenario 2: Mixed Concerns — Should Split

**Goal:** Verify the skill detects multiple concerns and suggests atomic splits.

**Setup:**
```bash
# Stage changes from fixtures/mixed-diff.txt
git apply fixtures/mixed-diff.txt
git add -A
```

**Expected behavior:**
1. Phase 1 identifies 3 concerns: feat(invoice), fix(auth), docs
2. Phase 4 calls `bash scripts/split-commits.sh`
3. Split plan shows 3 separate commits
4. Each commit has a clear single concern

**Pass criteria:**
- `bash scripts/split-commits.sh` suggests 3+ commits
- Commit messages distinguish: `feat(invoice)`, `fix(auth)`, `docs`

---

## Scenario 3: Secret Found in Diff — Must Block

**Goal:** Verify the security scan blocks commits containing secrets.

**Setup:**
```bash
# Stage changes from fixtures/secret-diff.txt
git apply fixtures/secret-diff.txt
git add -A
```

**Expected behavior:**
1. Phase 2 runs `bash scripts/scan-secrets.sh`
2. Script detects `API_KEY` assignment, `REDIS_URL` with password, `AWS_ACCESS_KEY_ID`, and `AWS_SECRET_ACCESS_KEY`
3. Script exits with code 1
4. Phase 2 stops — commit is blocked

**Pass criteria:**
- `bash scripts/scan-secrets.sh` exits with code 1
- Output JSON includes `"status":"fail"`
- Findings include at least: API key, AWS access key ID, AWS secret key, Redis URL with password

---

## Scenario 4: Tests Fail — Must Not Commit

**Goal:** Verify the test gate prevents commits when tests are failing.

**Setup:**
```bash
# Create a test that will fail
echo "def test_always_fails(): assert False" > test_fail.py
echo "[tool.pytest.ini_options]" > pyproject.toml
git add test_fail.py pyproject.toml
```

**Expected behavior:**
1. Phase 3 runs `bash scripts/detect-test-runner.sh`
2. Test suite fails
3. Script exits with code 1
4. Phase 3 blocks the commit
5. User is offered: fix tests, WIP override, or abort

**Pass criteria:**
- `bash scripts/detect-test-runner.sh` exits with code 1
- JSON output includes `"status":"fail"`

---

## Scenario 5: Release Tagging Flow

**Goal:** Verify the changelog generation and version bumping.

**Setup:**
```bash
# Create a repo with a tag and some commits
git tag v1.0.0
git commit --allow-empty -m "feat(api): add pagination"
git commit --allow-empty -m "fix(db): handle null timestamps"
```

**Expected behavior:**
1. `bash scripts/generate-changelog.sh` reads commits since v1.0.0
2. Groups commits into "Features" and "Bug Fixes"
3. Bumps version to v1.1.0 (because feat commits present)
4. Prepends new section to CHANGELOG.md

**Pass criteria:**
- CHANGELOG.md updated with new version section
- JSON output includes correct version bump
- Entries are grouped by type (feat, fix)

---

## Scenario 6: Hotfix from Main (Edge Case)

**Goal:** Verify the skill handles urgent production fixes correctly.

**Setup:**
```bash
git checkout main
git checkout -b hotfix/critical-bug
echo "fix" > patch.txt
git add patch.txt
```

**Expected behavior:**
1. Phase 8 (push strategy) allows push from hotfix branch
2. Phase 9 (PR creation) targets `main` directly
3. Commit uses `hotfix` type instead of `fix`
4. Commit message includes severity context

**Pass criteria:**
- Branch name detected as hotfix
- PR base defaults to main for hotfix branches

---

## Scenario 7: Breaking Change — Major Bump

**Goal:** Verify that breaking changes are properly flagged and cause a major version bump.

**Setup:**
```bash
git commit --allow-empty -m "feat(api)!: redesign user profile endpoint" \
  -m "BREAKING CHANGE: /user/profile is deprecated."
git tag v1.0.0
```

**Expected behavior:**
1. `bash scripts/generate-changelog.sh` detects `BREAKING CHANGE` footer
2. Version bumps from v1.0.0 to v2.0.0 (major)
3. Breaking changes section appears at top of changelog
4. Commit message includes `!` suffix and `BREAKING CHANGE:` footer

**Pass criteria:**
- Version bumped by major (1.0.0 → 2.0.0)
- Changelog includes "Breaking Changes" section
- Breaking changes listed first in changelog
