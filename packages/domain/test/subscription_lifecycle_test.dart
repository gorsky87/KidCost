import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testEveryLifecycleStateHasAFeatureMatrix();
    testPaymentFailureStatesKeepHistoricalRecordsReadable();
    testPremiumLikeStatesAllowNewPremiumConvenience();
    testPausedAndExpiredStatesStopNewPremiumConvenience();
    testPlEuPricingPolicyUsesFamilyScopedPlnMonthlyBetaOffer();
    testPriceChangeAndOfferMechanicsAreReleaseRequirements();
    testSubscriptionAnalyticsTaxonomyUsesSafeProperties();
    testPremiumCancellationPolicyIsEthicalAndAnalyticsSafe();
  });
}

void testEveryLifecycleStateHasAFeatureMatrix() {
  expectTrue(allSubscriptionLifecycleStatesAreMapped());
  expectTrue(allSubscriptionStatesKeepCoreRecordsReadable());

  for (final state in SubscriptionLifecycleState.values) {
    final rule = subscriptionLifecycleRuleFor(state);
    expectTrue(rule.userMessage.isNotEmpty);
    expectTrue(rule.analyticsState.isNotEmpty);
    expectTrue(rule.releaseOperationRequirement.isNotEmpty);
    for (final feature in EntitlementFeature.values) {
      rule.featureRuleFor(feature);
    }
  }
}

void testPaymentFailureStatesKeepHistoricalRecordsReadable() {
  final states = {
    SubscriptionLifecycleState.gracePeriod,
    SubscriptionLifecycleState.billingRetry,
    SubscriptionLifecycleState.accountHold,
    SubscriptionLifecycleState.expired,
    SubscriptionLifecycleState.refunded,
  };

  for (final state in states) {
    final rule = subscriptionLifecycleRuleFor(state);
    expectTrue(rule.keepsCoreRecordsReadable);
    expectTrue(
      rule
          .featureRuleFor(EntitlementFeature.basicCsvExport)
          .keepsExistingRecordsReadable,
    );
    expectTrue(
      rule
          .featureRuleFor(EntitlementFeature.receiptStorageMb)
          .keepsExistingRecordsReadable,
    );
  }
}

void testPremiumLikeStatesAllowNewPremiumConvenience() {
  final states = {
    SubscriptionLifecycleState.trial,
    SubscriptionLifecycleState.activePremium,
    SubscriptionLifecycleState.gracePeriod,
    SubscriptionLifecycleState.canceledActiveUntilPeriodEnd,
    SubscriptionLifecycleState.feeWaiver,
  };

  for (final state in states) {
    final rule = subscriptionLifecycleRuleFor(state);
    expectEqual(rule.entitlementPlan, KidCostPlan.premium);
    expectTrue(rule.allowsNewPremiumConvenienceUse);
  }
}

void testPausedAndExpiredStatesStopNewPremiumConvenience() {
  final states = {
    SubscriptionLifecycleState.free,
    SubscriptionLifecycleState.billingRetry,
    SubscriptionLifecycleState.accountHold,
    SubscriptionLifecycleState.expired,
    SubscriptionLifecycleState.refunded,
  };

  for (final state in states) {
    final rule = subscriptionLifecycleRuleFor(state);
    final ocr = rule.featureRuleFor(EntitlementFeature.receiptOcr);
    expectFalse(rule.allowsNewPremiumConvenienceUse);
    expectFalse(ocr.allowsNewUse);
    expectTrue(ocr.keepsExistingRecordsReadable);
  }
}

void testPlEuPricingPolicyUsesFamilyScopedPlnMonthlyBetaOffer() {
  final policy = kidCostPlEuPricingPolicy;
  final primary = policy.primaryBetaOffer();

  expectEqual(policy.baseStorefrontCountryCode, 'PL');
  expectEqual(policy.baseCurrencyCode, 'PLN');
  expectEqual(primary.period, SubscriptionBillingPeriod.monthly);
  expectEqual(primary.currencyCode, 'PLN');
  expectTrue(primary.familyScoped);
  expectTrue(primary.priceMinorUnits > 0);
  expectTrue(
    policy.copy.billingOwnerDoesNotControlData.contains('nie staje sie'),
  );
  expectTrue(policy.copy.afterCancellation.contains('nadal widzisz'));
}

