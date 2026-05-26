<img width="1693" height="929" alt="Linkedin Post-Skill" src="https://github.com/user-attachments/assets/c1d37c69-31d4-4d9d-ab25-60ad7cf146ba" />



<div align="center">

# Smart Git Commit

**The git commit skill your AI agent should've had by default.**

[![Install](https://img.shields.io/badge/npx_skills_add-Zarl--prog%2FSmart--git--commit-6C47FF?style=flat-square&logo=npm&logoColor=white)](https://github.com/Zarl-prog/Smart-git-commit)
[![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)](https://github.com/Zarl-prog/Smart-git-commit/blob/master/CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](https://github.com/Zarl-prog/Smart-git-commit/blob/master/LICENSE)
[![Bash](https://img.shields.io/badge/bash-4%2B-gray?style=flat-square&logo=gnubash)](https://www.gnu.org/software/bash/)

<br>

**Works with** → Claude Code · Cursor · Codex · Windsurf · OpenCode · Gemini CLI

</div>

---

<!-- ⚡ DEMO VIDEO — Add a ~25 second terminal recording here showing:
     1. Agent triggered with "commit my changes"
     2. Secret scan passing (green ✓)
     3. Tests passing
     4. The 5-part commit message appearing
     5. git log showing the final result
     Use Terminalizer or Asciinema to record, convert to GIF, upload to the repo and embed below:
     ![Demo](./assets/demo.gif)
-->

## What problem does this solve?

Every AI coding agent commits like this by default:

```
fix stuff
update file.js
wip
```

**Smart Git Commit** enforces an 11-phase workflow that produces this instead:

```
fix(payments): prevent double-charge on Stripe webhook retry

CONTEXT: Stripe delivered webhooks twice under high load due to 30s
         application timeout, causing duplicate charges.
CHANGE:  Adds idempotency_key (order_id + unix_ts hash) to all Stripe
         charge requests.
WHY:     Stripe's API natively deduplicates on idempotency keys —
         simpler than Redis-based deduplication.
IMPACT:  Eliminates billing support tickets for duplicate charges.

Fixes #301
```

Every commit carries *why the code was the way it was*, *what changed*, *the real reason it changed*, and *what it unblocks downstream*. Six months later, `git blame` actually tells you something.

---

## Install

```bash
npx skills add Zarl-prog/Smart-git-commit
```

That's it. Your AI agent now follows the full 11-phase workflow on every commit.

---

## The 11-phase workflow

Every time you ask your agent to commit — whether you say *"commit my changes"*, *"ship this"*, *"save my work"*, or *"create a PR"* — it runs all of this automatically:

| Phase | What happens |
|-------|-------------|
| **0 — Read project rules** | Checks for `CLAUDE.md`, `.gitmessage`, custom overrides |
| **1 — Diff analysis** | Categorizes every changed file by concern before touching `git add` |
| **2 — Secret scan** | Runs `scan-secrets.sh` — hard blocks on API keys, tokens, `.env` files, private keys |
| **3 — Test gate** | Auto-detects your runner, executes tests, hard blocks if red |
| **4 — Atomic split** | Detects mixed concerns, proposes and executes clean separate commits |
| **5 — Commit message** | Builds the 5-part CONTEXT / CHANGE / WHY / IMPACT format |
| **6 — Issue linking** | Auto-detects GitHub / Jira / Linear ticket from branch name |
| **7 — Execute** | Selective `git add`, verifies with `diff --cached` before each commit |
| **8 — Push** | Feature branch only — never pushes directly to `main` |
| **9 — PR creation** | Draft PR with rich body via `gh` CLI |
| **10 — Release tagging** | Generates `CHANGELOG.md`, semver bumps, annotated tags |

---

## The 5-part commit format

This is what makes this skill different from every other commit tool. Every message follows an exact structure — no exceptions:

```
<type>(<scope>): <imperative summary — max 72 chars>

CONTEXT: What state existed BEFORE this change (past tense)
CHANGE:  Exactly what was done (present tense, specific)
WHY:     The business or technical reason — not obvious from the code
IMPACT:  What this enables or unblocks downstream

<footers: Closes #N | BREAKING CHANGE: ... >
```

**Three more real examples:**

<details>
<summary><code>feat</code> — New feature</summary>

```
feat(api): add pagination to user list endpoint

CONTEXT: GET /api/users returned all users in a single response,
         causing 15s load times for orgs with 50k+ users.
CHANGE:  Adds ?page=N&per_page=100 query params with Link header
         for cursor-based pagination.
WHY:     Stripe-style cursor pagination scales better than offset-based
         for high-write tables; no page drift on insert.
IMPACT:  Reduces P95 response time from 15s to 120ms for large orgs.

Closes #204
```
</details>

<details>
<summary><code>security</code> — Security fix</summary>

```
security(auth): rotate all JWT signing keys after audit finding

CONTEXT: Signing keys had not been rotated since initial deploy 18
         months ago, creating long exposure window if ever leaked.
CHANGE:  Rotates to RS256 asymmetric keys with 90-day auto-rotation
         via AWS Secrets Manager.
WHY:     SOC2 Type II audit requires key rotation policy with
         documented rotation interval.
IMPACT:  Satisfies audit finding SEC-04. Enables Type II certification
         renewal next quarter.

Refs #189
```
</details>

<details>
<summary><code>perf</code> — Performance improvement</summary>

```
perf(db): add composite index on org_id + created_at

CONTEXT: Dashboard query scanning 2.1M rows on every page load,
         causing 8-12s load times for enterprise accounts.
CHANGE:  Adds composite index (org_id, created_at DESC) to events
         table via zero-downtime migration.
WHY:     Query planner confirmed full table scan; index reduces scan
         to ~400 rows per org with no locking.
IMPACT:  Dashboard load drops from 8s to 90ms. Unblocks enterprise
         tier launch planned for next sprint.

Closes #317
```
</details>

See [`references/message-examples.md`](./skills/smart-git-commit/references/message-examples.md) for all 15 examples covering every commit type.

---

## What gets scanned for secrets

`scan-secrets.sh` catches these patterns in your staged diff before any commit goes through:

- AWS Access Keys (`AKIA...`)
- GitHub tokens (`ghp_`, `gho_`, `ghs_`, `ghu_`)
- Stripe secret keys (`sk_live_`, `sk_test_`)
- Generic API keys and Bearer tokens
- Passwords in assignments (`password=`, `PASSWORD=`)
- Private keys (`-----BEGIN ... PRIVATE KEY-----`)
- Database URIs with embedded credentials (`mongodb://user:pass@...`)
- Staged credential files (`.env`, `.pem`, `.key`, `id_rsa`)

Exit 0 = clean and commit proceeds. Exit 1 = hard stop, commit blocked, findings printed with file and line.

---

## Test runners supported

`detect-test-runner.sh` auto-detects your stack — no configuration needed:

| Detection signal | Runner |
|-----------------|--------|
| `package.json` with `"test"` script | `npm test` |
| `pytest.ini` or `[tool.pytest]` in `pyproject.toml` | `python -m pytest` |
| `Cargo.toml` | `cargo test` |
| `go.mod` | `go test ./...` |
| `Makefile` with `test:` target | `make test` |
| `.rspec` | `bundle exec rspec` |
| `mix.exs` | `mix test` |
| `build.gradle` / `build.gradle.kts` | `./gradlew test` |

If no runner is found: warns to stderr, asks if you want to proceed. Never silently skips.

---

## Configuration

### Drop-in project template

Copy the example into your project root and fill in your test command and ticket prefix:

```bash
cp skills/smart-git-commit/templates/CLAUDE.md.example CLAUDE.md
```

The skill reads `CLAUDE.md` first on every run and overrides its defaults with whatever you put there — branch naming rules, forbidden patterns, PR requirements.

### Git commit template

Set the 5-part format as your interactive commit template:

```bash
git config commit.template skills/smart-git-commit/templates/.gitmessage
```

Now `git commit` (without `-m`) opens your editor with the structure pre-filled.

---

## For Contributors

Using this skill as a contributor to any open source repo:

### What it does for you
- ✅ Checks your fork is synced with upstream before anything
- ✅ Enforces correct branch naming (feat/234-add-oauth-login)
- ✅ Runs the repo's test suite before letting you submit
- ✅ Scans your diff for secrets
- ✅ Builds a professional PR body automatically from your commits
- ✅ Helps you respond to review comments correctly

### Contributor install
npx skills add Zarl-prog/Smart-git-commit

### Usage
Just say:
"prepare my contribution"
"open a PR for this change"
"help me respond to this review comment"

## License

| Requirement | Version | Notes |
|------------|---------|-------|
| Git | 2.x | Core |
| Bash | 4+ | All scripts use `set -euo pipefail` |
| Node.js | Any | For `npx skills add` |
| `gh` CLI | Any | Optional — only needed for PR creation |

---

## Compatible agents

| Agent | Install method | Notes |
|-------|---------------|-------|
| **Claude Code** | `npx skills add` | Native skill support |
| **Cursor** | `npx skills add` | Composer integration |
| **Codex** | `npx skills add` | Via OpenAI agent SDK |
| **Windsurf** | `npx skills add` | Cascade support |
| **OpenCode** | `npx skills add` | Open-source agent |
| **Gemini CLI** | `npx skills add` | Google AI CLI |
| **GitHub Copilot** | Manual | Copy `CLAUDE.md.example` → `.github/copilot-instructions.md` |

---

## Repo structure

```
skills/smart-git-commit/
├── SKILL.md                      # 11-phase skill definition
├── scripts/
│   ├── scan-secrets.sh           # Secret pattern scanner
│   ├── detect-test-runner.sh     # Auto test runner detection
│   ├── split-commits.sh          # Atomic commit splitter
│   ├── generate-changelog.sh     # CHANGELOG.md generator
│   └── create-pr.sh              # Draft PR via gh CLI
├── references/
│   ├── commit-types.md           # All 16 commit types with examples
│   ├── atomic-patterns.md        # When and how to split commits
│   ├── message-examples.md       # 15 gold-standard commit examples
│   ├── security-rules.md         # Secret pattern reference
│   └── release-workflow.md       # Semver and tagging guide
├── templates/
│   ├── CLAUDE.md.example         # Drop-in project config
│   ├── .gitmessage               # Git commit template
│   └── pr-body.md                # PR body template
└── tests/
    ├── test-scenarios.md         # 7 test scenarios with expected outputs
    └── fixtures/
        ├── mixed-diff.txt        # 3-concern mixed diff fixture
        └── secret-diff.txt       # Diff with embedded fake API key
```

---

## Quick reference

| Situation | Start at |
|-----------|----------|
| Normal commit | Phase 1 — diff analysis |
| Secret found in diff | Phase 2 — fix first, then restart |
| Tests failing | Phase 3 — fix first, commit fix + feature together |
| Mixed concerns in diff | Phase 4 — atomic split |
| Already staged, need message only | Phase 5 — commit message |
| Need to push and open PR | Phase 8 — push strategy |
| Release / version bump | Phase 10 — release tagging |
| Hotfix on main | Phase 0 — check project rules first |

---

## Contributing

Issues and PRs welcome. If you add a new secret pattern to `scan-secrets.sh`, add a corresponding fixture to `tests/fixtures/` and a scenario to `test-scenarios.md`.

---

<div align="center">

MIT © 2026 [Zarl-prog](https://github.com/Zarl-prog)

**If this saved you from a bad commit, give it a ⭐**

</div>
