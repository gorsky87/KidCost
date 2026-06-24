-- Manual settlements and audit log verification for issue #31.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/settlements_audit_manual_check.sql
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

create temp table settlement_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into settlement_ids (name, id)
values
  ('owner', gen_random_uuid()),
  ('co_parent', gen_random_uuid()),
  ('outsider', gen_random_uuid()),
  ('family_id', gen_random_uuid()),
  ('outsider_family_id', gen_random_uuid()),
  ('expense_id', gen_random_uuid());

grant select on settlement_ids to authenticated;

insert into auth.users (id, email, raw_user_meta_data)
values
  ((select id from settlement_ids where name = 'owner'), 'settlement-owner@example.com', '{"display_name":"Owner"}'::jsonb),
  ((select id from settlement_ids where name = 'co_parent'), 'settlement-co-parent@example.com', '{"display_name":"Co Parent"}'::jsonb),
  ((select id from settlement_ids where name = 'outsider'), 'settlement-outsider@example.com', '{"display_name":"Outsider"}'::jsonb);

insert into public.families (id, name, created_by)
values
  (
    (select id from settlement_ids where name = 'family_id'),
    'Settlement family',
    (select id from settlement_ids where name = 'owner')
  ),
  (
    (select id from settlement_ids where name = 'outsider_family_id'),
    'Outsider family',
    (select id from settlement_ids where name = 'outsider')
  );

insert into public.family_members (family_id, profile_id, role, status)
values
  (
    (select id from settlement_ids where name = 'family_id'),
    (select id from settlement_ids where name = 'owner'),
    'owner',
    'active'
  ),
  (
    (select id from settlement_ids where name = 'family_id'),
    (select id from settlement_ids where name = 'co_parent'),
    'parent',
    'active'
  ),
  (
    (select id from settlement_ids where name = 'outsider_family_id'),
    (select id from settlement_ids where name = 'outsider'),
    'owner',
    'active'
  );

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from settlement_ids where name = 'owner'), true);

insert into public.expenses (
  id,
  family_id,
  paid_by,
  amount,
  category,
  description,
  expense_date,
  status,
  created_by
)
values (
  (select id from settlement_ids where name = 'expense_id'),
  (select id from settlement_ids where name = 'family_id'),
  (select id from settlement_ids where name = 'owner'),
  600.00,
  'school',
  'School trip',
  '2026-06-12',
  'pending',
  (select id from settlement_ids where name = 'owner')
);

select set_config('request.jwt.claim.sub', (select id::text from settlement_ids where name = 'co_parent'), true);

update public.expenses
set
  status = 'accepted',
  updated_by = (select id from settlement_ids where name = 'co_parent')
where id = (select id from settlement_ids where name = 'expense_id');

insert into public.settlements (
  family_id,
  paid_by,
  paid_to,
  amount,
  currency,
  settlement_date,
  note,
  expense_id,
  period_start,
  period_end,
  created_by
)
values (
  (select id from settlement_ids where name = 'family_id'),
  (select id from settlement_ids where name = 'co_parent'),
  (select id from settlement_ids where name = 'owner'),
  300.00,
  'PLN',
  '2026-06-20',
  'Offline transfer',
  (select id from settlement_ids where name = 'expense_id'),
  '2026-06-01',
  '2026-06-30',
  (select id from settlement_ids where name = 'co_parent')
);

do $$
declare
  settlement_count integer;
  audit_count integer;
begin
  select count(*)
  into settlement_count
  from public.settlements
  where family_id = (select id from settlement_ids where name = 'family_id');

  if settlement_count <> 1 then
    raise exception 'family member cannot see inserted settlement';
  end if;

  select count(*)
  into audit_count
  from public.audit_events
  where family_id = (select id from settlement_ids where name = 'family_id')
    and (
      event_type = 'created'
      or event_type = 'status_changed'
      or event_type = 'settlement_added'
    );

  if audit_count <> 3 then
    raise exception 'audit log should contain expense create, status change, and settlement events; got %', audit_count;
  end if;

  if not exists (
    select 1
    from public.audit_events
    where event_type = 'status_changed'
      and entity_type = 'expense'
      and entity_id = (select id from settlement_ids where name = 'expense_id')
      and metadata->>'from' = 'pending'
      and metadata->>'to' = 'accepted'
  ) then
    raise exception 'status change audit metadata is missing';
  end if;

  if not exists (
    select 1
    from public.audit_events
    where event_type = 'settlement_added'
      and entity_type = 'settlement'
      and (metadata->>'amount')::numeric = 300.00
  ) then
    raise exception 'settlement audit metadata is missing';
  end if;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from settlement_ids where name = 'outsider'), true);

do $$
declare
  outsider_settlements integer;
  outsider_audit_events integer;
  insert_denied boolean := false;
begin
  select count(*)
  into outsider_settlements
  from public.settlements
  where family_id = (select id from settlement_ids where name = 'family_id');

  if outsider_settlements <> 0 then
    raise exception 'outsider can see another family settlements';
  end if;

  select count(*)
  into outsider_audit_events
  from public.audit_events
  where family_id = (select id from settlement_ids where name = 'family_id');

  if outsider_audit_events <> 0 then
    raise exception 'outsider can see another family audit events';
  end if;

  begin
    insert into public.settlements (
      family_id,
      paid_by,
      paid_to,
      amount,
      settlement_date,
      created_by
    )
    values (
      (select id from settlement_ids where name = 'family_id'),
      (select id from settlement_ids where name = 'outsider'),
      (select id from settlement_ids where name = 'owner'),
      10.00,
      '2026-06-21',
      (select id from settlement_ids where name = 'outsider')
    );
  exception
    when insufficient_privilege or raise_exception or check_violation or foreign_key_violation then
      insert_denied := true;
  end;

  if not insert_denied then
    raise exception 'outsider inserted settlement into another family';
  end if;
end $$;

rollback;
