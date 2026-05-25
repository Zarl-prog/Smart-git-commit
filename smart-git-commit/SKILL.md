---
name: smart-git-commit
description: >
  Use this skill whenever the user wants to commit code, push to GitHub, create a PR,
  or do anything related to saving/sharing their code changes. Triggers on: "commit",
  "push", "save my changes", "create a PR", "make a pull request", "git commit",
  "ship this", "checkpoint my work", "version this", or any request to record/publish
  code changes. This skill produces the most useful, richest Git commits possible —
  far beyond what typical agents do — with test-gating, atomic splits, decision logs,
  security scanning, issue linking, and semantic versioning. Use it aggressively
  whenever git workflow is involved, even implicitly.
---

# Smart Git Commit Skill

Produces gold-standard Git commits: tested, atomic, well-documented, secure, and
traceable. Follow every phase below in order. Never skip phases unless the user
explicitly says so.

---

## Phase 0 — Read Project Rules First

Before doing anything, check for a `CLAUDE.md` or `.git/COMMIT_TEMPLATE` in the repo root:

```bash
cat CLAUDE.md 2>/dev/null || true
cat .git/COMMIT_TEMPLATE 2>/dev/null || true
cat .gitmessage 2>/dev/null || true
```

If found, **those rules override the defaults in this skill**. Merge them with the
steps below — don't ignore either.

---

## Phase 1 — Understand What Changed

Run a full diff analysis before touching `git add`:

```bash
git status
git diff --stat          # which files, how many lines
git diff                 # full diff for small changesets
git log --oneline -5     # recent context
```

Ask yourself:
- Do the changes span **multiple concerns**? (feature + bugfix + refactor = 3 commits)
- Are there **test files** present for the changed code?
- Is there an **open issue or ticket** this relates to?
- Does anything look like a **breaking change**?

Read `references/analysis-guide.md` for diff analysis patterns.

---

## Phase 2 — Security Scan (Never Skip)

Before staging anything, scan for secrets:

```bash
# Check for common secret patterns
git diff | grep -iE "(api_key|secret|password|token|private_key|bearer|auth)" | head -20
git diff --name-only | xargs grep -liE "(api_key|secret|password|token)" 2>/dev/null | head -10

# Check if .env or credential files are accidentally staged
git status | grep -E "\.env|\.pem|\.key|credentials|secrets"
```

If anything suspicious is found:
1. Remove it immediately
2. Add the file to `.gitignore`
3. Inform the user
4. Never proceed until clean

---

## Phase 3 — Run Tests (Gate the Commit)

Detect and run the project's test suite:

```bash
# Auto-detect test runner
if [ -f "package.json" ]; then
  npm test 2>&1 | tail -20
elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
  pytest --tb=short 2>&1 | tail -20
elif [ -f "Cargo.toml" ]; then
  cargo test 2>&1 | tail -20
elif [ -f "go.mod" ]; then
  go test ./... 2>&1 | tail -20
fi
```

**If tests fail**: Fix the failures first, then commit the fix alongside the feature.
Never commit a broken state. If the user says "commit anyway", add a `WIP:` prefix
and create a draft PR instead of a regular commit.

---

## Phase 4 — Split Into Atomic Commits

Group changes by concern. Each commit should answer: *"What single thing does this do?"*

**Splitting strategy:**
- `feat:` — new capability added
- `fix:` — bug resolved
- `refactor:` — restructured without behavior change
- `test:` — tests added/updated
- `docs:` — documentation only
- `chore:` — config, deps, tooling
- `perf:` — performance improvement
- `security:` — security fix (use this explicitly, not `fix:`)

Stage selectively:
```bash
git add src/auth/           # only auth changes
git add tests/test_auth.py  # tests together with what they test
# NOT: git add .            # avoid unless single-concern changeset
```

Read `references/atomic-commit-patterns.md` for splitting examples.

---

## Phase 5 — Write the Commit Message

Follow this exact structure:

```
<type>(<scope>): <short imperative summary under 72 chars>

<body — explain WHY, not just what. Include:>
- The problem that existed before this change
- What approach was chosen and why (vs alternatives considered)
- Any side effects or things to watch out for
- Performance/security implications if relevant

<footers>
Closes #<issue>
Breaking change: <description if applicable>
Co-authored-by: <if pair programmed>
```

