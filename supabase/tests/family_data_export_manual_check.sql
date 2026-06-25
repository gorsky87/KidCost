-- Manual family data export verification for issue #122.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/family_data_export_manual_check.sql
--
-- This script rolls back at the end.

begin;

create temp table family_export_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into family_export_ids (name, id)
values
  ('owner', gen_random_uuid()),
  ('co_parent', gen_random_uuid()),
  ('outsider', gen_random_uuid()),
  ('family_id', gen_random_uuid()),
  ('outsider_family_id', gen_random_uuid()),
  ('child_id', gen_random_uuid()),
  ('expense_id', gen_random_uuid()),
  ('settlement_id', gen_random_uuid()),
  ('attachment_id', gen_random_uuid()),
  ('payment_proof_id', gen_random_uuid());

grant select on family_export_ids to authenticated;

insert into auth.users (id, email, raw_user_meta_data)
values
  ((select id from family_export_ids where name = 'owner'), 'export-owner@example.com', '{"display_name":"Owner"}'::jsonb),
  ((select id from family_export_ids where name = 'co_parent'), 'export-co-parent@example.com', '{"display_name":"Co Parent"}'::jsonb),
  ((select id from family_export_ids where name = 'outsider'), 'export-outsider@example.com', '{"display_name":"Outsider"}'::jsonb);

insert into public.profiles (id, display_name, email)
values
  ((select id from family_export_ids where name = 'owner'), 'Owner', 'export-owner@example.com'),
  ((select id from family_export_ids where name = 'co_parent'), 'Co Parent', 'export-co-parent@example.com'),
  ((select id from family_export_ids where name = 'outsider'), 'Outsider', 'export-outsider@example.com')
on conflict (id) do update
set
  display_name = excluded.display_name,
  email = excluded.email,
  updated_at = now();

insert into public.families (id, name, created_by)
values
  (
    (select id from family_export_ids where name = 'family_id'),
    'Export family',
    (select id from family_export_ids where name = 'owner')
  ),
  (
    (select id from family_export_ids where name = 'outsider_family_id'),
    'Other export family',
    (select id from family_export_ids where name = 'outsider')
  );

insert into public.family_members (family_id, profile_id, role, status)
values
  (
    (select id from family_export_ids where name = 'family_id'),
    (select id from family_export_ids where name = 'owner'),
    'owner',
    'active'
  ),
  (
    (select id from family_export_ids where name = 'family_id'),
    (select id from family_export_ids where name = 'co_parent'),
    'parent',
    'active'
  ),
  (
    (select id from family_export_ids where name = 'outsider_family_id'),
    (select id from family_export_ids where name = 'outsider'),
    'owner',
    'active'
  );

insert into public.children (id, family_id, first_name, birth_date)
values (
  (select id from family_export_ids where name = 'child_id'),
  (select id from family_export_ids where name = 'family_id'),
  'Export Child',
  '2018-04-12'
);

insert into public.expenses (
  id,
  family_id,
  child_id,
  paid_by,
  amount,
  category,
  description,
  expense_date,
  status,
  created_by
)
values (
  (select id from family_export_ids where name = 'expense_id'),
  (select id from family_export_ids where name = 'family_id'),
  (select id from family_export_ids where name = 'child_id'),
  (select id from family_export_ids where name = 'owner'),
  150.25,
  'school',
  'Books and supplies',
  '2026-06-15',
  'accepted',
  (select id from family_export_ids where name = 'owner')
);

insert into storage.objects (bucket_id, name)
values (
  'expense-attachments',
  'families/' || (select id from family_export_ids where name = 'family_id') || '/expenses/' || (select id from family_export_ids where name = 'expense_id') || '/books.pdf'
);

insert into public.expense_attachments (
  id,
  expense_id,
  storage_path,
  file_type,
  original_filename,
  uploaded_by,
  evidence_type,
  merchant,
  document_number
)
values (
  (select id from family_export_ids where name = 'attachment_id'),
  (select id from family_export_ids where name = 'expense_id'),
  'families/' || (select id from family_export_ids where name = 'family_id') || '/expenses/' || (select id from family_export_ids where name = 'expense_id') || '/books.pdf',
  'pdf',
  'books.pdf',
  (select id from family_export_ids where name = 'owner'),
  'invoice',
  'Bookstore',
  'FV/EXPORT/2026'
);

insert into public.settlements (
  id,
  family_id,
  paid_by,
  paid_to,
  amount,
  settlement_date,
  note,
  expense_id,
  created_by
)
values (
  (select id from family_export_ids where name = 'settlement_id'),
  (select id from family_export_ids where name = 'family_id'),
  (select id from family_export_ids where name = 'co_parent'),
  (select id from family_export_ids where name = 'owner'),
  75.12,
  '2026-06-20',
  'Partial reimbursement',
  (select id from family_export_ids where name = 'expense_id'),
  (select id from family_export_ids where name = 'co_parent')
);

