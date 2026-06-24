import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testDefaultRulesCoverExpenseCategories();
    testApprovalThresholdRequiresPriorAgreement();
    testNonShareableCategoriesAskForSeparateAgreement();
    testAgreementDocumentsBalanceAndStatusDependencies();
  });
}

void testDefaultRulesCoverExpenseCategories() {
  final ids = {
    for (final rule in kidCostSharedExpenseAgreement.rules) rule.categoryId,
  };

  expectTrue(ids.contains('food'));
  expectTrue(ids.contains('clothes'));
  expectTrue(ids.contains('school'));
  expectTrue(ids.contains('health'));
  expectTrue(ids.contains('activities'));
  expectTrue(ids.contains('holiday'));
  expectTrue(ids.contains('transport'));
  expectTrue(ids.contains('other'));
  expectTrue(sharedExpenseRulesForStage(AgreementSettingStage.mvp).isNotEmpty);
}

void testApprovalThresholdRequiresPriorAgreement() {
  final decision = evaluateSharedExpenseRule(
    categoryId: 'activities',
    amountCents: 25000,
  );

  expectTrue(decision.rule.isShareableByDefault);
  expectTrue(decision.requiresPriorApproval);
  expectTrue(decision.guidance.contains('prog uprzedniej zgody'));
  expectEqual(decision.rule.splitSummary, 'Domyslny podzial 50/50.');
}

void testNonShareableCategoriesAskForSeparateAgreement() {
  final decision = evaluateSharedExpenseRule(
    categoryId: 'holiday',
    amountCents: 5000,
  );

  expectFalse(decision.rule.isShareableByDefault);
  expectFalse(decision.requiresPriorApproval);
  expectTrue(decision.guidance.contains('osobnego ustalenia'));
}

void testAgreementDocumentsBalanceAndStatusDependencies() {
  expectTrue(
    kidCostSharedExpenseAgreement.reportDisclaimer.contains(
      'nie wnioski prawne',
    ),
  );
  expectTrue(kidCostSharedExpenseAgreement.balanceDependency.contains('50/50'));
  expectTrue(
    kidCostSharedExpenseAgreement.statusDependency.contains('pending'),
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
