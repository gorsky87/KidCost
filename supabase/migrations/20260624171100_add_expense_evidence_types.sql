-- KidCost expense evidence metadata.
-- Scope: issue #40.

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'evidence_type'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.evidence_type as enum (
      'receipt',
      'invoice',
      'bank_confirmation',
      'online_order',
      'other'
    );
  end if;
end $$;

alter table public.expense_attachments
  add column if not exists evidence_type public.evidence_type,
  add column if not exists document_date date,
  add column if not exists merchant text,
  add column if not exists document_number text,
  add column if not exists payment_method text,
  add column if not exists buyer_name_present boolean;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'expense_attachments_merchant_not_blank'
      and conrelid = 'public.expense_attachments'::regclass
  ) then
    alter table public.expense_attachments
      add constraint expense_attachments_merchant_not_blank
      check (merchant is null or length(trim(merchant)) > 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'expense_attachments_document_number_not_blank'
      and conrelid = 'public.expense_attachments'::regclass
  ) then
    alter table public.expense_attachments
      add constraint expense_attachments_document_number_not_blank
      check (document_number is null or length(trim(document_number)) > 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'expense_attachments_payment_method_not_blank'
      and conrelid = 'public.expense_attachments'::regclass
  ) then
    alter table public.expense_attachments
      add constraint expense_attachments_payment_method_not_blank
      check (payment_method is null or length(trim(payment_method)) > 0);
  end if;
end $$;

create index if not exists expense_attachments_evidence_type_idx
on public.expense_attachments (evidence_type);

create or replace function public.monthly_expense_report(
  target_family_id uuid,
  report_month date
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  month_start date;
  month_end date;
  report_payload jsonb;
begin
  if target_family_id is null then
    raise exception 'target_family_id is required'
      using errcode = '22023';
  end if;

  if report_month is null then
    raise exception 'report_month is required'
      using errcode = '22023';
  end if;

  if not public.is_family_member(target_family_id) then
    raise exception 'monthly report is not available for this family'
      using errcode = '42501';
  end if;

  month_start := date_trunc('month', report_month)::date;
  month_end := (month_start + interval '1 month')::date;

  with month_expenses as (
    select
      e.id,
      e.child_id,
      coalesce(c.first_name, 'Family expense') as child_label,
      e.paid_by,
      coalesce(p.display_name, p.email, e.paid_by::text) as paid_by_label,
      e.amount,
      round(e.amount * 100)::bigint as amount_cents,
      e.currency,
      e.category::text as category,
      coalesce(e.description, '') as description,
      e.expense_date,
      e.status::text as status,
      evidence.evidence_type,
      e.created_at
    from public.expenses e
    left join public.children c on c.id = e.child_id
    left join public.profiles p on p.id = e.paid_by
    left join lateral (
      select ea.evidence_type::text as evidence_type
      from public.expense_attachments ea
      where ea.expense_id = e.id
      order by (ea.evidence_type is null), ea.created_at, ea.id
      limit 1
    ) evidence on true
    where e.family_id = target_family_id
      and e.expense_date >= month_start
      and e.expense_date < month_end
  ),
  totals as (
    select
      count(*)::integer as expense_count,
      coalesce(sum(amount_cents), 0)::bigint as total_cents,
      coalesce(
        max(currency),
        (select f.default_currency from public.families f where f.id = target_family_id),
        'PLN'
      ) as currency
    from month_expenses
  ),
  by_parent as (
    select
      paid_by,
      paid_by_label,
      currency,
      count(*)::integer as expense_count,
      sum(amount_cents)::bigint as total_cents
    from month_expenses
    group by paid_by, paid_by_label, currency
  ),
  by_child as (
    select
      child_id,
      child_label,
      currency,
      count(*)::integer as expense_count,
      sum(amount_cents)::bigint as total_cents
    from month_expenses
    group by child_id, child_label, currency
  ),
  by_category as (
    select
      category,
      currency,
      count(*)::integer as expense_count,
      sum(amount_cents)::bigint as total_cents
    from month_expenses
    group by category, currency
  ),
  by_status as (
    select
      status,
      currency,
      count(*)::integer as expense_count,
      sum(amount_cents)::bigint as total_cents
    from month_expenses
    group by status, currency
  )
  select jsonb_build_object(
    'familyId', target_family_id,
    'month', to_char(month_start, 'YYYY-MM'),
    'range', jsonb_build_object(
      'from', month_start,
      'toExclusive', month_end
    ),
    'currency', totals.currency,
    'totalCents', totals.total_cents,
    'expenseCount', totals.expense_count,
    'byParent', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'parentId', paid_by,
          'label', paid_by_label,
          'currency', currency,
          'totalCents', total_cents,
          'expenseCount', expense_count
        )
        order by paid_by_label
      )
      from by_parent
    ), '[]'::jsonb),
    'byChild', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'childId', child_id,
          'label', child_label,
          'currency', currency,
          'totalCents', total_cents,
          'expenseCount', expense_count
        )
        order by child_label
      )
      from by_child
    ), '[]'::jsonb),
    'byCategory', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'category', category,
          'currency', currency,
          'totalCents', total_cents,
          'expenseCount', expense_count
        )
        order by category
      )
      from by_category
    ), '[]'::jsonb),
    'byStatus', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'status', status,
          'currency', currency,
          'totalCents', total_cents,
          'expenseCount', expense_count
        )
        order by status
      )
      from by_status
    ), '[]'::jsonb),
    'openExpenses', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', id,
          'date', expense_date,
          'childId', child_id,
          'childName', child_label,
          'category', category,
          'description', description,
          'paidBy', paid_by,
          'paidByName', paid_by_label,
          'amountCents', amount_cents,
          'currency', currency,
          'status', status,
          'evidenceType', evidence_type
        )
        order by expense_date, created_at, id
      )
      from month_expenses
      where status <> 'settled'
    ), '[]'::jsonb),
    'expenses', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', id,
          'date', expense_date,
          'childId', child_id,
          'childName', child_label,
          'category', category,
          'description', description,
          'paidBy', paid_by,
          'paidByName', paid_by_label,
          'amountCents', amount_cents,
          'amount', amount,
          'currency', currency,
          'status', status,
          'evidenceType', evidence_type
        )
        order by expense_date, created_at, id
      )
      from month_expenses
    ), '[]'::jsonb),
    'exports', jsonb_build_object(
      'csv', jsonb_build_object(
        'rpc', 'monthly_expense_report_csv',
        'columns', jsonb_build_array(
          'data',
          'dziecko',
          'kategoria',
          'opis',
          'płacący',
          'kwota',
          'status',
          'typ_dowodu'
        )
      ),
      'pdf', jsonb_build_object(
        'status', 'planned',
        'source', 'monthly_expense_report',
        'plannedColumns', jsonb_build_array('typ_dowodu')
      )
    )
  )
  into report_payload
  from totals;

  return report_payload;
