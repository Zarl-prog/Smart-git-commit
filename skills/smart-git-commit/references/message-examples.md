# Gold-Standard Commit Message Examples

15 examples across all commit types, following the 5-part format:

```
<type>(<scope>): <imperative summary — max 72 chars>

CONTEXT: <what state the code was in BEFORE this change>
CHANGE:  <exactly what was done>
WHY:     <the reason — business or technical motivation>
IMPACT:  <what this enables or unblocks>

<footer>
```

---

## 1. feat — New Feature

```
feat(auth): add Google OAuth2 login with PKCE flow

CONTEXT: Only email/password login existed, causing 40% signup abandonment on mobile.
CHANGE:  Implements OAuth2 PKCE flow with Google Identity Services SDK.
WHY:     Users expect social login. PKCE is mandatory for mobile SPAs; auth code flow
         was rejected due to client_secret storage concerns.
IMPACT:  Enables one-tap login on Android/iOS. Reduces signup friction in Phase 2 rollout.

Closes #178
```

---

## 2. fix — Bug Fix

```
fix(payments): prevent double-charge on Stripe webhook retry

CONTEXT: Stripe delivered webhooks twice under high load due to 30s application timeout,
         causing duplicate charges.
CHANGE:  Adds idempotency_key (order_id + unix_ts hash) to all Stripe charge requests.
WHY:     Stripe's API natively deduplicates on idempotency keys — simpler than
         Redis-based deduplication. Only new charge attempts are affected.
IMPACT:  Eliminates billing support tickets for duplicate charges. No data migration needed.

Closes #301
```

---

## 3. perf — Performance Improvement

```
perf(dashboard): replace ORM queries with raw SQL for reports

CONTEXT: Reports page generated N+1 queries (one per user row), causing 8-12s load times.
CHANGE:  Rewrites the reports/summary endpoint with a single raw SQL JOIN query.
WHY:     ORM abstraction prevented query optimization. Raw SQL is isolated to this one
         endpoint — all other code still uses the ORM.
IMPACT:  Reduces load time from 11.2s to 0.18s (62x improvement). Unblocks real-time dashboard feature.

Refs #156
```

---

## 4. security — Security Fix

```
security(api): enforce rate limiting on /auth/login endpoint

CONTEXT: Login endpoint had no rate limiting, allowing brute-force password attacks.
CHANGE:  Adds express-rate-limit middleware: 5 attempts per 15 minutes per IP,
         with exponential backoff on repeated violations. Adds account lockout
         after 10 failed attempts (IP-independent).
WHY:     SOC2 compliance requirement. Distributed brute-force via botnets was the
         primary threat model — account lockout addresses this where IP limits alone fail.
IMPACT:  Clients retrying rapidly now receive 429 Too Many Requests. Enables SOC2 audit pass in Phase 2.

BREAKING CHANGE: Automated login scripts must handle 429 responses.
Closes #233
```

---

## 5. refactor — Code Restructure (No Behavior Change)

```
refactor(payments): extract validation logic into PaymentValidator class

CONTEXT: Payment handler was 340 lines with validation, business logic, and Stripe calls
         all interleaved — impossible to unit test validation in isolation.
CHANGE:  Extracts all input validation into a dedicated PaymentValidator class with
         single-responsibility methods.
WHY:     The current structure blocks adding Apple Pay support (next sprint). Validator
         must be independently testable before introducing new payment methods.
IMPACT:  Unblocks Apple Pay feature. All 47 existing tests pass unchanged.
```

---

## 6. test — Test Coverage

```
test(cart): add edge case coverage for empty cart checkout

CONTEXT: Three edge cases from production bug #211 had zero test coverage: empty cart,
         all-out-of-stock items, and expired coupons between add-to-cart and checkout.
CHANGE:  Adds test cases for all three scenarios, mocking the cart service boundary.
WHY:     These paths were exercised only in production. Automated coverage prevents
         regression when the checkout flow is refactored next quarter.
IMPACT:  No production code changed — tests confirm fixes from commit a3f9c12 hold under refactor.
```

---

## 7. docs — Documentation

```
docs(api): add rate limiting section to API reference

CONTEXT: Rate limits were implemented in v1.4 but never documented, causing confusion
         when clients received 429 responses without explanation.
CHANGE:  Adds rate limit documentation covering per-endpoint tiers (free/pro/enterprise),
         response headers (X-RateLimit-Remaining, X-RateLimit-Reset), and code examples
         for handling 429 in JS and Python.
WHY:     Developer experience survey scored 3.2/5 on API documentation — rate limits were
         the #1 missing section. This was the most-requested docs improvement.
IMPACT:  Reduces support tickets for rate limit errors. API docs score expected to reach 4.5/5.
```

---

## 8. chore — Maintenance (Deps)

