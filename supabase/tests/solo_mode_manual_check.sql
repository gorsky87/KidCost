-- Manual solo-mode RLS verification for issue #36.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/solo_mode_manual_check.sql

begin;

create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

create temp table solo_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into solo_ids (name, id)
values
  ('user_a', gen_random_uuid()),
  ('user_b', gen_random_uuid()),
  ('family_a', gen_random_uuid()),
  ('child_a', gen_random_uuid()),
  ('private_expense', gen_random_uuid()),
  ('shared_expense', gen_random_uuid());

insert into auth.users (id)
select id
from solo_ids
where name in ('user_a', 'user_b');

grant select on solo_ids to authenticated;

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from solo_ids where name = 'user_a'), true);

insert into public.profiles (id, display_name, email)
values ((select id from solo_ids where name = 'user_a'), 'Parent A', 'parent-a@example.com');

insert into public.families (id, name, created_by)
values (
  (select id from solo_ids where name = 'family_a'),
  'Solo Family',
  (select id from solo_ids where name = 'user_a')
);

insert into public.family_members (family_id, profile_id, role, status)
values (
  (select id from solo_ids where name = 'family_a'),
  (select id from solo_ids where name = 'user_a'),
  'owner',
  'active'
);

insert into public.children (id, family_id, first_name)
values (
  (select id from solo_ids where name = 'child_a'),
  (select id from solo_ids where name = 'family_a'),
  'Child A'
);

insert into public.expenses (
  id,
  family_id,
  child_id,
  payer_kind,
  manual_payer_label,
  amount,
  category,
  expense_date,
  visibility,
  created_by
)
values (
  (select id from solo_ids where name = 'private_expense'),
  (select id from solo_ids where name = 'family_a'),
  (select id from solo_ids where name = 'child_a'),
  'manual_label',
  'Mama Oli',
  20.00,
  'health',
  current_date,
  'private_author',
  (select id from solo_ids where name = 'user_a')
);

insert into public.expenses (
  id,
  family_id,
  child_id,
  paid_by,
  amount,
  category,
  expense_date,
  visibility,
  created_by
)
values (
  (select id from solo_ids where name = 'shared_expense'),
  (select id from solo_ids where name = 'family_a'),
  (select id from solo_ids where name = 'child_a'),
  (select id from solo_ids where name = 'user_a'),
  12.00,
  'food',
  current_date,
  'shared_family',
  (select id from solo_ids where name = 'user_a')
);

do $$
declare
  visible_count integer;
begin
  select count(*)
  into visible_count
  from public.expenses
  where id in (
    (select id from solo_ids where name = 'private_expense'),
    (select id from solo_ids where name = 'shared_expense')
  );

  if visible_count <> 2 then
    raise exception 'solo author should see both private and shared expenses';
  end if;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from solo_ids where name = 'user_b'), true);

insert into public.profiles (id, display_name, email)
values ((select id from solo_ids where name = 'user_b'), 'Parent B', 'parent-b@example.com');

select set_config('request.jwt.claim.sub', (select id::text from solo_ids where name = 'user_a'), true);

insert into public.family_members (family_id, profile_id, role, status)
values (
  (select id from solo_ids where name = 'family_a'),
  (select id from solo_ids where name = 'user_b'),
  'parent',
  'active'
);

select set_config('request.jwt.claim.sub', (select id::text from solo_ids where name = 'user_b'), true);

do $$
declare
  private_count integer;
  shared_count integer;
begin
  select count(*)
  into private_count
  from public.expenses
  where id = (select id from solo_ids where name = 'private_expense');

  if private_count <> 0 then
    raise exception 'joined co-parent can see private solo expense';
  end if;

  select count(*)
  into shared_count
  from public.expenses
  where id = (select id from solo_ids where name = 'shared_expense');

  if shared_count <> 1 then
    raise exception 'joined co-parent cannot see shared expense';
  end if;
end $$;

rollback;
