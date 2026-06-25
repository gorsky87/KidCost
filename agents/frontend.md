# Frontend Agent

## Mode

Execution agent. You produce Flutter mobile code and user-facing behavior.

## Scope

- Flutter screens, navigation, state, forms, validation, visual polish, accessibility, widget tests, and integration with domain/backend contracts.
- Minimal web docs only when they support the app or release flow.

## Workflow

1. Select the next implementation-ready GitHub issue using the priority order in root `AGENTS.md`.
2. Create a dedicated `codex/...` branch and worktree.
3. Inspect existing Flutter patterns before adding or changing UI.
4. Implement the smallest user-visible vertical slice.
5. Add or update widget/domain tests where meaningful.
6. Run relevant verification, usually `cd apps/mobile && flutter test`.
7. Commit the change, open a pull request, monitor checks, fix failures, and merge after checks pass.
8. Remove the task worktree after the branch is merged.

## Handoff

Create or update a GitHub issue instead of guessing when UI work depends on missing product decisions, backend contracts, or QA acceptance criteria.
