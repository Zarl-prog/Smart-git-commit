# Atomic Commit Patterns

How to split a mixed changeset into clean, atomic commits.

---

## Rule: One Commit = One Answerable Question

Every commit should answer *exactly one* of:
- "What feature did you add?" → `feat:`
- "What bug did you fix?" → `fix:`
- "What did you clean up?" → `refactor:`
- "What tests did you write?" → `test:` (only if tests are for pre-existing code)
- "What docs did you update?" → `docs:`

If a commit needs an "and" to describe it — split it.

---

## Pattern 1: Feature + Its Tests (Keep Together)

Tests that were written *for* the feature being committed should be in the **same commit** as the feature code. They prove it works.

```bash
# CORRECT — feature and its tests together
git add src/auth/oauth.py tests/test_oauth.py
git commit -m "feat(auth): add Google OAuth login"

# WRONG — splitting feature from its own tests
git add src/auth/oauth.py && git commit -m "feat(auth): add Google OAuth"
git add tests/test_oauth.py && git commit -m "test: add oauth tests"
```

Exception: If adding tests for *existing* code with no feature change, `test:` is its own commit.

---

## Pattern 2: Refactor Before Feature

If you had to clean up old code to make room for the feature, commit the cleanup first:

```bash
# Commit 1: cleanup (no behavior change)
git add src/payments/
git commit -m "refactor(payments): extract PaymentValidator class"

# Commit 2: the actual feature
git add src/payments/ tests/
git commit -m "feat(payments): add Apple Pay support"
```

This keeps refactors reviewable in isolation.

---

## Pattern 3: Dependency Bump Separate from Feature

```bash
# WRONG — mixing deps with feature
git add package.json src/charts/
git commit -m "feat: add chart library and dashboard"

# CORRECT — separate
git add package.json package-lock.json
git commit -m "chore(deps): add recharts 2.10.0 for dashboard charts"

git add src/charts/ tests/
git commit -m "feat(dashboard): add revenue chart component"
```

---

## Pattern 4: Bug Fix Separate from Unrelated Changes

If you spotted and fixed a bug while working on a feature — separate commits:

```bash
# You were building feature X but found bug Y along the way

# Fix the bug first
git add src/users/permissions.py tests/test_permissions.py
git commit -m "fix(users): correct admin permission check for deleted accounts"

# Then commit your feature
git add src/users/invite.py tests/test_invite.py
git commit -m "feat(users): add team invite via email"
```

---

## Pattern 5: Config/Env Changes

Always separate from code changes:

```bash
git add .env.example docker-compose.yml
git commit -m "chore(config): add Redis config for session storage"

git add src/sessions/
git commit -m "feat(sessions): migrate sessions from memory to Redis"
```

---

## Staged Patch — Committing Part of a File

When a single file has changes for two different concerns, use interactive staging:

```bash
git add -p src/api/routes.py
# Git shows each hunk — press 'y' to stage, 'n' to skip
```

This lets you commit only the relevant lines from a file.

---

## Checklist Before Each Commit

- [ ] Does this commit do exactly one thing?
- [ ] Can I describe it without using "and"?
- [ ] Are tests included (if this is a feat/fix)?
- [ ] Is this the smallest possible atomic unit?
- [ ] Would reverting this commit be safe and clean?
