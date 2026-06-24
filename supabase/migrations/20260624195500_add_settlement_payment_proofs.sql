-- KidCost settlement payment proof attachments.
-- Scope: issue #48.

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'payment_proof_kind'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.payment_proof_kind as enum (
      'bank_transfer_confirmation',
      'blik_confirmation',
      'cash_receipt',
      'check_image',
      'paypal_confirmation',
      'other'
    );
  end if;

  if not exists (
    select 1
    from pg_type
    where typname = 'payment_proof_upload_state'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.payment_proof_upload_state as enum (
      'uploading',
      'uploaded',
      'failed_upload',
      'removed'
    );
  end if;
end $$;

create table if not exists public.settlement_payment_proofs (
  id uuid primary key default gen_random_uuid(),
  settlement_id uuid not null references public.settlements(id) on delete cascade,
  storage_path text unique,
  file_type public.attachment_file_type not null,
  original_filename text not null check (length(trim(original_filename)) > 0),
  proof_kind public.payment_proof_kind not null default 'other',
  payment_method text not null check (length(trim(payment_method)) > 0),
  reference_note text,
  settled_at date not null,
  upload_state public.payment_proof_upload_state not null default 'uploaded',
  uploaded_by uuid not null references public.profiles(id) on delete restrict,
  failure_reason text,
  deleted_at timestamptz,
  deleted_by uuid references public.profiles(id) on delete restrict,
  delete_reason text,
  replaced_by_proof_id uuid references public.settlement_payment_proofs(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint settlement_payment_proofs_reference_note_not_blank
    check (reference_note is null or length(trim(reference_note)) > 0),
  constraint settlement_payment_proofs_failure_reason_not_blank
    check (failure_reason is null or length(trim(failure_reason)) > 0),
  constraint settlement_payment_proofs_delete_reason_not_blank
    check (delete_reason is null or length(trim(delete_reason)) > 0),
  constraint settlement_payment_proofs_storage_for_uploaded
    check (upload_state <> 'uploaded' or storage_path is not null),
  constraint settlement_payment_proofs_failed_needs_reason
    check (upload_state <> 'failed_upload' or failure_reason is not null),
  constraint settlement_payment_proofs_removed_needs_deleted_metadata
    check (upload_state <> 'removed' or (deleted_at is not null and deleted_by is not null)),
  constraint settlement_payment_proofs_not_replaced_by_self
    check (replaced_by_proof_id is null or replaced_by_proof_id <> id)
);

create index if not exists settlement_payment_proofs_settlement_id_idx
on public.settlement_payment_proofs (settlement_id);

create index if not exists settlement_payment_proofs_uploaded_by_idx
on public.settlement_payment_proofs (uploaded_by);

create index if not exists settlement_payment_proofs_upload_state_idx
on public.settlement_payment_proofs (upload_state);

create index if not exists settlement_payment_proofs_active_idx
on public.settlement_payment_proofs (settlement_id)
where upload_state <> 'removed';

create or replace function public.storage_settlement_family_id(object_name text)
returns uuid
language sql
immutable
as $$
  select case
    when split_part(object_name, '/', 1) = 'families'
     and split_part(object_name, '/', 3) = 'settlements'
     and split_part(object_name, '/', 2) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then split_part(object_name, '/', 2)::uuid
    else null
  end
$$;

create or replace function public.storage_settlement_id(object_name text)
returns uuid
language sql
immutable
as $$
  select case
    when split_part(object_name, '/', 1) = 'families'
     and split_part(object_name, '/', 3) = 'settlements'
     and split_part(object_name, '/', 4) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then split_part(object_name, '/', 4)::uuid
    else null
  end
$$;

create or replace function public.is_valid_expense_attachment_path(object_name text)
returns boolean
language sql
stable
as $$
  select (
      public.storage_expense_family_id(object_name) is not null
      and public.storage_expense_id(object_name) is not null
      and public.storage_attachment_filename(object_name) is not null
      and public.storage_attachment_extension(object_name) in ('jpg', 'jpeg', 'png', 'pdf')
    )
    or (
      public.storage_settlement_family_id(object_name) is not null
      and public.storage_settlement_id(object_name) is not null
      and public.storage_attachment_filename(object_name) is not null
      and public.storage_attachment_extension(object_name) in ('jpg', 'jpeg', 'png', 'pdf')
    )
$$;

create or replace function public.can_access_attachment_path(object_name text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.expenses e
    where e.id = public.storage_expense_id(object_name)
      and e.family_id = public.storage_expense_family_id(object_name)
      and public.is_family_member(e.family_id)
  )
  or exists (
    select 1
    from public.settlements s
    where s.id = public.storage_settlement_id(object_name)
      and s.family_id = public.storage_settlement_family_id(object_name)
      and public.is_family_member(s.family_id)
  )
$$;

create or replace function public.can_write_attachment_path(object_name text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.expenses e
    where e.id = public.storage_expense_id(object_name)
      and e.family_id = public.storage_expense_family_id(object_name)
      and public.can_write_family(e.family_id)
  )
  or exists (
    select 1
    from public.settlements s
    where s.id = public.storage_settlement_id(object_name)
      and s.family_id = public.storage_settlement_family_id(object_name)
      and public.can_write_family(s.family_id)
  )
$$;

create or replace function public.validate_settlement_payment_proof_lifecycle()
returns trigger
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  proof_family_id uuid;
  replacement_settlement_id uuid;
  actor_is_writer boolean;
begin
  select s.family_id
  into proof_family_id
  from public.settlements s
  where s.id = new.settlement_id;

  if proof_family_id is null then
    raise exception 'payment proof settlement_id must reference an existing settlement';
  end if;

  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = proof_family_id
      and fm.profile_id = new.uploaded_by
      and fm.role in ('owner', 'parent')
      and fm.status = 'active'
  )
  into actor_is_writer;

  if not actor_is_writer then
    raise exception 'payment proof uploaded_by must be an active family writer';
  end if;

  if tg_op = 'UPDATE' then
    if old.upload_state = 'removed' then
      raise exception 'removed payment proof metadata is immutable';
    end if;

    if old.settlement_id is distinct from new.settlement_id
      or old.file_type is distinct from new.file_type
      or old.original_filename is distinct from new.original_filename
      or old.proof_kind is distinct from new.proof_kind
      or old.payment_method is distinct from new.payment_method
      or old.reference_note is distinct from new.reference_note
      or old.settled_at is distinct from new.settled_at
      or old.uploaded_by is distinct from new.uploaded_by
      or old.created_at is distinct from new.created_at
    then
      raise exception 'payment proof evidence fields are immutable; replace the proof instead';
    end if;

    if old.storage_path is distinct from new.storage_path
      and not (old.upload_state = 'uploading' and new.upload_state = 'uploaded')
    then
      raise exception 'payment proof storage_path can only be set when upload completes';
    end if;

    if old.upload_state <> new.upload_state
      and not (
        (old.upload_state = 'uploading' and new.upload_state in ('uploaded', 'failed_upload'))
        or (old.upload_state in ('uploaded', 'failed_upload') and new.upload_state = 'removed')
      )
    then
      raise exception 'payment proof upload_state transition is not allowed';
    end if;
  end if;

  if new.storage_path is not null then
    if public.storage_settlement_family_id(new.storage_path) <> proof_family_id then
      raise exception 'payment proof storage_path family_id must match settlement family_id';
    end if;

    if public.storage_settlement_id(new.storage_path) <> new.settlement_id then
      raise exception 'payment proof storage_path settlement_id must match settlement_id';
    end if;

    if public.storage_attachment_extension(new.storage_path) <> new.file_type::text then
      raise exception 'payment proof file_type must match storage_path extension';
    end if;

    if not exists (
      select 1
      from storage.objects o
      where o.bucket_id = 'expense-attachments'
        and o.name = new.storage_path
    ) then
      raise exception 'payment proof metadata requires an uploaded storage object';
    end if;
  end if;

  if new.upload_state = 'failed_upload' and new.storage_path is not null then
    raise exception 'failed payment proof upload cannot point to a storage object';
  end if;

  if new.upload_state = 'removed' then
    select exists (
      select 1
      from public.family_members fm
      where fm.family_id = proof_family_id
        and fm.profile_id = new.deleted_by
        and fm.role in ('owner', 'parent')
        and fm.status = 'active'
    )
    into actor_is_writer;

    if not actor_is_writer then
      raise exception 'payment proof deleted_by must be an active family writer';
    end if;
  end if;

  if new.replaced_by_proof_id is not null then
    select spp.settlement_id
    into replacement_settlement_id
    from public.settlement_payment_proofs spp
    where spp.id = new.replaced_by_proof_id;

    if replacement_settlement_id is null then
      raise exception 'replacement payment proof must exist';
    end if;

    if replacement_settlement_id <> new.settlement_id then
      raise exception 'replacement payment proof must belong to the same settlement';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.record_settlement_payment_proof_audit_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  proof_family_id uuid;
  audit_actor_id uuid;
  audit_event_type text;
  audit_metadata jsonb;
begin
  select s.family_id
  into proof_family_id
  from public.settlements s
  where s.id = new.settlement_id;

  if proof_family_id is null then
    return new;
  end if;

  if tg_op = 'INSERT' and new.upload_state = 'uploaded' then
    audit_actor_id := new.uploaded_by;
    audit_event_type := 'payment_proof_added';
  elsif tg_op = 'INSERT' and new.upload_state = 'failed_upload' then
    audit_actor_id := new.uploaded_by;
    audit_event_type := 'payment_proof_upload_failed';
  elsif tg_op = 'UPDATE'
    and old.upload_state = 'uploading'
    and new.upload_state = 'uploaded'
  then
    audit_actor_id := new.uploaded_by;
    audit_event_type := 'payment_proof_added';
  elsif tg_op = 'UPDATE'
    and old.upload_state = 'uploading'
    and new.upload_state = 'failed_upload'
  then
    audit_actor_id := new.uploaded_by;
    audit_event_type := 'payment_proof_upload_failed';
  elsif tg_op = 'UPDATE'
    and old.upload_state <> 'removed'
    and new.upload_state = 'removed'
  then
    audit_actor_id := new.deleted_by;
    audit_event_type := case
      when new.replaced_by_proof_id is null then 'payment_proof_removed'
      else 'payment_proof_replaced'
    end;
  else
    return new;
  end if;

  audit_metadata := jsonb_strip_nulls(jsonb_build_object(
    'settlementId', new.settlement_id,
    'storagePath', new.storage_path,
    'fileType', new.file_type,
    'proofKind', new.proof_kind,
    'paymentMethod', new.payment_method,
    'referenceNote', new.reference_note,
    'settledAt', new.settled_at,
    'failureReason', new.failure_reason,
    'deleteReason', new.delete_reason,
    'replacedByProofId', new.replaced_by_proof_id
  ));

  insert into public.audit_events (
    family_id,
    entity_type,
    entity_id,
    actor_id,
    event_type,
    metadata
  )
  values (
    proof_family_id,
    'settlement_payment_proof',
    new.id,
    audit_actor_id,
    audit_event_type,
    audit_metadata
  );

  return new;
end;
$$;

drop trigger if exists settlement_payment_proofs_validate_lifecycle
on public.settlement_payment_proofs;
create trigger settlement_payment_proofs_validate_lifecycle
before insert or update on public.settlement_payment_proofs
for each row execute function public.validate_settlement_payment_proof_lifecycle();

drop trigger if exists settlement_payment_proofs_record_added_audit_event
on public.settlement_payment_proofs;
create trigger settlement_payment_proofs_record_added_audit_event
after insert on public.settlement_payment_proofs
for each row execute function public.record_settlement_payment_proof_audit_event();

drop trigger if exists settlement_payment_proofs_record_changed_audit_event
on public.settlement_payment_proofs;
create trigger settlement_payment_proofs_record_changed_audit_event
after update of upload_state, storage_path, failure_reason, deleted_at, deleted_by, delete_reason, replaced_by_proof_id
on public.settlement_payment_proofs
for each row execute function public.record_settlement_payment_proof_audit_event();

alter table public.settlement_payment_proofs enable row level security;

grant select, insert, update on public.settlement_payment_proofs to authenticated;
grant execute on function public.storage_settlement_family_id(text) to authenticated;
grant execute on function public.storage_settlement_id(text) to authenticated;
grant execute on function public.validate_settlement_payment_proof_lifecycle() to authenticated;
grant execute on function public.record_settlement_payment_proof_audit_event() to authenticated;

create or replace function public.monthly_settlement_payment_proofs(
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
    raise exception 'settlement payment proof report is not available for this family'
      using errcode = '42501';
  end if;

  month_start := date_trunc('month', report_month)::date;
  month_end := (month_start + interval '1 month')::date;

  select jsonb_build_object(
    'familyId', target_family_id,
    'month', to_char(month_start, 'YYYY-MM'),
    'settlements', coalesce(jsonb_agg(
      jsonb_build_object(
        'settlementId', s.id,
        'settlementDate', s.settlement_date,
        'paidBy', s.paid_by,
        'paidTo', s.paid_to,
        'amount', s.amount,
        'currency', s.currency,
        'paymentProofMarker', case
          when proof_summary.proof_count > 0 then 'Dowod platnosci dolaczony'
          else 'Brak dowodu platnosci'
        end,
        'paymentProofAttachmentCount', proof_summary.proof_count,
        'paymentProofAttachments', proof_summary.attachments
      )
      order by s.settlement_date, s.created_at, s.id
    ) filter (where s.id is not null), '[]'::jsonb)
  )
  into report_payload
  from public.settlements s
  left join lateral (
    select
      count(*)::integer as proof_count,
      coalesce(jsonb_agg(
        jsonb_build_object(
          'id', spp.id,
          'fileName', spp.original_filename,
          'proofKind', spp.proof_kind,
          'paymentMethod', spp.payment_method,
          'referenceNote', spp.reference_note,
          'settledAt', spp.settled_at,
          'storagePath', spp.storage_path
        )
        order by spp.created_at, spp.id
      ), '[]'::jsonb) as attachments
    from public.settlement_payment_proofs spp
    where spp.settlement_id = s.id
      and spp.upload_state = 'uploaded'
  ) proof_summary on true
  where s.family_id = target_family_id
    and s.settlement_date >= month_start
    and s.settlement_date < month_end;

  return coalesce(report_payload, jsonb_build_object(
    'familyId', target_family_id,
    'month', to_char(month_start, 'YYYY-MM'),
    'settlements', '[]'::jsonb
  ));
end;
$$;

grant execute on function public.monthly_settlement_payment_proofs(uuid, date)
to authenticated;

drop policy if exists "settlement_payment_proofs_select_family_member"
on public.settlement_payment_proofs;
create policy "settlement_payment_proofs_select_family_member"
on public.settlement_payment_proofs for select
to authenticated
using (
  exists (
    select 1
    from public.settlements s
    where s.id = settlement_payment_proofs.settlement_id
      and public.is_family_member(s.family_id)
  )
);

drop policy if exists "settlement_payment_proofs_insert_family_writer"
on public.settlement_payment_proofs;
create policy "settlement_payment_proofs_insert_family_writer"
on public.settlement_payment_proofs for insert
to authenticated
with check (
  uploaded_by = auth.uid()
  and exists (
    select 1
    from public.settlements s
    where s.id = settlement_payment_proofs.settlement_id
      and public.can_write_family(s.family_id)
  )
);

drop policy if exists "settlement_payment_proofs_update_family_writer"
on public.settlement_payment_proofs;
create policy "settlement_payment_proofs_update_family_writer"
on public.settlement_payment_proofs for update
to authenticated
using (
  exists (
    select 1
    from public.settlements s
    where s.id = settlement_payment_proofs.settlement_id
      and public.can_write_family(s.family_id)
  )
)
with check (
  exists (
    select 1
    from public.settlements s
    where s.id = settlement_payment_proofs.settlement_id
      and public.can_write_family(s.family_id)
  )
);

revoke delete on public.settlement_payment_proofs from authenticated;
