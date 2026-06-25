import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testFreePlanKeepsCoreLedgerAvailable();
    testFreeLimitsCanBlockNewUsageWithoutHidingExistingData();
    testPremiumUnlocksAutomationAndReports();
    testCalendarExportIsPremiumConvenience();
    testDowngradeKeepsCoreRecordsReadable();
    testFamilyPayerDoesNotBecomeSoleDataAdmin();
  });
}

void testFreePlanKeepsCoreLedgerAvailable() {
  final manualExpense = evaluateEntitlement(
    plan: KidCostPlan.free,
    feature: EntitlementFeature.manualExpenses,
  );
  final basicCsv = evaluateEntitlement(
    plan: KidCostPlan.free,
    feature: EntitlementFeature.basicCsvExport,
  );

  expectTrue(manualExpense.isAllowed);
  expectTrue(basicCsv.isAllowed);
}

void testFreeLimitsCanBlockNewUsageWithoutHidingExistingData() {
  final firstChild = evaluateEntitlement(
    plan: KidCostPlan.free,
    feature: EntitlementFeature.childProfiles,
    currentUsage: 1,
  );
  final thirdChild = evaluateEntitlement(
    plan: KidCostPlan.free,
    feature: EntitlementFeature.childProfiles,
    currentUsage: 2,
  );
  final definition = entitlementDefinitionFor(EntitlementFeature.childProfiles);

  expectTrue(firstChild.isAllowed);
  expectEqual(firstChild.remaining, 1);
  expectFalse(thirdChild.isAllowed);
  expectEqual(thirdChild.remaining, 0);
  expectTrue(definition.keepsExistingAccessOnDowngrade);
}

void testPremiumUnlocksAutomationAndReports() {
  final freeOcr = evaluateEntitlement(
    plan: KidCostPlan.free,
    feature: EntitlementFeature.receiptOcr,
  );
  final premiumOcr = evaluateEntitlement(
    plan: KidCostPlan.premium,
    feature: EntitlementFeature.receiptOcr,
  );
  final premiumPdf = evaluateEntitlement(
    plan: KidCostPlan.premium,
    feature: EntitlementFeature.pdfReports,
  );

  expectFalse(freeOcr.isAllowed);
  expectTrue(premiumOcr.isAllowed);
  expectTrue(premiumPdf.isAllowed);
}

void testCalendarExportIsPremiumConvenience() {
  final freeExport = evaluateEntitlement(
    plan: KidCostPlan.free,
    feature: EntitlementFeature.calendarIcsExport,
  );
  final premiumExport = evaluateEntitlement(
    plan: KidCostPlan.premium,
    feature: EntitlementFeature.calendarIcsExport,
  );
  final definition = entitlementDefinitionFor(
    EntitlementFeature.calendarIcsExport,
  );

  expectFalse(freeExport.isAllowed);
  expectTrue(premiumExport.isAllowed);
  expectTrue(definition.keepsExistingAccessOnDowngrade);
  expectTrue(definition.downgradeRule.contains('Dni opieki'));
}

void testDowngradeKeepsCoreRecordsReadable() {
  expectTrue(coreRecordsRemainReadableAfterDowngrade());
  expectTrue(
    entitlementDefinitionFor(
      EntitlementFeature.receiptStorageMb,
    ).downgradeRule.contains('czytelne'),
  );
  expectTrue(
    entitlementDefinitionFor(
      EntitlementFeature.pdfReports,
    ).downgradeRule.contains('Wygenerowane'),
  );
}

void testFamilyPayerDoesNotBecomeSoleDataAdmin() {
  expectTrue(familyBillingPolicy.payerCoversFamily);
  expectFalse(familyBillingPolicy.payerIsSoleDataAdmin);
  expectTrue(familyBillingPolicy.lapseKeepsCoreRecordsReadable);
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
