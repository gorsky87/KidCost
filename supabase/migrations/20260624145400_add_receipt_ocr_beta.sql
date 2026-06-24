-- KidCost receipt OCR beta primitives.
-- Scope: issue #33.

create type public.ocr_processing_status as enum (
  'queued',
  'processed',
  'failed',
  'needs_review'
);

create table public.ocr_results (
  id uuid primary key default gen_random_uuid(),
  attachment_id uuid not null references public.expense_attachments(id) on delete cascade,
  status public.ocr_processing_status not null default 'queued',
  extracted_amount numeric(12, 2) check (extracted_amount is null or extracted_amount > 0),
  extracted_currency text check (
    extracted_currency is null
    or extracted_currency ~ '^[A-Z]{3}$'
  ),
  extracted_date date,
  merchant text,
  confidence numeric(4, 3) check (
    confidence is null
    or (confidence >= 0 and confidence <= 1)
  ),
  requires_review boolean not null default true,
  raw_response jsonb not null default '{}'::jsonb,
  error_message text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  processed_at timestamptz,
  constraint ocr_results_unique_attachment unique (attachment_id),
  constraint ocr_results_raw_response_object check (jsonb_typeof(raw_response) = 'object')
);

create or replace function public.can_access_attachment_metadata(target_attachment_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.expense_attachments ea
    join public.expenses e on e.id = ea.expense_id
    where ea.id = target_attachment_id
      and public.is_family_member(e.family_id)
  )
$$;

create or replace function public.can_write_attachment_metadata(target_attachment_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.expense_attachments ea
    join public.expenses e on e.id = ea.expense_id
    where ea.id = target_attachment_id
      and public.can_write_family(e.family_id)
  )
$$;

create or replace function public.queue_attachment_ocr_result()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.ocr_results (
    attachment_id,
    status,
    requires_review,
    created_by
  )
  values (
    new.id,
    'queued',
    true,
    new.uploaded_by
  )
  on conflict (attachment_id) do nothing;

  return new;
end;
$$;

create or replace function public.save_ocr_result(
  target_attachment_id uuid,
  result_status public.ocr_processing_status,
  result_amount numeric default null,
  result_currency text default null,
  result_date date default null,
  result_merchant text default null,
  result_confidence numeric default null,
  result_raw_response jsonb default '{}'::jsonb,
  result_error_message text default null
)
returns public.ocr_results
language plpgsql
security definer
set search_path = public
as $$
declare
  saved_result public.ocr_results;
begin
  if target_attachment_id is null then
    raise exception 'target_attachment_id is required'
      using errcode = '22023';
  end if;

  if result_status is null then
    raise exception 'result_status is required'
      using errcode = '22023';
  end if;

  if not public.can_write_attachment_metadata(target_attachment_id) then
    raise exception 'OCR result is not available for this attachment'
      using errcode = '42501';
  end if;

  if result_raw_response is null or jsonb_typeof(result_raw_response) <> 'object' then
    raise exception 'result_raw_response must be a JSON object'
      using errcode = '22023';
  end if;

  insert into public.ocr_results (
    attachment_id,
    status,
    extracted_amount,
    extracted_currency,
    extracted_date,
    merchant,
    confidence,
    requires_review,
    raw_response,
    error_message,
    created_by,
    processed_at
  )
  values (
    target_attachment_id,
    result_status,
    result_amount,
    result_currency,
    result_date,
    nullif(trim(result_merchant), ''),
    result_confidence,
    result_status in (
      'processed'::public.ocr_processing_status,
      'needs_review'::public.ocr_processing_status
    ),
    result_raw_response,
    result_error_message,
    auth.uid(),
    case when result_status = 'queued' then null else now() end
  )
  on conflict (attachment_id) do update
  set
    status = excluded.status,
    extracted_amount = excluded.extracted_amount,
    extracted_currency = excluded.extracted_currency,
    extracted_date = excluded.extracted_date,
    merchant = excluded.merchant,
    confidence = excluded.confidence,
    requires_review = excluded.requires_review,
    raw_response = excluded.raw_response,
    error_message = excluded.error_message,
    updated_at = now(),
    processed_at = excluded.processed_at
  returning * into saved_result;

  return saved_result;
end;
$$;

create trigger ocr_results_set_updated_at
before update on public.ocr_results
for each row execute function public.set_updated_at();

create trigger expense_attachments_queue_ocr_result
after insert on public.expense_attachments
for each row execute function public.queue_attachment_ocr_result();

create index ocr_results_attachment_id_idx on public.ocr_results (attachment_id);
create index ocr_results_status_idx on public.ocr_results (status);
create index ocr_results_requires_review_idx on public.ocr_results (requires_review);
create index ocr_results_processed_at_idx on public.ocr_results (processed_at);

alter table public.ocr_results enable row level security;

grant select on public.ocr_results to authenticated;
grant execute on function public.can_access_attachment_metadata(uuid) to authenticated;
grant execute on function public.can_write_attachment_metadata(uuid) to authenticated;
grant execute on function public.save_ocr_result(
  uuid,
  public.ocr_processing_status,
  numeric,
  text,
  date,
  text,
  numeric,
  jsonb,
  text
) to authenticated;

create policy "ocr_results_select_attachment_family_member"
on public.ocr_results for select
to authenticated
using (public.can_access_attachment_metadata(attachment_id));
