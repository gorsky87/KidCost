-- Manual monthly report verification for issue #30.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/monthly_report_manual_check.sql
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

create temp table monthly_report_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into monthly_report_ids (name, id)
values
  ('owner', gen_random_uuid()),
  ('co_parent', gen_random_uuid()),
  ('outsider', gen_random_uuid()),
  ('family_id', gen_random_uuid()),
  ('outsider_family_id', gen_random_uuid()),
  ('child_a', gen_random_uuid()),
  ('child_b', gen_random_uuid()),
  ('expense_books', gen_random_uuid()),
  ('attachment_books', gen_random_uuid());

grant select on monthly_report_ids to authenticated;

insert into auth.users (id, email, raw_user_meta_data)
values
  ((select id from monthly_report_ids where name = 'owner'), 'monthly-owner@example.com', '{"display_name":"Owner"}'::jsonb),
  ((select id from monthly_report_ids where name = 'co_parent'), 'monthly-co-parent@example.com', '{"display_name":"Co Parent"}'::jsonb),
  ((select id from monthly_report_ids where name = 'outsider'), 'monthly-outsider@example.com', '{"display_name":"Outsider"}'::jsonb);

insert into public.profiles (id, display_name, email)
values
  ((select id from monthly_report_ids where name = 'owner'), 'Owner', 'monthly-owner@example.com'),
  ((select id from monthly_report_ids where name = 'co_parent'), 'Co Parent', 'monthly-co-parent@example.com'),
  ((select id from monthly_report_ids where name = 'outsider'), 'Outsider', 'monthly-outsider@example.com');

insert into public.families (id, name, created_by)
values
  (
    (select id from monthly_report_ids where name = 'family_id'),
    'Monthly report family',
    (select id from monthly_report_ids where name = 'owner')
  ),
  (
    (select id from monthly_report_ids where name = 'outsider_family_id'),
    'Outsider family',
    (select id from monthly_report_ids where name = 'outsider')
  );

insert into public.family_members (family_id, profile_id, role, status)
values
  (
    (select id from monthly_report_ids where name = 'family_id'),
    (select id from monthly_report_ids where name = 'owner'),
    'owner',
    'active'
  ),
  (
    (select id from monthly_report_ids where name = 'family_id'),
    (select id from monthly_report_ids where name = 'co_parent'),
    'parent',
    'active'
  ),
  (
    (select id from monthly_report_ids where name = 'outsider_family_id'),
    (select id from monthly_report_ids where name = 'outsider'),
    'owner',
    'active'
  );

insert into public.children (id, family_id, first_name)
values
  (
    (select id from monthly_report_ids where name = 'child_a'),
    (select id from monthly_report_ids where name = 'family_id'),
    'Child A'
  ),
  (
    (select id from monthly_report_ids where name = 'child_b'),
    (select id from monthly_report_ids where name = 'family_id'),
    'Child B'
  );

insert into public.expenses (
  id,
  family_id,
  child_id,
  paid_by,
  amount,
  category,
  description,
  expense_date,
  status,
  created_by
)
values
  (
    (select id from monthly_report_ids where name = 'expense_books'),
    (select id from monthly_report_ids where name = 'family_id'),
    (select id from monthly_report_ids where name = 'child_a'),
    (select id from monthly_report_ids where name = 'owner'),
    120.00,
    'school',
    'Books',
    '2026-06-03',
    'accepted',
    (select id from monthly_report_ids where name = 'owner')
  ),
  (
    gen_random_uuid(),
    (select id from monthly_report_ids where name = 'family_id'),
    (select id from monthly_report_ids where name = 'child_b'),
    (select id from monthly_report_ids where name = 'co_parent'),
    35.50,
    'food',
    'Lunch',
    '2026-06-04',
    'disputed',
    (select id from monthly_report_ids where name = 'co_parent')
  ),
  (
    gen_random_uuid(),
    (select id from monthly_report_ids where name = 'family_id'),
    null,
    (select id from monthly_report_ids where name = 'owner'),
    50.00,
    'transport',
    null,
    '2026-06-20',
    'pending',
    (select id from monthly_report_ids where name = 'owner')
  ),
  (
    gen_random_uuid(),
    (select id from monthly_report_ids where name = 'family_id'),
    (select id from monthly_report_ids where name = 'child_a'),
    (select id from monthly_report_ids where name = 'owner'),
    999.00,
    'school',
    'Previous month',
    '2026-05-31',
    'accepted',
    (select id from monthly_report_ids where name = 'owner')
  );

