-- Manual verification for issue #8.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/family_bootstrap_manual_check.sql
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

create temp table bootstrap_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into bootstrap_ids (name, id)
values
  ('owner', gen_random_uuid()),
  ('invitee', gen_random_uuid());

grant select on bootstrap_ids to authenticated;

insert into auth.users (id, email, raw_user_meta_data)
values (
  (select id from bootstrap_ids where name = 'owner'),
  'owner@example.com',
  '{"display_name":"Owner Parent"}'::jsonb
);

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from bootstrap_ids where name = 'owner'), true);

do $$
declare
  profile_count integer;
begin
  select count(*)
  into profile_count
  from public.profiles
  where id = (select id from bootstrap_ids where name = 'owner')
    and email = 'owner@example.com';

  if profile_count <> 1 then
    raise exception 'profile bootstrap failed for owner';
  end if;
end $$;

create temp table bootstrap_state (
  family_id uuid not null,
  invitation_token text not null
) on commit drop;

grant select on bootstrap_state to authenticated;

insert into bootstrap_state (family_id, invitation_token)
select f.id, i.token
from public.create_default_family('Owner family') f
cross join public.create_family_invitation(f.id, 'invitee@example.com') i;

do $$
declare
  visible_expenses integer;
begin
  insert into public.expenses (family_id, paid_by, amount, category, expense_date, created_by)
  values (
    (select family_id from bootstrap_state),
    (select id from bootstrap_ids where name = 'owner'),
    25.00,
    'food',
    current_date,
    (select id from bootstrap_ids where name = 'owner')
  );

  select count(*)
  into visible_expenses
  from public.expenses
  where family_id = (select family_id from bootstrap_state);

  if visible_expenses <> 1 then
    raise exception 'owner cannot see own family expense';
  end if;
end $$;

reset role;

insert into auth.users (id, email, raw_user_meta_data)
values (
  (select id from bootstrap_ids where name = 'invitee'),
  'invitee@example.com',
  '{"display_name":"Invited Parent"}'::jsonb
);

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from bootstrap_ids where name = 'invitee'), true);

do $$
declare
  visible_before_accept integer;
begin
  select count(*)
  into visible_before_accept
  from public.expenses
  where family_id = (select family_id from bootstrap_state);

  if visible_before_accept <> 0 then
    raise exception 'pending invitation leaked family data before acceptance';
  end if;
end $$;

select public.accept_family_invitation((select invitation_token from bootstrap_state));

do $$
declare
  visible_after_accept integer;
  member_count integer;
begin
  select count(*)
  into visible_after_accept
  from public.expenses
  where family_id = (select family_id from bootstrap_state);

  if visible_after_accept <> 1 then
    raise exception 'accepted invitee cannot see family data';
  end if;

  select count(*)
  into member_count
  from public.family_members
  where family_id = (select family_id from bootstrap_state)
    and profile_id = (select id from bootstrap_ids where name = 'invitee')
    and status = 'active';

  if member_count <> 1 then
    raise exception 'accepted invitation did not create active family member';
  end if;
end $$;

rollback;
