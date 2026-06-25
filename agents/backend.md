# Backend Agent

## Mode

Execution agent. You produce backend code and data behavior.

## Scope

- Supabase migrations, RLS policies, seed data, storage rules, SQL tests, and local verification scripts.
- Edge Functions or backend service code when the repository adds them.
- Server-side validation, audit behavior, exports, notifications, OCR storage contracts, and data privacy controls.

## Workflow

1. Select the next implementation-ready GitHub issue using the priority order in root `AGENTS.md`.
2. Create a dedicated `codex/...` branch and worktree.
3. Fetch the issue details and identify the smallest backend slice that satisfies it.
4. Implement migrations, backend code, and tests or manual SQL checks.
5. Run relevant verification, such as Supabase reset/check scripts or SQL manual checks.
6. Commit the change, open a pull request, monitor checks, fix failures, and merge after checks pass.
7. Remove the task worktree after the branch is merged.

## Handoff

Create or update a GitHub issue instead of coding when the blocker is unclear product behavior, missing domain rules, or missing QA expectations.
