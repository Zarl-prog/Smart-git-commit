# Release Workflow

## Semantic Versioning

Given a version number `MAJOR.MINOR.PATCH`:

| Increment | When | Example |
|-----------|------|---------|
| **MAJOR** | Breaking changes (`BREAKING CHANGE` footer) | `1.0.0` → `2.0.0` |
| **MINOR** | New features (`feat:` commits) | `1.0.0` → `1.1.0` |
| **PATCH** | Bug fixes (`fix:` commits) | `1.0.0` → `1.0.1` |

Pre-release suffixes: `-alpha.1`, `-beta.2`, `-rc.1`

## Release Process

### Step 1: Read Current Version

```bash
# Common locations
cat package.json | grep '"version"'
cat pyproject.toml | grep 'version'
cat Cargo.toml | grep 'version'
grep '^version' mix.exs 2>/dev/null
grep '^VERSION' Makefile 2>/dev/null

# If none found, ask user for current version
```

### Step 2: Generate Changelog

```bash
# Run the changelog script
bash scripts/generate-changelog.sh
# This groups commits by type and prepends to CHANGELOG.md
```

### Step 3: Determine New Version

Check the commits since the last tag:
- Contains `BREAKING CHANGE` → bump MAJOR
- Contains `feat:` commits → bump MINOR
- Contains only `fix:` / `chore:` / `docs:` → bump PATCH

### Step 4: Update Version File

```bash
# For npm projects
npm version patch --no-git-tag-version
npm version minor --no-git-tag-version
npm version major --no-git-tag-version

# Manual update
sed -i 's/"version": "1.0.0"/"version": "1.0.1"/' package.json
```

### Step 5: Commit + Tag Release

```bash
git add CHANGELOG.md <version-file>
git commit -m "release: bump version to v1.x.x"
git tag -a v1.x.x -m "Release v1.x.x"
git push origin main --tags
```

## Branching Strategy

| Branch | Purpose | Lifecycle |
|--------|---------|-----------|
| `main` | Production-ready releases | Protected, no direct pushes |
| `develop` | Integration branch | Feature branches merge here |
| `feature/*` | New features | Branched from develop, merges back |
| `fix/*` | Bug fixes | Branched from main, merges back |
| `hotfix/*` | Urgent production fixes | Branched from main, merges to main + develop |
| `release/*` | Release preparation | Branched from develop, merges to main + develop |

## Hotfix Release

```bash
git checkout main
git checkout -b hotfix/critical-bug
# Fix the bug
git commit -m "fix: critical bug description"
git push origin hotfix/critical-bug
# Create PR to main, then merge
# After merge: bump PATCH version, tag, deploy
# Cherry-pick back to develop:
git checkout develop
git cherry-pick <hotfix-commit-hash>
```

## Changelog Format

```markdown
# Changelog

## [1.1.0] - 2024-03-15

### Features
- feat(auth): add OAuth2 login with Google (#42)
- feat(api): add pagination to user list endpoint (#38)

### Bug Fixes
- fix(payments): handle null response from gateway (#41)

### Performance
- perf(db): add composite index on (user_id, created_at) (#39)

### Security
- security(api): add rate limiting to login endpoint (#40)

### Maintenance
- chore(deps): upgrade axios to 1.6.2 (#37)
- docs(api): update rate limiting docs (#36)

## [1.0.0] - 2024-02-01

### Initial Release
- Initial project setup with all core features
```
