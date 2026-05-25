# Agent Skills — Smart Git Commit

This document defines the machine-readable manifest for the `smart-git-commit` skill.
It follows the [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) convention.

## Directory Structure

```
skills/
  smart-git-commit/       # kebab-case directory — required
    SKILL.md              # Skill definition — required
    scripts/              # Bash/Node automation scripts
      scan-secrets.sh
      detect-test-runner.sh
      split-commits.sh
      generate-changelog.sh
      create-pr.sh
    references/           # Supporting docs loaded on demand
      commit-types.md
      atomic-patterns.md
      message-examples.md
      security-rules.md
      release-workflow.md
    templates/            # Drop-in config files
      CLAUDE.md.example
      .gitmessage
      pr-body.md
    tests/                # Test cases for the skill
      README.md
      fixtures/
        mixed-diff.txt
        secret-diff.txt
      test-scenarios.md
```

## Naming Conventions

- **Skill directory**: kebab-case (`smart-git-commit/`)
- **Scripts**: kebab-case with `.sh` extension (`scan-secrets.sh`)
- **References**: kebab-case with `.md` extension (`commit-types.md`)
- **Templates**: dotfiles and `.example` suffixes (`.gitmessage`, `CLAUDE.md.example`)

## Script Requirements

All scripts in `scripts/` must:

1. **Shebang**: `#!/usr/bin/env bash`
2. **Error handling**: `set -euo pipefail` for strict mode
3. **Logging**: Progress and status messages go to **stderr**
4. **Output**: Machine-readable results go to **stdout** as **JSON**
5. **Exit codes**: `0` = success, `1` = failure/block
6. **Color**: Use ANSI color codes for human-readable output (RED for errors, GREEN for success, YELLOW for warnings)
7. **Dependencies**: Check for required tools first, provide clear error messages if missing

### Output JSON Schema

All scripts must output JSON to stdout when called with `--json` flag (or by default):

```json
{
  "status": "pass" | "fail" | "not_found",
  "findings": [],
  "message": "Human-readable summary"
}
```

## SKILL.md Requirements

- **Line limit**: 500 lines maximum
- **Frontmatter**: YAML frontmatter with `name` and `description` fields
- **Progressive disclosure**: Start with summary, provide depth via reference links
- **Phase structure**: Numbered phases (Phase 0 through Phase 10+)
- **Script/template references**: Each phase that uses a script or template must reference it

## Progressive Disclosure Pattern

The skill follows a progressive disclosure model:

1. **Top-level SKILL.md**: Complete workflow with phase-by-phase instructions
2. **References/**: Deep dives loaded on demand for specific topics
3. **Scripts/**: Automation for repetitive tasks, called from phases
4. **Templates/**: Drop-in config files users can customize
5. **Tests/**: Test scenarios and fixtures for validating the skill itself
