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

## Triggers

This skill auto-activates when the user says:
- **Committing**: "commit", "git commit", "save my changes", "checkpoint", "record changes"
- **Pushing**: "push", "push to GitHub", "upload changes"
- **PRs**: "create a PR", "make a pull request", "open a PR", "draft PR"
- **Releases**: "release", "ship", "version bump", "tag this", "publish"
- **Fixes**: "hotfix", "fix this bug", "patch"
- **General**: "save my work", "version this", "I'm done with this feature"

---

## Scripts & Templates Overview

This skill ships with:
```
scripts/
  scan-secrets.sh          — Scan staged changes for secrets before committing
  detect-test-runner.sh    — Auto-detect and run the project's test suite
  split-commits.sh         — Analyze diff and suggest atomic commit splitting
  generate-changelog.sh    — Auto-generate CHANGELOG.md from git history

templates/
  CLAUDE.md.example        — Drop-in project rules template for AI agents
  commit-types.md          — Full conventional commits reference card
  gitmessage               — Git commit message template (.git/COMMIT_TEMPLATE)

references/
  analysis-guide.md        — How to read diffs & find commit boundaries
  atomic-commit-patterns.md — Splitting mixed changesets with examples
  message-examples.md      — 13 gold-standard commit messages by type
  pr-template.md           — Rich PR body template for gh pr create
  security-scan-rules.md   — Secret patterns, what to block, how to fix
  release-workflow.md      — Semver, changelog gen, tagging strategy
```

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

Run the automated security scanner before staging:

```bash
bash scripts/scan-secrets.sh
```

Or for a quick manual scan:
```bash
git diff | grep -iE "(api_key|secret|password|token|private_key|bearer|auth)" | head -20
git diff --name-only | xargs grep -liE "(api_key|secret|password|token)" 2>/dev/null | head -10
git status | grep -E "\.env|\.pem|\.key|credentials|secrets"
```

If anything suspicious is found:
1. Remove it immediately
2. Add the file to `.gitignore`
3. Inform the user
4. Never proceed until clean

Read `references/security-scan-rules.md` for the full list of secret patterns to block.

---

## Phase 3 — Run Tests (Gate the Commit)

Run the auto-detection script to find and execute the project's test suite:

```bash
bash scripts/detect-test-runner.sh
```

The script supports: npm, yarn, pnpm, pytest, cargo, go test, make test, rspec, mix test, gradle, maven, ctest.

**If tests fail**: Fix the failures first, then commit the fix alongside the feature.
Never commit a broken state. If the user says "commit anyway", add a `WIP:` prefix
and create a draft PR instead of a regular commit.

If no test runner is detected, ask the user if they want to proceed.

---

## Phase 4 — Split Into Atomic Commits

Group changes by concern. Each commit should answer: *"What single thing does this do?"*

Run the split helper to analyze and plan:
```bash
bash scripts/split-commits.sh
```

**Splitting strategy:**
- `feat:` — new capability added
- `fix:` — bug resolved
- `refactor:` — restructured without behavior change
- `test:` — tests added/updated
- `docs:` — documentation only
- `chore:` — config, deps, tooling
- `perf:` — performance improvement
- `security:` — security fix (use this explicitly, not `fix:`)
- `hotfix:` — urgent production fix (always from main)

Stage selectively:
```bash
git add src/auth/           # only auth changes
git add tests/test_auth.py  # tests together with what they test
# NOT: git add .            # avoid unless single-concern changeset
```

Read `references/atomic-commit-patterns.md` for splitting examples.
Read `templates/commit-types.md` for the full commit type reference card.

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

### Git Message Template

Use the included template for consistent formatting:
```bash
# Set up the template for this repo
git config commit.template templates/gitmessage
```

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

Read `references/message-examples.md` for 13 real examples across all commit types.
Read `templates/commit-types.md` for the quick-reference card.

---

## Phase 6 — Link to Issues & Project Trackers

Before committing, check if there's an open issue:

```bash
# If GitHub CLI is available
gh issue list --state open 2>/dev/null | head -20

# If project uses Jira / Linear / etc.
# Check for ticket references in branch name or recent commits
git log --oneline -3 | grep -iE "(PROJ-\d+|#[0-9]+)" || true
```

Ask the user: *"Is this related to any open issue or ticket?"*

Use the correct footer keyword based on intent:
- `Closes #N` — fully resolves the issue (auto-closes on merge)
- `Fixes #N` — same as Closes, for bugs specifically
- `Refs #N` — related but doesn't close it
- `Part of #N` — one commit in a larger effort
- `Jira: PROJ-123` — reference for Jira tickets (no auto-close)

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

For hotfix PRs, always target `main` directly:
```bash
gh pr create --base main \
  --title "hotfix(scope): urgent description" \
  --body "$(cat references/pr-template.md)" \
  --label hotfix
```

---

## Phase 10 — Release Tagging (When Applicable)

If the user says "release", "ship", "version bump", or "tag this":

```bash
# Generate changelog and bump version automatically
bash scripts/generate-changelog.sh

# Or read current version manually
cat package.json | grep '"version"' 2>/dev/null
cat pyproject.toml | grep 'version' 2>/dev/null
```

Then:
1. Bump version in the appropriate file (`package.json`, `pyproject.toml`, etc.)
2. Run `bash scripts/generate-changelog.sh` to update CHANGELOG.md (if not run already)
3. Commit: `release: bump version to v1.x.x`
4. Tag: `git tag -a v1.x.x -m "Release v1.x.x"`
5. Push with tags: `git push && git push --tags`

Read `references/release-workflow.md` for full release process including hotfix releases and branching strategy.

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
| Secret found in diff | Remove, add to .gitignore, run `bash scripts/scan-secrets.sh` |
| Mixed concerns in diff | Run `bash scripts/split-commits.sh`, split into atomic commits |
| No issue to link | Ask the user before proceeding |
| On main branch | Create feature branch first |
| Breaking change | Add `BREAKING CHANGE:` footer + `!` suffix, bump major version |
| WIP / incomplete | `git commit -m "WIP: ..."` + open draft PR |
| Hotfix needed | Branch from `main`, fix, PR to `main`, cherry-pick to `develop` |
| Release / version | Run `bash scripts/generate-changelog.sh`, tag, push tags |
| No test runner found | Warn user, ask if they want to proceed |
| Project needs rules | Copy `templates/CLAUDE.md.example` to `CLAUDE.md` and customize |

---

## Reference Files

- `references/analysis-guide.md` — How to read diffs and identify commit boundaries
- `references/atomic-commit-patterns.md` — Real examples of splitting mixed changesets
- `references/message-examples.md` — 13 gold-standard commit message examples across all types
- `references/security-scan-rules.md` — Secret patterns, what to block, how to fix
- `references/release-workflow.md` — Semver, changelog gen, tagging, hotfix branch strategy
- `references/pr-template.md` — PR body template to use with `gh pr create`
- `scripts/scan-secrets.sh` — Automated security scanner (exit code gates commits)
- `scripts/detect-test-runner.sh` — Auto-detect and run project test suite
- `scripts/split-commits.sh` — Analyze changes and suggest atomic commit splits
- `scripts/generate-changelog.sh` — Auto-generate CHANGELOG.md from git history
- `templates/CLAUDE.md.example` — Drop-in project rules template for AI agents
- `templates/commit-types.md` — Full conventional commits reference card
- `templates/gitmessage` — Git commit message template
