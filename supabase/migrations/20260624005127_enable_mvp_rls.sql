-- KidCost MVP row level security.
-- Scope: issue #7.

create or replace function public.current_profile_id()
returns uuid
language sql
stable
as $$
  select auth.uid()
$$;

create or replace function public.is_family_member(target_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = target_family_id
      and fm.profile_id = auth.uid()
      and fm.status = 'active'
  )
$$;

create or replace function public.is_family_owner(target_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = target_family_id
      and fm.profile_id = auth.uid()
      and fm.role = 'owner'
      and fm.status = 'active'
  )
$$;

create or replace function public.can_write_family(target_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = target_family_id
      and fm.profile_id = auth.uid()
      and fm.role in ('owner', 'parent')
      and fm.status = 'active'
  )
$$;

create or replace function public.is_family_creator(target_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.families f
    where f.id = target_family_id
      and f.created_by = auth.uid()
  )
$$;

create or replace function public.shares_family_with(target_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members me
    join public.family_members other on other.family_id = me.family_id
    where me.profile_id = auth.uid()
      and me.status = 'active'
      and other.profile_id = target_profile_id
      and other.status = 'active'
  )
$$;

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
  )
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
    or new.amount is distinct from old.amount
    or new.currency is distinct from old.currency
    or new.category is distinct from old.category
    or new.expense_date is distinct from old.expense_date
    or new.created_by is distinct from old.created_by
  ) then
    raise exception 'accepted or disputed expenses require a correction entry instead of rewriting core fields';
  end if;

  return new;
end;
$$;

create trigger expenses_prevent_finalized_rewrite
before update on public.expenses
for each row execute function public.prevent_finalized_expense_rewrite();

alter table public.profiles enable row level security;
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.children enable row level security;
alter table public.expenses enable row level security;
alter table public.expense_attachments enable row level security;

grant usage on schema public to authenticated;
grant select, insert, update, delete on
  public.profiles,
  public.families,
  public.family_members,
  public.children,
  public.expenses,
  public.expense_attachments
to authenticated;

grant execute on function public.current_profile_id() to authenticated;
grant execute on function public.is_family_member(uuid) to authenticated;
grant execute on function public.is_family_owner(uuid) to authenticated;
grant execute on function public.can_write_family(uuid) to authenticated;
grant execute on function public.is_family_creator(uuid) to authenticated;
grant execute on function public.shares_family_with(uuid) to authenticated;
grant execute on function public.can_access_expense(uuid) to authenticated;
grant execute on function public.can_write_expense(uuid) to authenticated;

create policy "profiles_select_self_or_family"
on public.profiles for select
to authenticated
using (
  id = auth.uid()
  or public.shares_family_with(id)
);

create policy "profiles_insert_self"
on public.profiles for insert
to authenticated
with check (id = auth.uid());

create policy "profiles_update_self"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy "families_select_member"
on public.families for select
to authenticated
using (public.is_family_member(id));

create policy "families_insert_creator"
on public.families for insert
to authenticated
with check (created_by = auth.uid());

create policy "families_update_owner"
on public.families for update
to authenticated
using (public.is_family_owner(id))
with check (public.is_family_owner(id));

create policy "family_members_select_same_family"
on public.family_members for select
to authenticated
using (public.is_family_member(family_id));

create policy "family_members_insert_bootstrap_owner_or_owner"
on public.family_members for insert
to authenticated
with check (
  (
    profile_id = auth.uid()
    and role = 'owner'
    and status = 'active'
    and public.is_family_creator(family_id)
  )
  or public.is_family_owner(family_id)
);

create policy "family_members_update_owner"
on public.family_members for update
to authenticated
using (public.is_family_owner(family_id))
with check (public.is_family_owner(family_id));

create policy "children_select_family_member"
on public.children for select
to authenticated
using (public.is_family_member(family_id));

create policy "children_insert_family_writer"
on public.children for insert
to authenticated
with check (public.can_write_family(family_id));

create policy "children_update_family_writer"
on public.children for update
to authenticated
using (public.can_write_family(family_id))
with check (public.can_write_family(family_id));

create policy "expenses_select_family_member"
on public.expenses for select
to authenticated
using (public.is_family_member(family_id));

create policy "expenses_insert_family_writer"
on public.expenses for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.can_write_family(family_id)
);

create policy "expenses_update_family_writer"
on public.expenses for update
to authenticated
using (public.can_write_family(family_id))
with check (public.can_write_family(family_id));

create policy "expenses_delete_pending_creator"
on public.expenses for delete
to authenticated
using (
  status = 'pending'
  and created_by = auth.uid()
  and public.can_write_family(family_id)
);

create policy "attachments_select_expense_family_member"
on public.expense_attachments for select
to authenticated
using (public.can_access_expense(expense_id));

create policy "attachments_insert_expense_family_writer"
on public.expense_attachments for insert
to authenticated
with check (
  uploaded_by = auth.uid()
  and public.can_write_expense(expense_id)
);

create policy "attachments_update_expense_family_writer"
on public.expense_attachments for update
to authenticated
using (public.can_write_expense(expense_id))
with check (public.can_write_expense(expense_id));
