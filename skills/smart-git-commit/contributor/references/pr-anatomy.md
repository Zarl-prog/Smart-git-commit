# PR Anatomy — What Makes a Perfect Pull Request

Every section of a PR serves a specific purpose. Here's how to nail each one.

---

## Title: The Merge Commit Message

Your PR title IS the merge commit message on most repos (squash merge).
It appears in the CHANGELOG forever. Make it count.

### Formula

```
<type>(<scope>): <imperative summary under 72 chars>
```

Same rules as the commit subject line:
- **Imperative mood**: "add" not "added", "fix" not "fixed"
- **No period** at the end
- **Under 72 characters** so it renders fully in GitHub's UI
- **Must make sense in a CHANGELOG** — this is what users see

### Examples

| ✅ Good | ❌ Bad |
|---------|--------|
| `feat(auth): add Google OAuth login with refresh token rotation` | `Added oauth stuff` |
| `fix(api): handle null response on connection timeout` | `fixed a bug` |
| `perf(db): add composite index on (org_id, created_at)` | `performance improvements` |
| `docs(api): document webhook payload format and retry behavior` | `updated docs` |
| `refactor(payments): extract PaymentValidator from PaymentProcessor` | `refactored payments` |

---

## Body: What Changed and Why

Copy from your commit messages. If you used the 5-part format (CONTEXT / CHANGE /
WHY / IMPACT), this section is already written for you.

### Good Example

```markdown
## What changed and why

Added idempotency_key (order_id + unix_ts hash) to all Stripe charge
requests. Stripe's API natively deduplicates on idempotency keys — this
is simpler than Redis-based deduplication and requires no new infra.

## Context

Stripe delivered webhooks twice under high load due to a 30s application
timeout. This caused duplicate charges and billing support tickets.
```

### Bad Example

```markdown
## What changed

Fixed some stripe stuff
```

---

## Body: How to Test

This is the most useful section for maintainers. Be painfully specific.

### Good Example

```markdown
## How to test

1. Run `npm test` — all 342 tests should pass
2. Start the dev server: `npm run dev`
3. Visit `http://localhost:3000/auth/login`
4. Click "Sign in with Google"
5. Complete the OAuth flow
6. Expected: redirect to dashboard at `/dashboard` with user name displayed
7. Check the database: `select * from users where email = 'test@example.com'`
   - Expected: user row exists with `email_verified = true`
```

### Bad Example

```markdown
## How to test

Test the login flow
```

---

## Body: Type of Change

Be honest about what type of change this is. Breaking changes need extra
scrutiny from maintainers. Use checkboxes:

```markdown
## Type of change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [x] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that changes existing behavior)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Refactor (no behavior change)
```

---

## Body: Screenshots

If your change affects the UI — always include screenshots. Before/after
is ideal. Use the GitHub image upload (drag & drop into the textarea).

### Good

```markdown
## Screenshots

