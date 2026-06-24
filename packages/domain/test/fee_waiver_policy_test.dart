import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testLapsedSubscriptionKeepsHistoricalRecordsReadable();
    testFeeWaiverHasManualReviewDurationAndRenewal();
    testApplicationMinimizesSensitiveEvidence();
    testFollowUpTasksCoverEntitlementsAndAdminTooling();
  });
}

void testLapsedSubscriptionKeepsHistoricalRecordsReadable() {
  expectTrue(lapsedSubscriptionKeepsCoreRecordsReadable());
  expectTrue(kidCostFeeWaiverPolicy.copy.paymentFailure.contains('wstrzymane'));
  expectTrue(kidCostFeeWaiverPolicy.copy.paymentFailure.contains('pozostaja'));
}

void testFeeWaiverHasManualReviewDurationAndRenewal() {
  expectEqual(
    kidCostFeeWaiverPolicy.reviewOwner,
    FeeWaiverReviewOwner.supportTeam,
  );
  expectEqual(kidCostFeeWaiverPolicy.grant, FeeWaiverGrant.limitedPremium);
  expectTrue(kidCostFeeWaiverPolicy.durationDays >= 90);
  expectTrue(kidCostFeeWaiverPolicy.renewalWindowDays > 0);
}

void testApplicationMinimizesSensitiveEvidence() {
  expectTrue(kidCostFeeWaiverPolicy.avoidsSensitiveEvidenceCollection);
  expectTrue(kidCostFeeWaiverPolicy.retentionDaysAfterDecision <= 90);
  expectTrue(kidCostFeeWaiverPolicy.copy.privacy.contains('90 dni'));
}

void testFollowUpTasksCoverEntitlementsAndAdminTooling() {
  expectTrue(
    kidCostFeeWaiverPolicy.followUpTasks.any(
      (task) => task.contains('entitlement'),
    ),
  );
  expectTrue(
    kidCostFeeWaiverPolicy.followUpTasks.any(
      (task) => task.contains('support queue'),
    ),
  );
}

void expectTrue(bool value) {
  if (!value) throw StateError('Expected value to be true.');
}

void expectEqual(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected <$expected>, got <$actual>.');
  }
}