insert into storage.objects (bucket_id, name)
values (
  'expense-attachments',
  'families/' || (select id from monthly_report_ids where name = 'family_id') || '/expenses/' || (select id from monthly_report_ids where name = 'expense_books') || '/books.pdf'
);

insert into public.expense_attachments (
  id,
  expense_id,
  storage_path,
  file_type,
  original_filename,
  uploaded_by,
  evidence_type,
  merchant,
  document_number,
  buyer_name_present
)
values (
  (select id from monthly_report_ids where name = 'attachment_books'),
  (select id from monthly_report_ids where name = 'expense_books'),
  'families/' || (select id from monthly_report_ids where name = 'family_id') || '/expenses/' || (select id from monthly_report_ids where name = 'expense_books') || '/books.pdf',
  'pdf',
  'books.pdf',
  (select id from monthly_report_ids where name = 'owner'),
  'invoice',
  'Bookstore',
  'FV/BOOKS/2026',
  true
);

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from monthly_report_ids where name = 'owner'), true);

do $$
declare
  report jsonb;
  empty_report jsonb;
  csv_export text;
begin
  report := public.monthly_expense_report(
    (select id from monthly_report_ids where name = 'family_id'),
    '2026-06-10'
  );

  if (report->>'totalCents')::bigint <> 20550 then
    raise exception 'monthly report total is wrong: %', report->>'totalCents';
  end if;

  if (report->>'expenseCount')::integer <> 3 then
    raise exception 'monthly report expense count is wrong: %', report->>'expenseCount';
  end if;

  if jsonb_array_length(report->'byParent') <> 2 then
    raise exception 'monthly report parent aggregation is wrong';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(report->'byCategory') item
    where item->>'category' = 'school'
      and (item->>'totalCents')::bigint = 12000
  ) then
    raise exception 'monthly report category aggregation is wrong';
  end if;

  if jsonb_array_length(report->'openExpenses') <> 3 then
    raise exception 'monthly report open expense list is wrong';
  end if;

  empty_report := public.monthly_expense_report(
    (select id from monthly_report_ids where name = 'family_id'),
    '2026-07-01'
  );

  if (empty_report->>'totalCents')::bigint <> 0
    or (empty_report->>'expenseCount')::integer <> 0
    or jsonb_array_length(empty_report->'expenses') <> 0 then
    raise exception 'empty monthly report should return zero totals and empty lists';
  end if;

  csv_export := public.monthly_expense_report_csv(
    (select id from monthly_report_ids where name = 'family_id'),
    '2026-06-01'
  );

  if position('data,dziecko,kategoria,opis,płacący,kwota,status,typ_dowodu' in csv_export) <> 1 then
    raise exception 'monthly report CSV header is wrong: %', csv_export;
  end if;

  if position('"2026-06-03","Child A","school","Books","Owner","120.00","accepted","invoice"' in csv_export) = 0 then
    raise exception 'monthly report CSV row is missing: %', csv_export;
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(report->'expenses') item
    where item->>'description' = 'Books'
      and item->>'evidenceType' = 'invoice'
  ) then
    raise exception 'monthly report JSON should include evidenceType';
  end if;

  if public.monthly_expense_report_csv(
    (select id from monthly_report_ids where name = 'family_id'),
    '2026-07-01'
  ) <> 'data,dziecko,kategoria,opis,płacący,kwota,status,typ_dowodu' then
    raise exception 'empty monthly report CSV should contain only a header';
  end if;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from monthly_report_ids where name = 'outsider'), true);

do $$
declare
  report_denied boolean := false;
  csv_denied boolean := false;
begin
  begin
    perform public.monthly_expense_report(
      (select id from monthly_report_ids where name = 'family_id'),
      '2026-06-01'
    );
  exception
    when insufficient_privilege or raise_exception then
      report_denied := true;
  end;

  if not report_denied then
    raise exception 'outsider can read another family monthly report';
  end if;

  begin
    perform public.monthly_expense_report_csv(
      (select id from monthly_report_ids where name = 'family_id'),
      '2026-06-01'
    );
  exception
    when insufficient_privilege or raise_exception then
      csv_denied := true;
  end;

  if not csv_denied then
    raise exception 'outsider can export another family monthly report CSV';
  end if;
end $$;

rollback;
