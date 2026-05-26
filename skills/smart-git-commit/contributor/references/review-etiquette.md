# Review Etiquette — How to Handle Maintainer Feedback

Responding to code review is a skill. Done right, it builds trust and
gets your PR merged faster. Done wrong, it frustrates maintainers and
gets your PR closed.

---

## The Golden Rule

**Maintainers are volunteers.** They are donating their time to help you
make your code better. Every comment is an investment in the project's
quality — and in your growth as a developer. Treat it that way.

---

## Comment Types and How to Handle Each

### "Please change X to Y"

**Response**: Just do it. Thank them. No debate.

```
Hey @maintainer — thanks for catching that. Fixed in abc1234.
```

**Why**: Style preferences, naming conventions, and code organization
are subjective. The maintainer knows the project's conventions better
than you do. This is not worth arguing about.

---

### "Why did you do X?"

**Response**: Explain your reasoning clearly. Offer to add a code comment.

```
Hey @maintainer — great question. I chose an in-memory token bucket
instead of Redis because this service is single-instance and I wanted
to avoid adding a new dependency. If we scale to multi-instance,
swapping to Redis is a one-line config change.

I'll add a comment in the code explaining this trade-off.
```

**Why**: The maintainer is asking because they want to learn your
reasoning. A clear explanation shows you thought about the trade-offs.
Offering to add a comment shows you care about future readers.

---

### "This approach won't work"

**Response**: Stay curious. Ask what they would suggest.

```
Hey @maintainer — you're right, I didn't consider the multi-region
case. The in-memory cache would indeed desync.

What approach would you recommend here? Would a Redis-backed cache
with TTL work, or is there a simpler pattern used elsewhere in the
codebase?
```

**Why**: The maintainer has context you don't. They've seen what
works and what doesn't in this project. Your job is to learn from
their experience, not to defend your approach.

---

### "LGTM with nits" (Looks Good To Me with minor issues)

**Response**: Fix the nits, merge. Don't wait for re-review.

```
Thanks @maintainer! Fixed the nits in abc5678. Going to merge.
```

**Why**: "LGTM with nits" means "I approve but here are tiny things
to fix at your discretion." If you fix them, you don't need another
review cycle. Read the project's policy — some require re-review even
for nits.

---

### "Requesting changes"

**Response**: Address every single comment before re-requesting review.

```
Hey @maintainer — I've addressed all your feedback:

1. ✅ Switched from in-memory to Redis cache (abc1234)
2. ✅ Added error handling for network timeout (abc5678)
3. ✅ Updated the test to cover the null response case (abc9012)
4. ✅ Added documentation for the new config option (abc3456)

Ready for another look when you have time.
```

**Why**: Requesting changes is the most serious review signal. The
maintainer is saying "this cannot merge as-is." Every single comment
must be addressed before re-requesting. Missing one makes you look
careless.

---

### Silence for 2 weeks

**Response**: One polite ping. Then move on.

```
Hey @maintainer — gentle bump on this PR. No rush, just wanted to
make sure it didn't fall through the cracks. Happy to make any
changes needed.
```

**Why**: Maintainers are busy and may have dozens of PRs open. One
polite bump after 2 weeks is appropriate. If no response after
another week, consider closing the PR and moving on. Never ping more
than once.

---

## Hard Rules — Never Break These

### Never merge your own PR without review

Unless the repo explicitly allows it (e.g., a personal project), always
wait for at least one approval. Merging your own PR without review
undermines trust and can introduce bugs.

### Never force-push to a shared branch after review starts

Once a maintainer has reviewed your PR, force-pushing rewrites history
and makes it impossible to see what changed. Instead, add new commits
on top.

```
# ✅ CORRECT — push new commits
git add .
git commit -m "fix: address review feedback on null handling"
git push origin HEAD

# ❌ WRONG — force push after review
git commit --amend
git push origin HEAD --force
```

### Always resolve conversations after fixing

When you fix something a reviewer pointed out, resolve the conversation
(after pushing the fix). Don't leave conversations hanging — it makes
it look like you forgot.

### Thank reviewers by name

Every response should start with a genuine thank you. The reviewer's
name matters — it shows you know who you're talking to.

```
# ✅ GOOD
Hey @jane — thanks for catching the null pointer edge case.

# ❌ BAD
Thanks for the review.
```

### Don't batch unrelated fixes

If a reviewer asks for a change and you notice something else to fix
while you're in the file — make a separate commit.

```
# ✅ CORRECT
git commit -m "fix: address review feedback on null handler"
git commit -m "chore: fix typo in error message"
git push origin HEAD

# ❌ WRONG — mixed in one commit
git commit -m "fix: address review feedback and fix typo"
```

---

## What to Do When You Disagree

It happens. Sometimes you genuinely believe your approach is better.
Here's how to handle it professionally:

1. **Explain your reasoning once** — clearly, with evidence (docs,
   benchmarks, patterns used in other projects)
2. **Acknowledge their concern** — show you understand their perspective
3. **Propose a compromise** — e.g., "What if I make it configurable so
   both approaches work?"
4. **If they still disagree, defer** — the maintainer has final say on
   the project. Accept gracefully.

```
I see your concern about the in-memory cache scaling poorly. My
thinking was that this service is always single-instance, but I
understand wanting to keep options open.

How about this: I'll add a Redis-backed cache implementation as an
option, defaulting to in-memory. That way we don't add a dependency
until we need it, but the architecture supports it.

If you still prefer I go with Redis from the start, I'm happy to do
that instead.
```

---

## Summary: Do's and Don'ts

| Do ✅ | Don't ❌ |
|------|---------|
| Thank the reviewer by name | Argue or get defensive |
| Acknowledge what they spotted | Ignore a comment |
| Show exactly what you changed | Say "fixed" without details |
| Push new commits (not force-push) | Rebase/amend after review starts |
| Resolve conversations after fixing | Leave conversations hanging |
| Address every comment | Skip a comment you don't like |
| Re-request review when done | Batch re-request without fixing everything |
| One polite ping at 2 weeks | Ping daily or complain about delays |
| Learn from the feedback | Take feedback personally |
