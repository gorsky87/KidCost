-- Enforce expense status transition rules on the backend.
-- Scope: issue #116.

alter table public.expenses
add column if not exists status_comment text;

create or replace function public.prevent_finalized_expense_rewrite()
returns trigger
language plpgsql
as $$
begin
  if old.status in ('accepted', 'disputed', 'settled') and (
    new.family_id is distinct from old.family_id
    or new.child_id is distinct from old.child_id
    or new.paid_by is distinct from old.paid_by
    or new.amount is distinct from old.amount
    or new.currency is distinct from old.currency
    or new.category is distinct from old.category
    or new.expense_date is distinct from old.expense_date
    or new.created_by is distinct from old.created_by
  ) then
    raise exception 'accepted, disputed, or settled expenses require a correction entry instead of rewriting core fields';
  end if;

  return new;
end;
$$;

create or replace function public.validate_expense_status_transition()
returns trigger
language plpgsql
as $$
declare
  actor_id uuid;
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  actor_id := coalesce(new.updated_by, auth.uid());
  if actor_id is null then
    raise exception 'expense status changes require updated_by or an authenticated actor';
  end if;

  if auth.uid() is not null and actor_id is distinct from auth.uid() then
    raise exception 'expense status updated_by must match the authenticated actor';
  end if;

  new.updated_by := actor_id;

  if old.status = 'pending' and new.status in ('accepted', 'disputed') then
    if actor_id = old.created_by then
      raise exception 'expense creator cannot accept or dispute their own pending expense';
    end if;
  elsif old.status = 'disputed' and new.status = 'accepted' then
    if actor_id = old.created_by then
      raise exception 'expense creator cannot accept their own disputed expense';
    end if;
  elsif old.status = 'accepted' and new.status = 'settled' then
    null;
  else
    raise exception 'expense status transition from % to % is not allowed', old.status, new.status;
  end if;

  if new.status = 'disputed' and length(trim(coalesce(new.status_comment, ''))) = 0 then
    raise exception 'disputed expenses require a status_comment';
  end if;

  if new.status_comment is not null then
    new.status_comment := nullif(trim(new.status_comment), '');
  end if;

  return new;
end;
$$;

drop trigger if exists expenses_validate_status_transition on public.expenses;

create trigger expenses_validate_status_transition
before update of status on public.expenses
for each row execute function public.validate_expense_status_transition();

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
