-- KidCost family data export MVP.
-- Scope: issue #122.

create or replace function public.family_data_export(target_family_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  export_payload jsonb;
begin
  if target_family_id is null then
    raise exception 'target_family_id is required'
      using errcode = '22023';
  end if;

  if not public.is_family_member(target_family_id) then
    raise exception 'family data export is not available for this family'
      using errcode = '42501';
  end if;

  with family_row as (
    select
      f.id,
      f.name,
      f.default_currency,
      f.created_by,
      f.created_at,
      f.updated_at
    from public.families f
    where f.id = target_family_id
  ),
  member_rows as (
    select
      fm.id,
      fm.family_id,
      fm.profile_id,
      p.display_name,
      p.email,
      fm.role::text as role,
      fm.status::text as status,
      fm.joined_at,
      fm.created_at,
      fm.updated_at
    from public.family_members fm
    join public.profiles p on p.id = fm.profile_id
    where fm.family_id = target_family_id
  ),
  child_rows as (
    select
      c.id,
      c.family_id,
      c.first_name,
      c.birth_date,
      c.is_active,
      c.created_at,
      c.updated_at
    from public.children c
    where c.family_id = target_family_id
  ),
  expense_rows as (
    select
      e.id,
      e.family_id,
      e.child_id,
      e.paid_by,
      e.amount,
      round(e.amount * 100)::bigint as amount_cents,
      e.currency,
      e.category::text as category,
      e.description,
      e.expense_date,
      e.status::text as status,
      e.status_comment,
      e.created_by,
      e.updated_by,
      e.created_at,
      e.updated_at
    from public.expenses e
    where e.family_id = target_family_id
  ),
  attachment_rows as (
    select
      ea.id,
      ea.expense_id,
      e.family_id,
      ea.storage_path,
      ea.file_type::text as file_type,
      ea.original_filename,
      ea.uploaded_by,
      ea.created_at,
      to_jsonb(ea) as attachment_record
    from public.expense_attachments ea
    join public.expenses e on e.id = ea.expense_id
    where e.family_id = target_family_id
  ),
  settlement_payment_proof_rows as (
    select
      spp.id,
      spp.settlement_id,
      s.family_id,
      spp.storage_path,
      spp.file_type::text as file_type,
      spp.original_filename,
      spp.proof_kind::text as proof_kind,
      spp.payment_method,
      spp.reference_note,
      spp.settled_at,
      spp.upload_state::text as upload_state,
      spp.uploaded_by,
      spp.failure_reason,
      spp.deleted_at,
      spp.deleted_by,
      spp.delete_reason,
      spp.replaced_by_proof_id,
      spp.created_at
    from public.settlement_payment_proofs spp
    join public.settlements s on s.id = spp.settlement_id
    where s.family_id = target_family_id
  ),
  settlement_rows as (
    select
      s.id,
      s.family_id,
      s.paid_by,
      s.paid_to,
      s.amount,
      round(s.amount * 100)::bigint as amount_cents,
      s.currency,
      s.settlement_date,
      s.note,
      s.expense_id,
      s.period_start,
      s.period_end,
      s.created_by,
      s.created_at
    from public.settlements s
    where s.family_id = target_family_id
  ),
  audit_rows as (
    select
      ae.id,
      ae.family_id,
      ae.entity_type,
      ae.entity_id,
      ae.actor_id,
      ae.event_type,
      ae.metadata,
      ae.created_at
    from public.audit_events ae
    where ae.family_id = target_family_id
  )
  select jsonb_build_object(
    'schemaVersion', 1,
    'generatedAt', now(),
    'generatedBy', auth.uid(),
    'familyId', target_family_id,
    'format', 'json',
    'fieldCatalog', jsonb_build_object(
      'family', jsonb_build_array('id', 'name', 'defaultCurrency', 'createdBy', 'createdAt', 'updatedAt'),
      'members', jsonb_build_array('id', 'familyId', 'profileId', 'displayName', 'email', 'role', 'status', 'joinedAt', 'createdAt', 'updatedAt'),
      'children', jsonb_build_array('id', 'familyId', 'firstName', 'birthDate', 'isActive', 'createdAt', 'updatedAt'),
      'expenses', jsonb_build_array('id', 'familyId', 'childId', 'paidBy', 'amount', 'amountCents', 'currency', 'category', 'description', 'expenseDate', 'status', 'statusComment', 'createdBy', 'updatedBy', 'createdAt', 'updatedAt'),
      'expenseAttachments', jsonb_build_array('id', 'expenseId', 'familyId', 'storagePath', 'fileType', 'originalFilename', 'uploadedBy', 'createdAt', 'evidenceType', 'documentDate', 'merchant', 'documentNumber', 'paymentMethod', 'buyerNamePresent', 'deletedAt', 'deletedBy', 'deleteReason', 'replacedByAttachmentId'),
      'settlementPaymentProofs', jsonb_build_array('id', 'settlementId', 'familyId', 'storagePath', 'fileType', 'originalFilename', 'proofKind', 'paymentMethod', 'referenceNote', 'settledAt', 'uploadState', 'uploadedBy', 'failureReason', 'deletedAt', 'deletedBy', 'deleteReason', 'replacedByProofId', 'createdAt'),
      'settlements', jsonb_build_array('id', 'familyId', 'paidBy', 'paidTo', 'amount', 'amountCents', 'currency', 'settlementDate', 'note', 'expenseId', 'periodStart', 'periodEnd', 'createdBy', 'createdAt'),
      'auditEvents', jsonb_build_array('id', 'familyId', 'entityType', 'entityId', 'actorId', 'eventType', 'metadata', 'createdAt')
    ),
    'attachments', jsonb_build_object(
      'included', false,
      'reason', 'MVP export includes attachment metadata only; private files remain in Supabase Storage.',
      'expenseAttachmentMetadataFields', jsonb_build_array(
        'id',
        'expenseId',
        'storagePath',
        'fileType',
        'originalFilename',
        'uploadedBy',
        'createdAt',
        'deletedAt',
        'deletedBy',
        'deleteReason',
        'replacedByAttachmentId'
      ),
      'settlementPaymentProofMetadataFields', jsonb_build_array(
        'id',
        'settlementId',
        'storagePath',
        'fileType',
        'originalFilename',
        'proofKind',
        'paymentMethod',
        'referenceNote',
        'settledAt',
        'uploadState',
        'uploadedBy',
        'failureReason',
        'deletedAt',
        'deletedBy',
        'deleteReason',
        'replacedByProofId',
        'createdAt'
      )
    ),
    'recordCounts', jsonb_build_object(
      'members', (select count(*) from member_rows),
      'children', (select count(*) from child_rows),
      'expenses', (select count(*) from expense_rows),
      'expenseAttachments', (select count(*) from attachment_rows),
      'settlementPaymentProofs', (select count(*) from settlement_payment_proof_rows),
      'settlements', (select count(*) from settlement_rows),
      'auditEvents', (select count(*) from audit_rows)
    ),
    'family', (
      select jsonb_build_object(
        'id', id,
        'name', name,
        'defaultCurrency', default_currency,
        'createdBy', created_by,
        'createdAt', created_at,
        'updatedAt', updated_at
      )
      from family_row
    ),
    'members', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', id,
          'familyId', family_id,
          'profileId', profile_id,
          'displayName', display_name,
          'email', email,
          'role', role,
          'status', status,
          'joinedAt', joined_at,
          'createdAt', created_at,
          'updatedAt', updated_at
        )
        order by created_at, id
      )
      from member_rows
    ), '[]'::jsonb),
    'children', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', id,
          'familyId', family_id,
          'firstName', first_name,
          'birthDate', birth_date,
          'isActive', is_active,
          'createdAt', created_at,
          'updatedAt', updated_at
        )
        order by first_name, created_at, id
      )
      from child_rows
    ), '[]'::jsonb),
    'expenses', coalesce((
      select jsonb_agg(
        jsonb_strip_nulls(jsonb_build_object(
          'id', id,
          'familyId', family_id,
          'childId', child_id,
          'paidBy', paid_by,
          'amount', amount,
          'amountCents', amount_cents,
          'currency', currency,
          'category', category,
          'description', description,
          'expenseDate', expense_date,
          'status', status,
          'statusComment', status_comment,
          'createdBy', created_by,
          'updatedBy', updated_by,
          'createdAt', created_at,
          'updatedAt', updated_at
        ))
        order by expense_date, created_at, id
      )
      from expense_rows
    ), '[]'::jsonb),
    'expenseAttachments', coalesce((
      select jsonb_agg(
        jsonb_strip_nulls(jsonb_build_object(
          'id', id,
          'expenseId', expense_id,
          'familyId', family_id,
          'storagePath', storage_path,
          'fileType', file_type,
          'originalFilename', original_filename,
          'uploadedBy', uploaded_by,
          'createdAt', created_at,
          'evidenceType', attachment_record->>'evidence_type',
          'documentDate', attachment_record->>'document_date',
          'merchant', attachment_record->>'merchant',
          'documentNumber', attachment_record->>'document_number',
          'paymentMethod', attachment_record->>'payment_method',
          'buyerNamePresent', attachment_record->'buyer_name_present',
          'deletedAt', attachment_record->>'deleted_at',
          'deletedBy', attachment_record->>'deleted_by',
          'deleteReason', attachment_record->>'delete_reason',
          'replacedByAttachmentId', attachment_record->>'replaced_by_attachment_id'
        ))
        order by created_at, id
      )
      from attachment_rows
    ), '[]'::jsonb),
    'settlementPaymentProofs', coalesce((
      select jsonb_agg(
        jsonb_strip_nulls(jsonb_build_object(
          'id', id,
          'settlementId', settlement_id,
          'familyId', family_id,
          'storagePath', storage_path,
          'fileType', file_type,
          'originalFilename', original_filename,
          'proofKind', proof_kind,
          'paymentMethod', payment_method,
          'referenceNote', reference_note,
          'settledAt', settled_at,
          'uploadState', upload_state,
          'uploadedBy', uploaded_by,
          'failureReason', failure_reason,
          'deletedAt', deleted_at,
          'deletedBy', deleted_by,
          'deleteReason', delete_reason,
          'replacedByProofId', replaced_by_proof_id,
          'createdAt', created_at
        ))
        order by settled_at, created_at, id
      )
      from settlement_payment_proof_rows
    ), '[]'::jsonb),
    'settlements', coalesce((
      select jsonb_agg(
        jsonb_strip_nulls(jsonb_build_object(
          'id', id,
          'familyId', family_id,
          'paidBy', paid_by,
          'paidTo', paid_to,
          'amount', amount,
          'amountCents', amount_cents,
          'currency', currency,
          'settlementDate', settlement_date,
          'note', note,
          'expenseId', expense_id,
          'periodStart', period_start,
          'periodEnd', period_end,
          'createdBy', created_by,
          'createdAt', created_at
        ))
        order by settlement_date, created_at, id
      )
      from settlement_rows
    ), '[]'::jsonb),
    'auditEvents', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', id,
          'familyId', family_id,
          'entityType', entity_type,
          'entityId', entity_id,
          'actorId', actor_id,
          'eventType', event_type,
          'metadata', metadata,
          'createdAt', created_at
        )
        order by created_at, id
      )
      from audit_rows
    ), '[]'::jsonb)
  )
  into export_payload;

  return export_payload;
end;
$$;

grant execute on function public.family_data_export(uuid) to authenticated;
