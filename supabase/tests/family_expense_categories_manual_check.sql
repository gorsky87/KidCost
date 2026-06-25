-- Manual custom family expense category verification for issue #87.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/family_expense_categories_manual_check.sql
--
-- This script rolls back at the end.

begin;

create temp table family_category_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into family_category_ids (name, id)
values
  ('owner', gen_random_uuid()),
  ('co_parent', gen_random_uuid()),
  ('outsider', gen_random_uuid()),
  ('family_id', gen_random_uuid()),
  ('outsider_family_id', gen_random_uuid()),
  ('child_id', gen_random_uuid()),
  ('category_id', gen_random_uuid()),
  ('expense_id', gen_random_uuid());

grant select on family_category_ids to authenticated;

insert into auth.users (id, email, raw_user_meta_data)
values
  ((select id from family_category_ids where name = 'owner'), 'family-category-owner@example.com', '{"display_name":"Owner"}'::jsonb),
  ((select id from family_category_ids where name = 'co_parent'), 'family-category-co-parent@example.com', '{"display_name":"Co Parent"}'::jsonb),
  ((select id from family_category_ids where name = 'outsider'), 'family-category-outsider@example.com', '{"display_name":"Outsider"}'::jsonb);

insert into public.profiles (id, display_name, email)
values
  ((select id from family_category_ids where name = 'owner'), 'Owner', 'family-category-owner@example.com'),
  ((select id from family_category_ids where name = 'co_parent'), 'Co Parent', 'family-category-co-parent@example.com'),
  ((select id from family_category_ids where name = 'outsider'), 'Outsider', 'family-category-outsider@example.com')
on conflict (id) do update
set
  display_name = excluded.display_name,
  email = excluded.email,
  updated_at = now();

insert into public.families (id, name, created_by)
values
  (
    (select id from family_category_ids where name = 'family_id'),
    'Family category test',
    (select id from family_category_ids where name = 'owner')
  ),
  (
    (select id from family_category_ids where name = 'outsider_family_id'),
    'Outsider family',
    (select id from family_category_ids where name = 'outsider')
  );

insert into public.family_members (family_id, profile_id, role, status)
values
  (
    (select id from family_category_ids where name = 'family_id'),
    (select id from family_category_ids where name = 'owner'),
    'owner',
    'active'
  ),
  (
    (select id from family_category_ids where name = 'family_id'),
    (select id from family_category_ids where name = 'co_parent'),
    'parent',
    'active'
  ),
  (
    (select id from family_category_ids where name = 'outsider_family_id'),
    (select id from family_category_ids where name = 'outsider'),
    'owner',
    'active'
  );

insert into public.children (id, family_id, first_name)
values (
  (select id from family_category_ids where name = 'child_id'),
  (select id from family_category_ids where name = 'family_id'),
  'Maja'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from family_category_ids where name = 'owner'), true);

insert into public.family_expense_categories (
  id,
  family_id,
  name,
  icon_name,
  color_hex,
  report_group,
  created_by
)
values (
  (select id from family_category_ids where name = 'category_id'),
  (select id from family_category_ids where name = 'family_id'),
  'Wycieczki szkolne',
  'school-trip',
  '#2F6FED',
  'Szkola',
  (select id from family_category_ids where name = 'owner')
);

insert into public.expenses (
  id,
  family_id,
  child_id,
  paid_by,
  amount,
  category,
  family_expense_category_id,
  description,
  expense_date,
  status,
  created_by
)
values (
  (select id from family_category_ids where name = 'expense_id'),
  (select id from family_category_ids where name = 'family_id'),
  (select id from family_category_ids where name = 'child_id'),
  (select id from family_category_ids where name = 'owner'),
  125.00,
  'other',
  (select id from family_category_ids where name = 'category_id'),
  'Trip advance',
  '2026-06-05',
  'pending',
  (select id from family_category_ids where name = 'owner')
);

update public.family_expense_categories
set
  name = 'Wycieczki szkolne 2026',
  report_group = 'Szkola - archiwum',
  updated_by = (select id from family_category_ids where name = 'owner')
where id = (select id from family_category_ids where name = 'category_id');

update public.family_expense_categories
set
  archived_at = now(),
  archived_by = (select id from family_category_ids where name = 'owner')
where id = (select id from family_category_ids where name = 'category_id');

do $$
declare
  visible_category_count integer;
  archived_insert_blocked boolean := false;
  report jsonb;
  csv_export text;
  export_payload jsonb;
