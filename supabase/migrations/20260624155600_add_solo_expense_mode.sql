-- Solo expense mode.
-- Allows recording a cost before the co-parent has an account and keeps solo
-- expenses private to the author until explicitly shared.

create type public.expense_payer_kind as enum (
  'profile',
  'manual_label'
);

create type public.expense_visibility as enum (
  'private_author',
  'shared_family'
);

alter table public.expenses
  add column payer_kind public.expense_payer_kind not null default 'profile',
  add column manual_payer_label text,
  add column visibility public.expense_visibility not null default 'shared_family',
  add column shared_at timestamptz,
  add column shared_by uuid references public.profiles(id) on delete restrict;

alter table public.expenses
  alter column paid_by drop not null;

alter table public.expenses
  add constraint expenses_payer_source_check check (
    (
      payer_kind = 'profile'
      and paid_by is not null
      and manual_payer_label is null
    )
    or (
      payer_kind = 'manual_label'
      and paid_by is null
      and manual_payer_label is not null
      and length(trim(manual_payer_label)) > 0
    )
  ),
  add constraint expenses_shared_metadata_check check (
    (
      visibility = 'private_author'
      and shared_at is null
      and shared_by is null
    )
    or visibility = 'shared_family'
  );

create or replace function public.can_access_expense(target_expense_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.expenses e
    where e.id = target_expense_id
      and public.is_family_member(e.family_id)
      and (
        e.visibility = 'shared_family'
        or e.created_by = auth.uid()
      )
  )
$$;

create or replace function public.can_write_expense(target_expense_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.expenses e
    where e.id = target_expense_id
      and public.can_write_family(e.family_id)
      and (
        e.visibility = 'shared_family'
        or e.created_by = auth.uid()
      )
  )
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

create or replace function public.prevent_finalized_expense_rewrite()
returns trigger
language plpgsql
as $$
begin
  if old.status in ('accepted', 'disputed') and (
    new.family_id is distinct from old.family_id
    or new.child_id is distinct from old.child_id
    or new.paid_by is distinct from old.paid_by
    or new.payer_kind is distinct from old.payer_kind
    or new.manual_payer_label is distinct from old.manual_payer_label
    or new.amount is distinct from old.amount
    or new.currency is distinct from old.currency
    or new.category is distinct from old.category
    or new.expense_date is distinct from old.expense_date
    or new.visibility is distinct from old.visibility
    or new.created_by is distinct from old.created_by
  ) then
    raise exception 'accepted or disputed expenses require a correction entry instead of rewriting core fields';
  end if;

  return new;
end;
$$;

drop policy if exists "expenses_select_family_member" on public.expenses;
create policy "expenses_select_visible_family_member"
on public.expenses for select
to authenticated
using (
  public.is_family_member(family_id)
  and (
    visibility = 'shared_family'
    or created_by = auth.uid()
  )
);

drop policy if exists "expenses_insert_family_writer" on public.expenses;
create policy "expenses_insert_family_writer"
on public.expenses for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.can_write_family(family_id)
  and (
    visibility = 'shared_family'
    or created_by = auth.uid()
  )
);

drop policy if exists "expenses_update_family_writer" on public.expenses;
create policy "expenses_update_visible_family_writer"
on public.expenses for update
to authenticated
using (
  public.can_write_family(family_id)
  and (
    visibility = 'shared_family'
    or created_by = auth.uid()
  )
)
with check (
  public.can_write_family(family_id)
  and (
    visibility = 'shared_family'
    or created_by = auth.uid()
  )
);

create index expenses_payer_kind_idx on public.expenses (payer_kind);
create index expenses_visibility_idx on public.expenses (visibility);
create index expenses_manual_payer_label_idx
  on public.expenses (lower(manual_payer_label))
  where manual_payer_label is not null;
