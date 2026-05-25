<p align="center">
  <h1 align="center">🔬 Smart Git Commit</h1>
  <p align="center">
    Gold-standard Git commits — tested, atomic, secure, and richly documented.
    <br />
    Works with <strong>Claude Code</strong> · <strong>Codex</strong> · <strong>Cursor</strong> · <strong>Windsurf</strong> · <strong>OpenCode</strong> · <strong>Gemini CLI</strong>
  </p>
</p>

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/npx-skills%20add-6C47FF?style=flat-square&logo=npm" alt="npx install"></a>
  <a href="#"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License: MIT"></a>
  <a href="#"><img src="https://img.shields.io/badge/agent-Claude%20Code-FF6C37?style=flat-square" alt="Claude Code"></a>
  <a href="#"><img src="https://img.shields.io/badge/agent-Codex-0078D4?style=flat-square" alt="Codex"></a>
  <a href="#"><img src="https://img.shields.io/badge/agent-Cursor-6C47FF?style=flat-square" alt="Cursor"></a>
  <a href="#"><img src="https://img.shields.io/badge/agent-Windsurf-00B4D8?style=flat-square" alt="Windsurf"></a>
  <a href="#"><img src="https://img.shields.io/badge/agent-OpenCode-22C55E?style=flat-square" alt="OpenCode"></a>
  <a href="#"><img src="https://img.shields.io/badge/agent-Gemini%20CLI-4285F4?style=flat-square" alt="Gemini CLI"></a>
</p>

---

## 📦 Install

```bash
npx skills add Zarl-prog/Smart-git-commit
```

Or clone directly:

```bash
git clone https://github.com/Zarl-prog/Smart-git-commit.git
cd Smart-git-commit
```

## 🚀 What It Does

Smart Git Commit transforms your agent's git workflow from basic commits to a production-grade pipeline:

- 🔍 **Security scanning** — Auto-detects secrets, API keys, and credentials before they leak
- 🧪 **Test gating** — Runs your project's test suite and blocks commits if tests fail
- ✂️ **Atomic splitting** — Detects mixed-concern changesets and splits into clean, reviewable commits
- 📝 **Rich commit messages** — Structured 5-part format: CONTEXT · CHANGE · WHY · IMPACT · footers
- 🔗 **Issue linking** — Auto-detects GitHub issues, Jira tickets, and Linear tasks from branch names
- 🚀 **Smart PRs** — Creates draft PRs with rich bodies, linked issues, and review-ready formatting
- 🏷️ **Release management** — Auto-generates changelogs, bumps versions, and creates annotated tags
- 🔐 **Never push to main** — Enforces feature branch workflow by default

## ⚙️ How It Works

The skill runs through 11 sequential phases every time you commit:

1. **Read project rules** — Checks for CLAUDE.md and .gitmessage overrides
2. **Full diff analysis** — Scans every changed file and categorizes by concern
3. **Security scan** — Blocks commits with secrets (hard exit code gate)
4. **Test gate** — Auto-detects test runner, only commits if green
5. **Atomic split decision** — Splits mixed changesets into separate commits
6. **Commit message construction** — Builds the 5-part rich message format
7. **Issue & ticket linking** — Links to GitHub issues, Jira, Linear
8. **Execute commits** — Selective staging with `diff --cached` verification
9. **Push strategy** — Pushes to feature branch (never main by default)
10. **PR creation** — Creates draft PR with rich template
11. **Release tagging** — Changelog generation, semver bump, annotated tags

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SKIP_SECURITY_SCAN` | `false` | Skip Phase 2 security scanning |
| `SKIP_TEST_GATE` | `false` | Skip Phase 3 test running |
| `DEFAULT_BRANCH` | `main` | Protected branch name |
| `PR_DRAFT` | `true` | Create PRs as draft by default |

### CLAUDE.md Integration

Copy the template to customize per project:

```bash
cp templates/CLAUDE.md.example CLAUDE.md
```

Then edit `CLAUDE.md` to set your project's scopes, test commands, and conventions.

## 📋 Requirements

- **Git** 2.23+ (for `git branch --show-current`, `git restore`)
- **Bash** 4+ (for associative arrays in scripts)
- **GitHub CLI** `gh` (for PR creation and issue linking)
- **Common Unix tools**: `grep`, `sed`, `awk`, `head`, `tail`, `wc`

## 🖥️ Example Output

```bash
$ git add src/auth/ tests/test_auth.py
$ git commit -m "feat(auth): add OAuth2 login with Google"

✅ Committed: feat(auth): add OAuth2 login with Google
📁 Files: 4 changed, 127 insertions, 23 deletions
🔗 Closes: #178
🌿 Branch: feature/google-oauth
🚀 Pushed: yes → origin/feature/google-oauth
🔀 PR: https://github.com/org/repo/pull/42 (draft)
```

## 📁 Repository Structure

```
skills/smart-git-commit/
├── SKILL.md                     # Main skill definition (11 phases)
├── scripts/                     # Automation scripts
│   ├── scan-secrets.sh          # Secret scanner (exit code gate)
│   ├── detect-test-runner.sh    # Auto-detect & run test suite
│   ├── split-commits.sh         # Analyze & suggest atomic splits
│   ├── generate-changelog.sh    # Auto-generate CHANGELOG.md
│   └── create-pr.sh             # Create draft PR with rich body
├── references/                  # Supporting documentation
│   ├── commit-types.md          # Full conventional commits reference
│   ├── atomic-patterns.md       # Splitting mixed changesets
│   ├── message-examples.md      # 15 gold-standard commit examples
│   ├── security-rules.md        # Secret patterns & fix guide
│   └── release-workflow.md      # Versioning, changelog, tagging
├── templates/                   # Drop-in config files
│   ├── CLAUDE.md.example        # Project rules for AI agents
│   ├── .gitmessage              # Git commit message template
│   └── pr-body.md               # Rich PR body template
└── tests/                       # Test fixtures & scenarios
    ├── README.md                # How to run tests
    ├── fixtures/                 # Sample diffs for testing
    └── test-scenarios.md        # Written test cases
```

## 📄 License

MIT © 2026 Zarl-prog