```
chore(deps): upgrade axios from 0.27 to 1.6.2

CONTEXT: axios 0.27 had a prototype pollution vulnerability (CVE-2023-45857) and our
         nested filter params required a workaround due to axios 0.x serialization.
CHANGE:  Updates axios to 1.6.2 and removes the manual query param serialization hack.
WHY:     Security patch for CVE plus the fix for the nested param bug (#198) comes free
         with the major version bump.
IMPACT:  Resolves CVE-2023-45857. Our filter query params are now standard across all endpoints.

Closes #198
```

---

## 9. breaking-change — Breaking API Change

```
feat(api)!: rename /user/profile to /users/{id}/profile

CONTEXT: /user/profile returned full user objects for simple ID lookups, consuming 3x
         bandwidth needed. 60% of callers only needed the user ID.
CHANGE:  Replaces the single /user/profile endpoint with REST-compliant /users/{id}/profile.
         Old endpoint returns 301 redirect for 90-day migration window.
WHY:     REST consistency across the API. The 60% overhead was costing ~$200/mo in
         unnecessary data transfer at current scale.
IMPACT:  All clients must update endpoints. Migration guide at docs/migrations/v2-api-changes.md.

BREAKING CHANGE: /user/profile is deprecated. Update to /users/{id}/profile before v3.0.
Closes #189
```

---

## 10. WIP — Work In Progress

```
WIP: feat(ml): add product recommendation engine

CONTEXT: Product recommendations are currently static "best sellers" — no personalization.
CHANGE:  In-progress collaborative filtering model based on user purchase history.
         Pipeline built, offline accuracy at 82% on test set.
WHY:     A/B test showed 22% conversion lift with personalized recs. Full rollout expected Q3.
IMPACT:  Pushing to share with team for early feedback. NOT ready for production.

Done:
  - Purchase history data pipeline
  - Collaborative filtering model (offline, 82% accuracy)
TODO:
  - Real-time inference endpoint
  - A/B test setup
  - Cold-start fallback for new users
```

---

## 11. hotfix — Urgent Production Fix

```
hotfix(api): restore removed pagination parameter from user list

CONTEXT: Production monitoring detected 500 errors on /api/users — the page parameter
         was accidentally dropped during the query parser refactor in a3f9c12.
CHANGE:  Adds passthrough for page and per_page params in the new parser while preserving
         the new parser structure.
WHY:     Frontend sends these params unconditionally. 12 minutes from deploy to detection,
         4 minutes to fix. Critical severity — all API clients affected.
IMPACT:  API restored to working state. Root cause fix scheduled for next sprint.

Fixes INC-8472
```

---

## 12. revert — Revert

```
revert: remove buggy cursor pagination from user list

CONTEXT: Cursor-based pagination from b7e8f90d introduced a regression — users with
         >100 items couldn't navigate past page 1 due to incorrect cursor encoding.
CHANGE:  Reverts commit b7e8f90d, restoring offset-based pagination with no behavior change.
WHY:     The cursor encoding bug blocks a core UX flow for power users. Reverting is
         the fastest path to fix while a proper fix is developed.
IMPACT:  User list pagination restored. Cursor pagination will be re-implemented with
         proper base64 encoding in the next sprint.

Fixes #312
```

---

## 13. release — Version Release

```
release: bump version to v2.1.0

CONTEXT: Master branch contains 14 merged PRs since v2.0.0, including 3 features,
         5 fixes, and infrastructure changes.
CHANGE:  Bumps version to 2.1.0 and generates changelog entries for all merged commits.
WHY:     Minor bump due to features (feat) with no breaking changes. See CHANGELOG.md.
IMPACT:  Enables deployment to production. Tags created for rollback targets.

Highlights:
  - feat(api): add webhook event replay endpoint (#267)
  - feat(ui): real-time dashboard updates (#271)
  - fix(payments): handle Stripe idempotency errors (#269)
  - perf(db): reduce analytics query time by 80% (#272)
```

---

## 14. deps — Dependency Addition

```
deps: add date-fns 3.6.0 for timezone-aware date formatting

CONTEXT: All date formatting was done with raw Intl.DateTimeFormat, requiring 15+
         lines of boilerplate per component for timezone conversion.
CHANGE:  Adds date-fns 3.6.0 (only the required functions — tree-shaken) and creates
         a shared dateUtils wrapper.
WHY:     date-fns is 4kB gzipped with tree-shaking vs 72kB for moment.js. No runtime
         cost for SSR since it's tree-shaken. Formats matches our design system.
IMPACT:  Reduces date formatting code by ~60%. All existing dates remain unchanged.
```

---

## 15. migration — Database Migration

```
migration: add email_verified column to users table

CONTEXT: Email verification status was stored in a separate redis key, lost on cache
         flush — causing 200+ users/month to re-verify after cache wipes.
CHANGE:  Adds email_verified boolean (default false) and verified_at timestamp to
         the users table. Backfills existing verified users from audit logs.
WHY:     Persistent storage is required for compliance (SOC2 audit trail). Cache-only
         storage violated our data retention policy.
IMPACT:  Downstream: add email_verified to user serializers and profile UI. Migration
         is reversible: ALTER TABLE users DROP COLUMN email_verified.

Part of #401
```
