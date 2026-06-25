-- Family custom expense categories.
-- Scope: issue #87.

create table public.family_expense_categories (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  icon_name text check (
    icon_name is null
    or icon_name ~ '^[a-z0-9][a-z0-9_-]{0,39}$'
  ),
  color_hex text check (
    color_hex is null
    or color_hex ~ '^#[0-9A-Fa-f]{6}$'
  ),
  report_group text check (
    report_group is null
    or length(trim(report_group)) > 0
  ),
  created_by uuid not null references public.profiles(id) on delete restrict,
  updated_by uuid references public.profiles(id) on delete restrict,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint family_expense_categories_archive_metadata_check check (
    (archived_at is null and archived_by is null)
    or (archived_at is not null and archived_by is not null)
  )
);

create unique index family_expense_categories_active_name_idx
  on public.family_expense_categories (family_id, lower(name))
  where archived_at is null;

create index family_expense_categories_family_id_idx
  on public.family_expense_categories (family_id);

create index family_expense_categories_archived_at_idx
  on public.family_expense_categories (family_id, archived_at);

alter table public.expenses
  add column family_expense_category_id uuid references public.family_expense_categories(id) on delete restrict,
  add column category_name_snapshot text,
  add column category_report_group_snapshot text;

update public.expenses
set category_name_snapshot = category::text
where category_name_snapshot is null;

alter table public.expenses
  alter column category_name_snapshot set not null,
  add constraint expenses_category_name_snapshot_check check (
    length(trim(category_name_snapshot)) > 0
  ),
  add constraint expenses_category_report_group_snapshot_check check (
    category_report_group_snapshot is null
    or length(trim(category_report_group_snapshot)) > 0
  );

create index expenses_family_expense_category_id_idx
  on public.expenses (family_expense_category_id);

create index expenses_category_name_snapshot_idx
  on public.expenses (family_id, lower(category_name_snapshot));

create or replace function public.validate_family_expense_category_integrity()
returns trigger
language plpgsql
as $$
begin
  new.name := nullif(trim(new.name), '');
  new.icon_name := nullif(trim(new.icon_name), '');
  new.color_hex := nullif(trim(new.color_hex), '');
  new.report_group := nullif(trim(new.report_group), '');

  if new.name is null then
    raise exception 'family expense category name is required';
  end if;

  if tg_op = 'UPDATE' then
    if new.family_id is distinct from old.family_id
      or new.created_by is distinct from old.created_by then
      raise exception 'family expense category family_id and created_by cannot be changed';
    end if;
  end if;

  if new.archived_at is not null and new.archived_by is null then
    new.archived_by := auth.uid();
  end if;

  if new.archived_at is null then
    new.archived_by := null;
  end if;

  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.created_by
      and fm.status = 'active'
  ) then
    raise exception 'family expense category created_by must be an active family member';
  end if;

  if new.updated_by is not null and not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.updated_by
      and fm.status = 'active'
  ) then
    raise exception 'family expense category updated_by must be an active family member';
  end if;

  if new.archived_by is not null and not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.archived_by
      and fm.status = 'active'
  ) then
    raise exception 'family expense category archived_by must be an active family member';
  end if;

  return new;
end;
$$;

create trigger family_expense_categories_set_updated_at
before update on public.family_expense_categories
for each row execute function public.set_updated_at();

create trigger family_expense_categories_validate_integrity
before insert or update on public.family_expense_categories
for each row execute function public.validate_family_expense_category_integrity();

create or replace function public.apply_expense_category_snapshot()
returns trigger
language plpgsql
as $$
declare
  family_category record;
