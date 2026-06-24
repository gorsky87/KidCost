-- Manual custody calendar verification for issue #19.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/custody_calendar_manual_check.sql
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

create temp table custody_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into custody_ids (name, id)
values
  ('owner', gen_random_uuid()),
  ('co_parent', gen_random_uuid()),
  ('outsider', gen_random_uuid()),
  ('family_id', gen_random_uuid()),
  ('outsider_family_id', gen_random_uuid()),
  ('child_id', gen_random_uuid());

grant select on custody_ids to authenticated;

insert into auth.users (id, email, raw_user_meta_data)
values
  ((select id from custody_ids where name = 'owner'), 'owner-custody@example.com', '{"display_name":"Owner"}'::jsonb),
  ((select id from custody_ids where name = 'co_parent'), 'co-parent-custody@example.com', '{"display_name":"Co Parent"}'::jsonb),
  ((select id from custody_ids where name = 'outsider'), 'outsider-custody@example.com', '{"display_name":"Outsider"}'::jsonb);

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from custody_ids where name = 'owner'), true);

insert into public.families (id, name, created_by)
values (
  (select id from custody_ids where name = 'family_id'),
  'Custody family',
  (select id from custody_ids where name = 'owner')
);

insert into public.family_members (family_id, profile_id, role, status)
values
  (
    (select id from custody_ids where name = 'family_id'),
    (select id from custody_ids where name = 'owner'),
    'owner',
    'active'
  ),
  (
    (select id from custody_ids where name = 'family_id'),
    (select id from custody_ids where name = 'co_parent'),
    'parent',
    'active'
  );

insert into public.children (id, family_id, first_name)
values (
  (select id from custody_ids where name = 'child_id'),
  (select id from custody_ids where name = 'family_id'),
  'Child A'
);

insert into public.custody_days (
  family_id,
  child_id,
  custody_date,
  caregiver_id,
  created_by
)
values (
  (select id from custody_ids where name = 'family_id'),
  (select id from custody_ids where name = 'child_id'),
  current_date,
  (select id from custody_ids where name = 'owner'),
  (select id from custody_ids where name = 'owner')
);

do $$
declare
  visible_days integer;
begin
  select count(*)
  into visible_days
  from public.custody_days
  where family_id = (select id from custody_ids where name = 'family_id');

  if visible_days <> 1 then
    raise exception 'owner cannot see own custody day';
  end if;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from custody_ids where name = 'co_parent'), true);

update public.custody_days
set
  caregiver_id = (select id from custody_ids where name = 'co_parent'),
  updated_by = (select id from custody_ids where name = 'co_parent')
where family_id = (select id from custody_ids where name = 'family_id');

do $$
declare
  co_parent_days integer;
begin
  select count(*)
  into co_parent_days
  from public.custody_days
  where caregiver_id = (select id from custody_ids where name = 'co_parent');

  if co_parent_days <> 1 then
    raise exception 'co-parent could not update custody day';
  end if;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from custody_ids where name = 'outsider'), true);

insert into public.families (id, name, created_by)
values (
  (select id from custody_ids where name = 'outsider_family_id'),
  'Outsider family',
  (select id from custody_ids where name = 'outsider')
);

insert into public.family_members (family_id, profile_id, role, status)
values (
  (select id from custody_ids where name = 'outsider_family_id'),
  (select id from custody_ids where name = 'outsider'),
  'owner',
  'active'
);

do $$
declare
  outsider_days integer;
begin
  select count(*)
  into outsider_days
  from public.custody_days
  where family_id = (select id from custody_ids where name = 'family_id');

  if outsider_days <> 0 then
    raise exception 'outsider can see custody days from another family';
  end if;

  begin
    insert into public.custody_days (
      family_id,
      child_id,
      custody_date,
      caregiver_id,
      created_by
    )
    values (
      (select id from custody_ids where name = 'family_id'),
      (select id from custody_ids where name = 'child_id'),
      current_date + 1,
      (select id from custody_ids where name = 'outsider'),
      (select id from custody_ids where name = 'outsider')
    );
    raise exception 'outsider inserted custody day into another family';
  exception
    when insufficient_privilege or raise_exception or check_violation or foreign_key_violation then
      null;
  end;
end $$;

rollback;
