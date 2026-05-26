# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] — 2026-05-26

### Added
- Full contributor workflow (CONTRIBUTOR-SKILL.md) with 8 phases from fork to merge
- fork-check.sh — syncs fork with upstream before contributing
- branch-name.sh — enforces type/issue-description branch convention
- pr-readiness.sh — full pre-PR checklist (7 checks, hard blocks + warnings)
- review-response.sh — helps address review comments and notify maintainer
- pr-anatomy.md — complete guide to what makes a perfect PR
- review-etiquette.md — how to handle every type of maintainer feedback
- first-contribution.md — step by step guide for first-time contributors
- pr-title.md — PR title formula with good/bad examples
- pr-body-full.md — rich PR body template with all sections
- review-response.md — template for responding to review comments

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
