-- KidCost custody calendar.
-- Scope: issue #19.

create table public.custody_days (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  custody_date date not null,
  caregiver_id uuid not null references public.profiles(id) on delete restrict,
  notes text,
  created_by uuid not null references public.profiles(id) on delete restrict,
  updated_by uuid references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint custody_days_unique_child_date unique (child_id, custody_date)
);

create index custody_days_family_date_idx on public.custody_days (family_id, custody_date);
create index custody_days_child_date_idx on public.custody_days (child_id, custody_date);
create index custody_days_caregiver_id_idx on public.custody_days (caregiver_id);

create trigger custody_days_set_updated_at
before update on public.custody_days
for each row execute function public.set_updated_at();

create or replace function public.validate_custody_day_family_integrity()
returns trigger
language plpgsql
as $$
begin
  if not exists (
    select 1
    from public.children c
    where c.id = new.child_id
      and c.family_id = new.family_id
      and c.is_active
  ) then
    raise exception 'custody child_id must belong to the same active family';
  end if;

  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.caregiver_id
      and fm.status = 'active'
  ) then
    raise exception 'custody caregiver_id must be an active family member';
  end if;

  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.created_by
      and fm.status = 'active'
  ) then
    raise exception 'custody created_by must be an active family member';
  end if;

  if new.updated_by is not null and not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.updated_by
      and fm.status = 'active'
  ) then
    raise exception 'custody updated_by must be an active family member';
  end if;

  return new;
end;
$$;

create trigger custody_days_validate_family_integrity
before insert or update on public.custody_days
for each row execute function public.validate_custody_day_family_integrity();

alter table public.custody_days enable row level security;

grant select, insert, update, delete on public.custody_days to authenticated;

create policy "custody_days_select_family_member"
on public.custody_days for select
to authenticated
using (public.is_family_member(family_id));

create policy "custody_days_insert_family_writer"
on public.custody_days for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.can_write_family(family_id)
);

create policy "custody_days_update_family_writer"
on public.custody_days for update
to authenticated
using (public.can_write_family(family_id))
with check (public.can_write_family(family_id));

create policy "custody_days_delete_family_writer"
on public.custody_days for delete
to authenticated
using (public.can_write_family(family_id));
