enum TelemetryEvent {
  signupStarted('signup_started'),
  signupCompleted('signup_completed'),
  familyCreated('family_created'),
  childAdded('child_added'),
  expenseCreated('expense_created'),
  quickExpenseStarted('quick_expense_started'),
  expenseStatusChanged('expense_status_changed'),
  receiptAttached('receipt_attached'),
  balanceViewed('balance_viewed'),
  reportViewed('report_viewed'),
  premiumPaywallViewed('premium_paywall_viewed'),
  premiumTrialStarted('premium_trial_started'),
  premiumTrialCancelled('premium_trial_cancelled'),
  premiumUpgraded('premium_upgraded'),
  premiumDowngraded('premium_downgraded'),
  premiumCancellationStarted('premium_cancellation_started'),
  premiumCancellationReasonSelected('premium_cancellation_reason_selected'),
  premiumCancellationSavePathSelected(
    'premium_cancellation_save_path_selected',
  ),
  premiumFeatureIntent('premium_feature_intent'),
  professionalAccessInvited('professional_access_invited'),
  professionalAccessAccepted('professional_access_accepted'),
  professionalReportViewed('professional_report_viewed'),
  professionalReportDownloaded('professional_report_downloaded'),
  professionalAccessRevoked('professional_access_revoked'),
  professionalAccessExpired('professional_access_expired'),
  reportPassPreviewViewed('report_pass_preview_viewed'),
  reportPassPurchaseStarted('report_pass_purchase_started'),
  reportPassPurchased('report_pass_purchased'),
  reportPassGenerationStarted('report_pass_generation_started'),
  reportPassGenerated('report_pass_generated'),
  reportPassDownloaded('report_pass_downloaded'),
  reportPassExpiredViewed('report_pass_expired_viewed'),
  reportPassRefundRequested('report_pass_refund_requested'),
  polishReportContextUpdated('polish_report_context_updated'),
  parentingTimeReportToggled('parenting_time_report_toggled'),
  betaFeedbackDraftPrepared('beta_feedback_draft_prepared'),
  contextLogEntryCreated('context_log_entry_created'),
  historicalImportPreviewed('historical_import_previewed'),
  plannedPurchaseCreated('planned_purchase_created'),
  plannedPurchaseStatusChanged('planned_purchase_status_changed'),
  plannedPurchaseConverted('planned_purchase_converted'),
  supportContextEntryCreated('support_context_entry_created');

  const TelemetryEvent(this.name);

  final String name;
}

abstract class AppTelemetry {
  const AppTelemetry();

  Future<void> track(
    TelemetryEvent event, {
    Map<String, Object?> parameters = const {},
  });

  void recordError(Object error, StackTrace stackTrace, {String? reason});

  void dispose() {}
}

class NoopTelemetry extends AppTelemetry {
  const NoopTelemetry();

  @override
  Future<void> track(
    TelemetryEvent event, {
    Map<String, Object?> parameters = const {},
  }) async {}

  @override
  void recordError(Object error, StackTrace stackTrace, {String? reason}) {}
}

Map<String, Object> sanitizeTelemetryParameters(Map<String, Object?> input) {
  final sanitized = <String, Object>{};
  for (final entry in input.entries) {
    if (!_allowedParameterKeys.contains(entry.key)) continue;
    final value = entry.value;
    if (value == null) continue;
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty || _looksSensitive(normalized)) continue;
      sanitized[entry.key] = normalized;
    } else if (value is bool || value is int) {
      sanitized[entry.key] = value;
    }
  }
  return sanitized;
}

const _allowedParameterKeys = {
  'release_channel',
  'build_name',
  'build_number',
  'is_demo',
  'screen',
  'category_id',
  'status',
  'from_status',
  'to_status',
  'actor',
  'has_attachment',
  'has_line_items',
  'line_item_count',
  'has_status_comment',
  'content_type',
  'invitation_skipped',
  'feature',
  'plan_context',
  'reason_code',
  'save_path',
  'entitlement_state',
  'platform_handoff',
  'surface',
  'trigger',
  'access_scope',
  'audit_action',
  'expires_in_days',
  'professional_role',
  'report_month',
  'pass_state',
  'range_type',
  'expense_count',
  'has_receipts',
  'has_disputed_items',
  'regenerations_remaining',
  'export_format',
  'benefit_800_context',
  'dobry_start_context',
  'has_child_tax_relief_note',
  'has_alternating_custody_note',
  'has_free_text_assumption',
  'import_type',
  'import_row_count',
  'import_file_count',
  'import_error_count',
  'import_duplicate_count',
  'draft_expense_count',
  'planned_purchase_count',
  'parenting_time_context_enabled',
  'custody_day_count',
  'has_detailed_export',
  'source',
  'feedback_category',
  'has_reimbursement_impact',
  'has_attachment_context',
  'known_limitations_count',
  'context_category',
  'context_visibility',
  'support_context_visibility',
  'linked_record_type',
  'include_context_in_report',
};

bool _looksSensitive(String value) {
  return value.contains('@') ||
      value.contains(RegExp(r'\d+[,.]\d{2}')) ||
      value.length > 64;
}
