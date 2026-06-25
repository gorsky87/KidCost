-- KidCost expense attachment Storage.
-- Scope: issue #9.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'expense-attachments',
  'expense-attachments',
  false,
  10485760,
  array[
    'image/jpeg',
    'image/png',
    'application/pdf'
  ]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Supabase owns storage.objects as supabase_storage_admin and enables RLS in
-- the local stack bootstrap. Re-enabling it here breaks db reset ownership.

grant usage on schema storage to authenticated;
grant select, insert, update on storage.objects to authenticated;

create or replace function public.storage_expense_family_id(object_name text)
returns uuid
language sql
immutable
as $$
  select case
    when split_part(object_name, '/', 1) = 'families'
     and split_part(object_name, '/', 3) = 'expenses'
     and split_part(object_name, '/', 2) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then split_part(object_name, '/', 2)::uuid
    else null
  end
$$;

create or replace function public.storage_expense_id(object_name text)
returns uuid
language sql
immutable
as $$
  select case
    when split_part(object_name, '/', 1) = 'families'
     and split_part(object_name, '/', 3) = 'expenses'
     and split_part(object_name, '/', 4) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then split_part(object_name, '/', 4)::uuid
    else null
  end
$$;

create or replace function public.storage_attachment_filename(object_name text)
returns text
language sql
immutable
as $$
  select nullif(split_part(object_name, '/', 5), '')
$$;

create or replace function public.storage_attachment_extension(object_name text)
returns text
language sql
immutable
as $$
  select lower(regexp_replace(public.storage_attachment_filename(object_name), '^.*[.]', ''))
$$;

create or replace function public.is_valid_expense_attachment_path(object_name text)
returns boolean
language sql
stable
as $$
  select public.storage_expense_family_id(object_name) is not null
     and public.storage_expense_id(object_name) is not null
     and public.storage_attachment_filename(object_name) is not null
     and public.storage_attachment_extension(object_name) in ('jpg', 'jpeg', 'png', 'pdf')
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
$$;

create or replace function public.ensure_attachment_storage_object()
returns trigger
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  expense_family_id uuid;
  object_name text;
begin
  select e.family_id
  into expense_family_id
  from public.expenses e
  where e.id = new.expense_id;

  if expense_family_id is null then
    raise exception 'attachment expense_id must reference an existing expense';
  end if;

  if public.storage_expense_family_id(new.storage_path) <> expense_family_id then
    raise exception 'attachment storage_path family_id must match expense family_id';
  end if;

  if public.storage_expense_id(new.storage_path) <> new.expense_id then
    raise exception 'attachment storage_path expense_id must match expense_id';
  end if;

  if public.storage_attachment_extension(new.storage_path) <> new.file_type::text then
    raise exception 'attachment file_type must match storage_path extension';
  end if;

  if not exists (
    select 1
    from storage.objects o
    where o.bucket_id = 'expense-attachments'
      and o.name = new.storage_path
  ) then
    raise exception 'attachment metadata requires an uploaded storage object';
  end if;

  return new;
end;
$$;

create trigger expense_attachments_require_storage_object
before insert or update on public.expense_attachments
for each row execute function public.ensure_attachment_storage_object();

grant execute on function public.storage_expense_family_id(text) to authenticated;
grant execute on function public.storage_expense_id(text) to authenticated;
grant execute on function public.is_valid_expense_attachment_path(text) to authenticated;
grant execute on function public.can_access_attachment_path(text) to authenticated;
grant execute on function public.can_write_attachment_path(text) to authenticated;

create policy "expense_attachments_storage_select_family_member"
on storage.objects for select
to authenticated
using (
  bucket_id = 'expense-attachments'
  and public.is_valid_expense_attachment_path(name)
  and public.can_access_attachment_path(name)
);

create policy "expense_attachments_storage_insert_family_writer"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'expense-attachments'
  and public.is_valid_expense_attachment_path(name)
  and public.can_write_attachment_path(name)
);

create policy "expense_attachments_storage_update_family_writer"
on storage.objects for update
to authenticated
using (
  bucket_id = 'expense-attachments'
  and public.is_valid_expense_attachment_path(name)
  and public.can_write_attachment_path(name)
)
with check (
  bucket_id = 'expense-attachments'
  and public.is_valid_expense_attachment_path(name)
  and public.can_write_attachment_path(name)
);
