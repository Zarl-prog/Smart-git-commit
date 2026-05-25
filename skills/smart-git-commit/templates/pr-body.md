## What changed and why

<!-- Summarize the key changes and their motivation. Reference related commits. -->

**Context:** <!-- What state was the code in before? -->
**Change:**  <!-- What exactly was done? -->
**Why:**     <!-- Business or technical reason, not obvious from code -->

---

## How to test

<!-- Step-by-step instructions for the reviewer -->

1. Checkout this branch: `git checkout {{BRANCH_NAME}}`
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. <!-- Add more steps specific to this PR -->

---

## Related commits

<!-- Populated automatically from git history -->

---

## Checklist

- [ ] Tests pass locally (`npm test` / `pytest` / `cargo test`)
- [ ] No secrets or credentials in the diff (run `bash scripts/scan-secrets.sh`)
- [ ] Documentation updated (if behavior changed)
- [ ] Breaking changes documented in commit footer
- [ ] Related issue linked (Closes #N / Fixes #N)
- [ ] Commit messages follow the 5-part format (CONTEXT · CHANGE · WHY · IMPACT)

## Screenshots (if UI changed)

<!-- Paste before/after screenshots here -->

| Before | After |
|--------|-------|
|        |       |

## Notes for reviewer

<!-- Anything specific to look at, known trade-offs, decisions made, or follow-up work -->

- 
- 
- 
