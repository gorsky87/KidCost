import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testAllSponsoredPremiumStatesAreMapped();
    testSponsorPaysWithoutControllingSponsoredRecords();
    testFeeWaiverAndMismatchStatesAvoidSponsorLeverage();
    testSponsoredPremiumAnalyticsAvoidSensitiveProperties();
  });
}

void testAllSponsoredPremiumStatesAreMapped() {
  expectTrue(sponsoredPremiumStatesAreMapped());

  for (final state in SponsoredPremiumState.values) {
    final rule = kidCostSponsoredPremiumPolicy.ruleFor(state);
    expectTrue(rule.renewalSource.isNotEmpty);
    expectTrue(rule.summary.isNotEmpty);
  }
}

void testSponsorPaysWithoutControllingSponsoredRecords() {
  final policy = kidCostSponsoredPremiumPolicy;

  expectTrue(policy.sponsorCannotControlSponsoredRecords);
  expectTrue(
    policy.permissionAllowed(
      actor: SponsoredPremiumActor.sponsor,
      permission: SponsoredPremiumPermission.payForSeat,
    ),
  );
  expectTrue(
    policy.permissionAllowed(
      actor: SponsoredPremiumActor.sponsor,
      permission: SponsoredPremiumPermission.cancelSponsorship,
    ),
  );
  expectFalse(
    policy.permissionAllowed(
      actor: SponsoredPremiumActor.sponsor,
      permission: SponsoredPremiumPermission.viewSponsoredMemberRecords,
    ),
  );
  expectFalse(
    policy.permissionAllowed(
      actor: SponsoredPremiumActor.sponsor,
      permission: SponsoredPremiumPermission.editSponsoredMemberRecords,
    ),
  );
  expectFalse(
    policy.permissionAllowed(
      actor: SponsoredPremiumActor.sponsor,
      permission: SponsoredPremiumPermission.exportSponsoredMemberRecords,
    ),
  );
  expectFalse(
    policy.permissionAllowed(
      actor: SponsoredPremiumActor.sponsor,
      permission: SponsoredPremiumPermission.manageSponsoredMemberRole,
    ),
  );
  expectTrue(policy.copy.sponsorBoundary.contains('nie zmienia roli'));
}

void testFeeWaiverAndMismatchStatesAvoidSponsorLeverage() {
  final feeWaiverRule = kidCostSponsoredPremiumPolicy.ruleFor(
    SponsoredPremiumState.feeWaiverOverride,
  );
  final mismatchRule = kidCostSponsoredPremiumPolicy.ruleFor(
    SponsoredPremiumState.accountMismatch,
  );

  expectTrue(feeWaiverRule.memberHasPremium);
  expectEqual(feeWaiverRule.renewalSource, 'support_fee_waiver');
  expectFalse(mismatchRule.memberHasPremium);
  expectEqual(mismatchRule.renewalSource, 'support_review');
  expectTrue(
    kidCostSponsoredPremiumPolicy.copy.supportTransfer.contains(
      'bez pokazywania sponsorowi',
    ),
  );
}

void testSponsoredPremiumAnalyticsAvoidSensitiveProperties() {
  final policy = kidCostSponsoredPremiumPolicy;

  expectEqual(
    policy.analyticsEvents.length,
    SponsoredPremiumAnalyticsEvent.values.length,
  );
  expectTrue(
    policy.analyticsPropertiesAreSafe({
      'surface',
      'sponsorship_state',
      'renewal_source',
      'actor_type',
    }),
  );
  expectFalse(policy.analyticsPropertiesAreSafe({'child_name'}));
  expectFalse(policy.analyticsPropertiesAreSafe({'coparent_name'}));
  expectFalse(policy.analyticsPropertiesAreSafe({'receipt_content'}));
  expectFalse(policy.analyticsPropertiesAreSafe({'legal_context'}));
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
