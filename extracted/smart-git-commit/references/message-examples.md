# Gold-Standard Commit Message Examples

10 real-world examples across different types. Use these as templates.

---

## 1. Bug Fix with Root Cause

```
fix(auth): resolve JWT token expiry race condition

Token validation was checking expiry against server time at request
receipt, but the actual validation happened 50-200ms later due to
middleware chain length. Under load, valid tokens were being rejected.

Fixed by adding a 500ms grace window to expiry checks. Considered
clock sync (NTP) approach but the middleware delay is the actual
root cause, not clock drift.

Closes #204
```

---

## 2. New Feature with Alternatives Considered

```
feat(search): add fuzzy matching for product search

Users were getting zero results for minor typos (e.g. "samsng tv").
Integrated Fuse.js with threshold 0.4 — loose enough for typos,
tight enough to avoid irrelevant results.

Considered: Elasticsearch (overkill for current scale), Levenshtein
distance (rolled our own — too slow at 50k products). Fuse.js adds
12kb gzipped but the UX gain is significant.

Search latency: 45ms → 52ms avg (acceptable).

Closes #178
```

---

## 3. Performance Refactor with Metrics

```
perf(dashboard): replace ORM queries with raw SQL for reports

Reports page was generating N+1 queries (one per user row) causing
8-12 second load times under normal usage. Raw SQL with a single
JOIN reduces this to ~180ms.

ORM is still used everywhere else — only the reports/summary
endpoint uses raw SQL. Added query comment for future maintainers.

Before: 847 queries / 11.2s avg
After:  1 query / 0.18s avg

Refs #156
```

---

## 4. Security Fix

```
security(api): enforce rate limiting on /auth/login endpoint

Login endpoint had no rate limiting, allowing brute-force attacks.
Added express-rate-limit: 5 attempts per 15 minutes per IP, with
exponential backoff on repeated violations.

Also added account lockout after 10 failed attempts (separate from
IP limit — protects against distributed attacks).

BREAKING CHANGE: Clients retrying login in rapid succession will
now receive 429 Too Many Requests.

Closes #233
```

---

## 5. Refactor (No Behavior Change)

```
refactor(payments): extract validation logic into PaymentValidator

Payment processing handler was 340 lines with validation, business
logic, and Stripe calls all mixed together. Extracted validation
into a dedicated PaymentValidator class.

No behavior changes — all existing tests pass. New structure makes
it possible to unit test validation in isolation (follow-up: #241).
```

---

## 6. Breaking API Change

```
feat(api)!: rename /user/profile to /users/{id}/profile

Aligned endpoint naming with REST conventions across the API.
Old endpoint returns 301 redirect for 90 days to ease migration.

BREAKING CHANGE: /user/profile is deprecated. Update all clients
to use /users/{id}/profile. The old route will be removed in v3.0.

Migration guide: docs/migrations/v2-api-changes.md
Closes #189
```

---

## 7. Dependency Update with Reason

```
chore(deps): upgrade axios from 0.27 to 1.6.2

axios 0.27 had a prototype pollution vulnerability (CVE-2023-45857).
Version 1.x also changes the default serialization of nested objects
which fixes a bug in our filter query params (#198).

Tested against all API integration tests — no breaking changes found.
One test updated: axios 1.x throws on 4xx by default (previously silent).

Closes #198
Fixes CVE-2023-45857
```

---

## 8. Test Addition (Covering Edge Cases)

```
test(cart): add edge case coverage for empty cart checkout

Three edge cases were uncovered after production bug #211:
- Empty cart checkout (now returns 400 with clear message)
- Cart with all out-of-stock items
- Cart where coupon expires between add-to-cart and checkout

All three now have explicit tests. No production code changed —
these tests confirm existing fixes from commit a3f9c12.

Refs #211
```

---

## 9. Documentation Update

```
docs(api): add rate limiting section to API reference

Rate limits were implemented in v1.4 but never documented. Added:
- Limits per endpoint tier (free/pro/enterprise)
- Response headers (X-RateLimit-Remaining, X-RateLimit-Reset)
- Code examples for handling 429 responses in JS and Python
- Link to status page for current limits

Refs #167
```

---

## 10. WIP / Draft Commit

```
WIP: feat(ml): add product recommendation engine

In progress — not ready for review. Pushing to share with team.

Done:
- Data pipeline for user purchase history
- Collaborative filtering model (offline, ~82% accuracy on test set)

TODO:
- Real-time inference endpoint
- A/B test setup
- Fallback for new users (cold start problem)

Refs #254
```