begin
  if tg_op = 'UPDATE' then
    if new.family_id is not distinct from old.family_id
      and new.category is not distinct from old.category
      and new.family_expense_category_id is not distinct from old.family_expense_category_id then
      new.category_name_snapshot := old.category_name_snapshot;
      new.category_report_group_snapshot := old.category_report_group_snapshot;
      return new;
    end if;
  end if;

  if new.family_expense_category_id is null then
    new.category_name_snapshot := new.category::text;
    new.category_report_group_snapshot := null;
    return new;
  end if;

  select fec.name, fec.report_group, fec.archived_at
  into family_category
  from public.family_expense_categories fec
  where fec.id = new.family_expense_category_id
    and fec.family_id = new.family_id;

  if not found then
    raise exception 'family expense category must belong to the expense family';
  end if;

  if family_category.archived_at is not null then
    raise exception 'archived family expense categories cannot be used for new expenses';
  end if;

  new.category_name_snapshot := family_category.name;
  new.category_report_group_snapshot := family_category.report_group;
  return new;
end;
$$;

drop trigger if exists expenses_apply_category_snapshot on public.expenses;

create trigger expenses_apply_category_snapshot
before insert or update on public.expenses
for each row execute function public.apply_expense_category_snapshot();

create or replace function public.prevent_finalized_expense_rewrite()
returns trigger
language plpgsql
as $$
begin
  if old.status in ('accepted', 'disputed', 'settled') and (
    new.family_id is distinct from old.family_id
    or new.child_id is distinct from old.child_id
    or new.paid_by is distinct from old.paid_by
    or new.payer_kind is distinct from old.payer_kind
    or new.manual_payer_label is distinct from old.manual_payer_label
    or new.amount is distinct from old.amount
    or new.currency is distinct from old.currency
    or new.category is distinct from old.category
    or new.family_expense_category_id is distinct from old.family_expense_category_id
    or new.category_name_snapshot is distinct from old.category_name_snapshot
    or new.category_report_group_snapshot is distinct from old.category_report_group_snapshot
    or new.expense_date is distinct from old.expense_date
    or new.visibility is distinct from old.visibility
    or new.created_by is distinct from old.created_by
  ) then
    raise exception 'accepted, disputed, or settled expenses require a correction entry instead of rewriting core fields';
  end if;

  return new;
end;
$$;

create or replace function public.record_expense_audit_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  audit_actor_id uuid;
  audit_event_type text;
  audit_metadata jsonb;
begin
  if tg_op = 'INSERT' then
    audit_actor_id := coalesce(new.created_by, auth.uid());
    audit_event_type := 'created';
    audit_metadata := jsonb_strip_nulls(jsonb_build_object(
      'amount', new.amount,
      'currency', new.currency,
      'status', new.status,
      'category', new.category,
      'familyExpenseCategoryId', new.family_expense_category_id,
      'categoryName', new.category_name_snapshot,
      'categoryReportGroup', new.category_report_group_snapshot,
      'expenseDate', new.expense_date,
      'paidBy', new.paid_by
    ));
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    audit_actor_id := coalesce(new.updated_by, auth.uid(), new.created_by);
    audit_event_type := 'status_changed';
    audit_metadata := jsonb_strip_nulls(jsonb_build_object(
      'from', old.status,
      'to', new.status,
      'comment', new.status_comment
    ));
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
    new.family_id,
    'expense',
    new.id,
    audit_actor_id,
    audit_event_type,
    audit_metadata
  );

  return new;
end;
$$;

alter table public.family_expense_categories enable row level security;

grant select, insert, update on public.family_expense_categories to authenticated;

grant execute on function public.validate_family_expense_category_integrity() to authenticated;
grant execute on function public.apply_expense_category_snapshot() to authenticated;

create policy "family_expense_categories_select_family_member"
on public.family_expense_categories for select
to authenticated
using (public.is_family_member(family_id));

create policy "family_expense_categories_insert_family_writer"
on public.family_expense_categories for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.can_write_family(family_id)
);

