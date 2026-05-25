# Conventional Commits Reference Card

## Quick Reference

```
<type>(<scope>): <imperative summary — max 72 chars>

CONTEXT: <past tense — what existed before>
CHANGE:  <present tense — exactly what was done>
WHY:     <the non-obvious reason>
IMPACT:  <what this enables or unblocks>

<footer>
```

---

## Types Reference

| Type | Emoji | When to Use | Bad Example | Good Example |
|------|-------|-------------|-------------|--------------|
| `feat` | ✨ | New feature for the user or API | `feat: stuff` | `feat(auth): add OAuth2 login with Google` |
| `fix` | 🐛 | Bug fix (production or development) | `fix: fixed it` | `fix(api): handle null response on timeout` |
| `perf` | ⚡ | Performance improvement | `perf: faster now` | `perf(db): add composite index on org_id` |
| `security` | 🔐 | Security vulnerability fix | `security: patched` | `security(api): add rate limiting to login` |
| `refactor` | ♻️ | Code change with no behavior change | `refactor: cleaned up` | `refactor(payments): extract validator class` |
| `test` | 🧪 | Adding or updating tests | `test: more tests` | `test(cart): add empty cart checkout cases` |
| `docs` | 📚 | Documentation only | `docs: updated` | `docs(api): document webhook payload format` |
| `chore` | 🔧 | Config, deps, tooling, CI | `chore: stuff` | `chore(deps): upgrade axios to 1.7.2` |
| `hotfix` | 🚑 | Urgent production fix | `hotfix: fixed` | `hotfix(api): restore removed pagination param` |
| `revert` | ⏪ | Reverts a previous commit | `revert: revert` | `revert: restore removed endpoint from a3b2c1d` |
| `release` | 🏷️ | Version bump / release tagging | `release: bump` | `release: bump version to v2.1.0` |
| `deps` | 📦 | Dependency updates only | `deps: upgrade` | `deps: upgrade react to 18.3.0` |
| `migration` | 🗃️ | Database schema or data migration | `migration: add column` | `migration: add email_verified column to users` |
| `style` | 🎨 | Formatting, whitespace (no logic change) | `style: format` | `style(core): reformat with prettier` |
| `ci` | 👷 | CI/CD configuration changes | `ci: pipeline` | `ci: add GitHub Actions deploy workflow` |
| `build` | 🏗️ | Build system changes | `build: config` | `build: switch from webpack to vite` |

---

## Scope Guidance

| Good Scope | Bad Scope |
|------------|-----------|
| `(auth)` — specific module | `(src)` — too broad |
| `(payments)` — domain boundary | `(utils)` — dumping ground |
| `(api)` — API layer | `(fix)` — it's a type, not a scope |
| `(db)` — data layer | `(changes)` — meaningless |
| `(deps)` — dependencies | `(stuff)` — unprofessional |

**Rule of thumb**: The scope should be the directory or module name that contains
most of the changed files. If it spans 3+ modules, omit the scope.

---

## Summary Line Rules

| Rule | ✅ Good | ❌ Bad |
|------|---------|--------|
| Imperative mood | `add pagination` | `added pagination` / `adding pagination` |
| No period | `fix timeout` | `fix timeout.` |
| Under 72 chars | `feat(api): add pagination to user list` (38 chars) | `feat(api): add pagination support to the user list endpoint with cursor-based navigation` (97 chars) |
| Lowercase after colon | `feat: add` | `feat: Add` |

---

## Breaking Changes

Two ways to mark a breaking change:

```
# Method 1: ! before colon (shorter, preferred)
feat(api)!: redesign user profile endpoint

BREAKING CHANGE: /user/profile deprecated. Use /users/{id}/profile.

# Method 2: BREAKING CHANGE footer (more explicit)
feat(api): redesign user profile endpoint

BREAKING CHANGE: /user/profile deprecated. Use /users/{id}/profile.
```

Breaking changes trigger a **MAJOR** version bump (1.0.0 → 2.0.0).

---

## Footers Reference

| Footer | Usage |
|--------|-------|
| `Closes #N` | Fully resolves an issue (auto-closes on merge) |
| `Fixes #N` | Bug-specific auto-close (same as Closes) |
| `Refs #N` | Related but doesn't close |
| `Part of #N` | One commit in a larger effort |
| `BREAKING CHANGE:` | Breaking change description |
| `Co-authored-by:` | Pair programming credit |
| `Reviewed-by:` | Code review credit |

---

## Decision Tree

```
What type of change is this?
├─ New feature?                    → feat
├─ Bug fix?                        → fix
├─ Security vulnerability?         → security
├─ Performance improvement?        → perf
├─ Code restructure (no behavior)? → refactor
├─ Tests only?                     → test
├─ Documentation only?             → docs
├─ Config / Deps / CI / Tooling?   → chore
├─ Urgent production fix?          → hotfix
├─ Database migration?             → migration
├─ Dependency update?              → deps
├─ Reverting a previous commit?    → revert
├─ Version release?                → release
├─ Breaking change?                → add ! or BREAKING CHANGE footer
└─ Unsure?                         → refactor (safe default)
```
