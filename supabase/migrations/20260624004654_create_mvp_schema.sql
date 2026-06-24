-- KidCost MVP schema.
-- Scope: issue #6. RLS policies are intentionally handled in issue #7.

create extension if not exists "pgcrypto";

create type public.family_member_role as enum (
  'owner',
  'parent',
  'viewer'
);

create type public.membership_status as enum (
  'invited',
  'active',
  'revoked'
);

create type public.expense_status as enum (
  'pending',
  'accepted',
  'disputed',
  'settled'
);

create type public.expense_category as enum (
  'food',
  'clothing',
  'school',
  'health',
  'activities',
  'vacation',
  'transport',
  'other'
);

create type public.attachment_file_type as enum (
  'jpg',
  'jpeg',
  'png',
  'pdf'
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (length(trim(display_name)) > 0),
  email text not null check (position('@' in email) > 1),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) > 0),
  created_by uuid not null references public.profiles(id),
  default_currency text not null default 'PLN' check (default_currency ~ '^[A-Z]{3}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role public.family_member_role not null default 'parent',
  status public.membership_status not null default 'active',
  joined_at timestamptz default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint family_members_unique_profile unique (family_id, profile_id),
  constraint family_members_joined_when_active check (
    status <> 'active'
    or joined_at is not null
  )
);

create table public.children (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  first_name text not null check (length(trim(first_name)) > 0),
  birth_date date,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  child_id uuid references public.children(id) on delete restrict,
  paid_by uuid not null references public.profiles(id) on delete restrict,
  amount numeric(12, 2) not null check (amount > 0),
  currency text not null default 'PLN' check (currency ~ '^[A-Z]{3}$'),
  category public.expense_category not null,
  description text,
  expense_date date not null,
  status public.expense_status not null default 'pending',
  created_by uuid not null references public.profiles(id) on delete restrict,
  updated_by uuid references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.expense_attachments (
  id uuid primary key default gen_random_uuid(),
  expense_id uuid not null references public.expenses(id) on delete cascade,
  storage_path text not null check (length(trim(storage_path)) > 0),
  file_type public.attachment_file_type not null,
  original_filename text,
  uploaded_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint expense_attachments_unique_storage_path unique (storage_path)
);

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

  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = new.family_id
      and fm.profile_id = new.paid_by
      and fm.status = 'active'
  ) then
    raise exception 'expense paid_by must be an active family member';
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

  return new;
end;
$$;

create or replace function public.validate_attachment_family_integrity()
returns trigger
language plpgsql
as $$
declare
  attachment_family_id uuid;
begin
  select e.family_id
  into attachment_family_id
  from public.expenses e
  where e.id = new.expense_id;

  if attachment_family_id is null then
    raise exception 'attachment expense_id must reference an existing expense';
  end if;

  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = attachment_family_id
      and fm.profile_id = new.uploaded_by
      and fm.status = 'active'
  ) then
    raise exception 'attachment uploaded_by must be an active family member';
  end if;

  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger families_set_updated_at
before update on public.families
for each row execute function public.set_updated_at();

create trigger family_members_set_updated_at
before update on public.family_members
for each row execute function public.set_updated_at();

create trigger children_set_updated_at
before update on public.children
for each row execute function public.set_updated_at();

create trigger expenses_set_updated_at
before update on public.expenses
for each row execute function public.set_updated_at();

create trigger expenses_validate_family_integrity
before insert or update on public.expenses
for each row execute function public.validate_expense_family_integrity();

create trigger expense_attachments_validate_family_integrity
before insert or update on public.expense_attachments
for each row execute function public.validate_attachment_family_integrity();

create index profiles_email_idx on public.profiles (lower(email));

create index families_created_by_idx on public.families (created_by);

create index family_members_family_id_idx on public.family_members (family_id);
create index family_members_profile_id_idx on public.family_members (profile_id);
create index family_members_status_idx on public.family_members (status);

create index children_family_id_idx on public.children (family_id);

create index expenses_family_id_idx on public.expenses (family_id);
create index expenses_child_id_idx on public.expenses (child_id);
create index expenses_paid_by_idx on public.expenses (paid_by);
create index expenses_expense_date_idx on public.expenses (expense_date);
create index expenses_status_idx on public.expenses (status);
create index expenses_family_date_idx on public.expenses (family_id, expense_date);

create index expense_attachments_expense_id_idx on public.expense_attachments (expense_id);
create index expense_attachments_uploaded_by_idx on public.expense_attachments (uploaded_by);
