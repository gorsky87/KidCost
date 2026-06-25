# KidCost Supabase

This directory contains Supabase schema artifacts for the KidCost MVP.

## Layout

- `migrations/` - versioned PostgreSQL migrations for Supabase.
- `config.toml` - local Supabase CLI project configuration.
- `seed.sql` - deterministic local demo/test data loaded by `supabase db reset`.

## First migration

`migrations/20260624004654_create_mvp_schema.sql` creates the MVP tables:

- `profiles`
- `families`
- `family_members`
- `children`
- `expenses`
- `expense_attachments`

It also creates MVP enums, timestamp triggers, family-integrity triggers, and indexes needed by the day-3 expense flows.

## Local verification

Local database verification requires Docker, Supabase CLI, and `psql`:

```sh
supabase --version
psql --version
scripts/verify_supabase_local.sh
```

`supabase db reset` starts from the migrations in `supabase/migrations/` and then loads `supabase/seed.sql`.
The verifier checks the local Docker/Supabase prerequisites first, including the Supabase Postgres image, so image-pull, container-start, and reset problems fail with a bounded diagnostic before or during migration verification. Use a preflight when you only need to confirm the local host can reach the required image before starting containers:

```sh
scripts/verify_supabase_local.sh --preflight-only
```

The timeouts can be tuned with:

```sh
KIDCOST_SUPABASE_PULL_TIMEOUT=180 \
KIDCOST_SUPABASE_START_TIMEOUT=300 \
KIDCOST_SUPABASE_RESET_TIMEOUT=300 \
scripts/verify_supabase_local.sh
```

The seed creates a fake family with two parents, one child, sample expenses, a settlement, and a pending invitation. The demo users are:

- `demo.parent.one@example.test`
- `demo.parent.two@example.test`

Both use the local-only password `KidCostDemo123!`.

RLS policies are defined in `migrations/20260624005127_enable_mvp_rls.sql`.

## RLS verification

Issue #7 adds RLS policies and a manual smoke test:

```sh
supabase db reset
psql "$DATABASE_URL" -f supabase/tests/rls_manual_check.sql
```

The smoke test checks that a user can see and write their own family data, cannot see another family expense, cannot insert an expense into another family, and cannot see another family's attachment metadata.

## Family bootstrap verification

Issue #8 adds profile bootstrap, default family creation, and copyable invitation tokens:

```sh
supabase db reset
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/family_bootstrap_manual_check.sql
```

The smoke test checks that `auth.users` inserts create `profiles`, a user can create their default family, a pending invitation does not reveal family data, and accepting the token creates an active `family_members` row.

## Expense attachment Storage

Issue #9 configures the private `expense-attachments` bucket:

- path format: `families/<family_id>/expenses/<expense_id>/<file_id>.<ext>`
- file size limit: 10 MB
- allowed MIME types: `image/jpeg`, `image/png`, `application/pdf`
- allowed extensions in paths and metadata: `jpg`, `jpeg`, `png`, `pdf`
- access is limited to active members of the expense family
- metadata in `expense_attachments` must point to an uploaded object in the bucket
- client-side delete is intentionally not granted in MVP; attachment removal/replacement needs a follow-up audit/soft-delete flow so evidence does not disappear without trace

Manual verification:

```sh
supabase db reset
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/storage_manual_check.sql
```

## Operations and backups

Supabase environment decisions, reset rules, and backup steps live in `docs/SUPABASE_OPERATIONS.md`.

Create a database backup and Storage manifest with:

```sh
DATABASE_URL="$DATABASE_URL" KIDCOST_BACKUP_ENV=beta scripts/supabase_backup.sh
```

The script writes to `backups/supabase/` by default. Do not commit backup output because it may contain private family and financial data.
