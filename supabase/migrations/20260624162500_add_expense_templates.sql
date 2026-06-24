-- Recurring expense templates.
-- Scope: issue #38.

create type public.expense_template_recurrence as enum (
  'weekly',
  'monthly',
  'quarterly',
  'yearly'
);

create table public.expense_templates (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  child_id uuid references public.children(id) on delete restrict,
  name text not null check (length(trim(name)) > 0),
  amount numeric(12, 2) not null check (amount > 0),
  currency text not null default 'PLN' check (currency ~ '^[A-Z]{3}$'),
  category public.expense_category not null,
  paid_by uuid not null references public.profiles(id) on delete restrict,
  recurrence public.expense_template_recurrence not null,
  split_percent numeric(5, 2) not null default 50.00 check (
    split_percent >= 0
    and split_percent <= 100
  ),
  next_due_date date not null,
  note text,
  is_active boolean not null default true,
  created_by uuid not null references public.profiles(id) on delete restrict,
  updated_by uuid references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.expenses
add column source_template_id uuid references public.expense_templates(id) on delete set null;

create or replace function public.validate_expense_template_family_integrity()
returns trigger
language plpgsql
as $$
begin
  if new.child_id is not null and not exists (
    select 1
    from public.children c
    where c.id = new.child_id
      and c.family_id = new.family_id
  ) then
    raise exception 'expense template child_id must belong to the same family';
  end if;

  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.paid_by
      and fm.status = 'active'
  ) then
    raise exception 'expense template paid_by must be an active family member';
  end if;

  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.created_by
      and fm.status = 'active'
  ) then
    raise exception 'expense template created_by must be an active family member';
  end if;

  if new.updated_by is not null and not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.updated_by
      and fm.status = 'active'
  ) then
    raise exception 'expense template updated_by must be an active family member';
  end if;

  return new;
end;
$$;

create or replace function public.validate_expense_family_integrity()
returns trigger
language plpgsql
as $$
begin
  if new.child_id is not null and not exists (
    select 1
    from public.children c
    where c.id = new.child_id
      and c.family_id = new.family_id
  ) then
    raise exception 'expense child_id must belong to the same family';
  end if;

  if new.source_template_id is not null and not exists (
    select 1
    from public.expense_templates et
    where et.id = new.source_template_id
      and et.family_id = new.family_id
  ) then
    raise exception 'expense source_template_id must belong to the same family';
  end if;

  if new.payer_kind = 'profile' and not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.paid_by
      and fm.status = 'active'
  ) then
    raise exception 'expense paid_by must be an active family member';
  end if;

  if new.payer_kind = 'manual_label' and (
    new.paid_by is not null
    or new.manual_payer_label is null
    or length(trim(new.manual_payer_label)) = 0
  ) then
    raise exception 'manual payer expenses require only a non-empty label';
  end if;

  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.created_by
      and fm.status = 'active'
  ) then
    raise exception 'expense created_by must be an active family member';
  end if;

  if new.updated_by is not null and not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.updated_by
      and fm.status = 'active'
  ) then
    raise exception 'expense updated_by must be an active family member';
  end if;

  if new.shared_by is not null and not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.shared_by
      and fm.status = 'active'
  ) then
    raise exception 'expense shared_by must be an active family member';
  end if;

  return new;
end;
$$;

create trigger expense_templates_set_updated_at
before update on public.expense_templates
for each row execute function public.set_updated_at();

create trigger expense_templates_validate_family_integrity
before insert or update on public.expense_templates
for each row execute function public.validate_expense_template_family_integrity();

create index expense_templates_family_id_idx on public.expense_templates (family_id);
create index expense_templates_child_id_idx on public.expense_templates (child_id);
create index expense_templates_paid_by_idx on public.expense_templates (paid_by);
create index expense_templates_next_due_date_idx on public.expense_templates (next_due_date);
create index expense_templates_family_active_due_idx
on public.expense_templates (family_id, is_active, next_due_date);

create index expenses_source_template_id_idx on public.expenses (source_template_id);

alter table public.expense_templates enable row level security;

grant select, insert, update, delete on public.expense_templates to authenticated;

create policy "expense_templates_select_family_member"
on public.expense_templates for select
to authenticated
using (public.is_family_member(family_id));

create policy "expense_templates_insert_family_writer"
on public.expense_templates for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.can_write_family(family_id)
);

create policy "expense_templates_update_family_writer"
on public.expense_templates for update
to authenticated
using (public.can_write_family(family_id))
with check (public.can_write_family(family_id));

create policy "expense_templates_delete_family_writer"
on public.expense_templates for delete
to authenticated
using (public.can_write_family(family_id));
