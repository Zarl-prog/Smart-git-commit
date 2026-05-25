# Commit Message Examples — 15 Gold-Standard Examples

Every example uses the 5-part format: CONTEXT / CHANGE / WHY / IMPACT / footers.
These cover every commit type in the conventional commits specification.

---

## 1. feat — New Feature

```
feat(api): add pagination to user list endpoint

CONTEXT: GET /api/users returned all users in a single response, causing
         15s load times for orgs with 50k+ users.
CHANGE:  Adds ?page=N&per_page=100 query params with Link header for
         cursor-based pagination.
WHY:     Stripe-style cursor pagination scales better than offset-based
         for high-write tables; no page drift on insert.
IMPACT:  Reduces P95 response time from 15s to 120ms for large orgs.
         Backward compatible — missing params default to full list.

Closes #204
```

---

## 2. fix — Bug Fix

```
fix(payments): prevent double-charge on Stripe webhook retry

CONTEXT: Stripe delivered webhooks twice under high load due to 30s
         application timeout, causing duplicate charges.
CHANGE:  Adds idempotency_key (order_id + unix_ts hash) to all Stripe
         charge requests before callout.
WHY:     Stripe's API natively deduplicates on idempotency keys — simpler
         than Redis-based deduplication. Only new charge attempts affected.
IMPACT:  Eliminates billing support tickets for duplicate charges.

Fixes #301
```

---

## 3. perf — Performance

```
perf(db): add composite index on (org_id, created_at) for dashboard queries

CONTEXT: Dashboard page loaded 18s because org-scoped date-range queries
         were doing sequential scans on 12M-row audit_logs table.
CHANGE:  Adds B-tree composite index on audit_logs(org_id, created_at).
WHY:     All dashboard queries filter by org_id first, then sort by
         created_at. Composite index covers both — no INCLUDE columns needed.
IMPACT:  Dashboard P95 drops from 18s to 340ms. Index is 240MB — within
         budget for the 8GB RAM instance.

Closes #156
```

---

## 4. security — Security Fix

```
security(api): add rate limiting to login endpoint

CONTEXT: POST /api/auth/login had no rate limiting, allowing unlimited
         brute-force attempts — 12k requests/min in prod.
CHANGE:  Adds token-bucket rate limiter: 5 attempts/min per IP, 10/min
         per email. Returns 429 with Retry-After header on exceed.
WHY:     OWASP ASVS v4.0 requires rate limiting on authentication
         endpoints (V2.1.1). Previous attempts blocked by Redis dependency
         — this uses in-memory sliding window, Redis optional.
IMPACT:  Blocks brute-force at network edge. 429 response lets legitimate
         users retry after cooldown. No breaking changes to API contract.
```

---

## 5. refactor — Code Restructure

```
refactor(payments): extract PaymentValidator from PaymentProcessor

CONTEXT: PaymentProcessor class was 1,200 lines with mixed concerns:
         validation, network calls, webhooks, and refund logic tangled.
CHANGE:  Extracts PaymentValidator class with pure validation methods,
         moves Stripe client to PaymentGateway, keeps orchestration in
         PaymentProcessor.
WHY:     PaymentProcessor had 3 separate reasons to change, violating SRP.
         Unit tests needed heavy mocking — the validator is pure functions.
IMPACT:  Code coverage on validation logic goes from 22% to 91%. New
         PaymentGateway can swap providers without touching processor.
```

---

## 6. test — Tests Only

```
test(cart): add empty cart checkout and quantity overflow cases

CONTEXT: Cart checkout had 68% line coverage — missing edge cases for
         empty carts, max quantity, and concurrent add/remove.
CHANGE:  Adds 14 test cases: empty cart 422, quantity > 999 error,
         50 concurrent add operations, and mixed currency validation.
WHY:     Empty cart edge case caused a P0 incident last sprint when users
         could submit $0.00 orders. These tests prevent regression.
IMPACT:  Cart checkout coverage goes from 68% to 94%. All new cases
         documented in test names for quick debugging.
```

---

## 7. docs — Documentation

```
docs(api): document webhook payload format and retry behavior

CONTEXT: Webhook consumers had to reverse-engineer payload format from
         Stripe docs and production logs — no internal documentation.
CHANGE:  Adds webhooks.md with: payload schema for all 6 event types,
         retry schedule (3 attempts, exponential backoff), idempotency
         guidance, and local testing with stripe listen.
WHY:     Two integration PRs were delayed last quarter because developers
         didn't know webhooks returned ISO 8601 dates, not Unix timestamps.
IMPACT:  Self-serve onboarding for new webhook consumers. Reduces
         integration time from ~3 days to ~4 hours.
```

---

## 8. chore — Maintenance

