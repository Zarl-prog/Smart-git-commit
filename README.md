
[![Smart Git Commit](https://img.shields.io/badge/commits-Smart%20Git%20Commit-6C47FF?style=flat-square)](https://github.com/Zarl-prog/Smart-git-commit)
# Smart Git Commit

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/npx-skills%20add-6C47FF?style=flat-square&logo=npm" alt="npx install"></a>
  <a href="#"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License: MIT"></a>
  <br>
  <strong>Compatible agents:</strong> Claude Code · Codex · Cursor · Windsurf · OpenCode · Gemini CLI
</p>

---

## Install

```bash
npx skills add Zarl-prog/Smart-git-commit
```

## What It Does

- 🔍 **Full diff analysis** — categorizes every changed file before touching git
- 🔐 **Secret scanner** — blocks commits containing API keys, tokens, credentials
- 🧪 **Test gate** — auto-detects and runs your test suite, only commits if green
- ⚛️ **Atomic split** — detects mixed concerns, proposes and executes clean splits
- 📝 **5-Part commit format** — CONTEXT / CHANGE / WHY / IMPACT / footers
- 🔗 **Issue linking** — auto-detects GitHub/Jira/Linear tickets from branch name
- 🚀 **PR creation** — draft PR with rich body via gh CLI
- 🏷️ **Release tagging** — semver bump, CHANGELOG.md generation, git tag + push

## The Commit Format (What Makes This Different)

```
fix(auth): resolve JWT token expiry race condition

CONTEXT: Tokens were validated at request receipt but checked 200ms later,
         rejecting valid tokens under load.
CHANGE:  Adds 500ms grace window to all token expiry checks.
WHY:     Root cause was middleware chain latency, not clock drift.
IMPACT:  Enables audit logging of refresh events in the next phase.

Closes #204
```

## How It Works

1. Read project rules — checks for CLAUDE.md, .gitmessage overrides
2. Diff analysis — scans every changed file, categorizes by concern
3. Security scan — blocks commits with secrets (hard exit code gate)
4. Test gate — auto-detects runner, only commits if green
5. Atomic split — splits mixed changesets into separate commits
6. Commit message — builds the 5-part rich message format
7. Issue linking — links to GitHub issues, Jira, Linear
8. Execute commits — selective staging with diff --cached verification
9. Push strategy — feature branch only (never main by default)
10. PR creation — draft PR with rich body from templates/pr-body.md
11. Release tagging — changelog gen, semver bump, annotated tags

## Requirements

- **Git** 2.x
- **Bash** 4+
- **gh CLI** (for PR creation — optional)
- **Node.js** (for npx skills install)

## Configuration

Copy `templates/CLAUDE.md.example` to your project root, rename to `CLAUDE.md`,
and fill in your test command and ticket prefix. The skill reads it automatically.

```bash
cp skills/smart-git-commit/templates/CLAUDE.md.example CLAUDE.md
```

Set the git commit template to use the 5-part format interactively:

```bash
git config commit.template skills/smart-git-commit/templates/.gitmessage
```

## Compatible Agents

| Agent | Install Path | Notes |
|-------|-------------|-------|
| Claude Code | `npx skills add` | Native skill support |
| Codex | `npx skills add` | Via OpenAI agent SDK |
| Cursor | `npx skills add` | Composer integration |
| Windsurf | `npx skills add` | Cascade support |
| OpenCode | `npx skills add` | Open-source agent |
| Gemini CLI | `npx skills add` | Google AI CLI |
| GitHub Copilot | Manual copy | Copy CLAUDE.md.example → .github/ |

## License

MIT © 2026 Zarl-prog
