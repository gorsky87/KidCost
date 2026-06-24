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

RLS policies are intentionally handled in issue #7.
