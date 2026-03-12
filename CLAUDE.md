# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Claude Code plugin** - a collection of production-ready agents, skills, hooks, commands, rules, and MCP configurations. The project provides battle-tested workflows for software development using Claude Code.

## Running Tests

```bash
# Run all tests
node tests/run-all.js

# Run individual test files
node tests/lib/utils.test.js
node tests/lib/package-manager.test.js
node tests/hooks/hooks.test.js
```

## Architecture

The project is organized into several core components:

- **agents/** - Specialized subagents for delegation (planner, code-reviewer, tdd-guide, etc.)
- **skills/** - Workflow definitions and domain knowledge (coding standards, patterns, testing)
- **commands/** - Slash commands invoked by users (/tdd, /plan, /e2e, etc.)
- **hooks/** - Trigger-based automations (session persistence, pre/post-tool hooks)
- **rules/** - Always-follow guidelines (security, coding style, testing requirements)
- **mcp-configs/** - MCP server configurations for external integrations
- **scripts/** - Cross-platform Node.js utilities for hooks and setup
- **tests/** - Test suite for scripts and utilities

## Key Commands

- `/tdd` - Test-driven development workflow
- `/plan` - Implementation planning
- `/e2e` - Generate and run E2E tests
- `/code-review` - Quality review
- `/build-fix` - Fix build errors
- `/learn` - Extract patterns from sessions
- `/skill-create` - Generate skills from git history
- `/swift-build` - Swift/Xcode build
- `/swift-review` - Swift code review
- `/swift-test` - Swift test runner
- `/xcode-debug` - Xcode debugging, simulator management, DerivedData cleanup
- `/accessibility-check` - VoiceOver, Dynamic Type, tvOS Focus audit
- `/ios-release` - Version bump, changelog, release checklist

## iOS Governance Model

The project includes a full iOS development governance model with specialized agents:

- **ios-orchestrator** — coordinates the PLAN→APPROVED→EXECUTE→REVIEW→DONE lifecycle
- **ios-product-owner** — Feature Briefs, KPIs, acceptance gates
- **ios-product-pm** — Story Map, INVEST stories, release slicing
- **ios-tech-pm** — WBS, module mapping, risk/spike management
- **ios-architecture** — ADRs, Mermaid diagrams, API design
- **ios-coder** — TDD implementation (RED→GREEN→REFACTOR)
- **ios-collaboration-protocol** — agent coordination rules and approval gates
- **swift-reviewer** — code review with Task+[weak self] rules, tvOS Focus, DoD

### Tool Chain Integration

Agents integrate with the user's existing tools:
- `ios-commit` skill — structured commit workflow
- `gitea` skill — PR management via `tea` CLI
- `/pjm` — project management dashboard
- `jira` skill — issue tracking
- `updateStringKeyFiles` — localization management
- `crashlytics` / `confluence` toolSpecs — crash analysis and release notes

### Templates

`templates/` contains reusable templates for iOS projects:
- `ios-bug-report.md` — structured bug report
- `ios-story.md` — user story with Gherkin AC
- `ios-task.md` — technical task breakdown
- `release-checklist.md` — pre/post-release verification

## Development Notes

- Package manager detection: npm, pnpm, yarn, bun (configurable via `CLAUDE_PACKAGE_MANAGER` env var or project config)
- Cross-platform: Windows, macOS, Linux support via Node.js scripts
- Agent format: Markdown with YAML frontmatter (name, description, tools, model)
- Skill format: Markdown with clear sections for when to use, how it works, examples
- Hook format: JSON with matcher conditions and command/notification hooks

## Contributing

Follow the formats in CONTRIBUTING.md:
- Agents: Markdown with frontmatter (name, description, tools, model)
- Skills: Clear sections (When to Use, How It Works, Examples)
- Commands: Markdown with description frontmatter
- Hooks: JSON with matcher and hooks array

File naming: lowercase with hyphens (e.g., `python-reviewer.md`, `tdd-workflow.md`)
