---
name: smart-git-commit
description: >
  Use this skill whenever commits, pushes, PRs, or any git workflow is
  involved. Triggers on: "commit", "push", "save my changes", "create a PR",
  "ship this", "open a pull request", "make a release", "tag this version",
  "checkpoint", or any request to record or share code changes. Produces
  gold-standard commits: tested, atomic, secure, richly documented, and
  traceable. Far better than default agent git behavior. Use aggressively.
---

# Smart Git Commit Skill

Produces gold-standard Git commits: tested, atomic, secure, documented, and
traceable. Follow every phase below in order. Never skip phases unless the
user explicitly says so.

<!-- line-limit: 500 -->

## File Structure

```
skills/smart-git-commit/
├── SKILL.md                     ← This file
├── scripts/                     ← Bash automation (JSON stdout)
│   ├── scan-secrets.sh          — Security scanner (exit code gate)
│   ├── detect-test-runner.sh    — Auto-detect & run test suite
│   ├── split-commits.sh         — Analyze & suggest atomic splits
│   ├── generate-changelog.sh    — Auto-generate CHANGELOG.md
│   └── create-pr.sh             — Create draft PR with rich body
├── references/                  ← Deep dives loaded on demand
│   ├── commit-types.md          — Full conventional commits reference
│   ├── atomic-patterns.md       — Splitting mixed changesets
│   ├── message-examples.md      — 15 gold-standard commit examples
│   ├── security-rules.md        — Secret patterns & fix guide
│   └── release-workflow.md      — Versioning, changelog, tagging
├── templates/                   ← Drop-in config files
│   ├── CLAUDE.md.example        — Project rules for AI agents
│   ├── .gitmessage              — Git commit message template
│   └── pr-body.md               — Rich PR body template
└── tests/                       ← Test scenarios & fixtures
    ├── README.md                — How to run tests
    ├── fixtures/                — Sample diffs for testing
    └── test-scenarios.md        — 7 written test cases
```

---

## Phase 0 — Read Project Rules

Check for project-specific rules that override defaults:

```bash
cat CLAUDE.md 2>/dev/null && echo "→ Found CLAUDE.md"
cat .gitmessage 2>/dev/null && echo "→ Found .gitmessage"
```

If found, merge those rules with the steps below. **Project rules take priority.**

---

## Phase 1 — Full Diff Analysis

Run full diff analysis before touching `git add`:

```bash
git status
git diff --stat          # which files, how many lines
git diff                 # full diff for small changesets
git log --oneline -5     # recent commit context
```

Ask yourself:
- Do changes span **multiple concerns**? → split (Phase 4)
- Are **test files** present for the changed code?
- Is there an **open issue or ticket**? (Phase 6)
- Is this a **breaking change**? → add `BREAKING CHANGE:` footer

---

## Phase 2 — Security Scan (Never Skip)

Run the automated security scanner:

```bash
bash scripts/scan-secrets.sh
```

- **Exit 0** → clean, proceed
- **Exit 1** → secrets found, **block commit** immediately

If secrets are found:
1. `git reset HEAD <file>` to unstage
2. Replace with env var or placeholder
3. Add to `.gitignore` if needed
4. Rotate exposed credentials if already pushed

Read `references/security-rules.md` for the full pattern list.

---

## Phase 3 — Test Gate

Auto-detect and run the project's test suite:

```bash
bash scripts/detect-test-runner.sh
```

- **Tests pass** → proceed
- **Tests fail** → fix first, or use `WIP:` prefix for draft PR
- **No runner found** → warn user, ask to proceed

Supported runners: npm test, jest, vitest, pytest, cargo test, go test,
make test, rspec, mix test, gradle, maven, ctest.

---

## Phase 4 — Atomic Split Decision

Run the split analyzer to detect mixed concerns:

```bash
bash scripts/split-commits.sh
```

Group changes by concern. Each commit answers: *"What single thing does this do?"*

| Type | Concern | Example |
|------|---------|---------|
| `feat:` | New feature | `git add src/auth/` |
| `fix:` | Bug fix | `git add src/payments/` |
| `refactor:` | Restructure | `git add src/lib/` |
| `test:` | Tests only | `git add tests/` |
| `docs:` | Documentation | `git add docs/` |
| `chore:` | Config/deps | `git add package.json` |
| `hotfix:` | Urgent fix | `git add src/api/` |

Stage selectively — never `git add .` for mixed changesets.

Read `references/atomic-patterns.md` for splitting strategies.

---

## Phase 5 — Commit Message Construction

This is the **core of this skill**. Every commit uses this 5-part format:

```
<type>(<scope>): <imperative summary — max 72 chars>

CONTEXT: <what state the code was in BEFORE this change>
CHANGE:  <exactly what was done>
WHY:     <the reason — business or technical motivation>
IMPACT:  <what this enables or unblocks>

<footers: Closes #N | BREAKING CHANGE: ...>
```

### Rules for Each Field

| Field | Rule | Good | Bad |
|-------|------|------|-----|
| **CONTEXT** | Past tense, describes the gap | "Auth tokens had no expiry" | "There was a bug" |
| **CHANGE** | Present tense, specific | "Adds 15-min sliding expiry with refresh rotation" | "Fixed the token thing" |
| **WHY** | Not obvious from code | "Required for SOC2 compliance" | "To improve security" |
| **IMPACT** | Downstream effect | "Enables audit logging of token refresh events" | "Things are better now" |

