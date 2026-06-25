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
    testMultiCirclePricingKeepsCirclesIsolated();
    testCircleCreationAndDowngradeConflicts();
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
  expectTrue(familyBillingPolicy.crossFamilyRecordsAreIsolated);
}

void testMultiCirclePricingKeepsCirclesIsolated() {
  expectEqual(multiCirclePricingPolicy.subscriptionScope, 'account');
  expectEqual(multiCirclePricingPolicy.freeCircleLimit, 1);
  expectEqual(multiCirclePricingPolicy.premiumCircleLimit, 5);
  expectTrue(multiCirclePricingPolicy.crossCircleReportsDefaultOff);
  expectTrue(
      multiCirclePricingPolicy.supportCanTransferBillingWithoutFamilyData);

  final families = entitlementDefinitionFor(EntitlementFeature.families);
  expectEqual(families.free.limit, 1);
  expectEqual(families.premium.limit, 5);
  expectTrue(families.downgradeRule.contains('czytelne'));
  expectTrue(families.rationale.contains('widocznosci danych'));
}

void testCircleCreationAndDowngradeConflicts() {
  final freeFirstCircle = evaluateCircleCreation(
    plan: KidCostPlan.free,
    activeCircleCount: 0,
  );
  final freeSecondCircle = evaluateCircleCreation(
    plan: KidCostPlan.free,
    activeCircleCount: 1,
  );
  final premiumFifthCircle = evaluateCircleCreation(
    plan: KidCostPlan.premium,
    activeCircleCount: 4,
  );
  final premiumSixthCircle = evaluateCircleCreation(
    plan: KidCostPlan.premium,
    activeCircleCount: 5,
  );

  expectTrue(freeFirstCircle.isAllowed);
  expectFalse(freeFirstCircle.requiresUpgrade);
  expectFalse(freeSecondCircle.isAllowed);
  expectTrue(freeSecondCircle.requiresUpgrade);
  expectTrue(freeSecondCircle.reason.contains('bez laczenia danych'));
  expectTrue(premiumFifthCircle.isAllowed);
  expectEqual(premiumFifthCircle.remaining, 1);
  expectFalse(premiumSixthCircle.isAllowed);
  expectFalse(premiumSixthCircle.requiresUpgrade);

  expectTrue(
    downgradeCreatesCircleConflict(
      targetPlan: KidCostPlan.free,
      activeCircleCount: 2,
    ),
  );
  expectFalse(
    downgradeCreatesCircleConflict(
      targetPlan: KidCostPlan.free,
      activeCircleCount: 1,
    ),
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
