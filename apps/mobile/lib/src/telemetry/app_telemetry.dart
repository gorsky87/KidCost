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
  professionalAccessExpired('professional_access_expired');

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
};

bool _looksSensitive(String value) {
  return value.contains('@') ||
      value.contains(RegExp(r'\d+[,.]\d{2}')) ||
      value.length > 64;
}
