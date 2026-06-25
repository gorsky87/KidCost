-- KidCost duplicate bill detection primitives.
-- Scope: issue #58.

alter table public.expense_attachments
  add column if not exists service_date date;

create table if not exists public.expense_related_records (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  source_expense_id uuid not null references public.expenses(id) on delete cascade,
  related_expense_id uuid not null references public.expenses(id) on delete cascade,
  relation_type text not null default 'potential_duplicate'
    check (relation_type in ('potential_duplicate', 'same_bill', 'follow_up')),
  linked_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint expense_related_records_not_self
    check (source_expense_id <> related_expense_id),
  constraint expense_related_records_unique_pair
    unique (source_expense_id, related_expense_id)
);

create index if not exists expense_attachments_service_date_idx
on public.expense_attachments (service_date);

create index if not exists expense_attachments_document_number_normalized_idx
on public.expense_attachments (lower(trim(document_number)))
where document_number is not null;

create index if not exists expense_attachments_merchant_normalized_idx
on public.expense_attachments (lower(trim(merchant)))
where merchant is not null;

create index if not exists expense_related_records_family_idx
on public.expense_related_records (family_id);

create index if not exists expense_related_records_related_expense_idx
on public.expense_related_records (related_expense_id);

alter table public.expense_related_records enable row level security;

create policy "expense_related_records_select_family_member"
on public.expense_related_records for select
using (public.is_family_member(family_id));

create policy "expense_related_records_insert_family_writer"
on public.expense_related_records for insert
with check (
  public.is_family_member(family_id)
  and linked_by = auth.uid()
  and exists (
    select 1
    from public.expenses source
    join public.expenses related on related.id = related_expense_id
    where source.id = source_expense_id
      and source.family_id = family_id
      and related.family_id = family_id
  )
);

create or replace function public.find_potential_duplicate_expenses(
  target_family_id uuid,
  target_child_id uuid,
  target_category public.expense_category,
  target_amount numeric,
  target_provider text default null,
  target_service_date date default null,
  target_document_date date default null,
  target_document_number text default null,
  result_limit integer default 5
)
returns table (
  expense_id uuid,
  match_reasons text[],
  amount numeric,
  expense_date date,
  status text
)
language sql
stable
security definer
set search_path = public
as $$
  with candidate as (
    select
      nullif(lower(trim(target_provider)), '') as provider,
      nullif(lower(trim(target_document_number)), '') as document_number,
      greatest(round(target_amount * 100 * 0.02), 100)::bigint as amount_tolerance_cents
  ),
  existing as (
    select
      e.id,
      e.amount,
      round(e.amount * 100)::bigint as amount_cents,
      e.expense_date,
      e.status::text as status,
      nullif(lower(trim(ea.merchant)), '') as provider,
      ea.service_date,
      ea.document_date,
      nullif(lower(trim(ea.document_number)), '') as document_number
    from public.expenses e
    left join lateral (
      select
        attachment.merchant,
        attachment.service_date,
        attachment.document_date,
        attachment.document_number
      from public.expense_attachments attachment
      where attachment.expense_id = e.id
      order by
        (attachment.document_number is null),
        attachment.service_date nulls last,
        attachment.document_date nulls last,
        attachment.created_at,
        attachment.id
      limit 1
    ) ea on true
    where e.family_id = target_family_id
      and (target_child_id is null or e.child_id = target_child_id)
      and e.category = target_category
      and target_amount > 0
      and public.is_family_member(target_family_id)
  )
  select
    existing.id as expense_id,
    array_remove(array[
      'same_child_category',
      case
        when candidate.document_number is not null
          and candidate.document_number = existing.document_number
          then 'same_document_number'
      end,
      case
        when abs(existing.amount_cents - round(target_amount * 100)::bigint)
          <= candidate.amount_tolerance_cents
          then 'similar_amount'
      end,
      case
        when candidate.provider is not null
          and candidate.provider = existing.provider
          then 'same_provider'
      end,
      case
        when coalesce(target_service_date, target_document_date) is not null
          and (
            existing.service_date between coalesce(target_service_date, target_document_date) - 3
              and coalesce(target_service_date, target_document_date) + 3
            or existing.document_date between coalesce(target_service_date, target_document_date) - 3
              and coalesce(target_service_date, target_document_date) + 3
            or existing.expense_date between coalesce(target_service_date, target_document_date) - 3
              and coalesce(target_service_date, target_document_date) + 3
          )
          then 'similar_service_or_document_date'
      end
    ], null) as match_reasons,
    existing.amount,
    existing.expense_date,
    existing.status
  from existing
  cross join candidate
  where (
      candidate.document_number is not null
      and candidate.document_number = existing.document_number
    )
    or (
      abs(existing.amount_cents - round(target_amount * 100)::bigint)
        <= candidate.amount_tolerance_cents
      and (
        (
          candidate.provider is not null
          and candidate.provider = existing.provider
        )
        or (
          coalesce(target_service_date, target_document_date) is not null
          and (
            existing.service_date between coalesce(target_service_date, target_document_date) - 3
              and coalesce(target_service_date, target_document_date) + 3
            or existing.document_date between coalesce(target_service_date, target_document_date) - 3
              and coalesce(target_service_date, target_document_date) + 3
            or existing.expense_date between coalesce(target_service_date, target_document_date) - 3
              and coalesce(target_service_date, target_document_date) + 3
          )
        )
      )
    )
  order by array_length(match_reasons, 1) desc, existing.expense_date desc
  limit greatest(1, least(coalesce(result_limit, 5), 20));
$$;
