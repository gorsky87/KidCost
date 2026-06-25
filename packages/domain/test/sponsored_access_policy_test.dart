import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testSponsorCanPayWithoutControllingSponsoredRecords();
    testSponsoredAccessStatesCoverCancellationRefundAndOverrides();
    testSponsoredPremiumCopyExplainsTheDataBoundary();
    testSponsoredPremiumAnalyticsAvoidSensitiveFamilyDetails();
  });
}

void testSponsorCanPayWithoutControllingSponsoredRecords() {
  final entitlement = SponsoredPremiumEntitlement(
    state: SponsoredPremiumState.active,
    renewalSource: SponsoredPremiumRenewalSource.sponsor,
    sponsorUserId: 'parent-a',
    sponsoredUserId: 'parent-b',
    startsOn: DateTime.utc(2026, 6, 1),
  );

  expectTrue(sponsoredPremiumKeepsBillingSeparateFromDataControl());
  expectTrue(
    evaluateSponsoredAccess(
      entitlement: entitlement,
      action: SponsoredAccessAction.payForPremium,
    ).isAllowed,
  );
  expectFalse(
    evaluateSponsoredAccess(
      entitlement: entitlement,
      action: SponsoredAccessAction.readSponsoredMemberRecords,
    ).isAllowed,
  );
  expectFalse(
    evaluateSponsoredAccess(
      entitlement: entitlement,
      action: SponsoredAccessAction.editSponsoredMemberRecords,
    ).isAllowed,
  );
  expectFalse(
    evaluateSponsoredAccess(
      entitlement: entitlement,
      action: SponsoredAccessAction.exportSponsoredMemberRecords,
    ).isAllowed,
  );
  expectFalse(
    evaluateSponsoredAccess(
      entitlement: entitlement,
      action: SponsoredAccessAction.changeSponsoredMemberFamilyRole,
    ).isAllowed,
  );
}

void testSponsoredAccessStatesCoverCancellationRefundAndOverrides() {
  expectTrue(
    SponsoredPremiumState.values.contains(
      SponsoredPremiumState.sponsorCancelled,
    ),
  );
  expectTrue(
    SponsoredPremiumState.values.contains(SponsoredPremiumState.memberRemoved),
  );
  expectTrue(
    SponsoredPremiumState.values.contains(SponsoredPremiumState.refunded),
  );
  expectTrue(
    SponsoredPremiumState.values.contains(
      SponsoredPremiumState.accountMismatch,
    ),
  );
  expectTrue(
    SponsoredPremiumState.values.contains(
      SponsoredPremiumState.feeWaiverOverride,
    ),
  );
}

void testSponsoredPremiumCopyExplainsTheDataBoundary() {
  final policy = kidCostSponsoredPremiumPrivacyPolicy;

  expectTrue(policy.keepsDataBoundaryExplicit);
  expectTrue(policy.copy.settingsSummary.contains('nie dostaje dostepu'));
  expectTrue(policy.copy.sponsoredMemberNotice.contains('eksportowac'));
  expectTrue(policy.copy.supportCorrection.contains('bez udostepniania'));
}

void testSponsoredPremiumAnalyticsAvoidSensitiveFamilyDetails() {
  final policy = kidCostSponsoredPremiumPrivacyPolicy;
  final forbiddenWords = ['child', 'dziecko', 'co_parent', 'legal', 'receipt'];

  expectTrue(
    policy.analyticsEvents.every(
      (event) => forbiddenWords.every((word) => !event.contains(word)),
    ),
  );
  expectTrue(
    policy.supportOperations.any((operation) => operation.contains('refund')),
  );
  expectTrue(
    policy.supportOperations.any(
      (operation) => operation.contains('account mismatch'),
    ),
  );
}

void expectTrue(bool value) {
  if (!value) throw StateError('Expected value to be true.');
}

void expectFalse(bool value) {
  if (value) throw StateError('Expected value to be false.');
}
