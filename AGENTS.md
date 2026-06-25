# AGENTS.md

Guidance for AI agents working in this repository.

## Project Context

- Repository name: `KidCost`.
- The repository is now implementation-first: deliver a working Flutter mobile app, Supabase backend/data behavior, domain package rules, and minimal web docs only where they support the product.
- Before making changes, inspect the current files and follow the patterns already present in the repository.

## Project Organization

- `README.md` is the human entry point for the repository.
- `TASKS.md` describes how to select and execute work; GitHub issues remain the source of truth for implementation tasks.
- `ROADMAP.md` is the short roadmap index; detailed planning remains in `docs/ROADMAP_30_DAYS.md`.
- `docs/` contains architecture, business, security, release, UX, monetization, and research documentation.
- `agents/` contains role-specific operating briefs for product, backend, domain, frontend, QA, and DevOps agents.
- `adr/` contains durable architecture decision records.
- Keep existing uppercase docs such as `docs/ARCHITECTURE.md`; do not add lowercase duplicates on case-insensitive filesystems.

## Working Rules

- Keep changes small, focused, and directly related to the user's request.
- Prefer working code, tests, migrations, and verification over new Markdown. Create or expand documentation only when it unblocks implementation, records a durable decision, or explains behavior that was just shipped.
- Default to execution, not analysis. Once the next useful code change is clear, make the change instead of continuing to describe options.
- Keep planning lightweight and local to the current task: inspect enough context to avoid breaking existing behavior, then implement, test, and report the result.
- For feature, bug, backend, mobile, or domain requests, the expected output is a code/test/migration change unless the user explicitly asks only for research, review, or planning.
- Do not spend a turn only summarizing possible approaches when a small reversible implementation step can be made.
- Prefer one shipped vertical slice over several speculative design notes.
- If implementation tasks exist, pick and execute the next task before brainstorming, planning future work, or adding more ideas.
- Do not create new planning docs, idea lists, or backlog notes while a clear GitHub issue or code task is available.
- Do not overwrite or revert user changes unless the user explicitly asks for it.
- Prefer existing project conventions over introducing new structure or tooling.
- If a framework, package manager, formatter, or test runner appears later, use the repo's existing configuration.
- Avoid adding dependencies unless they are clearly necessary.

## Agent Defaults

- Agents are builders first. The normal loop is: inspect the relevant files, make the smallest useful implementation change, add or update tests where meaningful, run verification, then summarize what changed.
- Ask clarifying questions only when a reasonable implementation choice would risk wasted work, data loss, security issues, or a user-visible product direction change.
- When blocked by missing tooling or credentials, still make progress on code, tests, local fixtures, documentation tied to shipped behavior, or a clear failing test that captures the gap.
- Keep explanations brief during implementation. Put detailed reasoning in code comments or docs only when it helps future maintainers understand non-obvious behavior.
- Treat docs-only work as secondary unless the task explicitly targets docs, compliance, release readiness, or a durable architecture decision.

## Worktree Workflow

- Work on each task in a separate Git worktree and a dedicated branch.
- Use branch names that describe the task, for example `codex/issue-12-flutter-shell`.
- Do not work directly on `master` except for repository setup or explicit user-approved maintenance.
- When selecting the next GitHub issue for automation, use `gh issue list --state open --limit 200 --json number,title,createdAt,updatedAt,labels,assignees,url`; first process open issues labeled `blocker` by ascending issue number, then open issues labeled `mvp:must-have` by ascending issue number, then the remaining open issues by ascending issue number.
- After selecting an issue, fetch its current details with `gh issue view <number> --json number,title,body,labels,comments,url`, then implement the requested work instead of only summarizing it.
- When open implementation issues exist, do not pause to invent new tasks. Start the highest-priority existing issue and move it toward a verified app change.
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
cd apps/mobile && flutter run -d <android-device-id>

# Run domain package tests
cd packages/domain && dart test/balance_test.dart
cd packages/domain && dart test/expense_status_test.dart
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
