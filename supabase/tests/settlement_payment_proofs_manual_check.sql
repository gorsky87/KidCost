-- Manual settlement payment proof verification for issue #48.
--
-- Run against a disposable local database after migrations:
--
--   supabase db reset
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/settlement_payment_proofs_manual_check.sql
--
-- This script rolls back at the end.

begin;

create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

create temp table payment_proof_ids (
  name text primary key,
  id uuid not null
) on commit drop;

insert into payment_proof_ids (name, id)
values
  ('owner', gen_random_uuid()),
  ('co_parent', gen_random_uuid()),
  ('outsider', gen_random_uuid()),
  ('family_id', gen_random_uuid()),
  ('outsider_family_id', gen_random_uuid()),
  ('settlement_id', gen_random_uuid()),
  ('proof_id', gen_random_uuid()),
  ('replacement_proof_id', gen_random_uuid()),
  ('failed_proof_id', gen_random_uuid());

grant select on payment_proof_ids to authenticated;

insert into auth.users (id, email, raw_user_meta_data)
values
  ((select id from payment_proof_ids where name = 'owner'), 'proof-owner@example.com', '{"display_name":"Owner"}'::jsonb),
  ((select id from payment_proof_ids where name = 'co_parent'), 'proof-co-parent@example.com', '{"display_name":"Co Parent"}'::jsonb),
  ((select id from payment_proof_ids where name = 'outsider'), 'proof-outsider@example.com', '{"display_name":"Outsider"}'::jsonb);

set local role authenticated;
select set_config('request.jwt.claim.sub', (select id::text from payment_proof_ids where name = 'owner'), true);

insert into public.families (id, name, created_by)
values (
  (select id from payment_proof_ids where name = 'family_id'),
  'Settlement proof family',
  (select id from payment_proof_ids where name = 'owner')
);

insert into public.families (id, name, created_by)
values (
  (select id from payment_proof_ids where name = 'outsider_family_id'),
  'Outsider family',
  (select id from payment_proof_ids where name = 'outsider')
);

insert into public.family_members (family_id, profile_id, role, status)
values
  (
    (select id from payment_proof_ids where name = 'family_id'),
    (select id from payment_proof_ids where name = 'owner'),
    'owner',
    'active'
  ),
  (
    (select id from payment_proof_ids where name = 'family_id'),
    (select id from payment_proof_ids where name = 'co_parent'),
    'parent',
    'active'
  ),
  (
    (select id from payment_proof_ids where name = 'outsider_family_id'),
    (select id from payment_proof_ids where name = 'outsider'),
    'owner',
    'active'
  );

insert into public.settlements (
  id,
  family_id,
  paid_by,
  paid_to,
  amount,
  currency,
  settlement_date,
  note,
  created_by
)
values (
  (select id from payment_proof_ids where name = 'settlement_id'),
  (select id from payment_proof_ids where name = 'family_id'),
  (select id from payment_proof_ids where name = 'co_parent'),
  (select id from payment_proof_ids where name = 'owner'),
  42.00,
  'PLN',
  current_date,
  'June reimbursement',
  (select id from payment_proof_ids where name = 'co_parent')
);

insert into storage.objects (bucket_id, name)
values (
  'expense-attachments',
  'families/' || (select id from payment_proof_ids where name = 'family_id') || '/settlements/' || (select id from payment_proof_ids where name = 'settlement_id') || '/transfer.pdf'
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
  upload_state,
  uploaded_by
)
values (
  (select id from payment_proof_ids where name = 'proof_id'),
  (select id from payment_proof_ids where name = 'settlement_id'),
  'families/' || (select id from payment_proof_ids where name = 'family_id') || '/settlements/' || (select id from payment_proof_ids where name = 'settlement_id') || '/transfer.pdf',
  'pdf',
  'transfer.pdf',
  'bank_transfer_confirmation',
  'przelew bankowy',
  'Zwrot za czerwiec',
  current_date,
  'uploaded',
  (select id from payment_proof_ids where name = 'owner')
);

insert into public.settlement_payment_proofs (
  id,
  settlement_id,
  file_type,
  original_filename,
  proof_kind,
  payment_method,
  settled_at,
  upload_state,
  failure_reason,
  uploaded_by
)
values (
  (select id from payment_proof_ids where name = 'failed_proof_id'),
  (select id from payment_proof_ids where name = 'settlement_id'),
  'png',
  'blik.png',
  'blik_confirmation',
  'BLIK',
  current_date,
  'failed_upload',
  'Network timeout',
  (select id from payment_proof_ids where name = 'owner')
);