```
chore(deps): upgrade axios to 1.7.2 to fix CVE-2024-39338

CONTEXT: Axios 1.6.x had CVE-2024-39338 (SSRF via redirect) affecting
         all outbound HTTP calls in the payments service.
CHANGE:  Bumps axios from 1.6.7 to 1.7.2. No breaking API changes per
         axios changelog. All 342 existing tests pass.
WHY:     SSRF vulnerability allows internal network probing if attacker
         controls redirect target — critical for payments service.
IMPACT:  CVE patched. Zero breaking changes. CI pipeline updated to
         run `npm audit` on every build going forward.
```

---

## 9. BREAKING CHANGE — Breaking Change

```
feat(api)!: redesign user profile endpoint

CONTEXT: GET /api/users/:id/profile returned 60 fields when most callers
         only needed name + avatar. 85% of payload was unused.
CHANGE:  Replaces /api/users/:id/profile with /api/v2/users/:id/profile
         returning only requested fields (sparse fieldset via ?fields=).
WHY:     Payload size reduced by 85% on list views. Sparse fieldsets
         align with Google API AIP-157 and JSON:API spec.
IMPACT:  Old endpoint redirects with deprecation header for 90 days.
         All clients must update URLs and adopt field selection.

BREAKING CHANGE: /api/users/:id/profile deprecated. Use /api/v2/users/:id/profile.
```

---

## 10. WIP — Work in Progress

```
WIP: refactor(notifications): migrate from email to push

CONTEXT: Email notification latency was 2-5 minutes during peak hours
         (12M emails/day). Push notifications are <500ms.
CHANGE:  First phase: adds push notification schema, worker pool, and
         FCM integration. Email fallback still active.
WHY:     Incomplete — manual testing needed for FCM token expiry
         edge case before removing email fallback.
IMPACT:  Not for production. Use this WIP to test FCM integration in
         staging environment.
```

---

## 11. hotfix — Urgent Production Fix

```
hotfix(api): restore removed pagination parameter from user search

CONTEXT: Deploy v2.4.0 accidentally removed ?limit= param from
         /api/users/search. All API clients broke — 5xx errors at 2k/min.
CHANGE:  Restores the limit parameter with validation (1-200). Reverts
         the interface change only, keeps internal refactor intact.
WHY:     Hotfix must be minimal — reverting the entire deploy would lose
         3 other bug fixes. Single-line change, 5 minutes to ship.
IMPACT:  Restores API contract. Monitoring shows errors dropping to 0
         within 2 minutes of deploy. Patch version bump only.

Closes #417
```

---

## 12. revert — Revert a Previous Commit

```
revert: restore removed endpoint from commit a3b2c1d

CONTEXT: Commit a3b2c1d removed /api/v1/orders/:id/invoice endpoint,
         but 3 legacy mobile clients still depended on it.
CHANGE:  Reverts a3b2c1d with git revert a3b2c1d. Adds deprecation header
         to the restored endpoint.
WHY:     Full deprecation process (announce → warn → remove) needs 2
         release cycles. The revert buys time for mobile app update.
IMPACT:  Legacy clients work again. Deprecation header logged for
         analytics. Endpoint will be removed in v3.0.0.

Refs #318
```

---

## 13. release — Version Bump

```
release: bump version to v2.1.0

CONTEXT: 12 commits since v2.0.0: 3 feature, 5 bug fixes, 2 perf
         improvements, 2 documentation updates.
CHANGE:  Bumps version in package.json (2.0.0 → 2.1.0). Runs
         generate-changelog.sh to update CHANGELOG.md with all entries.
WHY:     Minor bump because feat commits are present. No breaking
         changes detected in commit history.
IMPACT:  Tag v2.1.0 created. CHANGELOG.md updated with emoji-grouped
         sections. npm publish ready.
```

---

## 14. deps — Dependency Update

```
deps: upgrade react to 18.3.0 for concurrent features

CONTEXT: React 18.2.0 was 8 months old, missing the useOptimistic hook
         and automatic batching improvements in 18.3.0.
CHANGE:  Bumps react and react-dom from 18.2.0 to 18.3.0. Updates
         @types/react to match. No API changes needed.
WHY:     New useOptimistic hook simplifies optimistic UI for the cart
         feature planned in Q3. Automatic batching reduces re-renders.
IMPACT:  Zero breaking changes. Enables useOptimistic for cart feature.
         Paves way for React 19 upgrade next quarter.
```

---

## 15. migration — Database Migration

```
migration: add email_verified column to users table

CONTEXT: User registration flow couldn't verify emails because the
         users table had no email_verified column or timestamp.
CHANGE:  Adds email_verified (BOOLEAN, DEFAULT false) and
         email_verified_at (TIMESTAMPTZ, NULLABLE) columns.
         Creates index on (email_verified, created_at) for admin queries.
WHY:     Email verification is prerequisite for passwordless login
         feature. Migration is reversible: down script drops both
         columns and index.
IMPACT:  No impact on existing rows (nullable columns, default false).
         Admin panel benefits from new index for user filtering.
         Next: verification email flow in follow-up PR.
```
