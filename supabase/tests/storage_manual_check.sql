-- Manual Storage verification for issue #9.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/storage_manual_check.sql
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

create temp table storage_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into storage_ids (name, id)
values
  ('owner', gen_random_uuid()),
  ('outsider', gen_random_uuid()),
  ('family_id', gen_random_uuid()),
  ('expense_id', gen_random_uuid()),
  ('attachment_id', gen_random_uuid());

grant select on storage_ids to authenticated;

insert into auth.users (id, email, raw_user_meta_data)
values
  ((select id from storage_ids where name = 'owner'), 'owner-storage@example.com', '{"display_name":"Owner"}'::jsonb),
  ((select id from storage_ids where name = 'outsider'), 'outsider-storage@example.com', '{"display_name":"Outsider"}'::jsonb);

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from storage_ids where name = 'owner'), true);

insert into public.families (id, name, created_by)
values (
  (select id from storage_ids where name = 'family_id'),
  'Storage family',
  (select id from storage_ids where name = 'owner')
);

insert into public.family_members (family_id, profile_id, role, status)
values (
  (select id from storage_ids where name = 'family_id'),
  (select id from storage_ids where name = 'owner'),
  'owner',
  'active'
);

insert into public.expenses (id, family_id, paid_by, amount, category, expense_date, created_by)
values (
  (select id from storage_ids where name = 'expense_id'),
  (select id from storage_ids where name = 'family_id'),
  (select id from storage_ids where name = 'owner'),
  19.99,
  'school',
  current_date,
  (select id from storage_ids where name = 'owner')
);

insert into storage.objects (bucket_id, name)
values (
  'expense-attachments',
  'families/' || (select id from storage_ids where name = 'family_id') || '/expenses/' || (select id from storage_ids where name = 'expense_id') || '/receipt.pdf'
);

insert into public.expense_attachments (
  id,
  expense_id,
  storage_path,
  file_type,
  uploaded_by,
  evidence_type,
  document_date,
  merchant,
  document_number,
  payment_method,
  buyer_name_present
)
values (
  (select id from storage_ids where name = 'attachment_id'),
  (select id from storage_ids where name = 'expense_id'),
  'families/' || (select id from storage_ids where name = 'family_id') || '/expenses/' || (select id from storage_ids where name = 'expense_id') || '/receipt.pdf',
  'pdf',
  (select id from storage_ids where name = 'owner'),
  'invoice',
  current_date,
  'Apteka Testowa',
  'FV/2026/06',
  'card',
  true
);

do $$
declare
  visible_objects integer;
  visible_metadata integer;
begin
  select count(*) into visible_objects from storage.objects where bucket_id = 'expense-attachments';
  select count(*) into visible_metadata from public.expense_attachments;

  if visible_objects <> 1 or visible_metadata <> 1 then
    raise exception 'family owner cannot see uploaded attachment object and metadata';
  end if;

  if not exists (
    select 1
    from public.expense_attachments
    where id = (select id from storage_ids where name = 'attachment_id')
      and evidence_type = 'invoice'
      and merchant = 'Apteka Testowa'
      and buyer_name_present is true
  ) then
    raise exception 'family owner cannot read expense evidence metadata';
  end if;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from storage_ids where name = 'outsider'), true);

do $$
declare
  visible_objects integer;
  visible_metadata integer;
begin
  select count(*) into visible_objects from storage.objects where bucket_id = 'expense-attachments';
  select count(*) into visible_metadata from public.expense_attachments;

  if visible_objects <> 0 or visible_metadata <> 0 then
    raise exception 'outsider can see attachment object or metadata';
  end if;

  begin
    insert into storage.objects (bucket_id, name)
    values (
      'expense-attachments',
      'families/' || (select id from storage_ids where name = 'family_id') || '/expenses/' || (select id from storage_ids where name = 'expense_id') || '/outsider.pdf'
    );
    raise exception 'outsider inserted storage object into another family';
  exception
    when insufficient_privilege or raise_exception or check_violation then
      null;
  end;
end $$;

rollback;
