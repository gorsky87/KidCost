-- KidCost local demo/test seed.
-- Scope: issue #70.
--
-- Loaded by `supabase db reset` because `[db.seed]` is enabled in config.toml.
-- The records are deterministic, fake, and safe to reset at any time.

begin;

create temp table kidcost_seed_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into kidcost_seed_ids (name, id)
values
  ('owner', '00000000-0000-4000-8000-000000000101'),
  ('co_parent', '00000000-0000-4000-8000-000000000102'),
  ('family', '00000000-0000-4000-8000-000000000201'),
  ('child', '00000000-0000-4000-8000-000000000301'),
  ('school_expense', '00000000-0000-4000-8000-000000000401'),
  ('health_expense', '00000000-0000-4000-8000-000000000402'),
  ('activity_expense', '00000000-0000-4000-8000-000000000403'),
  ('settlement', '00000000-0000-4000-8000-000000000501')
on conflict (name) do update
set id = excluded.id;

insert into auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    (select id from kidcost_seed_ids where name = 'owner'),
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'demo.parent.one@example.test',
    crypt('KidCostDemo123!', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Demo Parent One"}'::jsonb,
    now(),
    now()
  ),
  (
    (select id from kidcost_seed_ids where name = 'co_parent'),
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'demo.parent.two@example.test',
    crypt('KidCostDemo123!', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Demo Parent Two"}'::jsonb,
    now(),
    now()
  )
on conflict (id) do update
set
  email = excluded.email,
  encrypted_password = excluded.encrypted_password,
  email_confirmed_at = excluded.email_confirmed_at,
  raw_app_meta_data = excluded.raw_app_meta_data,
  raw_user_meta_data = excluded.raw_user_meta_data,
  updated_at = now();

insert into auth.identities (
  id,
  user_id,
  provider_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
values
  (
    '00000000-0000-4000-8000-000000000601',
    (select id from kidcost_seed_ids where name = 'owner'),
    (select id::text from kidcost_seed_ids where name = 'owner'),
    jsonb_build_object(
      'sub', (select id::text from kidcost_seed_ids where name = 'owner'),
      'email', 'demo.parent.one@example.test',
      'email_verified', true
    ),
    'email',
    now(),
    now(),
    now()
  ),
  (
    '00000000-0000-4000-8000-000000000602',
    (select id from kidcost_seed_ids where name = 'co_parent'),
    (select id::text from kidcost_seed_ids where name = 'co_parent'),
    jsonb_build_object(
      'sub', (select id::text from kidcost_seed_ids where name = 'co_parent'),
      'email', 'demo.parent.two@example.test',
      'email_verified', true
    ),
    'email',
    now(),
    now(),
    now()
  )
on conflict (provider_id, provider) do update
set
  identity_data = excluded.identity_data,
  updated_at = now();

insert into public.profiles (id, display_name, email)
values
  (
    (select id from kidcost_seed_ids where name = 'owner'),
    'Demo Parent One',
    'demo.parent.one@example.test'
  ),
  (
    (select id from kidcost_seed_ids where name = 'co_parent'),
    'Demo Parent Two',
    'demo.parent.two@example.test'
  )
on conflict (id) do update
set
  display_name = excluded.display_name,
  email = excluded.email,
  updated_at = now();

insert into public.families (id, name, created_by, default_currency)
values (
  (select id from kidcost_seed_ids where name = 'family'),
  'Demo KidCost Family',
  (select id from kidcost_seed_ids where name = 'owner'),
  'PLN'
)
on conflict (id) do update
set
  name = excluded.name,
  default_currency = excluded.default_currency,
  updated_at = now();

insert into public.family_members (family_id, profile_id, role, status, joined_at)
values
  (
    (select id from kidcost_seed_ids where name = 'family'),
    (select id from kidcost_seed_ids where name = 'owner'),
    'owner',
    'active',
    now()
  ),
  (
    (select id from kidcost_seed_ids where name = 'family'),
    (select id from kidcost_seed_ids where name = 'co_parent'),
    'parent',
    'active',
    now()
  )
on conflict (family_id, profile_id) do update
set
  role = excluded.role,
  status = excluded.status,
  joined_at = coalesce(public.family_members.joined_at, excluded.joined_at),
  updated_at = now();

insert into public.children (id, family_id, first_name, birth_date, is_active)
values (
  (select id from kidcost_seed_ids where name = 'child'),
  (select id from kidcost_seed_ids where name = 'family'),
  'Maja',
  date '2017-04-12',
  true
)
on conflict (id) do update
set
  first_name = excluded.first_name,
  birth_date = excluded.birth_date,
  is_active = excluded.is_active,
  updated_at = now();

insert into public.expenses (
  id,
  family_id,
  child_id,
  paid_by,
  amount,
  currency,
  category,
  description,
  expense_date,
  status,
  created_by,
  updated_by
)
values
  (
    (select id from kidcost_seed_ids where name = 'school_expense'),
    (select id from kidcost_seed_ids where name = 'family'),
    (select id from kidcost_seed_ids where name = 'child'),
    (select id from kidcost_seed_ids where name = 'owner'),
    129.90,
    'PLN',
    'school',
    'Demo: school supplies',
    current_date - 8,
    'accepted',
    (select id from kidcost_seed_ids where name = 'owner'),
    (select id from kidcost_seed_ids where name = 'co_parent')
  ),
  (
    (select id from kidcost_seed_ids where name = 'health_expense'),
    (select id from kidcost_seed_ids where name = 'family'),
    (select id from kidcost_seed_ids where name = 'child'),
    (select id from kidcost_seed_ids where name = 'co_parent'),
    84.50,
    'PLN',
    'health',
    'Demo: pharmacy',
    current_date - 5,
    'pending',
    (select id from kidcost_seed_ids where name = 'co_parent'),
    null
  ),
  (
    (select id from kidcost_seed_ids where name = 'activity_expense'),
    (select id from kidcost_seed_ids where name = 'family'),
    (select id from kidcost_seed_ids where name = 'child'),
    (select id from kidcost_seed_ids where name = 'owner'),
    60.00,
    'PLN',
    'activities',
    'Demo: art class',
    current_date - 2,
    'disputed',
    (select id from kidcost_seed_ids where name = 'owner'),
    (select id from kidcost_seed_ids where name = 'co_parent')
  )
on conflict (id) do update
set
  paid_by = excluded.paid_by,
  amount = excluded.amount,
  currency = excluded.currency,
  category = excluded.category,
  description = excluded.description,
  expense_date = excluded.expense_date,
  status = excluded.status,
  updated_by = excluded.updated_by,
  updated_at = now();

insert into public.settlements (
  id,
  family_id,
  paid_by,
  paid_to,
  amount,
  currency,
  settlement_date,
  note,
  expense_id,
  period_start,
  period_end,
  created_by
)
values (
  (select id from kidcost_seed_ids where name = 'settlement'),
  (select id from kidcost_seed_ids where name = 'family'),
  (select id from kidcost_seed_ids where name = 'co_parent'),
  (select id from kidcost_seed_ids where name = 'owner'),
  64.95,
  'PLN',
  current_date - 1,
  'Demo partial reimbursement for accepted school expense',
  (select id from kidcost_seed_ids where name = 'school_expense'),
  date_trunc('month', current_date)::date,
  current_date,
  (select id from kidcost_seed_ids where name = 'co_parent')
)
on conflict (id) do update
set
  amount = excluded.amount,
  settlement_date = excluded.settlement_date,
  note = excluded.note;

insert into public.family_invitations (
  family_id,
  invited_email,
  invited_by,
  token,
  status,
  expires_at
)
values (
  (select id from kidcost_seed_ids where name = 'family'),
  'demo.pending.parent@example.test',
  (select id from kidcost_seed_ids where name = 'owner'),
  'kidcost-demo-invite-token',
  'pending',
  now() + interval '14 days'
)
on conflict (token) do update
set
  invited_email = excluded.invited_email,
  status = excluded.status,
  expires_at = excluded.expires_at,
  updated_at = now();

commit;
