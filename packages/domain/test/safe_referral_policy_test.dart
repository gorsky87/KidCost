import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testReferralTriggersRewardHealthyCollaborationOnly();
    testDeclinedInviteNeverBlocksCoreTracking();
    testAbuseLimitsPreventDuplicateAndRapidRewards();
    testReferralCopyAvoidsPayerOwnershipAndPressure();
    testReferralAnalyticsTaxonomyUsesSafeProperties();
  });
}

void testReferralTriggersRewardHealthyCollaborationOnly() {
  final triggers = {
    for (final definition in kidCostSafeReferralPolicy.triggers)
      definition.trigger,
  };

  expectTrue(triggers.contains(ReferralTrigger.coParentInviteAccepted));
  expectTrue(triggers.contains(ReferralTrigger.firstSharedExpenseAcknowledged));
  expectTrue(triggers.contains(ReferralTrigger.firstReportShared));
  expectTrue(triggers.contains(ReferralTrigger.trustedHelperInvited));
  expectTrue(
    kidCostSafeReferralPolicy.triggers.every(
      (definition) =>
          definition.healthyCollaborationEvent &&
          definition.analyticsTriggerId.isNotEmpty &&
          definition.allowedSurfaces.isNotEmpty &&
          definition.reward.amount > 0,
    ),
  );
}

void testDeclinedInviteNeverBlocksCoreTracking() {
  final decision = evaluateReferralReward(
    const ReferralRewardRequest(
      trigger: ReferralTrigger.coParentInviteAccepted,
      invitedUserAccepted: false,
    ),
  );

  expectFalse(decision.isGranted);
  expectEqual(
    decision.reason,
    ReferralRewardDecisionReason.declinedOrIgnoredInvite,
  );
  expectTrue(decision.coreTrackingRemainsAvailable);
  expectTrue(safeReferralPolicyProtectsCoreAccess());
}

void testAbuseLimitsPreventDuplicateAndRapidRewards() {
  final duplicate = evaluateReferralReward(
    const ReferralRewardRequest(
      trigger: ReferralTrigger.coParentInviteAccepted,
      invitedUserAccepted: true,
      duplicateAccountSuspected: true,
    ),
  );
  final alreadyRewarded = evaluateReferralReward(
    const ReferralRewardRequest(
      trigger: ReferralTrigger.coParentInviteAccepted,
      invitedUserAccepted: true,
      hasPriorRewardForFamilyPair: true,
    ),
  );
  final cooldown = evaluateReferralReward(
    const ReferralRewardRequest(
      trigger: ReferralTrigger.firstReportShared,
      invitedUserAccepted: true,
      daysSinceLastReward: 7,
    ),
  );
  final granted = evaluateReferralReward(
    const ReferralRewardRequest(
      trigger: ReferralTrigger.firstReportShared,
      invitedUserAccepted: true,
      daysSinceLastReward: 45,
    ),
  );

  expectFalse(duplicate.isGranted);
  expectEqual(
    duplicate.reason,
    ReferralRewardDecisionReason.duplicateAccountSuspected,
  );
  expectFalse(alreadyRewarded.isGranted);
  expectEqual(
    alreadyRewarded.reason,
    ReferralRewardDecisionReason.alreadyRewardedFamilyPair,
  );
  expectFalse(cooldown.isGranted);
  expectEqual(cooldown.reason, ReferralRewardDecisionReason.cooldownActive);
  expectTrue(granted.isGranted);
  expectEqual(granted.reward?.type, ReferralRewardType.oneTimeReportCredit);
}

void testReferralCopyAvoidsPayerOwnershipAndPressure() {
  final policy = kidCostSafeReferralPolicy;
  final ruleCodes = {for (final rule in policy.antiCoercionRules) rule.code};

  expectTrue(ruleCodes.contains('payer_is_not_data_admin'));
  expectTrue(ruleCodes.contains('no_public_pressure'));
  expectTrue(policy.copy.soloMode.contains('nadal prowadzisz'));
  expectTrue(policy.copy.dismissal.contains('pominac'));
  expectTrue(policy.abuseLimits.oneRewardPerFamilyPair);
  expectTrue(policy.abuseLimits.cooldownDays >= 30);
  expectTrue(policy.abuseLimits.maxTrialExtensionDaysPerFamily <= 30);
}

void testReferralAnalyticsTaxonomyUsesSafeProperties() {
  final eventNames = {
    for (final definition in kidCostReferralAnalyticsEvents) definition.name,
  };

  expectTrue(eventNames.contains('referral_invite_prompt_viewed'));
  expectTrue(eventNames.contains('referral_invite_sent'));
  expectTrue(eventNames.contains('referral_invite_accepted'));
  expectTrue(eventNames.contains('referral_reward_granted'));
  expectTrue(eventNames.contains('referral_reward_used'));
  expectTrue(eventNames.contains('referral_invite_declined_or_ignored'));
  expectTrue(
    kidCostReferralAnalyticsEvents.every(
      (definition) =>
          referralAnalyticsPropertiesAreSafe(definition.requiredProperties),
    ),
  );
  expectFalse(referralAnalyticsPropertiesAreSafe({'email'}));
  expectFalse(referralAnalyticsPropertiesAreSafe({'family_id'}));
  expectFalse(referralAnalyticsPropertiesAreSafe({'child_id'}));
  expectFalse(referralAnalyticsPropertiesAreSafe({'expense_id'}));
  expectFalse(referralAnalyticsPropertiesAreSafe({'coparent_id'}));
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