### Rules for the summary line:
- Use **imperative mood**: "add", "fix", "remove" — not "added", "fixing"
- No period at the end
- Scope = the module/area affected: `auth`, `api`, `db`, `ui`, `payments`
- Under 72 characters

### Body requirements (what other agents skip):
- At least 2–3 sentences explaining **why**
- Mention **alternatives considered** for non-trivial decisions
- Flag **breaking changes** explicitly
- Reference **performance numbers** if this is a perf fix

### Example of a great commit:

```
fix(payments): prevent double-charge on webhook retry

Stripe was delivering webhooks twice under high load due to a 30s
timeout on our side. Added idempotency_key (order_id + unix_ts hash)
to all charge requests. Considered Redis deduplication but this is
simpler and Stripe-native.

Affects all payment flows. Existing orders are safe — key only
applies to new charge attempts after deploy.

Closes #301
```

Read `references/message-examples.md` for 10 real examples across different types.

---

## Phase 6 — Link to Issues & Project Trackers

Before committing, check if there's an open issue:

```bash
# If GitHub CLI is available
gh issue list --state open 2>/dev/null | head -20
```

Ask the user: *"Is this related to any open issue or ticket?"*

Use the correct footer keyword based on intent:
- `Closes #N` — fully resolves the issue (auto-closes on merge)
- `Fixes #N` — same as Closes, for bugs specifically
- `Refs #N` — related but doesn't close it
- `Part of #N` — one commit in a larger effort

---

## Phase 7 — Execute the Commit

```bash
git add <carefully selected files>
git status   # confirm staged files look right
git diff --cached --stat   # one final check
git commit -m "<subject>" -m "<body>" -m "<footers>"
```

After committing, show the result:
```bash
git show --stat HEAD
```

---

## Phase 8 — Push Strategy

**Never push directly to `main` or `develop`** unless the user has explicitly said
the repo uses trunk-based development.

```bash
# Preferred: push to feature branch
git push origin HEAD

# If branch doesn't exist on remote yet
git push --set-upstream origin <branch-name>
```

For multiple commits, consider:
```bash
git log --oneline origin/main..HEAD   # show what will be pushed
```

---

## Phase 9 — Create PR (If Pushing Feature Branch)

If GitHub CLI is available and this is a feature branch:

```bash
gh pr create \
  --title "<type>(<scope>): <summary>" \
  --body "$(cat references/pr-template.md)" \
  --draft   # default to draft; user promotes when ready
```

The PR body should include:
- What changed and why (from commit body)
- How to test it
- Screenshots if UI changed
- Checklist: tests pass, docs updated, no secrets

---

## Phase 10 — Release Tagging (When Applicable)

If the user says "release", "ship", "version bump", or "tag this":

```bash
# Read current version
cat package.json | grep '"version"' 2>/dev/null
cat pyproject.toml | grep 'version' 2>/dev/null

# Generate changelog from commits since last tag
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

Then:
1. Bump version in the appropriate file (`package.json`, `pyproject.toml`, etc.)
2. Update `CHANGELOG.md` with categorized changes
3. Commit: `chore(release): bump version to v1.x.x`
4. Tag: `git tag -a v1.x.x -m "Release v1.x.x"`
5. Push with tags: `git push && git push --tags`

---

## Output to User After Each Commit

Always show a clean summary:

```
✅ Committed: fix(auth): resolve token expiry race condition
📁 Files: 3 changed, 47 insertions, 12 deletions
🔗 Closes: #188
🌿 Branch: feature/auth-improvements
🚀 Pushed: yes → origin/feature/auth-improvements
```

---

## Quick Reference

| Scenario | Action |
|---|---|
| Tests fail | Fix first, commit fix + feature together |
| Secret found in diff | Remove, add to .gitignore, then commit |
| Mixed concerns in diff | Split into multiple atomic commits |
| No issue to link | Ask the user before proceeding |
| On main branch | Create feature branch first |
| Breaking change | Add `BREAKING CHANGE:` footer, bump major version |
| WIP / incomplete | `git commit -m "WIP: ..."` + open draft PR |

---

## Reference Files

- `references/analysis-guide.md` — How to read diffs and identify commit boundaries
- `references/atomic-commit-patterns.md` — Real examples of splitting mixed changesets
- `references/message-examples.md` — 10 gold-standard commit message examples
- `references/pr-template.md` — PR body template to use with `gh pr create`
