# KidCost Supabase

This directory contains Supabase schema artifacts for the KidCost MVP.

## Layout

- `migrations/` - versioned PostgreSQL migrations for Supabase.

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

Supabase CLI is not yet committed as a project dependency. Once installed locally, verify migrations from a clean database with:

```sh
supabase db reset
```

RLS policies are defined in `migrations/20260624005127_enable_mvp_rls.sql`.

## RLS verification

Issue #7 adds RLS policies and a manual smoke test:

```sh
supabase db reset
psql "$DATABASE_URL" -f supabase/tests/rls_manual_check.sql
```

The smoke test checks that a user can see and write their own family data, cannot see another family expense, cannot insert an expense into another family, and cannot see another family's attachment metadata.
