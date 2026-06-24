-- KidCost family bootstrap and invitations.
-- Scope: issue #8.

create type public.family_invitation_status as enum (
  'pending',
  'accepted',
  'expired',
  'revoked'
);

create table public.family_invitations (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  invited_email text not null check (position('@' in invited_email) > 1),
  invited_by uuid not null references public.profiles(id) on delete restrict,
  token text not null default encode(gen_random_bytes(24), 'hex'),
  status public.family_invitation_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  accepted_at timestamptz,
  accepted_by uuid references public.profiles(id) on delete restrict,
  expires_at timestamptz not null default (now() + interval '14 days'),
  revoked_at timestamptz,
  constraint family_invitations_token_unique unique (token),
  constraint family_invitations_pending_requires_no_accept check (
    status <> 'pending'
    or (accepted_at is null and accepted_by is null and revoked_at is null)
  ),
  constraint family_invitations_accepted_requires_accept check (
    status <> 'accepted'
    or (accepted_at is not null and accepted_by is not null)
  )
);

create index family_invitations_family_id_idx on public.family_invitations (family_id);
create index family_invitations_invited_email_idx on public.family_invitations (lower(invited_email));
create index family_invitations_status_idx on public.family_invitations (status);
create index family_invitations_expires_at_idx on public.family_invitations (expires_at);

create trigger family_invitations_set_updated_at
before update on public.family_invitations
for each row execute function public.set_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  raw_name text;
  raw_email text;
begin
  raw_email := lower(trim(coalesce(
    new.email,
    new.raw_user_meta_data ->> 'email',
    new.id::text || '@pending.kidcost.local'
  )));
  raw_name := coalesce(
    new.raw_user_meta_data ->> 'display_name',
    new.raw_user_meta_data ->> 'full_name',
    split_part(raw_email, '@', 1),
    'Parent'
  );

  insert into public.profiles (id, display_name, email)
  values (
    new.id,
    coalesce(nullif(trim(raw_name), ''), 'Parent'),
    raw_email
  )
  on conflict (id) do update
  set
    display_name = excluded.display_name,
    email = excluded.email;

  return new;
end;
$$;

create trigger on_auth_user_created_create_profile
after insert on auth.users
for each row execute function public.handle_new_auth_user();

create or replace function public.create_default_family(family_name text default null)
returns public.families
language plpgsql
security definer
set search_path = public
as $$
declare
  profile public.profiles;
  created_family public.families;
begin
  select *
  into profile
  from public.profiles
  where id = auth.uid();

  if profile.id is null then
    raise exception 'profile is required before creating a family';
  end if;

  insert into public.families (name, created_by)
  values (
    coalesce(nullif(trim(family_name), ''), profile.display_name || ' family'),
    profile.id
  )
  returning * into created_family;

  insert into public.family_members (family_id, profile_id, role, status)
  values (created_family.id, profile.id, 'owner', 'active')
  on conflict (family_id, profile_id) do update
  set role = 'owner', status = 'active', joined_at = coalesce(public.family_members.joined_at, now());

  return created_family;
end;
$$;

create or replace function public.create_family_invitation(
  target_family_id uuid,
  target_email text
)
returns public.family_invitations
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_email text;
  invitation public.family_invitations;
begin
  normalized_email := lower(trim(target_email));

  if normalized_email is null or position('@' in normalized_email) <= 1 then
    raise exception 'valid invited email is required';
  end if;

  if not public.is_family_owner(target_family_id) then
    raise exception 'only a family owner can invite another parent';
  end if;

  insert into public.family_invitations (family_id, invited_email, invited_by)
  values (target_family_id, normalized_email, auth.uid())
  returning * into invitation;

  return invitation;
end;
$$;

create or replace function public.accept_family_invitation(invitation_token text)
returns public.family_members
language plpgsql
security definer
set search_path = public
as $$
declare
  invitation public.family_invitations;
  accepted_member public.family_members;
  profile public.profiles;
begin
  select *
  into profile
  from public.profiles
  where id = auth.uid();

  if profile.id is null then
    raise exception 'profile is required before accepting an invitation';
  end if;

  select *
  into invitation
  from public.family_invitations
  where token = invitation_token
  for update;

  if invitation.id is null then
    raise exception 'invitation not found';
  end if;

  if invitation.status <> 'pending' then
    raise exception 'invitation is not pending';
  end if;

  if invitation.expires_at <= now() then
    update public.family_invitations
    set status = 'expired'
    where id = invitation.id;
    raise exception 'invitation has expired';
  end if;

  if lower(profile.email) <> lower(invitation.invited_email) then
    raise exception 'invitation email does not match current profile';
  end if;

  insert into public.family_members (family_id, profile_id, role, status)
  values (invitation.family_id, profile.id, 'parent', 'active')
  on conflict (family_id, profile_id) do update
  set status = 'active', joined_at = coalesce(public.family_members.joined_at, now())
  returning * into accepted_member;

  update public.family_invitations
  set status = 'accepted',
      accepted_at = now(),
      accepted_by = profile.id
  where id = invitation.id;

  return accepted_member;
end;
$$;

alter table public.family_invitations enable row level security;

grant select, insert, update on public.family_invitations to authenticated;
grant execute on function public.create_default_family(text) to authenticated;
grant execute on function public.create_family_invitation(uuid, text) to authenticated;
grant execute on function public.accept_family_invitation(text) to authenticated;

create policy "family_invitations_select_owner_or_invited_email"
on public.family_invitations for select
to authenticated
using (
  public.is_family_owner(family_id)
  or lower(invited_email) = (
    select lower(p.email)
    from public.profiles p
    where p.id = auth.uid()
  )
);

create policy "family_invitations_insert_owner"
on public.family_invitations for insert
to authenticated
with check (
  invited_by = auth.uid()
  and public.is_family_owner(family_id)
);

create policy "family_invitations_update_owner"
on public.family_invitations for update
to authenticated
using (public.is_family_owner(family_id))
with check (public.is_family_owner(family_id));