do $$
declare
  visible_objects integer;
  visible_proofs integer;
  added_audit_count integer;
  failed_audit_count integer;
  report_payload jsonb;
begin
  select count(*) into visible_objects
  from storage.objects
  where bucket_id = 'expense-attachments';

  select count(*) into visible_proofs
  from public.settlement_payment_proofs
  where settlement_id = (select id from payment_proof_ids where name = 'settlement_id');

  select count(*) into added_audit_count
  from public.audit_events
  where entity_type = 'settlement_payment_proof'
    and entity_id = (select id from payment_proof_ids where name = 'proof_id')
    and event_type = 'payment_proof_added'
    and metadata->>'paymentMethod' = 'przelew bankowy';

  select count(*) into failed_audit_count
  from public.audit_events
  where entity_type = 'settlement_payment_proof'
    and entity_id = (select id from payment_proof_ids where name = 'failed_proof_id')
    and event_type = 'payment_proof_upload_failed'
    and metadata->>'failureReason' = 'Network timeout';

  if visible_objects <> 1 or visible_proofs <> 2 then
    raise exception 'family owner cannot see settlement payment proof object and metadata';
  end if;

  if added_audit_count <> 1 then
    raise exception 'payment proof add audit event is missing';
  end if;

  if failed_audit_count <> 1 then
    raise exception 'payment proof failed-upload audit event is missing';
  end if;

  select public.monthly_settlement_payment_proofs(
    (select id from payment_proof_ids where name = 'family_id'),
    current_date
  )
  into report_payload;

  if report_payload #>> '{settlements,0,paymentProofMarker}' <> 'Dowod platnosci dolaczony' then
    raise exception 'monthly settlement report is missing payment proof marker';
  end if;

  if (report_payload #>> '{settlements,0,paymentProofAttachmentCount}')::integer <> 1 then
    raise exception 'monthly settlement report should list uploaded proof attachments only';
  end if;
end $$;

insert into storage.objects (bucket_id, name)
values (
  'expense-attachments',
  'families/' || (select id from payment_proof_ids where name = 'family_id') || '/settlements/' || (select id from payment_proof_ids where name = 'settlement_id') || '/transfer-v2.pdf'
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
  upload_state,
  uploaded_by
)
values (
  (select id from payment_proof_ids where name = 'replacement_proof_id'),
  (select id from payment_proof_ids where name = 'settlement_id'),
  'families/' || (select id from payment_proof_ids where name = 'family_id') || '/settlements/' || (select id from payment_proof_ids where name = 'settlement_id') || '/transfer-v2.pdf',
  'pdf',
  'transfer-v2.pdf',
  'bank_transfer_confirmation',
  'przelew bankowy',
  'Czytelniejszy plik',
  current_date,
  'uploaded',
  (select id from payment_proof_ids where name = 'owner')
);

update public.settlement_payment_proofs
set
  upload_state = 'removed',
  deleted_at = now(),
  deleted_by = (select id from payment_proof_ids where name = 'owner'),
  delete_reason = 'replaced with clearer confirmation',
  replaced_by_proof_id = (select id from payment_proof_ids where name = 'replacement_proof_id')
where id = (select id from payment_proof_ids where name = 'proof_id');

do $$
declare
  replacement_audit_count integer;
  original_object_count integer;
begin
  select count(*) into replacement_audit_count
  from public.audit_events
  where entity_type = 'settlement_payment_proof'
    and entity_id = (select id from payment_proof_ids where name = 'proof_id')
    and event_type = 'payment_proof_replaced'
    and metadata->>'replacedByProofId' = (select id::text from payment_proof_ids where name = 'replacement_proof_id');

  select count(*) into original_object_count
  from storage.objects
  where bucket_id = 'expense-attachments'
    and name = 'families/' || (select id from payment_proof_ids where name = 'family_id') || '/settlements/' || (select id from payment_proof_ids where name = 'settlement_id') || '/transfer.pdf';

  if replacement_audit_count <> 1 then
    raise exception 'payment proof replacement audit event is missing';
  end if;

  if original_object_count <> 1 then
    raise exception 'payment proof soft replacement should not delete the original object';
  end if;
end $$;

select set_config('request.jwt.claim.sub', (select id::text from payment_proof_ids where name = 'outsider'), true);

do $$
declare
  visible_objects integer;
  visible_proofs integer;
begin
  select count(*) into visible_objects
  from storage.objects
  where bucket_id = 'expense-attachments';

  select count(*) into visible_proofs
  from public.settlement_payment_proofs;

  if visible_objects <> 0 or visible_proofs <> 0 then
    raise exception 'outsider can see another family settlement payment proof';
  end if;
end $$;

rollback;
