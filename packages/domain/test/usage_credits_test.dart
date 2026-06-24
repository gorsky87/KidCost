import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testCreditGrantRulesCoverMvpSources();
    testCreditLedgerCalculatesConsumptionReversalAndExpiry();
    testLedgerFieldsCaptureBalanceConsumptionAndAuditMetadata();
    testSuccessfulJobsSpendCreditsAndFailuresDoNotCharge();
    testCoreLedgerAccessIsNeverGatedByUsageCredits();
    testUsageCreditAnalyticsTaxonomyUsesSafeProperties();
    testCanceledAndExpiredStatesKeepExistingCreditsPolicyExplicit();
  });
}

void testCreditGrantRulesCoverMvpSources() {
  final sources = {
    for (final rule in kidCostUsageCreditGrantRules) rule.source,
  };

  expectTrue(sources.contains(UsageCreditGrantSource.freeMonthlyAllowance));
  expectTrue(sources.contains(UsageCreditGrantSource.premiumMonthlyBundle));
  expectTrue(sources.contains(UsageCreditGrantSource.premiumAnnualBundle));
  expectTrue(sources.contains(UsageCreditGrantSource.referralReward));
  expectTrue(sources.contains(UsageCreditGrantSource.hardshipSupportGrant));
  expectTrue(sources.contains(UsageCreditGrantSource.adminAdjustment));
  expectTrue(sources.contains(UsageCreditGrantSource.addOnPurchase));

  final freeRule = usageCreditGrantRuleFor(
    UsageCreditGrantSource.freeMonthlyAllowance,
  );
  final premiumRule = usageCreditGrantRuleFor(
    UsageCreditGrantSource.premiumMonthlyBundle,
  );
  final hardshipRule = usageCreditGrantRuleFor(
    UsageCreditGrantSource.hardshipSupportGrant,
  );

  expectTrue(freeRule.amountFor(UsageCreditType.receiptOcr) > 0);
  expectEqual(freeRule.amountFor(UsageCreditType.premiumReport), 0);
  expectTrue(premiumRule.amountFor(UsageCreditType.premiumReport) > 0);
  expectTrue(hardshipRule.requiresSupportAudit);
}

void testCreditLedgerCalculatesConsumptionReversalAndExpiry() {
  final now = DateTime.utc(2026, 6, 24, 12);
  final grant = buildUsageCreditGrantEntry(
    id: 'grant-1',
    scope: UsageCreditScope.family,
    scopeId: 'family-1',
    type: UsageCreditType.receiptOcr,
    source: UsageCreditGrantSource.premiumMonthlyBundle,
    lifecycleState: SubscriptionLifecycleState.activePremium,
    grantedAt: now,
    auditActor: 'system',
  );
  final consumed = buildUsageCreditConsumptionEntry(
    id: 'consume-1',
    scope: UsageCreditScope.family,
    scopeId: 'family-1',
    type: UsageCreditType.receiptOcr,
    consumedAt: now.add(const Duration(hours: 1)),
    auditActor: 'ocr-worker',
    relatedFeatureEvent: 'receipt_ocr_completed',
    amount: 3,
  );
  final reversed = buildUsageCreditReversalEntry(
    id: 'reverse-1',
    scope: UsageCreditScope.family,
    scopeId: 'family-1',
    type: UsageCreditType.receiptOcr,
    reversedAt: now.add(const Duration(hours: 2)),
    auditActor: 'support',
    reason: UsageCreditLedgerReason.refundReversal,
    amount: 2,
  );

  final balance = calculateUsageCreditBalance(
    entries: [grant, consumed, reversed],
    type: UsageCreditType.receiptOcr,
    asOf: now.add(const Duration(days: 2)),
  );
  expectEqual(balance.granted, 50);
  expectEqual(balance.consumed, 3);
  expectEqual(balance.reversed, 2);
  expectEqual(balance.available, 45);
  expectEqual(balance.expired, 0);

  final expiredBalance = calculateUsageCreditBalance(
    entries: [grant, consumed, reversed],
    type: UsageCreditType.receiptOcr,
    asOf: now.add(const Duration(days: 40)),
  );
  expectEqual(expiredBalance.available, 0);
  expectEqual(expiredBalance.expired, 45);
}

void testLedgerFieldsCaptureBalanceConsumptionAndAuditMetadata() {
  final now = DateTime.utc(2026, 6, 24, 12);
  final grant = buildUsageCreditGrantEntry(
    id: 'grant-1',
    scope: UsageCreditScope.family,
    scopeId: 'family-1',
    type: UsageCreditType.receiptOcr,
    source: UsageCreditGrantSource.freeMonthlyAllowance,
    lifecycleState: SubscriptionLifecycleState.free,
    grantedAt: now,
    auditActor: 'system',
    balanceAfter: 2,
    auditMetadataKeys: {'ledger_policy_version'},
  );
  final consumed = buildUsageCreditConsumptionEntry(
    id: 'consume-1',
    scope: UsageCreditScope.family,
    scopeId: 'family-1',
    type: UsageCreditType.receiptOcr,
    consumedAt: now.add(const Duration(minutes: 10)),
    auditActor: 'ocr-worker',
    relatedFeatureEvent: 'receipt_ocr_completed',
    balanceAfter: 1,
    auditMetadataKeys: {'job_result', 'worker_attempt'},
  );

  expectEqual(grant.balanceAfter, 2);
  expectTrue(grant.grantReason!.contains('Free allowance'));
  expectTrue(grant.auditMetadataKeys.contains('ledger_policy_version'));
  expectEqual(consumed.consumedAt, now.add(const Duration(minutes: 10)));
  expectEqual(consumed.balanceAfter, 1);
  expectTrue(usageCreditAuditMetadataKeysAreSafe(consumed.auditMetadataKeys));
  expectFalse(usageCreditAuditMetadataKeysAreSafe({'child_id'}));
  expectFalse(usageCreditAuditMetadataKeysAreSafe({'receipt_text'}));
}

