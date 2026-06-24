import 'package:kidcost_domain/domain.dart';

void main() {
  testApprovedPaywallTriggersFollowValueMoments();
  testRejectedTriggersProtectCoreLedger();
  testPremiumAnalyticsTaxonomyUsesSafeProperties();
  testTrialMessagingAvoidsPressureAndOwnershipConfusion();
}

void testApprovedPaywallTriggersFollowValueMoments() {
  final approved = approvedPaywallTriggers();
  final triggerIds = {
    for (final definition in approved) definition.analyticsTriggerId,
  };

  expectTrue(triggerIds.contains('after_first_balance_viewed'));
  expectTrue(triggerIds.contains('after_first_receipt_attached'));
  expectTrue(triggerIds.contains('receipt_ocr_intent'));
  expectTrue(triggerIds.contains('pdf_report_preview'));
  expectTrue(triggerIds.contains('storage_limit_reached'));
  expectTrue(triggerIds.contains('history_limit_reached'));
  expectTrue(triggerIds.contains('after_coparent_invite'));
  expectTrue(approved.every((definition) => definition.valueMoment.isNotEmpty));
}

void testRejectedTriggersProtectCoreLedger() {
  final rejected = rejectedPaywallTriggers();
  final rejectedTriggers = {
    for (final definition in rejected) definition.trigger,
  };

  expectTrue(
    rejectedTriggers.contains(PaywallTrigger.beforeFirstManualExpense),
  );
  expectTrue(rejectedTriggers.contains(PaywallTrigger.signupBeforeLedger));
  expectTrue(rejectedTriggers.contains(PaywallTrigger.viewExistingExpense));
  expectTrue(firstManualExpenseCreationIsNeverBlocked());
}

void testPremiumAnalyticsTaxonomyUsesSafeProperties() {
  final eventNames = {
    for (final definition in kidCostPremiumAnalyticsEvents) definition.name,
  };

  expectTrue(eventNames.contains('premium_paywall_viewed'));
  expectTrue(eventNames.contains('premium_trial_started'));
  expectTrue(eventNames.contains('premium_trial_cancelled'));
  expectTrue(eventNames.contains('premium_upgraded'));
  expectTrue(eventNames.contains('premium_downgraded'));
  expectTrue(eventNames.contains('premium_feature_intent'));
  expectTrue(
    kidCostPremiumAnalyticsEvents.every(
      (definition) =>
          premiumAnalyticsPropertiesAreSafe(definition.requiredProperties),
    ),
  );
  expectFalse(premiumAnalyticsPropertiesAreSafe({'amount'}));
  expectFalse(premiumAnalyticsPropertiesAreSafe({'child_id'}));
  expectFalse(premiumAnalyticsPropertiesAreSafe({'family_id'}));
}

void testTrialMessagingAvoidsPressureAndOwnershipConfusion() {
  expectTrue(kidCostTrialMessagingPolicy.avoidsLegalFear);
  expectTrue(kidCostTrialMessagingPolicy.reminderDaysBeforeEnd >= 1);
  expectTrue(
    kidCostTrialMessagingPolicy.primaryCopy.contains('platnik nie staje sie'),
  );
  expectTrue(
    kidCostTrialMessagingPolicy.accessAfterTrialCopy.contains('nadal dostepne'),
  );
}

void expectTrue(bool value) {
  if (!value) {
    throw StateError('Expected value to be true.');
  }
}

void expectFalse(bool value) {
  if (value) {
    throw StateError('Expected value to be false.');
  }
}
