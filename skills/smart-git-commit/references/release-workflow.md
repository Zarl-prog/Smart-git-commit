# Release Workflow

## Semantic Versioning Guide

Given a version number **MAJOR.MINOR.PATCH** (e.g., `2.1.3`):

| Bump | When | Example |
|------|------|---------|
| **MAJOR** | Breaking changes in commit messages (BREAKING CHANGE footer or `!` suffix) | `1.0.0` → `2.0.0` |
| **MINOR** | New features (`feat:` commits) without breaking changes | `1.0.0` → `1.1.0` |
| **PATCH** | Bug fixes, performance, security, refactors only (no feat commits) | `1.0.0` → `1.0.1` |

Additional labels for pre-release and build metadata:

```
1.0.0-alpha.1       → Early testing
1.0.0-beta.1        → Feature complete, testing
1.0.0-rc.1          → Release candidate
1.0.0               → Stable release
1.0.1+build.123     → Build metadata (ignored for precedence)
```

Pre-release versions have **lower** precedence than the normal version:
`1.0.0-alpha < 1.0.0 < 1.1.0`

---

## Step-by-Step Release Process

### Phase 1: Prepare

```bash
# 1. Ensure you're on the release branch
git checkout develop
git pull origin develop

# 2. Create release branch
git checkout -b release/v2.1.0

# 3. Run full test suite
bash scripts/detect-test-runner.sh
```

### Phase 2: Generate Changelog

```bash
# 4. Check commits since last tag
git log --oneline v2.0.0..HEAD

# 5. Generate changelog
bash scripts/generate-changelog.sh
```

This parses all commits since the last tag, groups by type, and prepends
to CHANGELOG.md. Review and edit the generated entries.

### Phase 3: Bump Version

```bash
# 6. Update version in manifest file
# package.json:
#   "version": "2.1.0"
# pyproject.toml:
#   version = "2.1.0"
# Cargo.toml:
#   version = "2.1.0"

# 7. Commit the version bump
git add package.json CHANGELOG.md
git commit -m "chore(release): bump version to v2.1.0" \
  -m "CONTEXT: 12 commits since v2.0.0 with 3 feat commits requiring minor bump." \
  -m "CHANGE:  Bumps version from 2.0.0 to 2.1.0. Updates CHANGELOG.md with all entries." \
  -m "WHY:     Minor bump because feat commits are present. No breaking changes." \
  -m "IMPACT:  Prepares for release. CHANGELOG.md documents all changes since last release."
```

### Phase 4: Tag

```bash
# 8. Create annotated tag
git tag -a v2.1.0 -m "Release v2.1.0"

# 9. Push both commit and tags
git push origin release/v2.1.0
git push origin v2.1.0
```

### Phase 5: GitHub Release

```bash
# 10. Create GitHub Release
gh release create v2.1.0 \
  --title "v2.1.0" \
  --notes-file <(echo "See CHANGELOG.md for details") \
  --target release/v2.1.0
```

### Phase 6: Merge

```bash
# 11. Merge release branch to main
gh pr create --title "Release v2.1.0" --base main --head release/v2.1.0
# After merge:
git checkout main && git pull

# 12. Back-merge to develop
git checkout develop && git merge main
git push origin develop

# 13. Delete release branch (local and remote)
git branch -d release/v2.1.0
git push origin --delete release/v2.1.0
```

---

## Hotfix Release Process

For urgent production fixes that can't wait for the next release cycle.

```bash
# 1. Branch from the release tag (NOT from develop)
git checkout -b hotfix/critical-bug v2.0.0

# 2. Make the fix
# ... edit files ...

# 3. Commit with hotfix type
git add src/api/
git commit -m "hotfix(api): restore removed pagination parameter" \
  -m "CONTEXT: Deploy v2.0.0 removed ?limit= param — all API clients broken." \
  -m "CHANGE:  Restores limit parameter with validation (1-200)." \
  -m "WHY:     Hotfix must be minimal — revert entire deploy would lose 3 fixes." \
  -m "IMPACT:  Single-line change, 5 min to ship. Patch version bump only."

# 4. Tag and push
git tag -a v2.0.1 -m "Hotfix v2.0.1"
git push origin hotfix/critical-bug
git push origin v2.0.1

# 5. Create PR targeting main
gh pr create --title "Hotfix v2.0.1 — restore pagination param" \
  --base main --head hotfix/critical-bug --draft

# 6. After merge to main, cherry-pick to develop
git checkout develop && git cherry-pick v2.0.1
git push origin develop
```

---

## Pre-Release Process

For alpha/beta/RC releases before a stable release.

```bash
# 1. From release branch, tag as pre-release
git tag -a v2.1.0-beta.1 -m "Beta 1 of v2.1.0"

# 2. Push tags
git push origin v2.1.0-beta.1

# 3. Create pre-release on GitHub
gh release create v2.1.0-beta.1 \
  --title "v2.1.0-beta.1" \
  --prerelease

# 4. Iterate with beta.2, beta.3, rc.1, etc.
# Each pre-release gets its own tag
```

---

## Automated Version Detection

When running `scripts/generate-changelog.sh`, the version is auto-detected:

| Commit Contents | Bump | Example |
|----------------|------|---------|
| Contains `BREAKING CHANGE:` or `!` suffix | MAJOR | 1.0.0 → 2.0.0 |
| Contains `feat:` commits | MINOR | 1.0.0 → 1.1.0 |
| Only `fix:`, `perf:`, `refactor:`, etc. | PATCH | 1.0.0 → 1.0.1 |
| No changes since last tag | No bump | Stays at current version |

---

## CHANGELOG.md Format

The generated changelog uses [Keep a Changelog](https://keepachangelog.com/) format
with emoji-categorized sections:

```markdown
## [2.1.0] — 2026-06-15

### ✨ Features
- **(api)**: add pagination to user list endpoint (CONTEXT: 15s load times...)

### 🐛 Bug Fixes
- **(payments)**: prevent double-charge on Stripe webhook retry

### ⚡ Performance
- **(db)**: add composite index on org_id

### 🔐 Security
- **(api)**: add rate limiting to login endpoint
```
