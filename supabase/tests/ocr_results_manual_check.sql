-- Manual OCR result verification for issue #33.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/ocr_results_manual_check.sql
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

create temp table ocr_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into ocr_ids (name, id)
values
  ('owner', gen_random_uuid()),
  ('outsider', gen_random_uuid()),
  ('family_id', gen_random_uuid()),
  ('outsider_family_id', gen_random_uuid()),
  ('expense_id', gen_random_uuid()),
  ('attachment_id', gen_random_uuid());

grant select on ocr_ids to authenticated;

insert into auth.users (id, email, raw_user_meta_data)
values
  ((select id from ocr_ids where name = 'owner'), 'ocr-owner@example.com', '{"display_name":"Owner"}'::jsonb),
  ((select id from ocr_ids where name = 'outsider'), 'ocr-outsider@example.com', '{"display_name":"Outsider"}'::jsonb);

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from ocr_ids where name = 'owner'), true);

insert into public.families (id, name, created_by)
values (
  (select id from ocr_ids where name = 'family_id'),
  'OCR family',
  (select id from ocr_ids where name = 'owner')
);

insert into public.family_members (family_id, profile_id, role, status)
values (
  (select id from ocr_ids where name = 'family_id'),
  (select id from ocr_ids where name = 'owner'),
  'owner',
  'active'
);

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
values (
  (select id from ocr_ids where name = 'expense_id'),
  (select id from ocr_ids where name = 'family_id'),
  (select id from ocr_ids where name = 'owner'),
  10.00,
  'school',
  'Manual amount stays authoritative',
  '2026-06-24',
  (select id from ocr_ids where name = 'owner')
);

insert into storage.objects (bucket_id, name)
values (
  'expense-attachments',
  'families/' || (select id from ocr_ids where name = 'family_id') || '/expenses/' || (select id from ocr_ids where name = 'expense_id') || '/receipt.pdf'
);

insert into public.expense_attachments (id, expense_id, storage_path, file_type, uploaded_by)
values (
  (select id from ocr_ids where name = 'attachment_id'),
  (select id from ocr_ids where name = 'expense_id'),
  'families/' || (select id from ocr_ids where name = 'family_id') || '/expenses/' || (select id from ocr_ids where name = 'expense_id') || '/receipt.pdf',
  'pdf',
  (select id from ocr_ids where name = 'owner')
);

do $$
declare
  queued_count integer;
begin
  select count(*)
  into queued_count
  from public.ocr_results
  where attachment_id = (select id from ocr_ids where name = 'attachment_id')
    and status = 'queued'
    and requires_review = true;

  if queued_count <> 1 then
    raise exception 'attachment should create one queued OCR result';
  end if;
end $$;

select public.save_ocr_result(
  (select id from ocr_ids where name = 'attachment_id'),
  'needs_review',
  42.99,
  'PLN',
  '2026-06-23',
  'Receipt Shop',
  0.840,
  '{"provider":"manual-test","fields":["amount","date","merchant"]}'::jsonb,
  null
);

do $$
declare
  manual_amount numeric;
  manual_date date;
  result_count integer;
begin
  select amount, expense_date
  into manual_amount, manual_date
  from public.expenses
  where id = (select id from ocr_ids where name = 'expense_id');

  if manual_amount <> 10.00 or manual_date <> '2026-06-24'::date then
    raise exception 'OCR result overwrote manually entered expense data';
  end if;

  select count(*)
  into result_count
  from public.ocr_results
  where attachment_id = (select id from ocr_ids where name = 'attachment_id')
    and status = 'needs_review'
    and extracted_amount = 42.99
    and extracted_date = '2026-06-23'
    and merchant = 'Receipt Shop'
    and confidence = 0.840
    and requires_review = true;

  if result_count <> 1 then
    raise exception 'OCR result was not saved for user review';
  end if;
end $$;

select public.save_ocr_result(
  (select id from ocr_ids where name = 'attachment_id'),
  'failed',
  null,
  null,
  null,
  null,
  null,
  '{"provider":"manual-test"}'::jsonb,
  'OCR provider timeout'
);

do $$
declare
  expense_count integer;
  failed_count integer;
begin
  select count(*)
  into expense_count
  from public.expenses
  where id = (select id from ocr_ids where name = 'expense_id');

  select count(*)
  into failed_count
  from public.ocr_results
  where attachment_id = (select id from ocr_ids where name = 'attachment_id')
    and status = 'failed'
    and error_message = 'OCR provider timeout';

  if expense_count <> 1 or failed_count <> 1 then
    raise exception 'failed OCR should preserve the expense and save the error';
  end if;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from ocr_ids where name = 'outsider'), true);

insert into public.families (id, name, created_by)
values (
  (select id from ocr_ids where name = 'outsider_family_id'),
  'OCR outsider family',
  (select id from ocr_ids where name = 'outsider')
);

insert into public.family_members (family_id, profile_id, role, status)
values (
  (select id from ocr_ids where name = 'outsider_family_id'),
  (select id from ocr_ids where name = 'outsider'),
  'owner',
  'active'
);

do $$
declare
  outsider_results integer;
  save_denied boolean := false;
begin
  select count(*)
  into outsider_results
  from public.ocr_results
  where attachment_id = (select id from ocr_ids where name = 'attachment_id');

  if outsider_results <> 0 then
    raise exception 'outsider can see OCR result from another family';
  end if;

  begin
    perform public.save_ocr_result(
      (select id from ocr_ids where name = 'attachment_id'),
      'processed',
      12.00,
      'PLN',
      '2026-06-24',
      'Outsider',
      0.900,
      '{}'::jsonb,
      null
    );
  exception
    when insufficient_privilege or raise_exception then
      save_denied := true;
  end;

  if not save_denied then
    raise exception 'outsider saved OCR result for another family';
  end if;
end $$;

rollback;