**Before** (login page had no Google button):
![Before](https://i.imgur.com/old.png)

**After** (Google OAuth button added below email form):
![After](https://i.imgur.com/new.png)
```

### Bad

```markdown
## Screenshots

N/A
```

If no UI changed — remove this section entirely.

---

## Body: Related Issues

Use the correct keyword so GitHub auto-closes issues on merge.

```markdown
## Related issues

Closes #234    ← Auto-closes when merged
Refs #301      ← Related but doesn't close
Part of #189   ← Part of a larger effort
```

**Never** write "See issue #234" — it does nothing. Use the keywords.

---

## Body: Checklist

Show maintainers you've done your homework:

```markdown
## Checklist

- [x] Tests pass locally (342 passed, 0 failed)
- [x] No secrets in diff (verified with scan-secrets.sh)
- [x] Docs updated if behavior changed
- [x] CONTRIBUTING.md guidelines followed
- [x] Self-reviewed the diff before submitting
```

---

## Body: Notes for Maintainer

Your chance to flag anything unusual:

```markdown
## Notes for maintainer

- Trade-off: Used in-memory rate limiting instead of Redis to avoid
  adding a new dependency. If we outgrow single-instance limits,
  swapping to Redis is a 1-line config change.
- The FCM token expiry edge case is not handled in this PR — filed
  as issue #301 for follow-up.
- The test coverage on the new endpoint is 91%. The remaining 9% is
  the error branch for network timeouts, which needs a mock server.
```

---

## PR Size: Keep It Under 400 Lines

The ideal PR is **under 400 lines changed**. Here's why:

| Lines Changed | Review Quality | Time to Merge |
|---------------|---------------|---------------|
| 1-100 | 🟢 Thorough review | Fast |
| 100-400 | 🟡 Good review | Moderate |
| 400-1000 | 🟠 Surface-level review | Slow |
| 1000+ | 🔴 Skipped or rubber-stamped | Very slow |

Research shows: PRs over 400 lines get **proportionally less review
attention** per line. Maintainers just skim or close the tab.

### How to Split Large PRs

If your PR is over 400 lines:

1. **Split by concern** — auth changes in one PR, API changes in another
2. **Split by dependency** — refactor first, feature on top
3. **Split into stacked PRs** — PR #1: refactor, PR #2: feature (based on PR #1)
4. **Use draft PRs** — open early to show direction, iterate

---

## Timing: When to Open vs. Mark Ready

### Draft PR (Open Immediately)

Open a **draft PR** as soon as you have any code to show:
- Shows intent — prevents duplicate work
- Gets early architecture feedback
- Lets CI run on your branch
- Maintainers can comment on direction without pressure

### Ready for Review (After Self-Review)

Only mark **ready for review** after:
- All tests pass on CI
- You've done a full self-review (see checklist below)
- PR body is complete, not a skeleton
- No WIP commits or debugging code
- You've verified the diff contains only your intended changes

### Ping Timing

After opening for review:
- **48 hours** — normal wait before first ping
- **1 week** — if no response, one polite bump comment
- **2 weeks** — consider closing and moving on

Never ping more than once. Maintainers are volunteers.

---

## Self-Review Checklist

Before marking a PR as ready for review, go through this:

- [ ] PR title follows `<type>(<scope>): <summary>` format
- [ ] PR body has all sections filled (what, why, context, test, related)
- [ ] Tests pass locally
- [ ] No secrets in the diff
- [ ] No WIP commits, debug logging, or commented-out code
- [ ] Diff size is under 400 lines (if not, explain why)
- [ ] Each commit is atomic (one concern per commit)
- [ ] Commit messages use the 5-part format
- [ ] Related issues are linked with correct keywords
- [ ] Branch is up to date with upstream/main
- [ ] You've read through your own diff as if you were the reviewer

---

## Real Example PR

### Title
```
feat(auth): add Google OAuth login with refresh token rotation
```

### Full Body

```markdown
## What changed and why

Adds Google OAuth 2.0 login with PKCE flow and automatic refresh token
rotation. Users can now sign in with their Google account instead of
creating a new password-based account. Refresh tokens are rotated on
each use (old token invalidated, new token issued) per Google's
security recommendations.

## Context

Our signup flow required email + password, which had a 40% abandonment
rate. Only 12% of users completed registration. OAuth login is the #1
requested feature from user feedback. Adding OAuth is expected to
increase signup completion to 65%+.

## Type of change

- [x] New feature (non-breaking change that adds functionality)
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] Breaking change (fix or feature that changes existing behavior)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Refactor (no behavior change)

## How to test

1. Run `npm test` — all 342 tests should pass, 14 new auth tests added
2. Start the dev server: `npm run dev`
3. Visit `http://localhost:3000/auth/login`
4. Click "Sign in with Google" button
5. Complete the Google OAuth consent screen
6. Expected: redirect to `/dashboard` showing user name and avatar
7. Open browser dev tools → Application → Cookies
8. Expected: `session_token` cookie set with HttpOnly and Secure flags
9. Check database: `select * from users where email = '<your-email>'`
10. Expected: user row with `auth_provider = 'google'` and
    `email_verified = true`

## Screenshots

**Before** (login page had email/password form only):
![Before](https://i.imgur.com/before-login.png)

**After** (Google button added below email form):
![After](https://i.imgur.com/after-login.png)

## Related issues

Closes #234

## Checklist

- [x] Tests pass locally (356 passed, 0 failed)
- [x] No secrets in diff (verified with scan-secrets.sh)
- [x] Docs updated — added GOOGLE_OAUTH.md with setup instructions
- [x] CONTRIBUTING.md guidelines followed
- [x] Self-reviewed the diff — no debugging code or WIP commits

## Notes for maintainer

- Follow-up: Token refresh UI indicator will be in a separate PR (#301)
- Trade-off: Used Google's official Node.js SDK instead of raw fetch
  calls. Adds a dependency but handles token rotation automatically.
- The OAuth state parameter uses a SHA-256 hash of session ID + nonce.
  It's stored in-memory with 10-minute TTL to prevent CSRF.
```

