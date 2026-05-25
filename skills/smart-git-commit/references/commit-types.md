# Conventional Commits Reference Card

## Quick Reference

```
<type>(<scope>): <imperative summary — max 72 chars>

CONTEXT: <what state the code was in BEFORE this change>
CHANGE:  <exactly what was done>
WHY:     <the reason — business or technical motivation>
IMPACT:  <what this enables or unblocks>

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
| `hotfix` | Urgent production fix | Patch | `hotfix(api): restore removed pagination param` |
| `deps` | Dependency updates | — | `deps: upgrade react to 18.3.0` |
| `migration` | Database or data migration | — | `migration: add email_verified column to users` |

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
| `(config)` | Configuration files, env vars |

## Subject Line Rules

- **Imperative mood**: "add" not "added", "fix" not "fixing"
- **No period** at the end
- **Under 72 characters**
- **Lowercase** after the colon

✅ `feat(api): add pagination to user list`
❌ `feat(api): Added pagination to user list.`

## Breaking Changes

```
feat(api)!: redesign user profile endpoint

CONTEXT: /user/profile returned full objects even when callers only needed IDs.
CHANGE:  Replaces /user/profile with /users/{id}/profile returning only requested fields.
WHY:     Reduced payload size by 60% on list views; aligns with REST conventions.
IMPACT:  All clients must update their endpoint URLs. Old endpoint redirects for 90 days.

BREAKING CHANGE: /user/profile is deprecated. Use /users/{id}/profile.
```

Two ways to mark:
1. `!` before the colon: `feat(api)!: ...`
2. `BREAKING CHANGE:` in the footer

## Footers

| Footer | Usage |
|--------|-------|
| `Closes #N` | Fully resolves an issue |
| `Fixes #N` | Same as Closes, for bugs specifically |
| `Refs #N` | Related but doesn't close |
| `Part of #N` | One commit in a larger effort |
| `Jira: PROJ-123` | Jira ticket reference (no auto-close) |
| `Linear: PROJ-123` | Linear issue reference |
| `BREAKING CHANGE:` | Breaking change description |
| `Co-authored-by:` | Pair programming credit |
| `Reviewed-by:` | Code review credit |

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
├─ Urgent production fix? → hotfix
├─ Database migration?    → migration
├─ Dependency update?     → deps
├─ Reverting?             → revert
├─ Breaking change?       → add ! or BREAKING CHANGE footer
└─ Version release?       → release
```