insert into storage.objects (bucket_id, name)
values (
  'expense-attachments',
  'families/' || (select id from family_export_ids where name = 'family_id') || '/settlements/' || (select id from family_export_ids where name = 'settlement_id') || '/transfer.pdf'
);

insert into public.settlement_payment_proofs (
  id,
  settlement_id,
  storage_path,
  file_type,
  original_filename,
  proof_kind,
  payment_method,
  reference_note,
  settled_at,
  uploaded_by
)
values (
  (select id from family_export_ids where name = 'payment_proof_id'),
  (select id from family_export_ids where name = 'settlement_id'),
  'families/' || (select id from family_export_ids where name = 'family_id') || '/settlements/' || (select id from family_export_ids where name = 'settlement_id') || '/transfer.pdf',
  'pdf',
  'transfer.pdf',
  'bank_transfer_confirmation',
  'bank_transfer',
  'June reimbursement proof',
  '2026-06-20',
  (select id from family_export_ids where name = 'co_parent')
);

insert into public.audit_events (
  family_id,
  entity_type,
  entity_id,
  actor_id,
  event_type,
  metadata
)
values (
  (select id from family_export_ids where name = 'family_id'),
  'expense',
  (select id from family_export_ids where name = 'expense_id'),
  (select id from family_export_ids where name = 'owner'),
  'manual_export_test',
  '{"source":"family_data_export_manual_check"}'::jsonb
);

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from family_export_ids where name = 'owner'), true);

do $$
declare
  export_payload jsonb;
begin
  export_payload := public.family_data_export(
    (select id from family_export_ids where name = 'family_id')
  );

  if export_payload->>'schemaVersion' <> '1' then
    raise exception 'family export schemaVersion is wrong: %', export_payload->>'schemaVersion';
  end if;

  if export_payload->'attachments'->>'included' <> 'false' then
    raise exception 'family export must not embed attachment files';
  end if;

  if (export_payload->'recordCounts'->>'members')::integer <> 2 then
    raise exception 'family export member count is wrong: %', export_payload->'recordCounts'->>'members';
  end if;

  if (export_payload->'recordCounts'->>'familyExpenseCategories')::integer <> 0
    or jsonb_array_length(export_payload->'familyExpenseCategories') <> 0 then
    raise exception 'family export category section should be present and empty for this fixture: %', export_payload;
  end if;

  if (export_payload->'recordCounts'->>'children')::integer <> 1
    or (export_payload->'recordCounts'->>'expenses')::integer <> 1
    or (export_payload->'recordCounts'->>'expenseAttachments')::integer <> 1
    or (export_payload->'recordCounts'->>'settlementPaymentProofs')::integer <> 1
    or (export_payload->'recordCounts'->>'settlements')::integer <> 1 then
    raise exception 'family export record counts are wrong: %', export_payload->'recordCounts';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(export_payload->'members') item
    where item->>'email' = 'export-co-parent@example.com'
      and item->>'role' = 'parent'
  ) then
    raise exception 'family export should include active family members';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(export_payload->'expenses') item
    where item->>'description' = 'Books and supplies'
      and (item->>'amountCents')::bigint = 15025
      and item->>'status' = 'accepted'
  ) then
    raise exception 'family export should include expense rows';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(export_payload->'expenseAttachments') item
    where item->>'originalFilename' = 'books.pdf'
      and item->>'evidenceType' = 'invoice'
      and item ? 'storagePath'
  ) then
    raise exception 'family export should include attachment metadata';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(export_payload->'settlementPaymentProofs') item
    where item->>'originalFilename' = 'transfer.pdf'
      and item->>'proofKind' = 'bank_transfer_confirmation'
      and item->>'paymentMethod' = 'bank_transfer'
      and item->>'uploadState' = 'uploaded'
      and item ? 'storagePath'
  ) then
    raise exception 'family export should include settlement payment proof metadata';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(export_payload->'expenseAttachments') item
    where item ? 'signedUrl'
      or item ? 'fileBytes'
  ) then
    raise exception 'family export must not include private attachment file payloads';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(export_payload->'settlementPaymentProofs') item
    where item ? 'signedUrl'
      or item ? 'fileBytes'
  ) then
    raise exception 'family export must not include private payment proof file payloads';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(export_payload->'settlements') item
    where item->>'note' = 'Partial reimbursement'
      and (item->>'amountCents')::bigint = 7512
  ) then
    raise exception 'family export should include settlement rows';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(export_payload->'auditEvents') item
    where item->>'eventType' = 'manual_export_test'
  ) then
    raise exception 'family export should include audit events';
  end if;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from family_export_ids where name = 'outsider'), true);

do $$
declare
  export_denied boolean := false;
begin
  begin
    perform public.family_data_export(
      (select id from family_export_ids where name = 'family_id')
    );
  exception
    when insufficient_privilege or raise_exception then
      export_denied := true;
  end;

  if not export_denied then
    raise exception 'outsider can export another family data set';
  end if;
end $$;

rollback;
