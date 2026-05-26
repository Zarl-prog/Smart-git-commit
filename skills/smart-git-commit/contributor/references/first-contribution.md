# First Open Source Contribution — Step by Step

This guide walks you through your very first open source contribution.
Every step is intentionally small. Follow them in order.

---

## Step 1: Find a Good First Issue

Look for labels on GitHub issues:

- `good first issue`
- `beginner friendly`
- `help wanted`
- `up-for-grabs`

### How to Pick

- **Scope**: The issue should change 1-2 files max
- **Clarity**: The description should tell you exactly what to do
- **Activity**: The repo should have recent commits (not abandoned)
- **Language**: Should match what you already know

### Where to Look

- [GitHub's good first issues explorer](https://github.com/topics/good-first-issue)
- [First Timers Only](https://www.firsttimersonly.com/)
- [Up For Grabs](https://up-for-grabs.net/)

---

## Step 2: Claim the Issue

Before writing any code, comment on the issue:

```
I'd like to work on this issue. Can you assign it to me?
```

### Why This Matters

- **Tells maintainers** someone is working on it
- **Prevents duplicate work** — two people fixing the same thing
- **Gets you guidance** — the maintainer might give tips on approach
- **Shows commitment** — you're more likely to follow through

Wait 24-48 hours for a response. If no response, it's probably safe to
start working. If someone else is already assigned, pick a different issue.

---

## Step 3: Fork, Clone, Add Upstream

### 3a: Fork on GitHub

Go to the repo page → click "Fork" (top-right) → creates a copy under
your GitHub account.

### 3b: Clone Your Fork

```bash
git clone https://github.com/YOUR-USERNAME/REPO-NAME.git
cd REPO-NAME
```

### 3c: Add Upstream Remote

```bash
git remote add upstream https://github.com/ORIGINAL-OWNER/REPO-NAME.git
git remote -v
# Should show:
# origin    https://github.com/YOU/REPO.git (fetch)
# origin    https://github.com/YOU/REPO.git (push)
# upstream  https://github.com/OWNER/REPO.git (fetch)
# upstream  https://github.com/OWNER/REPO.git (push)
```

---

## Step 4: Create a Correctly Named Branch

Never work on `main` or `master`.

```bash
# First, update your fork
git fetch upstream
git checkout main
git rebase upstream/main

# Create a feature branch
git checkout -b fix/123-fix-typo-in-readme
```

Branch pattern: `<type>/<issue-number>-<short-description>`
- `fix/123-fix-typo-in-readme`
- `feat/456-add-dark-mode-toggle`
- `docs/789-update-contributing-guide`

---

## Step 5: Make the Change

### Keep It Small

Your first contribution should change as few lines as possible. A typo
fix, a documentation update, or a simple bug fix with a clear test.

### Write Tests (If Applicable)

If you're fixing a bug, write a test that reproduces it first — then
fix it. This proves to maintainers that the fix works and won't regress.

### Stay Focused

Change only what the issue asks for. Don't refactor nearby code, don't
fix unrelated typos you spot, don't upgrade dependencies. One change =
one PR.

---

## Step 6: Run the Test Suite Locally

```bash
# Most common:
npm test
# Or:
pytest
# Or:
cargo test
# Or:
go test ./...
```

All tests must pass before you commit. If you broke existing tests,
figure out why before proceeding.

---

## Step 7: Commit Using the 5-Part Format

```bash
git add <your-changed-files>
git commit -m "docs(readme): fix typo in installation instructions" \
  -m "CONTEXT: README installation section had 'npx intall' instead of 'npx install'." \
  -m "CHANGE: Fixes the typo in the install command example on line 42." \
  -m "WHY: Users following the instructions would get a command-not-found error." \
  -m "IMPACT: No breaking changes. Fixes a confusing typo for new users."
```

**Never use `git add .`** — always stage specific files. Review what
you're staging with `git diff --cached` before committing.

---

## Step 8: Push to Your Fork

```bash
git push origin fix/123-fix-typo-in-readme
```

If it's your first push on this branch, you may need to set upstream:
```bash
git push --set-upstream origin fix/123-fix-typo-in-readme
```

---

## Step 9: Open a Draft PR Immediately

Go to your fork on GitHub → you'll see a banner: "Recently pushed
branches" → click "Compare & pull request".

Or use the CLI:
```bash
gh pr create --title "docs(readme): fix typo in installation instructions" \
  --body "Closes #123" \
  --draft
```

**Always open as draft**. This tells maintainers "I'm working on this
but not done yet." They can give early feedback before you invest more
time.

---

## Step 10: Fill the PR Body Completely

Don't leave the default template blank. Fill every section:

```markdown
## What changed

Fixed a typo in the README installation instructions.

## Context

The install command said "npx intall" instead of "npx install", which
would cause a command-not-found error for new users following along.

## How to test

1. Open README.md
2. Look at line 42
3. The command should read "npx install" (not "npx intall")

## Related issues

Closes #123

## Checklist

- [x] Tests pass locally
- [x] No secrets in diff
- [x] Docs updated (it's a docs fix)
- [x] One change per commit
```

---

## Step 11: Mark Ready for Review

When you've done a self-review:

1. Read through your entire diff as if you were a stranger
2. Verify tests pass on CI (check the Actions tab)
3. Click "Ready for review" on GitHub
4. Leave a comment: "Ready for review. Let me know if any changes needed."

---

## Step 12: Respond to Every Comment Within 48 Hours

When a maintainer reviews your PR:

- **Thank them** by name
- **Address every comment** — fix or explain
- **Push updates as new commits** (never force-push)
- **Resolve conversations** after fixing

See `contributor/references/review-etiquette.md` for detailed response
templates for every type of comment.

---

## Step 13: Celebrate When Merged 🎉

Your first open source contribution is merged! Here's what to do next:

- **Add the "Contributor" badge** to your GitHub profile
- **Share it on social media** — you earned it
- **Find another issue** in the same repo (you're a known contributor now)
- **Help someone else** make their first contribution

---

## Common First-Contribution Mistakes

### ❌ Working on multiple things at once

Fix one typo, not three. One PR = one change. Multiple changes in one
PR makes it hard to review and hard to merge.

### ❌ Not checking if someone else is working on it

Always check the issue comments before starting. If someone is assigned
or has commented "I'll take this," pick a different issue.

### ❌ Force-pushing after review starts

Once a maintainer has looked at your PR, never force-push. Add new
commits on top. Force-pushing deletes the review history.

### ❌ Ignoring CI failures

If CI (continuous integration) tests fail, fix them. Don't say "tests
pass locally" — the CI environment is what matters. The maintainer
won't merge with red CI checks.

### ❌ Being impatient

Maintainers are volunteers with full-time jobs. A 2-week wait for review
is normal. One polite bump after 2 weeks is appropriate. Don't ping
daily or complain on social media.

### ❌ Getting defensive about feedback

A review of your code is not a review of you as a person. Every comment
is someone trying to make the project better. Say "thank you" and learn
from it.

### ❌ Opening a massive PR for a "small" issue

A "small change" should be 1-10 lines. If you find yourself changing
20+ files for what the issue described as a typo fix, stop and ask the
maintainer if you're on the right track.

---

## Quick Reference Card

| Step | Action | Command |
|------|--------|---------|
| 1 | Find issue | `good first issue` label on GitHub |
| 2 | Claim it | Comment "I'd like to work on this" |
| 3 | Fork + clone | `git clone` + `git remote add upstream` |
| 4 | Create branch | `git checkout -b fix/123-short-name` |
| 5 | Make change | Edit files, test locally |
| 6 | Run tests | `npm test` or equivalent |
| 7 | Commit | 5-part format: CONTEXT/CHANGE/WHY/IMPACT |
| 8 | Push | `git push origin HEAD` |
| 9 | Draft PR | `gh pr create --draft` |
| 10 | Fill body | What, why, how to test, related issues |
| 11 | Mark ready | Self-review → "Ready for review" |
| 12 | Respond | Thank → fix → resolve conversations |
| 13 | Celebrate | 🎉 |
