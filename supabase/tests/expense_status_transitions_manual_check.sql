-- Manual expense status transition verification for issue #116.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/expense_status_transitions_manual_check.sql
--
-- This script rolls back at the end.

begin;

create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

create temp table expense_status_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into expense_status_ids (name, id)
values
  ('owner', gen_random_uuid()),
  ('co_parent', gen_random_uuid()),
  ('family_id', gen_random_uuid()),
  ('expense_id', gen_random_uuid()),
  ('self_action_expense_id', gen_random_uuid()),
  ('missing_comment_expense_id', gen_random_uuid());

grant select on expense_status_ids to authenticated;

insert into auth.users (id, email, raw_user_meta_data)
values
  ((select id from expense_status_ids where name = 'owner'), 'status-owner@example.com', '{"display_name":"Owner"}'::jsonb),
  ((select id from expense_status_ids where name = 'co_parent'), 'status-co-parent@example.com', '{"display_name":"Co Parent"}'::jsonb);

insert into public.families (id, name, created_by)
values (
  (select id from expense_status_ids where name = 'family_id'),
  'Status family',
  (select id from expense_status_ids where name = 'owner')
);

insert into public.family_members (family_id, profile_id, role, status)
values
  (
    (select id from expense_status_ids where name = 'family_id'),
    (select id from expense_status_ids where name = 'owner'),
    'owner',
    'active'
  ),
  (
    (select id from expense_status_ids where name = 'family_id'),
    (select id from expense_status_ids where name = 'co_parent'),
    'parent',
    'active'
  );

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from expense_status_ids where name = 'owner'), true);

insert into public.expenses (
  id,
  family_id,
  paid_by,
  amount,
  category,
  description,
  expense_date,
  created_by
)
values
  (
    (select id from expense_status_ids where name = 'expense_id'),
    (select id from expense_status_ids where name = 'family_id'),
    (select id from expense_status_ids where name = 'owner'),
    120.00,
    'school',
    'Books',
    '2026-06-24',
    (select id from expense_status_ids where name = 'owner')
  ),
  (
    (select id from expense_status_ids where name = 'self_action_expense_id'),
    (select id from expense_status_ids where name = 'family_id'),
    (select id from expense_status_ids where name = 'owner'),
    80.00,
    'health',
    'Medicine',
    '2026-06-24',
    (select id from expense_status_ids where name = 'owner')
  ),
  (
    (select id from expense_status_ids where name = 'missing_comment_expense_id'),
    (select id from expense_status_ids where name = 'family_id'),
    (select id from expense_status_ids where name = 'owner'),
    40.00,
    'food',
    'Lunch',
    '2026-06-24',
    (select id from expense_status_ids where name = 'owner')
  );

do $$
declare
  self_action_denied boolean := false;
begin
  begin
    update public.expenses
    set
      status = 'accepted',
      updated_by = (select id from expense_status_ids where name = 'owner')
    where id = (select id from expense_status_ids where name = 'self_action_expense_id');
  exception
    when raise_exception then
      self_action_denied := true;
  end;

  if not self_action_denied then
    raise exception 'expense creator accepted their own pending expense';
  end if;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from expense_status_ids where name = 'co_parent'), true);

do $$
declare
  missing_comment_denied boolean := false;
begin
  begin
    update public.expenses
    set
      status = 'disputed',
      updated_by = (select id from expense_status_ids where name = 'co_parent')
    where id = (select id from expense_status_ids where name = 'missing_comment_expense_id');
  exception
    when raise_exception then
      missing_comment_denied := true;
  end;

  if not missing_comment_denied then
    raise exception 'disputed expense was saved without a comment';
  end if;
end $$;

update public.expenses
set
  status = 'disputed',
  status_comment = 'Receipt is unclear.',
  updated_by = (select id from expense_status_ids where name = 'co_parent')
where id = (select id from expense_status_ids where name = 'expense_id');

update public.expenses
set
  status = 'accepted',
  status_comment = 'Explanation accepted.',
  updated_by = (select id from expense_status_ids where name = 'co_parent')
where id = (select id from expense_status_ids where name = 'expense_id');

update public.expenses
set
  status = 'settled',
  updated_by = (select id from expense_status_ids where name = 'co_parent')
where id = (select id from expense_status_ids where name = 'expense_id');

do $$
declare
  settled_rewrite_denied boolean := false;
  settled_reopen_denied boolean := false;
begin
  begin
    update public.expenses
    set amount = 121.00
    where id = (select id from expense_status_ids where name = 'expense_id');
  exception
    when raise_exception then
      settled_rewrite_denied := true;
  end;

  if not settled_rewrite_denied then
    raise exception 'settled expense core fields were rewritten';
  end if;

  begin
    update public.expenses
    set
      status = 'disputed',
      status_comment = 'Trying to reopen.',
      updated_by = (select id from expense_status_ids where name = 'co_parent')
    where id = (select id from expense_status_ids where name = 'expense_id');
  exception
    when raise_exception then
      settled_reopen_denied := true;
  end;

  if not settled_reopen_denied then
    raise exception 'settled expense was reopened';
  end if;

  if not exists (
    select 1
    from public.audit_events
    where event_type = 'status_changed'
      and entity_type = 'expense'
      and entity_id = (select id from expense_status_ids where name = 'expense_id')
      and metadata->>'from' = 'pending'
      and metadata->>'to' = 'disputed'
      and metadata->>'comment' = 'Receipt is unclear.'
  ) then
    raise exception 'dispute status audit metadata with comment is missing';
  end if;
end $$;

rollback;
