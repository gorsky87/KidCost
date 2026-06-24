# AGENTS.md

Guidance for AI agents working in this repository.

## Project Context

- Repository name: `KidCost`.
- The repository is currently documentation-first, but the planned stack is a monorepo with Flutter mobile, Supabase backend/data, and minimal web docs pages.
- Before making changes, inspect the current files and follow the patterns already present in the repository.

## Working Rules

- Keep changes small, focused, and directly related to the user's request.
- Do not overwrite or revert user changes unless the user explicitly asks for it.
- Prefer existing project conventions over introducing new structure or tooling.
- If a framework, package manager, formatter, or test runner appears later, use the repo's existing configuration.
- Avoid adding dependencies unless they are clearly necessary.

## Worktree Workflow

- Work on each task in a separate Git worktree and a dedicated branch.
- Use branch names that describe the task, for example `codex/issue-12-flutter-shell`.
- Do not work directly on `master` except for repository setup or explicit user-approved maintenance.
- When selecting the next GitHub issue for automation, use `gh issue list --state open --limit 200 --json number,title,createdAt,updatedAt,labels,assignees,url` and process issues by ascending issue number.
- Before starting a task, check the main worktree status and avoid touching uncommitted user changes.
- Keep each worktree scoped to one GitHub issue or one clearly defined task.
- Add or update tests for every code change whenever a meaningful test can be written.
- Add regression tests for bug fixes and behavior changes, covering the scenario that could break again.
- Merge a task back into `master` only after the relevant tests have passed.
- For documentation-only, configuration-only, or design-only changes where automated tests are not meaningful, perform an explicit review/verification and mention that no automated test was applicable.
- After finishing a task, run the relevant verification commands, commit the work, and merge it back into `master` only when verification is clean.
- Resolve conflicts intentionally; never discard user or unrelated agent changes to force a merge.
- Remove completed task worktrees after their branch has been merged and no longer needs inspection.

## Commands

```sh
# Install Flutter mobile dependencies
cd apps/mobile && flutter pub get

# Run Flutter tests
cd apps/mobile && flutter test

# Start the Flutter mobile app
cd apps/mobile && flutter run
```

Supabase CLI is not committed as a project dependency yet. Once installed locally, verify migrations from a clean database with:

```sh
# Reset local Supabase database after migrations exist
supabase db reset
```

## Testing

- Run relevant tests before finishing a change whenever tests exist.
- If tests do not exist, verify changes with the most appropriate available command or manual check.
- Mention any verification that could not be run.

## Code Style

- Use clear names and simple, maintainable code.
- Add comments only when they explain non-obvious behavior.
- Keep generated or build artifacts out of version control unless the project explicitly tracks them.

## Security And Privacy

- Do not commit secrets, credentials, tokens, private keys, or local environment files.
- Treat user data and financial information as sensitive.
- Validate inputs at boundaries once the application has user-facing or API surfaces.
- Follow `docs/SECURITY.md` for the KidCost family data access model, RLS expectations, storage limits, soft delete, and audit log conventions.

## Updating This File

Update this file whenever the repository gains:

- a defined technology stack,
- package manager commands,
- test or lint commands,
- deployment instructions,
- important architecture or domain conventions.
