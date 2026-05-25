# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-25

### 🚀 Features

- feat(skill): add 11-phase commit workflow with security scan, test gate, atomic splitting
- feat(scripts): add scan-secrets.sh — auto-detect secrets, API keys, and credentials in staged diffs
- feat(scripts): add detect-test-runner.sh — auto-detect and run project test suite (10+ runners supported)
- feat(scripts): add split-commits.sh — analyze diffs and suggest atomic commit splits
- feat(scripts): add generate-changelog.sh — auto-generate CHANGELOG.md from git history
- feat(scripts): add create-pr.sh — create draft PRs with rich body from commit data
- feat(format): add 5-part commit message format (CONTEXT · CHANGE · WHY · IMPACT · footers)
- feat(integration): support GitHub issues, Jira, and Linear auto-detection from branch names

### 🔒 Security

- security(scan): detect AWS keys, Stripe keys, GitHub tokens, database connection strings, private keys
- security(scan): block dangerous file types (.env, .pem, .key, credentials) from being staged
- security(scan): color-coded output with file:line findings

### 🧪 Tests

- test(skill): add 7 test scenarios covering happy path, mixed concerns, secrets, failures, releases, hotfixes, breaking changes
- test(fixtures): add realistic mixed-diff.txt and secret-diff.txt for testing

### 📖 Documentation

- docs(skill): add reference files for commit types, atomic patterns, message examples, security rules, release workflow
- docs(templates): add CLAUDE.md.example, .gitmessage, and pr-body.md templates
- docs(readme): add professional README with badges, install guide, feature list, and example output

### 🛠 Maintenance

- chore(repo): add AGENTS.md machine-readable skill manifest
- chore(repo): add CHANGELOG.md with Keep a Changelog format
- chore(repo): add .gitignore for shell/node projects
- chore(repo): add MIT license