end;
$$;

create or replace function public.monthly_expense_report_csv(
  target_family_id uuid,
  report_month date
)
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  month_start date;
  month_end date;
  csv_header text := 'data,dziecko,kategoria,opis,płacący,kwota,status,typ_dowodu';
  csv_rows text;
begin
  if target_family_id is null then
    raise exception 'target_family_id is required'
      using errcode = '22023';
  end if;

  if report_month is null then
    raise exception 'report_month is required'
      using errcode = '22023';
  end if;

  if not public.is_family_member(target_family_id) then
    raise exception 'monthly report CSV is not available for this family'
      using errcode = '42501';
  end if;

  month_start := date_trunc('month', report_month)::date;
  month_end := (month_start + interval '1 month')::date;

  select string_agg(
    public.monthly_report_csv_cell(e.expense_date::text)
      || ',' || public.monthly_report_csv_cell(coalesce(c.first_name, 'Family expense'))
      || ',' || public.monthly_report_csv_cell(e.category::text)
      || ',' || public.monthly_report_csv_cell(e.description)
      || ',' || public.monthly_report_csv_cell(coalesce(p.display_name, p.email, e.paid_by::text))
      || ',' || public.monthly_report_csv_cell(to_char(e.amount, 'FM999999999990.00'))
      || ',' || public.monthly_report_csv_cell(e.status::text)
      || ',' || public.monthly_report_csv_cell(evidence.evidence_type),
    E'\n'
    order by e.expense_date, e.created_at, e.id
  )
  into csv_rows
  from public.expenses e
  left join public.children c on c.id = e.child_id
  left join public.profiles p on p.id = e.paid_by
  left join lateral (
    select ea.evidence_type::text as evidence_type
    from public.expense_attachments ea
    where ea.expense_id = e.id
    order by (ea.evidence_type is null), ea.created_at, ea.id
    limit 1
  ) evidence on true
  where e.family_id = target_family_id
    and e.expense_date >= month_start
    and e.expense_date < month_end;

  return csv_header || coalesce(E'\n' || csv_rows, '');
end;
$$;

grant execute on function public.monthly_expense_report(uuid, date) to authenticated;
grant execute on function public.monthly_expense_report_csv(uuid, date) to authenticated;
