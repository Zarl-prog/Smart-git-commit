# Test Scenarios — Smart Git Commit Skill

## Scenario 1 — Happy Path Single Commit

**Goal:** Verify the skill handles a single-concern changeset without splitting.

**Setup:**
```bash
echo "console.log('hello')" > index.js
git add index.js
```

**Trigger phrase:** "commit these changes"

**Expected behavior:**
1. Phase 1 identifies 1 file, single concern
2. Phase 2 security scan passes (exit 0)
3. Phase 3 test gate warns "no runner found" and asks to proceed
4. Phase 4 determines single concern — no split needed
5. Phase 5 constructs 5-part commit message
6. Phase 7 commits successfully

**Pass criteria:**
- `bash scripts/scan-secrets.sh` exits 0 with `"status":"clean"`
- `bash scripts/split-commits.sh` outputs `"status":"single_concern"`
- A single commit is created with the 5-part format

---

## Scenario 2 — Mixed Concerns (Should Produce 3 Commits)

**Goal:** Verify the skill detects multiple concerns and suggests atomic splits.

**Setup:**
```bash
git apply tests/fixtures/mixed-diff.txt
git add -A
```

**Trigger phrase:** "commit these changes"

**Expected behavior:**
1. Phase 1 identifies 3 concerns: auth, payments, deps
2. Phase 4 calls `bash scripts/split-commits.sh`
3. Split plan shows 3 separate commits
4. Each commit has a clear single concern

**Pass criteria:**
- `bash scripts/split-commits.sh` suggests 3+ commits
- Commit messages distinguish: auth, payments, deps
- No commit contains files from multiple concerns

---

## Scenario 3 — Secret in Diff (Must Hard-Block)

**Goal:** Verify the security scan blocks commits containing secrets.

**Setup:**
```bash
git apply tests/fixtures/secret-diff.txt
git add -A
```

**Trigger phrase:** "commit these changes"

**Expected behavior:**
1. Phase 2 runs `bash scripts/scan-secrets.sh`
2. Script detects at least 2 secret patterns
3. Script exits with code 1
4. Phase 2 stops — commit is blocked

**Pass criteria:**
- `bash scripts/scan-secrets.sh` exits with code 1
- JSON output includes `"status":"found"`
- Findings include at least: AWS key, API key

---

## Scenario 4 — Tests Failing (Must Hard-Block)

**Goal:** Verify the test gate prevents commits when tests are failing.

**Setup:**
```bash
echo "def test_always_fails(): assert False" > test_fail.py
echo "[tool.pytest.ini_options]" > pyproject.toml
git add test_fail.py pyproject.toml
```

**Trigger phrase:** "commit these changes"

**Expected behavior:**
1. Phase 3 runs `bash scripts/detect-test-runner.sh`
2. Test suite fails (exit code 1)
3. Phase 3 blocks the commit
4. User is offered: fix tests or abort

**Pass criteria:**
- `bash scripts/detect-test-runner.sh` outputs `"status":"fail"`
- Phase 3 does NOT proceed to Phase 4

---

## Scenario 5 — Full Release Flow

**Goal:** Verify the changelog generation and version bumping.

**Setup:**
```bash
git tag v1.0.0
git commit --allow-empty -m "feat(api): add pagination to user list"
git commit --allow-empty -m "fix(db): handle null timestamps"
```

**Trigger phrase:** "make a release"

**Expected behavior:**
1. Phase 10 runs `bash scripts/generate-changelog.sh`
2. Script reads commits since v1.0.0
3. Groups commits into Features and Bug Fixes
4. Version bumps to v1.1.0 (feat commits present)
5. Prepends new section to CHANGELOG.md

**Pass criteria:**
- CHANGELOG.md updated with new version section
- JSON output includes version bump
- Entries are grouped by type (feat, fix)

---

## Scenario 6 — Hotfix on Main Branch

**Goal:** Verify the skill handles urgent production fixes correctly.

**Setup:**
```bash
git checkout main
git checkout -b hotfix/critical-bug
echo "fix" > patch.txt
git add patch.txt
```

**Trigger phrase:** "ship this hotfix"

**Expected behavior:**
1. Phase 0 checks CLAUDE.md for hotfix rules
2. Phase 8 allows push from hotfix branch
3. Commit uses `hotfix` type instead of `fix`
4. Commit message includes severity context

**Pass criteria:**
- Branch name detected as hotfix
- Commit type is `hotfix`, not `fix`
- Phase 8 pushes directly (hotfix exception)

---

## Scenario 7 — Breaking Change (Must Include Major Bump)

**Goal:** Verify that breaking changes are properly flagged and cause a major version bump.

**Setup:**
```bash
git commit --allow-empty -m "feat(api)!: redesign user profile endpoint" \
  -m "BREAKING CHANGE: /user/profile is deprecated."
git tag v1.0.0
```

**Trigger phrase:** "make a release"

**Expected behavior:**
1. `bash scripts/generate-changelog.sh` detects `BREAKING CHANGE` footer
2. Version bumps from v1.0.0 to v2.0.0 (major)
3. Breaking Changes section appears at top of changelog
4. Commit message includes `!` suffix and `BREAKING CHANGE:` footer

**Pass criteria:**
- Version bumped by major (1.0.0 → 2.0.0)
- Changelog includes "Breaking Changes" section
- Breaking changes listed first in changelog
