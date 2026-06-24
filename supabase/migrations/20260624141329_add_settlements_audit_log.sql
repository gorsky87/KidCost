-- KidCost settlements and audit log MVP.
-- Scope: issue #31.

create table public.settlements (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  paid_by uuid not null references public.profiles(id) on delete restrict,
  paid_to uuid not null references public.profiles(id) on delete restrict,
  amount numeric(12, 2) not null check (amount > 0),
  currency text not null default 'PLN' check (currency ~ '^[A-Z]{3}$'),
  settlement_date date not null,
  note text,
  expense_id uuid references public.expenses(id) on delete restrict,
  period_start date,
  period_end date,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint settlements_distinct_participants check (paid_by <> paid_to),
  constraint settlements_period_order check (
    period_start is null
    or period_end is null
    or period_start <= period_end
  )
);

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  entity_type text not null check (length(trim(entity_type)) > 0),
  entity_id uuid not null,
  actor_id uuid not null references public.profiles(id) on delete restrict,
  event_type text not null check (length(trim(event_type)) > 0),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint audit_events_metadata_object check (jsonb_typeof(metadata) = 'object')
);

create or replace function public.validate_settlement_family_integrity()
returns trigger
language plpgsql
as $$
begin
  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.paid_by
      and fm.status = 'active'
  ) then
    raise exception 'settlement paid_by must be an active family member';
  end if;

  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.paid_to
      and fm.status = 'active'
  ) then
    raise exception 'settlement paid_to must be an active family member';
  end if;

  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.created_by
      and fm.status = 'active'
  ) then
    raise exception 'settlement created_by must be an active family member';
  end if;

  if new.expense_id is not null and not exists (
    select 1
    from public.expenses e
    where e.id = new.expense_id
      and e.family_id = new.family_id
  ) then
    raise exception 'settlement expense_id must belong to the same family';
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
    audit_metadata := jsonb_build_object(
      'amount', new.amount,
      'currency', new.currency,
      'status', new.status,
      'category', new.category,
      'expenseDate', new.expense_date,
      'paidBy', new.paid_by
    );
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    audit_actor_id := coalesce(new.updated_by, auth.uid(), new.created_by);
    audit_event_type := 'status_changed';
    audit_metadata := jsonb_build_object(
      'from', old.status,
      'to', new.status
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

create or replace function public.record_settlement_audit_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
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
    'settlement',
    new.id,
    new.created_by,
    'settlement_added',
    jsonb_build_object(
      'paidBy', new.paid_by,
      'paidTo', new.paid_to,
      'amount', new.amount,
      'currency', new.currency,
      'settlementDate', new.settlement_date,
      'expenseId', new.expense_id,
      'periodStart', new.period_start,
      'periodEnd', new.period_end
    )
  );

  return new;
end;
$$;

create trigger settlements_validate_family_integrity
before insert or update on public.settlements
for each row execute function public.validate_settlement_family_integrity();

create trigger expenses_record_created_audit_event
after insert on public.expenses
for each row execute function public.record_expense_audit_event();

create trigger expenses_record_status_audit_event
after update of status on public.expenses
for each row execute function public.record_expense_audit_event();

create trigger settlements_record_added_audit_event
after insert on public.settlements
for each row execute function public.record_settlement_audit_event();

create index settlements_family_id_idx on public.settlements (family_id);
create index settlements_paid_by_idx on public.settlements (paid_by);
create index settlements_paid_to_idx on public.settlements (paid_to);
create index settlements_expense_id_idx on public.settlements (expense_id);
create index settlements_family_date_idx on public.settlements (family_id, settlement_date);

create index audit_events_family_id_idx on public.audit_events (family_id);
create index audit_events_entity_idx on public.audit_events (entity_type, entity_id);
create index audit_events_actor_id_idx on public.audit_events (actor_id);
create index audit_events_family_created_idx on public.audit_events (family_id, created_at);

alter table public.settlements enable row level security;
alter table public.audit_events enable row level security;

grant select, insert on public.settlements to authenticated;
grant select on public.audit_events to authenticated;

create policy "settlements_select_family_member"
on public.settlements for select
to authenticated
using (public.is_family_member(family_id));

create policy "settlements_insert_family_writer"
on public.settlements for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.can_write_family(family_id)
);

create policy "audit_events_select_family_member"
on public.audit_events for select
to authenticated
using (public.is_family_member(family_id));
