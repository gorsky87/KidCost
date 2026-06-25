-- Manual duplicate bill detection verification for issue #58.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/duplicate_bill_detection_manual_check.sql
--
-- This script rolls back at the end.

begin;

create temp table duplicate_bill_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into duplicate_bill_ids (name, id)
values
  ('owner', gen_random_uuid()),
  ('co_parent', gen_random_uuid()),
  ('outsider', gen_random_uuid()),
  ('family_id', gen_random_uuid()),
  ('outsider_family_id', gen_random_uuid()),
  ('child_id', gen_random_uuid()),
  ('expense_original', gen_random_uuid()),
  ('expense_other', gen_random_uuid()),
  ('attachment_original', gen_random_uuid()),
  ('related_link', gen_random_uuid());

grant select on duplicate_bill_ids to authenticated;

insert into auth.users (id, email, raw_user_meta_data)
values
  ((select id from duplicate_bill_ids where name = 'owner'), 'duplicate-owner@example.com', '{"display_name":"Owner"}'::jsonb),
  ((select id from duplicate_bill_ids where name = 'co_parent'), 'duplicate-co-parent@example.com', '{"display_name":"Co Parent"}'::jsonb),
  ((select id from duplicate_bill_ids where name = 'outsider'), 'duplicate-outsider@example.com', '{"display_name":"Outsider"}'::jsonb);

insert into public.profiles (id, display_name, email)
values
  ((select id from duplicate_bill_ids where name = 'owner'), 'Owner', 'duplicate-owner@example.com'),
  ((select id from duplicate_bill_ids where name = 'co_parent'), 'Co Parent', 'duplicate-co-parent@example.com'),
  ((select id from duplicate_bill_ids where name = 'outsider'), 'Outsider', 'duplicate-outsider@example.com')
on conflict (id) do update
set
  display_name = excluded.display_name,
  email = excluded.email,
  updated_at = now();

insert into public.families (id, name, created_by)
values
  (
    (select id from duplicate_bill_ids where name = 'family_id'),
    'Duplicate bill family',
    (select id from duplicate_bill_ids where name = 'owner')
  ),
  (
    (select id from duplicate_bill_ids where name = 'outsider_family_id'),
    'Outsider family',
    (select id from duplicate_bill_ids where name = 'outsider')
  );

insert into public.family_members (family_id, profile_id, role, status)
values
  (
    (select id from duplicate_bill_ids where name = 'family_id'),
    (select id from duplicate_bill_ids where name = 'owner'),
    'owner',
    'active'
  ),
  (
    (select id from duplicate_bill_ids where name = 'family_id'),
    (select id from duplicate_bill_ids where name = 'co_parent'),
    'parent',
    'active'
  ),
  (
    (select id from duplicate_bill_ids where name = 'outsider_family_id'),
    (select id from duplicate_bill_ids where name = 'outsider'),
    'owner',
    'active'
  );

insert into public.children (id, family_id, first_name)
values (
  (select id from duplicate_bill_ids where name = 'child_id'),
  (select id from duplicate_bill_ids where name = 'family_id'),
  'Antek'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from duplicate_bill_ids where name = 'owner'), true);

insert into public.expenses (
  id,
  family_id,
  child_id,
  paid_by,
  amount,
  currency,
  category,
  description,
  expense_date,
  status,
  created_by
)
values
  (
    (select id from duplicate_bill_ids where name = 'expense_original'),
    (select id from duplicate_bill_ids where name = 'family_id'),
    (select id from duplicate_bill_ids where name = 'child_id'),
    (select id from duplicate_bill_ids where name = 'owner'),
    120.00,
    'PLN',
    'health',
    'Ortodonta',
    '2026-06-20',
    'accepted',
    (select id from duplicate_bill_ids where name = 'owner')
  ),
  (
    (select id from duplicate_bill_ids where name = 'expense_other'),
    (select id from duplicate_bill_ids where name = 'family_id'),
    (select id from duplicate_bill_ids where name = 'child_id'),
    (select id from duplicate_bill_ids where name = 'owner'),
    120.50,
    'PLN',
    'health',
    'Inny gabinet',
    '2026-08-20',
    'pending',
    (select id from duplicate_bill_ids where name = 'owner')
  );

insert into storage.objects (bucket_id, name)
values (
  'expense-attachments',
  'families/' || (select id from duplicate_bill_ids where name = 'family_id') || '/expenses/' || (select id from duplicate_bill_ids where name = 'expense_original') || '/fv-7.pdf'
);

insert into public.expense_attachments (
  id,
  expense_id,
  storage_path,
  file_type,
  original_filename,
  uploaded_by,
  evidence_type,
  service_date,
  document_date,
  merchant,
  document_number
)
values (
  (select id from duplicate_bill_ids where name = 'attachment_original'),
  (select id from duplicate_bill_ids where name = 'expense_original'),
  'families/' || (select id from duplicate_bill_ids where name = 'family_id') || '/expenses/' || (select id from duplicate_bill_ids where name = 'expense_original') || '/fv-7.pdf',
  'pdf',
  'fv-7.pdf',
  (select id from duplicate_bill_ids where name = 'owner'),
  'invoice',
  '2026-06-20',
  '2026-06-21',
  'Orto Dent',
  'FV-7'
);

do $$
declare
  exact_count integer;
  provider_count integer;
  false_positive_count integer;
begin
  select count(*)
  into exact_count
  from public.find_potential_duplicate_expenses(
    (select id from duplicate_bill_ids where name = 'family_id'),
    (select id from duplicate_bill_ids where name = 'child_id'),
    'health',
    999.99,
    null,
    null,
    null,
    'fv-7'
  )
  where 'same_document_number' = any(match_reasons);

  if exact_count <> 1 then
    raise exception 'expected one exact document-number duplicate, got %', exact_count;
  end if;

  select count(*)
  into provider_count
  from public.find_potential_duplicate_expenses(
    (select id from duplicate_bill_ids where name = 'family_id'),
    (select id from duplicate_bill_ids where name = 'child_id'),
    'health',
    121.00,
    'orto dent',
    '2026-06-22',
    null,
    null
  )
  where 'same_provider' = any(match_reasons)
    and 'similar_service_or_document_date' = any(match_reasons)
    and 'similar_amount' = any(match_reasons);

  if provider_count <> 1 then
    raise exception 'expected one provider/date/amount duplicate, got %', provider_count;
  end if;

  select count(*)
  into false_positive_count
  from public.find_potential_duplicate_expenses(
    (select id from duplicate_bill_ids where name = 'family_id'),
    (select id from duplicate_bill_ids where name = 'child_id'),
    'health',
    121.00,
    'Inna klinika',
    '2026-09-20',
    null,
    null
  );

  if false_positive_count <> 0 then
    raise exception 'expected no false-positive duplicates, got %', false_positive_count;
  end if;
end $$;

insert into public.expense_related_records (
  id,
  family_id,
  source_expense_id,
  related_expense_id,
  linked_by
)
values (
  (select id from duplicate_bill_ids where name = 'related_link'),
  (select id from duplicate_bill_ids where name = 'family_id'),
  (select id from duplicate_bill_ids where name = 'expense_other'),
  (select id from duplicate_bill_ids where name = 'expense_original'),
  (select id from duplicate_bill_ids where name = 'owner')
);

do $$
declare
  visible_links integer;
begin
  select count(*)
  into visible_links
  from public.expense_related_records
  where family_id = (select id from duplicate_bill_ids where name = 'family_id');

  if visible_links <> 1 then
    raise exception 'expected owner to see one related-record link, got %', visible_links;
  end if;
end $$;

rollback;
