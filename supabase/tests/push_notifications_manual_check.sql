-- Manual push notification verification for issue #32.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/push_notifications_manual_check.sql
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

create temp table push_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into push_ids (name, id)
values
  ('owner', gen_random_uuid()),
  ('co_parent', gen_random_uuid()),
  ('outsider', gen_random_uuid()),
  ('family_id', gen_random_uuid()),
  ('outsider_family_id', gen_random_uuid()),
  ('expense_id', gen_random_uuid());

grant select on push_ids to authenticated;

insert into auth.users (id, email, raw_user_meta_data)
values
  ((select id from push_ids where name = 'owner'), 'push-owner@example.com', '{"display_name":"Owner"}'::jsonb),
  ((select id from push_ids where name = 'co_parent'), 'push-co-parent@example.com', '{"display_name":"Co Parent"}'::jsonb),
  ((select id from push_ids where name = 'outsider'), 'push-outsider@example.com', '{"display_name":"Outsider"}'::jsonb);

insert into public.families (id, name, created_by)
values
  (
    (select id from push_ids where name = 'family_id'),
    'Push family',
    (select id from push_ids where name = 'owner')
  ),
  (
    (select id from push_ids where name = 'outsider_family_id'),
    'Outsider family',
    (select id from push_ids where name = 'outsider')
  );

insert into public.family_members (family_id, profile_id, role, status)
values
  (
    (select id from push_ids where name = 'family_id'),
    (select id from push_ids where name = 'owner'),
    'owner',
    'active'
  ),
  (
    (select id from push_ids where name = 'family_id'),
    (select id from push_ids where name = 'co_parent'),
    'parent',
    'active'
  ),
  (
    (select id from push_ids where name = 'outsider_family_id'),
    (select id from push_ids where name = 'outsider'),
    'owner',
    'active'
  );

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from push_ids where name = 'owner'), true);

select public.upsert_push_device_token(
  'owner-token-with-enough-length-for-test',
  'ios',
  '1.0.0'
);

insert into public.notification_preferences (
  profile_id,
  push_new_expense,
  push_status_changed,
  push_unsettled_balance_reminders
)
values (
  (select id from push_ids where name = 'owner'),
  true,
  true,
  false
);

select set_config('request.jwt.claim.sub', (select id::text from push_ids where name = 'co_parent'), true);

select public.upsert_push_device_token(
  'co-parent-token-with-enough-length-for-test',
  'android',
  '1.0.0'
);

select set_config('request.jwt.claim.sub', (select id::text from push_ids where name = 'owner'), true);

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
  (select id from push_ids where name = 'expense_id'),
  (select id from push_ids where name = 'family_id'),
  (select id from push_ids where name = 'owner'),
  42.00,
  'school',
  'Private description',
  '2026-06-24',
  'pending',
  (select id from push_ids where name = 'owner')
);

do $$
declare
  notification_count integer;
begin
  select count(*)
  into notification_count
  from public.notification_outbox
  where audience_profile_id = (select id from push_ids where name = 'co_parent')
    and event_type = 'expense_created';

  if notification_count <> 1 then
    raise exception 'co-parent should receive one new expense notification, got %', notification_count;
  end if;

  if exists (
    select 1
    from public.notification_outbox
    where data::text like '%Private description%'
      or data::text like '%42.00%'
  ) then
    raise exception 'push notification payload leaked sensitive expense data';
  end if;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from push_ids where name = 'co_parent'), true);

insert into public.notification_preferences (
  profile_id,
  push_new_expense,
  push_status_changed,
  push_unsettled_balance_reminders
)
values (
  (select id from push_ids where name = 'co_parent'),
  true,
  false,
  true
);

update public.expenses
set
  status = 'accepted',
  updated_by = (select id from push_ids where name = 'co_parent')
where id = (select id from push_ids where name = 'expense_id');

select set_config('request.jwt.claim.sub', (select id::text from push_ids where name = 'owner'), true);

do $$
declare
  status_notification_count integer;
begin
  select count(*)
  into status_notification_count
  from public.notification_outbox
  where audience_profile_id = (select id from push_ids where name = 'owner')
    and event_type = 'expense_status_changed';

  if status_notification_count <> 1 then
    raise exception 'owner should receive one status notification, got %', status_notification_count;
  end if;
end $$;

update public.expenses
set
  status = 'settled',
  updated_by = (select id from push_ids where name = 'owner')
where id = (select id from push_ids where name = 'expense_id');

select set_config('request.jwt.claim.sub', (select id::text from push_ids where name = 'co_parent'), true);

do $$
declare
  disabled_status_count integer;
begin
  select count(*)
  into disabled_status_count
  from public.notification_outbox
  where audience_profile_id = (select id from push_ids where name = 'co_parent')
    and event_type = 'expense_status_changed';

  if disabled_status_count <> 0 then
    raise exception 'disabled status notifications should not be queued';
  end if;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from push_ids where name = 'outsider'), true);

do $$
declare
  outsider_tokens integer;
  outsider_notifications integer;
  insert_denied boolean := false;
begin
  select count(*)
  into outsider_tokens
  from public.push_device_tokens
  where profile_id = (select id from push_ids where name = 'owner');

  if outsider_tokens <> 0 then
    raise exception 'outsider can see another user push token';
  end if;

  select count(*)
  into outsider_notifications
  from public.notification_outbox
  where family_id = (select id from push_ids where name = 'family_id');

  if outsider_notifications <> 0 then
    raise exception 'outsider can see another family notification outbox';
  end if;

  begin
    insert into public.push_device_tokens (profile_id, platform, token)
    values (
      (select id from push_ids where name = 'owner'),
      'ios',
      'stolen-token-with-enough-length'
    );
  exception
    when insufficient_privilege or raise_exception or check_violation or unique_violation then
      insert_denied := true;
  end;

  if not insert_denied then
    raise exception 'outsider inserted a token for another profile';
  end if;
end $$;

rollback;
