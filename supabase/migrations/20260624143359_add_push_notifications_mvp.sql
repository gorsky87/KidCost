-- KidCost push notification MVP primitives.
-- Scope: issue #32.

create table public.push_device_tokens (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null default 'fcm' check (provider in ('fcm')),
  platform text not null check (platform in ('android', 'ios', 'web')),
  token text not null check (length(trim(token)) > 20),
  token_hash text generated always as (encode(digest(token, 'sha256'), 'hex')) stored,
  app_version text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  revoked_at timestamptz,
  constraint push_device_tokens_unique_hash unique (provider, token_hash)
);

create table public.notification_preferences (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  push_new_expense boolean not null default true,
  push_status_changed boolean not null default true,
  push_unsettled_balance_reminders boolean not null default true,
  updated_at timestamptz not null default now()
);

create table public.notification_outbox (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  audience_profile_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  event_type text not null check (
    event_type in (
      'expense_created',
      'expense_status_changed',
      'unsettled_balance_reminder'
    )
  ),
  entity_type text not null check (entity_type in ('expense', 'balance')),
  entity_id uuid,
  title_key text not null check (length(trim(title_key)) > 0),
  body_key text not null check (length(trim(body_key)) > 0),
  data jsonb not null default '{}'::jsonb,
  delivery_status text not null default 'pending' check (
    delivery_status in ('pending', 'sent', 'failed', 'skipped')
  ),
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  constraint notification_outbox_data_object check (jsonb_typeof(data) = 'object')
);

create trigger notification_preferences_set_updated_at
before update on public.notification_preferences
for each row execute function public.set_updated_at();

create or replace function public.upsert_push_device_token(
  token_value text,
  device_platform text,
  app_version_value text default null,
  provider_value text default 'fcm'
)
returns public.push_device_tokens
language plpgsql
security definer
set search_path = public
as $$
declare
  saved_token public.push_device_tokens;
begin
  if auth.uid() is null then
    raise exception 'authenticated user is required'
      using errcode = '42501';
  end if;

  if token_value is null or length(trim(token_value)) <= 20 then
    raise exception 'valid push token is required'
      using errcode = '22023';
  end if;

  if device_platform not in ('android', 'ios', 'web') then
    raise exception 'valid device platform is required'
      using errcode = '22023';
  end if;

  insert into public.push_device_tokens (
    profile_id,
    provider,
    platform,
    token,
    app_version,
    last_seen_at,
    revoked_at
  )
  values (
    auth.uid(),
    provider_value,
    device_platform,
    trim(token_value),
    app_version_value,
    now(),
    null
  )
  on conflict (provider, token_hash) do update
  set
    profile_id = excluded.profile_id,
    platform = excluded.platform,
    token = excluded.token,
    app_version = excluded.app_version,
    last_seen_at = now(),
    revoked_at = null
  returning * into saved_token;

  return saved_token;
end;
$$;

create or replace function public.record_expense_notification_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  notification_actor_id uuid;
  notification_event_type text;
  notification_title_key text;
  notification_body_key text;
  notification_data jsonb;
begin
  if tg_op = 'INSERT' then
    notification_actor_id := coalesce(new.created_by, auth.uid());
    notification_event_type := 'expense_created';
    notification_title_key := 'push.expense_created.title';
    notification_body_key := 'push.expense_created.body';
    notification_data := jsonb_build_object(
      'expenseId', new.id,
      'status', new.status
    );
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    notification_actor_id := coalesce(new.updated_by, auth.uid(), new.created_by);
    notification_event_type := 'expense_status_changed';
    notification_title_key := 'push.expense_status_changed.title';
    notification_body_key := 'push.expense_status_changed.body';
    notification_data := jsonb_build_object(
      'expenseId', new.id,
      'fromStatus', old.status,
      'toStatus', new.status
    );
  else
    return new;
  end if;

  insert into public.notification_outbox (
    family_id,
    audience_profile_id,
    actor_id,
    event_type,
    entity_type,
    entity_id,
    title_key,
    body_key,
    data
  )
  select
    new.family_id,
    fm.profile_id,
    notification_actor_id,
    notification_event_type,
    'expense',
    new.id,
    notification_title_key,
    notification_body_key,
    notification_data
  from public.family_members fm
  left join public.notification_preferences np on np.profile_id = fm.profile_id
  where fm.family_id = new.family_id
    and fm.status = 'active'
    and fm.profile_id <> notification_actor_id
    and (
      (
        notification_event_type = 'expense_created'
        and coalesce(np.push_new_expense, true)
      )
      or (
        notification_event_type = 'expense_status_changed'
        and coalesce(np.push_status_changed, true)
      )
    );

  return new;
end;
$$;

create trigger expenses_record_created_notification_event
after insert on public.expenses
for each row execute function public.record_expense_notification_event();

create trigger expenses_record_status_notification_event
after update of status on public.expenses
for each row execute function public.record_expense_notification_event();

create index push_device_tokens_profile_id_idx on public.push_device_tokens (profile_id);
create index push_device_tokens_last_seen_idx on public.push_device_tokens (last_seen_at);
create index notification_outbox_family_id_idx on public.notification_outbox (family_id);
create index notification_outbox_audience_idx on public.notification_outbox (audience_profile_id);
create index notification_outbox_status_idx on public.notification_outbox (delivery_status);
create index notification_outbox_created_idx on public.notification_outbox (created_at);

alter table public.push_device_tokens enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.notification_outbox enable row level security;

grant select, insert, update, delete on public.push_device_tokens to authenticated;
grant select, insert, update on public.notification_preferences to authenticated;
grant select on public.notification_outbox to authenticated;
grant execute on function public.upsert_push_device_token(text, text, text, text) to authenticated;

create policy "push_device_tokens_select_own"
on public.push_device_tokens for select
to authenticated
using (profile_id = auth.uid());

create policy "push_device_tokens_insert_own"
on public.push_device_tokens for insert
to authenticated
with check (profile_id = auth.uid());

create policy "push_device_tokens_update_own"
on public.push_device_tokens for update
to authenticated
using (profile_id = auth.uid())
with check (profile_id = auth.uid());

create policy "push_device_tokens_delete_own"
on public.push_device_tokens for delete
to authenticated
using (profile_id = auth.uid());

create policy "notification_preferences_select_own"
on public.notification_preferences for select
to authenticated
using (profile_id = auth.uid());

create policy "notification_preferences_insert_own"
on public.notification_preferences for insert
to authenticated
with check (profile_id = auth.uid());

create policy "notification_preferences_update_own"
on public.notification_preferences for update
to authenticated
using (profile_id = auth.uid())
with check (profile_id = auth.uid());

create policy "notification_outbox_select_own"
on public.notification_outbox for select
to authenticated
using (audience_profile_id = auth.uid());
