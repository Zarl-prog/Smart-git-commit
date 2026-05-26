# PR Title Template

Your PR title becomes the merge commit message on most repos.
It appears in the CHANGELOG forever. Write it carefully.

---

## Formula

```
<type>(<scope>): <imperative summary under 72 chars>
```

Same rules as a commit subject line:
- **Imperative mood**: "add" not "added", "fix" not "fixed"
- **No period** at the end
- **Under 72 characters** so it renders fully in GitHub's UI
- **Must make sense in a CHANGELOG** — this is what users will see

---

## 10 Good Examples

| # | Title | Type | Why It Works |
|---|-------|------|-------------|
| 1 | `feat(auth): add Google OAuth login with refresh token rotation` | feat | Specific scope, clear what was added, CHANGELOG-ready |
| 2 | `fix(api): handle null response on connection timeout` | fix | States exact bug and condition, scope = api |
| 3 | `perf(db): add composite index on (org_id, created_at)` | perf | Specific index, measurable scope, CHANGELOG-ready |
| 4 | `security(api): add rate limiting to login endpoint` | security | Clear security concern, specific endpoint |
| 5 | `refactor(payments): extract PaymentValidator from PaymentProcessor` | refactor | Shows what moved where, no behavior change implied |
| 6 | `test(cart): add empty cart checkout and quantity overflow cases` | test | Specific test scenarios named, scope = cart |
| 7 | `docs(api): document webhook payload format and retry behavior` | docs | What was documented, scope = api |
| 8 | `chore(deps): upgrade axios to 1.7.2 to fix CVE-2024-39338` | chore | Specific dep + version + reason |
| 9 | `feat(api)!: redesign user profile endpoint with sparse fieldsets` | feat! | Breaking change marked with `!` |
| 10 | `hotfix(api): restore removed pagination parameter` | hotfix | Urgent fix, specific thing restored |

---

## 5 Bad Examples

| # | Bad Title | Why It Fails |
|---|-----------|-------------|
| 1 | `Added oauth stuff and fixed some things` | Past tense ("Added"), vague ("stuff"/"things"), multiple concerns ("and") |
| 2 | `fix things` | No scope, no detail, no one knows what this does |
| 3 | `feat: This is a very long title that goes way beyond the 72 character limit and nobody can read it in full` | Exceeds 72 chars, gets truncated in GitHub UI and CHANGELOG |
| 4 | `Updated the files` | Past tense ("Updated"), no scope, no specific change |
| 5 | `wip` | WIP is for commits, not PRs. Draft status handles this |

---

## The One Rule

**If your PR title doesn't make sense in a CHANGELOG, rewrite it.**

```
# ✅ Good in CHANGELOG
feat(auth): add Google OAuth login
   ↓
## ✨ Features
- **(auth)**: add Google OAuth login

# ❌ Bad in CHANGELOG
Added oauth feature
   ↓
## ✨ Features
- Added oauth feature   ← Unprofessional, inconsistent
```
