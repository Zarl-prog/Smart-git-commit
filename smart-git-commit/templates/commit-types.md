# Conventional Commits Reference Card

## Quick Reference

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Types

| Type | Description | Releases | Example |
|------|-------------|----------|---------|
| `feat` | A new feature | Minor | `feat(auth): add OAuth2 login with Google` |
| `fix` | A bug fix | Patch | `fix(api): handle null response on timeout` |
| `refactor` | Code change with no behavior change | — | `refactor(payments): extract validator class` |
| `test` | Adding or updating tests | — | `test(cart): add empty cart checkout cases` |
| `docs` | Documentation only | — | `docs(api): document webhook payload format` |
| `chore` | Config, deps, tooling, CI | — | `chore(deps): upgrade axios to 1.6.2` |
| `perf` | Performance improvement | Patch | `perf(db): add composite index on user_id` |
| `security` | Security fix | Patch | `security(api): add rate limiting to login` |
| `style` | Formatting, whitespace (no logic change) | — | `style(core): reformat with prettier` |
| `ci` | CI/CD configuration changes | — | `ci: add GitHub Actions deploy workflow` |
| `build` | Build system changes | — | `build: switch from webpack to vite` |
| `revert` | Reverts a previous commit | — | `revert: restore removed endpoint from #123` |
| `release` | Version bump / release | — | `release: bump version to v1.2.0` |

## Scopes (Examples)

| Scope | When to Use |
|-------|-------------|
| `(api)` | API endpoints, controllers, routes |
| `(auth)` | Authentication, authorization, sessions |
| `(db)` | Database schemas, migrations, queries |
| `(ui)` | Frontend components, styles, pages |
| `(payments)` | Payment processing, billing, invoices |
| `(deps)` | Dependency updates |
| `(infra)` | Infrastructure, deployment, CI/CD |
| `(cli)` | Command-line interface tools |
| `(core)` | Core logic, shared utilities |

## Subject Line Rules

- **Imperative mood**: "add" not "added", "fix" not "fixing"
- **No period** at the end
- **Under 72 characters**
- **Lowercase** after the colon

✅ "feat(api): add pagination to user list"
❌ "feat(api): Added pagination to user list."
❌ "feat(api): added pagination to user list."

## Breaking Changes

```
feat(api)!: redesign user profile endpoint

BREAKING CHANGE: /user/profile is deprecated. Use /users/{id}/profile.
```

Two ways to mark:
1. `!` before the colon: `feat(api)!: ...`
2. `BREAKING CHANGE:` in the footer

## Footers

| Footer | Usage |
|--------|-------|
| `Closes #N` | Fully resolves an issue |
| `Fixes #N` | Fixes a bug (same as Closes) |
| `Refs #N` | Related to an issue |
| `Part of #N` | One commit in a larger effort |
| `BREAKING CHANGE:` | Breaking change description |
| `Co-authored-by: Name <email>` | Pair programming credit |
| `Reviewed-by: Name <email>` | Code review credit |

## Examples by Type

### feat — New Feature
```
feat(search): add fuzzy matching for product search

Users were getting zero results for minor typos. Integrated Fuse.js
with threshold 0.4. Search latency: 45ms → 52ms avg.

Closes #178
```

### fix — Bug Fix
```
fix(payments): prevent double-charge on webhook retry

Added idempotency_key to all Stripe charge requests. Keys based on
order_id + unix timestamp hash. This is Stripe-native and simpler
than Redis-based deduplication alternatives.

Closes #301
```

### perf — Performance
```
perf(dashboard): replace ORM with raw SQL for reports

Before: 847 queries / 11.2s avg
After:  1 query / 0.18s avg
```

### revert — Revert
```
revert: remove buggy pagination from user list

This reverts commit a3f9c12b. Pagination introduced a regression
where users with >100 items couldn't load their full list. Will
re-implement with cursor-based pagination instead.
```

### release — Release
```
release: bump version to v1.2.0

See CHANGELOG.md for full list of changes.
```

## Decision Tree

```
What type of change is this?
├─ New feature?           → feat
├─ Bug fix?               → fix
├─ Security vulnerability?→ security (not fix)
├─ Performance?           → perf
├─ Code restructure?      → refactor
├─ Tests?                 → test
├─ Documentation?         → docs
├─ Config / Deps / CI?    → chore
├─ Reverting?             → revert
├─ Breaking change?       → add ! or BREAKING CHANGE footer
└─ Version release?       → release
```
