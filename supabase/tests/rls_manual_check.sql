-- Manual RLS verification for issue #7.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls_manual_check.sql
--
-- This script creates demo auth users directly because it is a database-level
-- RLS smoke test. It rolls back at the end.

begin;

create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

create temp table rls_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into rls_ids (name, id)
values
  ('user_a', gen_random_uuid()),
  ('user_b', gen_random_uuid()),
  ('family_a', gen_random_uuid()),
  ('family_b', gen_random_uuid()),
  ('child_a', gen_random_uuid()),
  ('template_a', gen_random_uuid()),
  ('expense_a', gen_random_uuid()),
  ('attachment_a', gen_random_uuid());

insert into auth.users (id)
select id
from rls_ids
where name in ('user_a', 'user_b');

grant select on rls_ids to authenticated;

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from rls_ids where name = 'user_a'), true);

insert into public.profiles (id, display_name, email)
values ((select id from rls_ids where name = 'user_a'), 'Parent A', 'parent-a@example.com')
on conflict (id) do update
set display_name = excluded.display_name,
    email = excluded.email;

insert into public.families (id, name, created_by)
values (
  (select id from rls_ids where name = 'family_a'),
  'Family A',
  (select id from rls_ids where name = 'user_a')
);

insert into public.family_members (family_id, profile_id, role, status)
values (
  (select id from rls_ids where name = 'family_a'),
  (select id from rls_ids where name = 'user_a'),
  'owner',
  'active'
);

insert into public.children (id, family_id, first_name)
values (
  (select id from rls_ids where name = 'child_a'),
  (select id from rls_ids where name = 'family_a'),
  'Child A'
);

insert into public.expense_templates (
  id,
  family_id,
  child_id,
  name,
  amount,
  category,
  paid_by,
  recurrence,
  next_due_date,
  created_by
)
values (
  (select id from rls_ids where name = 'template_a'),
  (select id from rls_ids where name = 'family_a'),
  (select id from rls_ids where name = 'child_a'),
  'Monthly preschool',
  650.00,
  'school',
  (select id from rls_ids where name = 'user_a'),
  'monthly',
  current_date,
  (select id from rls_ids where name = 'user_a')
);

insert into public.expenses (
  id,
  family_id,
  child_id,
  paid_by,
  amount,
  category,
  expense_date,
  status,
  created_by,
  source_template_id
)
values (
  (select id from rls_ids where name = 'expense_a'),
  (select id from rls_ids where name = 'family_a'),
  (select id from rls_ids where name = 'child_a'),
  (select id from rls_ids where name = 'user_a'),
  123.45,
  'school',
  current_date,
  'accepted',
  (select id from rls_ids where name = 'user_a'),
  (select id from rls_ids where name = 'template_a')
);

insert into storage.objects (bucket_id, name)
values (
  'expense-attachments',
  'families/' || (select id from rls_ids where name = 'family_a') || '/expenses/' || (select id from rls_ids where name = 'expense_a') || '/receipt.pdf'
);

insert into public.expense_attachments (id, expense_id, storage_path, file_type, uploaded_by)
values (
  (select id from rls_ids where name = 'attachment_a'),
  (select id from rls_ids where name = 'expense_a'),
  'families/' || (select id from rls_ids where name = 'family_a') || '/expenses/' || (select id from rls_ids where name = 'expense_a') || '/receipt.pdf',
  'pdf',
  (select id from rls_ids where name = 'user_a')
);

do $$
begin
  begin
    update public.expenses
    set amount = 999.99
    where id = (select id from rls_ids where name = 'expense_a');
    raise exception 'finalized expense rewrite was allowed';
  exception
    when raise_exception then
      null;
  end;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from rls_ids where name = 'user_b'), true);

insert into public.profiles (id, display_name, email)
values ((select id from rls_ids where name = 'user_b'), 'Parent B', 'parent-b@example.com')
on conflict (id) do update
set display_name = excluded.display_name,
    email = excluded.email;

insert into public.families (id, name, created_by)
values (
  (select id from rls_ids where name = 'family_b'),
  'Family B',
  (select id from rls_ids where name = 'user_b')
);

insert into public.family_members (family_id, profile_id, role, status)
values (
  (select id from rls_ids where name = 'family_b'),
  (select id from rls_ids where name = 'user_b'),
  'owner',
  'active'
);

do $$
declare
  outsider_count integer;
begin
  select count(*)
  into outsider_count
  from public.expenses
  where id = (select id from rls_ids where name = 'expense_a');

  if outsider_count <> 0 then
    raise exception 'RLS leak: user B can see user A expense';
  end if;

  select count(*)
  into outsider_count
  from public.expense_templates
  where id = (select id from rls_ids where name = 'template_a');

  if outsider_count <> 0 then
    raise exception 'RLS leak: user B can see user A expense template';
  end if;

  begin
    insert into public.expenses (family_id, child_id, paid_by, amount, category, expense_date, created_by)
    values (
      (select id from rls_ids where name = 'family_a'),
      (select id from rls_ids where name = 'child_a'),
      (select id from rls_ids where name = 'user_b'),
      10.00,
      'food',
      current_date,
      (select id from rls_ids where name = 'user_b')
    );
    raise exception 'RLS leak: user B inserted into user A family';
  exception
    when insufficient_privilege or raise_exception or check_violation or foreign_key_violation then
      null;
  end;

  select count(*)
  into outsider_count
  from public.expense_attachments
  where id = (select id from rls_ids where name = 'attachment_a');

  if outsider_count <> 0 then
    raise exception 'RLS leak: user B can see user A attachment';
  end if;
end $$;

rollback;
