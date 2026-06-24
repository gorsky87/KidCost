-- KidCost attachment soft delete and audit events.
-- Scope: issue #83.

alter table public.expense_attachments
  add column if not exists deleted_at timestamptz,
  add column if not exists deleted_by uuid references public.profiles(id) on delete restrict,
  add column if not exists delete_reason text,
  add column if not exists replaced_by_attachment_id uuid references public.expense_attachments(id) on delete restrict;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'expense_attachments_delete_reason_not_blank'
      and conrelid = 'public.expense_attachments'::regclass
  ) then
    alter table public.expense_attachments
      add constraint expense_attachments_delete_reason_not_blank
      check (delete_reason is null or length(trim(delete_reason)) > 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'expense_attachments_deleted_by_requires_deleted_at'
      and conrelid = 'public.expense_attachments'::regclass
  ) then
    alter table public.expense_attachments
      add constraint expense_attachments_deleted_by_requires_deleted_at
      check (deleted_by is null or deleted_at is not null);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'expense_attachments_replacement_requires_deleted_at'
      and conrelid = 'public.expense_attachments'::regclass
  ) then
    alter table public.expense_attachments
      add constraint expense_attachments_replacement_requires_deleted_at
      check (replaced_by_attachment_id is null or deleted_at is not null);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'expense_attachments_not_replaced_by_self'
      and conrelid = 'public.expense_attachments'::regclass
  ) then
    alter table public.expense_attachments
      add constraint expense_attachments_not_replaced_by_self
      check (replaced_by_attachment_id is null or replaced_by_attachment_id <> id);
  end if;
end $$;

create index if not exists expense_attachments_deleted_at_idx
on public.expense_attachments (deleted_at);

create index if not exists expense_attachments_replaced_by_idx
on public.expense_attachments (replaced_by_attachment_id);

create or replace function public.validate_attachment_lifecycle()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  attachment_family_id uuid;
  replacement_expense_id uuid;
  deleter_is_member boolean;
begin
  if tg_op = 'UPDATE' then
    if old.expense_id is distinct from new.expense_id
      or old.storage_path is distinct from new.storage_path
      or old.file_type is distinct from new.file_type
      or old.uploaded_by is distinct from new.uploaded_by
      or old.created_at is distinct from new.created_at
    then
      raise exception 'attachment evidence fields are immutable; replace the attachment instead';
    end if;

    if old.deleted_at is not null and (
      new.deleted_at is distinct from old.deleted_at
      or new.deleted_by is distinct from old.deleted_by
      or new.delete_reason is distinct from old.delete_reason
      or new.replaced_by_attachment_id is distinct from old.replaced_by_attachment_id
    ) then
      raise exception 'soft-deleted attachment lifecycle metadata is immutable';
    end if;
  end if;

  if new.deleted_at is not null then
    if new.deleted_by is null then
      raise exception 'deleted_by is required when soft deleting an attachment';
    end if;

    select e.family_id
    into attachment_family_id
    from public.expenses e
    where e.id = new.expense_id;

    select exists (
      select 1
      from public.family_members fm
      where fm.family_id = attachment_family_id
        and fm.profile_id = new.deleted_by
        and fm.role in ('owner', 'parent')
        and fm.status = 'active'
    )
    into deleter_is_member;

    if not deleter_is_member then
      raise exception 'attachment deleted_by must be an active family writer';
    end if;
  end if;

  if new.replaced_by_attachment_id is not null then
    select ea.expense_id
    into replacement_expense_id
    from public.expense_attachments ea
    where ea.id = new.replaced_by_attachment_id;

    if replacement_expense_id is null then
      raise exception 'replacement attachment must exist';
    end if;

    if replacement_expense_id <> new.expense_id then
      raise exception 'replacement attachment must belong to the same expense';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.record_attachment_audit_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  attachment_family_id uuid;
  audit_actor_id uuid;
  audit_event_type text;
  audit_metadata jsonb;
begin
  select e.family_id
  into attachment_family_id
  from public.expenses e
  where e.id = new.expense_id;

  if attachment_family_id is null then
    return new;
  end if;

  if tg_op = 'INSERT' then
    audit_actor_id := new.uploaded_by;
    audit_event_type := 'attachment_added';
    audit_metadata := jsonb_build_object(
      'expenseId', new.expense_id,
      'storagePath', new.storage_path,
      'fileType', new.file_type,
      'evidenceType', new.evidence_type
    );
  elsif tg_op = 'UPDATE'
    and old.deleted_at is null
    and new.deleted_at is not null
  then
    audit_actor_id := new.deleted_by;
    audit_event_type := case
      when new.replaced_by_attachment_id is null then 'attachment_removed'
      else 'attachment_replaced'
    end;
    audit_metadata := jsonb_build_object(
      'expenseId', new.expense_id,
      'storagePath', new.storage_path,
      'fileType', new.file_type,
      'deleteReason', new.delete_reason,
      'replacedByAttachmentId', new.replaced_by_attachment_id
    );
  else
    return new;
  end if;

  insert into public.audit_events (
    family_id,
    entity_type,
    entity_id,
    actor_id,
    event_type,
    metadata
  )
  values (
    attachment_family_id,
    'expense_attachment',
    new.id,
    audit_actor_id,
    audit_event_type,
    audit_metadata
  );

  return new;
end;
$$;

drop trigger if exists expense_attachments_validate_lifecycle on public.expense_attachments;
create trigger expense_attachments_validate_lifecycle
before update on public.expense_attachments
for each row execute function public.validate_attachment_lifecycle();

drop trigger if exists expense_attachments_record_added_audit_event on public.expense_attachments;
create trigger expense_attachments_record_added_audit_event
after insert on public.expense_attachments
for each row execute function public.record_attachment_audit_event();

drop trigger if exists expense_attachments_record_removed_audit_event on public.expense_attachments;
create trigger expense_attachments_record_removed_audit_event
after update of deleted_at, deleted_by, delete_reason, replaced_by_attachment_id
on public.expense_attachments
for each row execute function public.record_attachment_audit_event();

revoke delete on public.expense_attachments from authenticated;
revoke delete on storage.objects from authenticated;

grant execute on function public.validate_attachment_lifecycle() to authenticated;
grant execute on function public.record_attachment_audit_event() to authenticated;

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
        and ea.deleted_at is null
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
      and ea.deleted_at is null
    order by (ea.evidence_type is null), ea.created_at, ea.id
    limit 1
  ) evidence on true
  where e.family_id = target_family_id
    and e.expense_date >= month_start
    and e.expense_date < month_end;

  return csv_header || coalesce(E'\n' || csv_rows, '');
end;
$$;
