# iOS Governance Workflow

## When to Use

Use this skill when implementing features that require the full iOS governance model: structured planning, approval gates, and multi-agent coordination.

## How It Works

The iOS Governance Workflow implements a three-plan approval model:

### Three Plans

1. **Product Plan** (Product Owner + Product PM)
   - Feature Brief with vision, KPIs, constraints
   - Story Map with INVEST user stories
   - Acceptance criteria in Given/When/Then format

2. **Technical Plan** (Tech PM + Architecture)
   - Work Breakdown Structure (WBS)
   - Module mapping (UI → ViewModel → UseCase → Repository → Service)
   - Architecture Decision Records (ADRs)
   - Risk assessment and spike identification

3. **Execution Plan** (Coder + Reviewer)
   - TDD slice plan (RED → GREEN → REFACTOR per slice)
   - Build verification after each slice
   - Code review with Definition of Done

### Approval Gates

```
Product Plan → [User Approval] → Technical Plan → [User Approval] → Execution → [Review Gate] → Done
```

Each gate requires explicit user approval before proceeding.

### Agent Coordination

| Phase | Agent | Output |
|-------|-------|--------|
| Product | ios-product-owner | Feature Brief |
| Product | ios-product-pm | Story Map, User Stories |
| Technical | ios-tech-pm | WBS, Task List |
| Technical | ios-architecture | ADR, Diagrams |
| Execution | ios-coder | Code + Tests |
| Review | swift-reviewer | Review Verdict |
| Orchestration | ios-orchestrator | Coordination |

## Integration Points

- **`/pjm`** — register project, track sprints and milestones
- **`jira` skill** — create and track issues (Stories, Tasks, Bugs)
- **`gitea` skill** — manage PRs (`tea pulls create/review`)
- **`ios-commit` skill** — structured commit messages

## Examples

### Starting a New Feature
```
User: Implement dark mode support for the player screen

Orchestrator activates:
1. Product Owner → Feature Brief (dark mode scope, KPIs)
2. Product PM → Stories (color system, asset updates, settings toggle)
3. Tech PM → WBS (theme service, asset catalog, view updates)
4. Architecture → ADR (centralized vs. per-view theming)
5. [User approves plan]
6. Coder → TDD implementation per slice
7. Reviewer → Code review
8. [Merge and done]
```

### Handling a Bug Fix
For smaller scope, the workflow can be abbreviated:
```
User: Fix crash when rotating device during playback

Orchestrator activates (abbreviated):
1. Tech PM → Analyze crash, create single task
2. Coder → TDD fix (reproduce → test → fix → verify)
3. Reviewer → Code review
4. [Merge and done]
```
