# Diff Analysis Guide

How to read a diff and identify the right commit boundaries.

---

## Step 1: Categorize Every Changed File

For each file in `git diff --stat`, assign it a category:

| File pattern | Category |
|---|---|
| `src/`, `lib/`, `app/` | Feature / Fix / Refactor |
| `tests/`, `__tests__/`, `*.test.*`, `*.spec.*` | Test |
| `docs/`, `*.md`, `README` | Docs |
| `package.json`, `requirements.txt`, `Cargo.toml` | Chore (deps) |
| `.github/`, `Makefile`, `Dockerfile` | Chore (tooling) |
| `CHANGELOG.md`, `version.py`, `package.json version field` | Release |

---

## Step 2: Detect Mixed Concerns

If files from **more than one category** appear in the same diff, you have a
mixed changeset — split it.

### Example: Mixed changeset that needs splitting

```
modified: src/auth/jwt.py          → Fix
modified: src/payments/stripe.py   → Feature
modified: tests/test_auth.py       → Test (for the fix)
modified: README.md                → Docs
modified: requirements.txt         → Chore
```

Split into:
1. `fix(auth): + tests/test_auth.py` — fix and its tests together
2. `feat(payments): stripe.py` — new feature
3. `docs: README.md` — documentation update
4. `chore: requirements.txt` — dependency bump

---

## Step 3: Identify the "Why"

Look for these patterns in the diff to understand the motivation:

- **Error handling added** → previous code could crash; commit explains the failure mode
- **Condition changed** (`if x` → `if x and y`) → there was an edge case; describe it
- **Magic numbers replaced with constants** → readability refactor
- **N queries → 1 query** → performance fix; include before/after timing if known
- **New dependency added** → explain why this library vs alternatives
- **Config value changed** → explain what was wrong with the old value

---

## Step 4: Assess Breaking Change Risk

A commit is a breaking change if it:
- Removes or renames a public function/method/API endpoint
- Changes the return type or shape of a public API
- Changes required vs optional parameters
- Changes database schema (migrations)
- Changes environment variable names or config file structure

If any of these apply, the commit **must** include a `BREAKING CHANGE:` footer.

---

## Step 5: Find Related Issues

Scan the diff for:
- TODO/FIXME comments being removed (likely closes an issue)
- Error message text matching known bug reports
- Branch name containing issue numbers (`feature/fix-#123-login-bug`)

```bash
# Extract issue numbers from branch name
git branch --show-current | grep -oE '#[0-9]+'
git branch --show-current | grep -oE '[0-9]+' | head -1
```