### Summary line rules:
- **Imperative mood**: "add" not "added", "fix" not "fixing"
- **No period** at end
- **Under 72 characters**
- **Scope** = module: `auth`, `api`, `payments`, `db`, `ui`, `cli`, `core`

### Example

```
fix(payments): prevent double-charge on Stripe webhook retry

CONTEXT: Stripe delivered webhooks twice under high load due to 30s
         application timeout, causing duplicate charges.
CHANGE:  Adds idempotency_key (order_id + unix_ts hash) to all Stripe
         charge requests.
WHY:     Stripe's API natively deduplicates on idempotency keys — simpler
         than Redis-based deduplication. Only new charge attempts affected.
IMPACT:  Eliminates billing support tickets for duplicate charges.

Closes #301
```

Use the included git template for consistent formatting:
```bash
git config commit.template templates/.gitmessage
```

Read `references/message-examples.md` for 15 full examples.
Read `references/commit-types.md` for the quick-reference card.

---

## Phase 6 — Issue & Ticket Linking

Check for related issues before committing:

```bash
# GitHub issues
gh issue list --state open 2>/dev/null | head -10

# Auto-detect from branch name
git branch --show-current | grep -oE '#[0-9]+|[A-Z]+-[0-9]+'
```

Ask the user: *"Is this related to any open issue or ticket?"*

Use the correct footer keyword:

| Footer | Intent |
|--------|--------|
| `Closes #N` | Fully resolves (auto-closes on merge) |
| `Fixes #N` | Bug-specific auto-close |
| `Refs #N` | Related but doesn't close |
| `Part of #N` | One commit in larger effort |
| `Jira: PROJ-123` | Jira reference (no auto-close) |
| `Linear: PROJ-123` | Linear reference |

---

## Phase 7 — Execute Commits

```bash
git add <carefully selected files>
git dif   --cached --stat   # final verification
git commit
```

After committing, show the result:
```bash
git show --stat HEAD
```

Always output a clean summary:
```
✅ Committed: fix(auth): resolve token expiry race condition
📁 Files: 3 changed, 47 insertions, 12 deletions
🔗 Closes: #188
🌿 Branch: feature/auth-improvements
```

---

## Phase 8 — Push Strategy

**Never push directly to `main` or `develop`** unless trunk-based dev is confirmed.

```bash
# Push to feature branch
git push origin HEAD

# If branch not on remote yet
git push --set-upstream origin $(git branch --show-current)
```

For multi-commit branches, review before push:
```bash
git log --oneline origin/main..HEAD
```

Exception: **hotfix** branches may push to main after user confirms.

---

## Phase 9 — PR Creation

If GitHub CLI is available and this is a feature branch:

```bash
bash scripts/create-pr.sh    # creates draft PR
```

Options:
- `--no-draft` — create as ready PR instead of draft
- `--base develop` — target develop branch

The script:
1. Reads branch name and recent commits
2. Builds PR title from most significant commit subject
3. Fills body from `templates/pr-body.md` with commit contexts
4. Creates as draft by default

For hotfix PRs, always target `main` directly.

---

## Phase 10 — Release Tagging

If the user says "release", "ship", "version bump", or "tag this":

```bash
# Generate changelog and bump version automatically
bash scripts/generate-changelog.sh
```

Then:
1. Read current version from `package.json`, `pyproject.toml`, `Cargo.toml`
2. Run `bash scripts/generate-changelog.sh` to update CHANGELOG.md
3. Bump version in the appropriate file
4. Commit: `release: bump version to v1.x.x` (with 5-part format)
5. Tag: `git tag -a v1.x.x -m "Release v1.x.x"`
6. Push: `git push && git push --tags`

Read `references/release-workflow.md` for full release process.

---

## Quick Reference

| Scenario | Action |
|---|---|
| Tests fail | Fix first, commit fix + feature together, or use WIP |
| Secret in diff | Unstage, remove, add to .gitignore, rotate if pushed |
| Mixed concerns | `bash scripts/split-commits.sh`, split into atomic commits |
| No issue to link | Ask user before proceeding |
| On main branch | Create feature branch first |
| Breaking change | Add `BREAKING CHANGE:` footer + `!` suffix, bump major |
| WIP / incomplete | `WIP: <type>(<scope>): <summary>` + draft PR |
| Hotfix needed | Branch from `main`, fix, PR to `main`, cherry-pick to develop |
| Release / version | `bash scripts/generate-changelog.sh`, tag, push tags |
| No test runner | Warn user, ask if they want to proceed |
| Start using skill | Copy `templates/CLAUDE.md.example` → `CLAUDE.md`, customize |

---

## References

- `references/commit-types.md` — Full conventional commits reference card
- `references/atomic-patterns.md` — Real examples of splitting changesets
- `references/message-examples.md` — 15 examples of the 5-part format
- `references/security-rules.md` — Secret patterns, what to block, how to fix
- `references/release-workflow.md` — Semver, changelog, tagging strategy
- `references/pr-template.md` — PR body template (legacy)
- `templates/.gitmessage` — Set as `git config commit.template`
- `templates/CLAUDE.md.example` — Drop-in project rules for AI agents
- `tests/test-scenarios.md` — 7 test cases for this skill