begin
  select count(*)
  into visible_category_count
  from public.family_expense_categories
  where family_id = (select id from family_category_ids where name = 'family_id');

  if visible_category_count <> 1 then
    raise exception 'family member should see one custom category, got %', visible_category_count;
  end if;

  if not exists (
    select 1
    from public.expenses
    where id = (select id from family_category_ids where name = 'expense_id')
      and category_name_snapshot = 'Wycieczki szkolne'
      and category_report_group_snapshot = 'Szkola'
  ) then
    raise exception 'expense should keep the original category snapshot';
  end if;

  if not exists (
    select 1
    from public.audit_events
    where entity_type = 'expense'
      and entity_id = (select id from family_category_ids where name = 'expense_id')
      and event_type = 'created'
      and metadata->>'categoryName' = 'Wycieczki szkolne'
      and metadata->>'categoryReportGroup' = 'Szkola'
  ) then
    raise exception 'expense audit event should include the category snapshot';
  end if;

  begin
    insert into public.expenses (
      family_id,
      child_id,
      paid_by,
      amount,
      category,
      family_expense_category_id,
      description,
      expense_date,
      status,
      created_by
    )
    values (
      (select id from family_category_ids where name = 'family_id'),
      (select id from family_category_ids where name = 'child_id'),
      (select id from family_category_ids where name = 'owner'),
      75.00,
      'other',
      (select id from family_category_ids where name = 'category_id'),
      'Archived category should be blocked',
      '2026-06-06',
      'pending',
      (select id from family_category_ids where name = 'owner')
    );
  exception
    when raise_exception then
      archived_insert_blocked := true;
  end;

  if not archived_insert_blocked then
    raise exception 'archived custom category should be blocked for new expenses';
  end if;

  report := public.monthly_expense_report(
    (select id from family_category_ids where name = 'family_id'),
    '2026-06-01'
  );

  if not exists (
    select 1
    from jsonb_array_elements(report->'byCategory') item
    where item->>'category' = 'Wycieczki szkolne'
      and item->>'reportGroup' = 'Szkola'
      and (item->>'totalCents')::bigint = 12500
  ) then
    raise exception 'monthly report should group by the historical custom category snapshot: %', report->'byCategory';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(report->'expenses') item
    where item->>'description' = 'Trip advance'
      and item->>'category' = 'Wycieczki szkolne'
      and item->>'categoryReportGroup' = 'Szkola'
      and item->>'defaultCategory' = 'other'
  ) then
    raise exception 'monthly report expense row should include category snapshot fields: %', report->'expenses';
  end if;

  csv_export := public.monthly_expense_report_csv(
    (select id from family_category_ids where name = 'family_id'),
    '2026-06-01'
  );

  if position('data,dziecko,kategoria,grupa_raportu,opis,płacący,kwota,status,typ_dowodu' in csv_export) <> 1 then
    raise exception 'custom category CSV header is wrong: %', csv_export;
  end if;

  if position('"2026-06-05","Maja","Wycieczki szkolne","Szkola","Trip advance","Owner","125.00","pending",""' in csv_export) = 0 then
    raise exception 'custom category CSV row is missing: %', csv_export;
  end if;

  export_payload := public.family_data_export(
    (select id from family_category_ids where name = 'family_id')
  );

  if (export_payload->'recordCounts'->>'familyExpenseCategories')::integer <> 1 then
    raise exception 'family export should count custom categories: %', export_payload->'recordCounts';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(export_payload->'familyExpenseCategories') item
    where item->>'name' = 'Wycieczki szkolne 2026'
      and item->>'reportGroup' = 'Szkola - archiwum'
      and item ? 'archivedAt'
  ) then
    raise exception 'family export should include archived custom category metadata';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(export_payload->'expenses') item
    where item->>'categoryName' = 'Wycieczki szkolne'
      and item->>'categoryReportGroup' = 'Szkola'
  ) then
    raise exception 'family export should include expense category snapshots';
  end if;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from family_category_ids where name = 'outsider'), true);

do $$
declare
  outsider_category_count integer;
begin
  select count(*)
  into outsider_category_count
  from public.family_expense_categories
  where family_id = (select id from family_category_ids where name = 'family_id');

  if outsider_category_count <> 0 then
    raise exception 'outsider should not see family custom categories';
  end if;
end $$;

rollback;
