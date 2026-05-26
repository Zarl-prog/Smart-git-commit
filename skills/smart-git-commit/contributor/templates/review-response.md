# Review Response Template

Use this template when responding to any PR review comment.
Fill in the placeholders in **bold**.

---

## Template

```
Hey @**reviewer** — thanks for catching that.

> **quote the reviewer's comment here**

You're right. **acknowledge what they spotted**.
Fixed in **commit hash** — **one line explanation of what you changed**.

Let me know if this looks good or if you had something else in mind.
```

---

## 5 Filled-In Examples

### Example 1: Style / Naming Comment

```
Hey @alice — thanks for catching that.

> "The variable name 'tmp' is unclear. Consider a more descriptive name."

You're right, 'tmp' doesn't describe what this value is.
Fixed in a3b2c1d — renamed to 'unprocessedWebhookPayload' to match
the naming convention used in the rest of the webhook handler.

Let me know if this looks good or if you had something else in mind.
```

### Example 2: Logic Concern

```
Hey @bob — thanks for the careful review.

> "Are we sure this handles the null user case? Looks like getOrCreateUser
> could return null but we're not checking it."

You're right, I missed that edge case. getOrCreateUser returns null when
the database call times out.
Fixed in d4e5f6g — added a null check that returns a 503 error with a
Retry-After header. Also added a test case for this scenario.

Let me know if this looks good or if you had something else in mind.
```

### Example 3: "This Approach Won't Work"

```
Hey @charlie — thanks for catching this early.

> "In-memory caching won't work for our multi-region setup. Requests
> from eu-west-1 will get stale data cached in us-east-1."

You're absolutely right, I didn't consider the multi-region case.
I've switched to a Redis-backed cache in h7i8j9k — the implementation
now uses the existing Redis cluster that the sessions service already
connects to. This also removes the need for my in-memory TTL logic
since Redis handles TTL natively.

Let me know if this looks good or if you had something else in mind.
```

### Example 4: Documentation Request

```
Hey @diana — great point, thanks.

> "We should document the new rate limit config options in the README."

You're right, this is missing documentation.
Added in k1l2m3n — added a "Rate Limiting" section to the README
covering:
- The 3 config options (RATE_LIMIT_WINDOW_MS, RATE_LIMIT_MAX_REQUESTS,
  RATE_LIMIT_BLOCK_DURATION_MS)
- Default values and what each controls
- How to test rate limiting locally using curl headers

Let me know if this looks good or if you had something else in mind.
```

### Example 5: Disagreeing but Deferring

```
Hey @eve — thanks for pushing on this.

> "I think we should use an environment variable for the cache TTL
> instead of hardcoding it."

I see your point about configurability. My reasoning for hardcoding was
that the TTL is a constant based on our session timeout policy (15 min),
not something operators would tune per-deployment. That said, I
understand wanting to keep it configurable for testing.

Fixed in o4p5q6r — moved the cache TTL to an env var
(SESSION_CACHE_TTL_SECONDS=900) with a default fallback. Added the
config to .env.example and documented it in the README.

Let me know if this looks good or if you had something else in mind.
```

---

## Quick Reference

| Scenario | Key Phrase |
|----------|-----------|
| They're right, easy fix | "Fixed in `<hash>` — `<one line>`" |
| They're right, complex fix | "You're right. I updated the approach to..." |
| Need to explain reasoning | "My thinking was... but I see your point." |
| Disagree but defer | "I understand your concern. I've updated to..." |
| Missing documentation | "Added docs covering..." |
| They found a real bug | "Great catch! Fixed the issue and added a test." |