create policy "family_expense_categories_update_family_writer"
on public.family_expense_categories for update
to authenticated
using (public.can_write_family(family_id))
with check (public.can_write_family(family_id));

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
      coalesce(p.display_name, p.email, e.manual_payer_label, e.paid_by::text) as paid_by_label,
      e.amount,
      round(e.amount * 100)::bigint as amount_cents,
      e.currency,
      e.category::text as default_category,
      e.family_expense_category_id,
      coalesce(e.category_name_snapshot, e.category::text) as category,
      e.category_report_group_snapshot as category_report_group,
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
      category_report_group,
      currency,
      count(*)::integer as expense_count,
      sum(amount_cents)::bigint as total_cents
    from month_expenses
    group by category, category_report_group, currency
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
        jsonb_strip_nulls(jsonb_build_object(
          'category', category,
          'reportGroup', category_report_group,
          'currency', currency,
          'totalCents', total_cents,
          'expenseCount', expense_count
        ))
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
        jsonb_strip_nulls(jsonb_build_object(
          'id', id,
          'date', expense_date,
          'childId', child_id,
          'childName', child_label,
          'category', category,
          'defaultCategory', default_category,
          'familyExpenseCategoryId', family_expense_category_id,
          'categoryReportGroup', category_report_group,
          'description', description,
          'paidBy', paid_by,
          'paidByName', paid_by_label,
          'amountCents', amount_cents,
          'currency', currency,
          'status', status,
          'evidenceType', evidence_type
        ))
        order by expense_date, created_at, id
      )
      from month_expenses
      where status <> 'settled'
    ), '[]'::jsonb),
    'expenses', coalesce((
      select jsonb_agg(
        jsonb_strip_nulls(jsonb_build_object(
          'id', id,
          'date', expense_date,
          'childId', child_id,
          'childName', child_label,
          'category', category,
          'defaultCategory', default_category,
          'familyExpenseCategoryId', family_expense_category_id,
          'categoryReportGroup', category_report_group,
          'description', description,
          'paidBy', paid_by,
          'paidByName', paid_by_label,
          'amountCents', amount_cents,
          'amount', amount,
          'currency', currency,
          'status', status,
          'evidenceType', evidence_type
        ))
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
          'grupa_raportu',
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
        'plannedColumns', jsonb_build_array('grupa_raportu', 'typ_dowodu')
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
  csv_header text := 'data,dziecko,kategoria,grupa_raportu,opis,płacący,kwota,status,typ_dowodu';
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
      || ',' || public.monthly_report_csv_cell(coalesce(e.category_name_snapshot, e.category::text))
      || ',' || public.monthly_report_csv_cell(e.category_report_group_snapshot)
      || ',' || public.monthly_report_csv_cell(e.description)
      || ',' || public.monthly_report_csv_cell(coalesce(p.display_name, p.email, e.manual_payer_label, e.paid_by::text))
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

create or replace function public.family_data_export(target_family_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  export_payload jsonb;
begin
  if target_family_id is null then
    raise exception 'target_family_id is required'
      using errcode = '22023';
  end if;

  if not public.is_family_member(target_family_id) then
    raise exception 'family data export is not available for this family'
      using errcode = '42501';
  end if;

  with family_row as (
    select
      f.id,
      f.name,
      f.default_currency,
      f.created_by,
      f.created_at,
      f.updated_at
    from public.families f
    where f.id = target_family_id
  ),
  member_rows as (
    select
      fm.id,
      fm.family_id,
      fm.profile_id,
      p.display_name,
      p.email,
      fm.role::text as role,
      fm.status::text as status,
      fm.joined_at,
      fm.created_at,
      fm.updated_at
    from public.family_members fm
    join public.profiles p on p.id = fm.profile_id
    where fm.family_id = target_family_id
  ),
  family_category_rows as (
    select
      fec.id,
      fec.family_id,
      fec.name,
      fec.icon_name,
      fec.color_hex,
      fec.report_group,
      fec.created_by,
      fec.updated_by,
      fec.archived_at,
      fec.archived_by,
      fec.created_at,
      fec.updated_at
    from public.family_expense_categories fec
    where fec.family_id = target_family_id
  ),
  child_rows as (
    select
      c.id,
      c.family_id,
      c.first_name,
      c.birth_date,
      c.is_active,
      c.created_at,
      c.updated_at
    from public.children c
    where c.family_id = target_family_id
  ),
  expense_rows as (
    select
      e.id,
      e.family_id,
      e.child_id,
      e.paid_by,
      e.amount,
      round(e.amount * 100)::bigint as amount_cents,
      e.currency,
      e.category::text as category,
      e.family_expense_category_id,
      e.category_name_snapshot,
      e.category_report_group_snapshot,
      e.description,
      e.expense_date,
      e.status::text as status,
      e.status_comment,
      e.created_by,
      e.updated_by,
      e.created_at,
      e.updated_at
    from public.expenses e
    where e.family_id = target_family_id
  ),
  attachment_rows as (
    select
      ea.id,
      ea.expense_id,
      e.family_id,
      ea.storage_path,
      ea.file_type::text as file_type,
      ea.original_filename,
      ea.uploaded_by,
      ea.created_at,
      to_jsonb(ea) as attachment_record
    from public.expense_attachments ea
    join public.expenses e on e.id = ea.expense_id
    where e.family_id = target_family_id
  ),
  settlement_payment_proof_rows as (
    select
      spp.id,
      spp.settlement_id,
      s.family_id,
      spp.storage_path,
      spp.file_type::text as file_type,
      spp.original_filename,
      spp.proof_kind::text as proof_kind,
      spp.payment_method,
      spp.reference_note,
      spp.settled_at,
      spp.upload_state::text as upload_state,
      spp.uploaded_by,
      spp.failure_reason,
      spp.deleted_at,
      spp.deleted_by,
      spp.delete_reason,
      spp.replaced_by_proof_id,
      spp.created_at
    from public.settlement_payment_proofs spp
    join public.settlements s on s.id = spp.settlement_id
    where s.family_id = target_family_id
  ),
  settlement_rows as (
    select
      s.id,
      s.family_id,
      s.paid_by,
      s.paid_to,
      s.amount,
      round(s.amount * 100)::bigint as amount_cents,
      s.currency,
      s.settlement_date,
      s.note,
      s.expense_id,
      s.period_start,
      s.period_end,
      s.created_by,
      s.created_at
    from public.settlements s
    where s.family_id = target_family_id
  ),
  audit_rows as (
    select
      ae.id,
      ae.family_id,
      ae.entity_type,
      ae.entity_id,
      ae.actor_id,
      ae.event_type,
      ae.metadata,
      ae.created_at
    from public.audit_events ae
    where ae.family_id = target_family_id
  )
  select jsonb_build_object(
    'schemaVersion', 1,
    'generatedAt', now(),
    'generatedBy', auth.uid(),
    'familyId', target_family_id,
    'format', 'json',
    'fieldCatalog', jsonb_build_object(
      'family', jsonb_build_array('id', 'name', 'defaultCurrency', 'createdBy', 'createdAt', 'updatedAt'),
      'members', jsonb_build_array('id', 'familyId', 'profileId', 'displayName', 'email', 'role', 'status', 'joinedAt', 'createdAt', 'updatedAt'),
      'familyExpenseCategories', jsonb_build_array('id', 'familyId', 'name', 'iconName', 'colorHex', 'reportGroup', 'createdBy', 'updatedBy', 'archivedAt', 'archivedBy', 'createdAt', 'updatedAt'),
      'children', jsonb_build_array('id', 'familyId', 'firstName', 'birthDate', 'isActive', 'createdAt', 'updatedAt'),
      'expenses', jsonb_build_array('id', 'familyId', 'childId', 'paidBy', 'amount', 'amountCents', 'currency', 'category', 'familyExpenseCategoryId', 'categoryName', 'categoryReportGroup', 'description', 'expenseDate', 'status', 'statusComment', 'createdBy', 'updatedBy', 'createdAt', 'updatedAt'),
      'expenseAttachments', jsonb_build_array('id', 'expenseId', 'familyId', 'storagePath', 'fileType', 'originalFilename', 'uploadedBy', 'createdAt', 'evidenceType', 'documentDate', 'merchant', 'documentNumber', 'paymentMethod', 'buyerNamePresent', 'deletedAt', 'deletedBy', 'deleteReason', 'replacedByAttachmentId'),
      'settlementPaymentProofs', jsonb_build_array('id', 'settlementId', 'familyId', 'storagePath', 'fileType', 'originalFilename', 'proofKind', 'paymentMethod', 'referenceNote', 'settledAt', 'uploadState', 'uploadedBy', 'failureReason', 'deletedAt', 'deletedBy', 'deleteReason', 'replacedByProofId', 'createdAt'),
      'settlements', jsonb_build_array('id', 'familyId', 'paidBy', 'paidTo', 'amount', 'amountCents', 'currency', 'settlementDate', 'note', 'expenseId', 'periodStart', 'periodEnd', 'createdBy', 'createdAt'),
      'auditEvents', jsonb_build_array('id', 'familyId', 'entityType', 'entityId', 'actorId', 'eventType', 'metadata', 'createdAt')
    ),
    'attachments', jsonb_build_object(
      'included', false,
      'reason', 'MVP export includes attachment metadata only; private files remain in Supabase Storage.',
      'expenseAttachmentMetadataFields', jsonb_build_array(
        'id',
        'expenseId',
        'storagePath',
        'fileType',
        'originalFilename',
        'uploadedBy',
        'createdAt',
        'deletedAt',
        'deletedBy',
        'deleteReason',
        'replacedByAttachmentId'
      ),
      'settlementPaymentProofMetadataFields', jsonb_build_array(
        'id',
        'settlementId',
        'storagePath',
        'fileType',
        'originalFilename',
        'proofKind',
        'paymentMethod',
        'referenceNote',
        'settledAt',
        'uploadState',
        'uploadedBy',
        'failureReason',
        'deletedAt',
        'deletedBy',
        'deleteReason',
        'replacedByProofId',
        'createdAt'
      )
    ),
    'recordCounts', jsonb_build_object(
      'members', (select count(*) from member_rows),
      'familyExpenseCategories', (select count(*) from family_category_rows),
      'children', (select count(*) from child_rows),
      'expenses', (select count(*) from expense_rows),
      'expenseAttachments', (select count(*) from attachment_rows),
      'settlementPaymentProofs', (select count(*) from settlement_payment_proof_rows),
      'settlements', (select count(*) from settlement_rows),
      'auditEvents', (select count(*) from audit_rows)
    ),
    'family', (
      select jsonb_build_object(
        'id', id,
        'name', name,
        'defaultCurrency', default_currency,
        'createdBy', created_by,
        'createdAt', created_at,
        'updatedAt', updated_at
      )
      from family_row
    ),
    'members', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', id,
          'familyId', family_id,
          'profileId', profile_id,
          'displayName', display_name,
          'email', email,
          'role', role,
          'status', status,
          'joinedAt', joined_at,
          'createdAt', created_at,
          'updatedAt', updated_at
        )
        order by created_at, id
      )
      from member_rows
    ), '[]'::jsonb),
    'familyExpenseCategories', coalesce((
      select jsonb_agg(
        jsonb_strip_nulls(jsonb_build_object(
          'id', id,
          'familyId', family_id,
          'name', name,
          'iconName', icon_name,
          'colorHex', color_hex,
          'reportGroup', report_group,
          'createdBy', created_by,
          'updatedBy', updated_by,
          'archivedAt', archived_at,
          'archivedBy', archived_by,
          'createdAt', created_at,
          'updatedAt', updated_at
        ))
        order by archived_at nulls first, name, created_at, id
      )
      from family_category_rows
    ), '[]'::jsonb),
    'children', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', id,
          'familyId', family_id,
          'firstName', first_name,
          'birthDate', birth_date,
          'isActive', is_active,
          'createdAt', created_at,
          'updatedAt', updated_at
        )
        order by first_name, created_at, id
      )
      from child_rows
    ), '[]'::jsonb),
    'expenses', coalesce((
      select jsonb_agg(
        jsonb_strip_nulls(jsonb_build_object(
          'id', id,
          'familyId', family_id,
          'childId', child_id,
          'paidBy', paid_by,
          'amount', amount,
          'amountCents', amount_cents,
          'currency', currency,
          'category', category,
          'familyExpenseCategoryId', family_expense_category_id,
          'categoryName', category_name_snapshot,
          'categoryReportGroup', category_report_group_snapshot,
          'description', description,
          'expenseDate', expense_date,
          'status', status,
          'statusComment', status_comment,
          'createdBy', created_by,
          'updatedBy', updated_by,
          'createdAt', created_at,
          'updatedAt', updated_at
        ))
        order by expense_date, created_at, id
      )
      from expense_rows
    ), '[]'::jsonb),
    'expenseAttachments', coalesce((
      select jsonb_agg(
        jsonb_strip_nulls(jsonb_build_object(
          'id', id,
          'expenseId', expense_id,
          'familyId', family_id,
          'storagePath', storage_path,
          'fileType', file_type,
          'originalFilename', original_filename,
          'uploadedBy', uploaded_by,
          'createdAt', created_at,
          'evidenceType', attachment_record->>'evidence_type',
          'documentDate', attachment_record->>'document_date',
          'merchant', attachment_record->>'merchant',
          'documentNumber', attachment_record->>'document_number',
          'paymentMethod', attachment_record->>'payment_method',
          'buyerNamePresent', attachment_record->'buyer_name_present',
          'deletedAt', attachment_record->>'deleted_at',
          'deletedBy', attachment_record->>'deleted_by',
          'deleteReason', attachment_record->>'delete_reason',
          'replacedByAttachmentId', attachment_record->>'replaced_by_attachment_id'
        ))
        order by created_at, id
      )
      from attachment_rows
    ), '[]'::jsonb),
    'settlementPaymentProofs', coalesce((
      select jsonb_agg(
        jsonb_strip_nulls(jsonb_build_object(
          'id', id,
          'settlementId', settlement_id,
          'familyId', family_id,
          'storagePath', storage_path,
          'fileType', file_type,
          'originalFilename', original_filename,
          'proofKind', proof_kind,
          'paymentMethod', payment_method,
          'referenceNote', reference_note,
          'settledAt', settled_at,
          'uploadState', upload_state,
          'uploadedBy', uploaded_by,
          'failureReason', failure_reason,
          'deletedAt', deleted_at,
          'deletedBy', deleted_by,
          'deleteReason', delete_reason,
          'replacedByProofId', replaced_by_proof_id,
          'createdAt', created_at
        ))
        order by settled_at, created_at, id
      )
      from settlement_payment_proof_rows
    ), '[]'::jsonb),
    'settlements', coalesce((
      select jsonb_agg(
        jsonb_strip_nulls(jsonb_build_object(
          'id', id,
          'familyId', family_id,
          'paidBy', paid_by,
          'paidTo', paid_to,
          'amount', amount,
          'amountCents', amount_cents,
          'currency', currency,
          'settlementDate', settlement_date,
          'note', note,
          'expenseId', expense_id,
          'periodStart', period_start,
          'periodEnd', period_end,
          'createdBy', created_by,
          'createdAt', created_at
        ))
        order by settlement_date, created_at, id
      )
      from settlement_rows
    ), '[]'::jsonb),
    'auditEvents', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', id,
          'familyId', family_id,
          'entityType', entity_type,
          'entityId', entity_id,
          'actorId', actor_id,
          'eventType', event_type,
          'metadata', metadata,
          'createdAt', created_at
        )
        order by created_at, id
      )
      from audit_rows
    ), '[]'::jsonb)
  )
  into export_payload;

  return export_payload;
end;
$$;

grant execute on function public.monthly_expense_report(uuid, date) to authenticated;
grant execute on function public.monthly_expense_report_csv(uuid, date) to authenticated;
grant execute on function public.family_data_export(uuid) to authenticated;
