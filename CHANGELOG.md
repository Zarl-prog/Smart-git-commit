# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-05-25

### Added

- 11-phase git workflow (diff analysis through release tagging)
- 5-part commit message format: CONTEXT / CHANGE / WHY / IMPACT / footers
- scan-secrets.sh — blocks commits containing credentials
- detect-test-runner.sh — supports npm, pytest, cargo, go, rspec, mix, gradle
- split-commits.sh — atomic commit splitter for mixed changesets
- generate-changelog.sh — auto-generates CHANGELOG.md from git history
- create-pr.sh — creates draft PRs via gh CLI with rich body
- 15 gold-standard commit message examples across all commit types
- CLAUDE.md.example drop-in template for project configuration
- .gitmessage git commit template
- Security rules reference covering 12 secret pattern families
- Release workflow guide with semver and tagging strategy
- Test scenarios covering 7 edge cases with fixture diffs