void testPriceChangeAndOfferMechanicsAreReleaseRequirements() {
  final mechanisms = kidCostPlEuPricingPolicy.futureSafeOfferMechanisms;

  expectTrue(kidCostPlEuPricingPolicy.priceChangeRequirement.contains('PL/EU'));
  expectTrue(
    mechanisms.contains(SubscriptionOfferMechanism.appStoreIntroductoryOffer),
  );
  expectTrue(mechanisms.contains(SubscriptionOfferMechanism.appStoreOfferCode));
  expectTrue(
    mechanisms.contains(SubscriptionOfferMechanism.appStoreWinBackOffer),
  );
  expectTrue(
    mechanisms.contains(SubscriptionOfferMechanism.googlePlayBasePlan),
  );
  expectTrue(mechanisms.contains(SubscriptionOfferMechanism.googlePlayOffer));
  expectTrue(
    mechanisms.contains(SubscriptionOfferMechanism.googlePlayAccountHold),
  );
}

void testSubscriptionAnalyticsTaxonomyUsesSafeProperties() {
  final eventNames = {
    for (final definition in kidCostSubscriptionAnalyticsEvents)
      definition.name,
  };

  expectTrue(eventNames.contains('subscription_lifecycle_changed'));
  expectTrue(eventNames.contains('subscription_recovery_prompt_viewed'));
  expectTrue(eventNames.contains('subscription_price_change_presented'));
  expectTrue(eventNames.contains('subscription_offer_redeemed'));
  expectTrue(
    kidCostSubscriptionAnalyticsEvents.every(
      (definition) =>
          subscriptionAnalyticsPropertiesAreSafe(definition.requiredProperties),
    ),
  );
  expectFalse(subscriptionAnalyticsPropertiesAreSafe({'amount'}));
  expectFalse(subscriptionAnalyticsPropertiesAreSafe({'child_id'}));
  expectFalse(subscriptionAnalyticsPropertiesAreSafe({'expense_note'}));
  expectFalse(subscriptionAnalyticsPropertiesAreSafe({'receipt_id'}));
  expectFalse(subscriptionAnalyticsPropertiesAreSafe({'coparent_id'}));
}

void testPremiumCancellationPolicyIsEthicalAndAnalyticsSafe() {
  final policy = kidCostPremiumCancellationPolicy;
  final eventNames = {
    for (final definition in kidCostSubscriptionAnalyticsEvents)
      definition.name,
  };

  expectTrue(cancellationReasonCodesAreUnique());
  expectTrue(cancellationSavePathCodesAreUnique());
  expectTrue(cancellationCopyAvoidsPressurePatterns());
  expectEqual(policy.reasons.length, PremiumCancellationReason.values.length);
  expectEqual(
    policy.savePaths.length,
    PremiumCancellationSavePath.values.length,
  );
  expectTrue(policy.recordsRemainReadable.contains('nadal widzisz'));
  expectTrue(
    policy.featureAccessPreview.any((copy) => copy.contains('Reczne koszty')),
  );
  expectTrue(policy.platformHandoffCopy.contains('App Store'));
  expectTrue(policy.platformHandoffCopy.contains('Google Play'));
  expectTrue(policy.analyticsRequirement.contains('reason_code'));
  expectTrue(policy.analyticsRequirement.contains('save_path'));
  expectTrue(eventNames.contains('premium_cancellation_started'));
  expectTrue(eventNames.contains('premium_cancellation_reason_selected'));
  expectTrue(eventNames.contains('premium_cancellation_save_path_selected'));
  expectTrue(
    subscriptionAnalyticsPropertiesAreSafe({
      'surface',
      'reason_code',
      'save_path',
      'entitlement_state',
      'platform_handoff',
    }),
  );
  expectFalse(subscriptionAnalyticsPropertiesAreSafe({'free_text_reason'}));
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
