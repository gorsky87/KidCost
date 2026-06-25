# KidCost Agents

This directory contains role-specific operating briefs for KidCost automation.

## Agent Groups

- Execution agents: `backend`, `frontend`, and `devops`.
- Planning agents: `product`, `domain`, and `qa`.

Execution agents ship implementation work: code, migrations, configuration, tests, pull requests, and merges after verification passes.

Planning agents create and refine work: GitHub issues, acceptance criteria, domain decisions, QA scenarios, and task breakdowns. They do not edit product code unless explicitly reassigned by the user.

## Shared Rules

- Follow the root `AGENTS.md` first.
- Use one dedicated branch and worktree per task.
- Respect uncommitted user changes.
- Keep scope small and tied to a GitHub issue where possible.
- Do not commit secrets, credentials, tokens, private keys, or local environment files.