void testSuccessfulJobsSpendCreditsAndFailuresDoNotCharge() {
  final now = DateTime.utc(2026, 6, 24, 12);
  final grant = buildUsageCreditGrantEntry(
    id: 'grant-1',
    scope: UsageCreditScope.user,
    scopeId: 'user-1',
    type: UsageCreditType.premiumReport,
    source: UsageCreditGrantSource.referralReward,
    lifecycleState: SubscriptionLifecycleState.free,
    grantedAt: now,
    auditActor: 'system',
  );

  final failed = evaluateUsageCreditSpend(
    entries: [grant],
    type: UsageCreditType.premiumReport,
    asOf: now.add(const Duration(minutes: 5)),
    jobSucceeded: false,
  );
  expectTrue(failed.isAllowed);
  expectFalse(failed.consumesCredit);
  expectEqual(failed.remainingAfter, 1);

  final successful = evaluateUsageCreditSpend(
    entries: [grant],
    type: UsageCreditType.premiumReport,
    asOf: now.add(const Duration(minutes: 5)),
  );
  expectTrue(successful.isAllowed);
  expectTrue(successful.consumesCredit);
  expectEqual(successful.remainingAfter, 0);

  final denied = evaluateUsageCreditSpend(
    entries: [],
    type: UsageCreditType.premiumReport,
    asOf: now,
  );
  expectFalse(denied.isAllowed);
  expectFalse(denied.consumesCredit);
  expectEqual(denied.remainingAfter, 0);
}

void testCoreLedgerAccessIsNeverGatedByUsageCredits() {
  expectFalse(
    usageCreditsCanGateAction(UsageCreditFeatureAction.manualExpenseCreation),
  );
  expectFalse(
    usageCreditsCanGateAction(UsageCreditFeatureAction.existingRecordAccess),
  );
  expectFalse(
    usageCreditsCanGateAction(UsageCreditFeatureAction.basicCsvExport),
  );
  expectFalse(
    usageCreditsCanGateAction(
      UsageCreditFeatureAction.receiptAttachmentStorage,
    ),
  );
  expectTrue(
    usageCreditsCanGateAction(UsageCreditFeatureAction.receiptOcrExtraction),
  );
  expectTrue(
    usageCreditsCanGateAction(UsageCreditFeatureAction.premiumReportGeneration),
  );
}

void testUsageCreditAnalyticsTaxonomyUsesSafeProperties() {
  final eventNames = {
    for (final definition in kidCostUsageCreditAnalyticsEvents) definition.name,
  };

  expectTrue(eventNames.contains('usage_credit_granted'));
  expectTrue(eventNames.contains('usage_credit_consumed'));
  expectTrue(eventNames.contains('usage_credit_job_failed_no_charge'));
  expectTrue(eventNames.contains('usage_credit_reversed'));
  expectTrue(allUsageCreditAnalyticsEventsAreSafe());
  expectFalse(usageCreditAnalyticsPropertiesAreSafe({'child_id'}));
  expectFalse(usageCreditAnalyticsPropertiesAreSafe({'receipt_text'}));
  expectFalse(usageCreditAnalyticsPropertiesAreSafe({'expense_note'}));
  expectFalse(usageCreditAnalyticsPropertiesAreSafe({'attachment_content'}));
  expectFalse(usageCreditAnalyticsPropertiesAreSafe({'amount'}));
}

void testCanceledAndExpiredStatesKeepExistingCreditsPolicyExplicit() {
  final premiumRule = usageCreditGrantRuleFor(
    UsageCreditGrantSource.premiumMonthlyBundle,
  );
  final referralRule = usageCreditGrantRuleFor(
    UsageCreditGrantSource.referralReward,
  );
  final hardshipRule = usageCreditGrantRuleFor(
    UsageCreditGrantSource.hardshipSupportGrant,
  );
  final addOnRule = usageCreditGrantRuleFor(
    UsageCreditGrantSource.addOnPurchase,
  );

  expectTrue(
    premiumRule.isEligibleFor(
      SubscriptionLifecycleState.canceledActiveUntilPeriodEnd,
    ),
  );
  expectFalse(premiumRule.isEligibleFor(SubscriptionLifecycleState.expired));
  expectTrue(referralRule.isEligibleFor(SubscriptionLifecycleState.expired));
  expectTrue(hardshipRule.isEligibleFor(SubscriptionLifecycleState.refunded));
  expectFalse(
    addOnRule.isEligibleFor(SubscriptionLifecycleState.activePremium),
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

void expectEqual(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected <$expected>, got <$actual>.');
  }
}
