# Atomic Commit Patterns

How to split a mixed changeset into clean, atomic commits.
Each pattern shows the WRONG way and the RIGHT way with actual git commands.

---

## Rule: One Commit = One Concern

Every commit should answer *exactly one* question:

- "What feature did you add?" → `feat:`
- "What bug did you fix?" → `fix:`
- "What did you clean up?" → `refactor:`
- "What tests did you write?" → `test:` (only if tests are for pre-existing code)
- "What docs did you update?" → `docs:`

If a commit needs an "and" to describe it — **split it**.

---

## Pattern 1: Feature + Its Tests Stay Together

Tests written *for* the feature go in the **same commit**. They prove it works.

```bash
# ❌ WRONG — splitting feature from its own tests
git add src/auth/oauth.py
git commit -m "feat(auth): add Google OAuth login"
git add tests/test_oauth.py
git commit -m "test: add oauth tests"
# Reviewers can't tell if tests pass for this feature

# ✅ CORRECT — feature and its tests together
git add src/auth/oauth.py tests/test_oauth.py
git commit -m "feat(auth): add Google OAuth login"
# One commit: "here's the feature, and here's proof it works"
```

**Exception**: If adding tests for *existing* code (not a new feature), use `test:` as a standalone commit.

---

## Pattern 2: Refactor Before Feature

If you cleaned up old code to make room for the feature, commit the cleanup first.

```bash
# ❌ WRONG — mixing cleanup with feature
git add src/payments/ tests/
git commit -m "feat(payments): add Apple Pay and refactor validator"
# Reviewers can't tell what's cleanup vs what's new

# ✅ CORRECT — refactor first, then feature
git add src/payments/validator.py
git commit -m "refactor(payments): extract PaymentValidator class"
# Clean commit: "I moved things around, nothing changed behavior"

git add src/payments/apple_pay.py tests/test_apple_pay.py
git commit -m "feat(payments): add Apple Pay support"
# Clean commit: "I added the feature on top of the cleanup"
```

This keeps refactors reviewable in isolation. Each commit is small and focused.

---

## Pattern 3: Dependency Bump Separate from Feature

```bash
# ❌ WRONG — mixing deps with feature
git add package.json src/charts/
git commit -m "feat(dashboard): add chart library and revenue chart"
# Rolling back the chart library breaks the feature

# ✅ CORRECT — separate commits
git add package.json package-lock.json
git commit -m "chore(deps): add recharts 2.10.0 for dashboard charts"
# Clean dep bump: can be reverted independently

git add src/charts/ tests/test_charts.py
git commit -m "feat(dashboard): add revenue chart component"
# Clean feature: deps already in place
```

---

## Pattern 4: Bug Fix Separate from Unrelated Changes

If you spotted and fixed a bug while working on a feature — separate commits.

```bash
# ❌ WRONG — bug fix buried in feature commit
git add src/users/permissions.py src/users/invite.py
git commit -m "feat(users): add team invite and fix permissions"
# Bug fix is invisible — no one knows to cherry-pick it

# ✅ CORRECT — fix the bug first
git add src/users/permissions.py tests/test_permissions.py
git commit -m "fix(users): correct admin permission check for deleted accounts"
# Clean fix: can be cherry-picked to hotfix branch

git add src/users/invite.py tests/test_invite.py
git commit -m "feat(users): add team invite via email"
# Clean feature: doesn't include the unrelated fix
```

---

## Pattern 5: Config/Env Changes Always Separate

```bash
# ❌ WRONG — config and code mixed
git add .env.example docker-compose.yml src/sessions/
git commit -m "feat(sessions): add Redis session storage"
# Config changes affect dev environment — shouldn't be in feature commit

# ✅ CORRECT — config first, then code
git add .env.example docker-compose.yml
git commit -m "chore(config): add Redis config for session storage"
# Clean config: devs can pull this without code changes

git add src/sessions/ tests/test_sessions.py
git commit -m "feat(sessions): migrate sessions from memory to Redis"
# Clean feature: config is already in place
```

---

## Partial Staging — Committing Part of a File

When a single file has changes for two different concerns (e.g., a refactor AND
a bug fix on the same function), use interactive staging:

```bash
# Stage only the bug fix hunks, skip the refactor hunks
git add -p src/api/routes.py

# Git shows each hunk:
# @@ -42,7 +42,7 @@ def get_user(id):
# Press 'y' to stage this hunk, 'n' to skip

# After staging the bug fix hunks:
git commit -m "fix(api): handle null user response in get_user"

# Then stage the remaining refactor hunks:
git add -p src/api/routes.py
git commit -m "refactor(api): extract validation from get_user"
```

Pro tips for `git add -p`:
- `y` — stage this hunk
- `n` — skip this hunk
- `s` — split into smaller hunks
- `e` — manually edit the hunk (advanced)
- `q` — quit (don't stage remaining hunks)

---

## Pre-Commit Checklist

Run through this checklist before EVERY commit:

- [ ] Does this commit do **exactly one thing**?
- [ ] Can I describe it **without using "and"**?
- [ ] Are **tests included** (if this is a feat/fix)?
- [ ] Is this the **smallest possible atomic unit**?
- [ ] Does the commit message explain **WHY** (not just what)?
- [ ] Are there **no secrets** in the diff? (Run scan-secrets.sh)
- [ ] Would **reverting** this commit be safe and clean?

If any answer is "no" — stop and split.
