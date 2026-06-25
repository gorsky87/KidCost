import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testCategoryDefaultsOverrideFamilyDefaults();
    testDueSoonAndOverdueStatesUseOpenDatesOnly();
    testPaidTimingComparesAgainstPaymentDueDate();
    testDeadlineExportFieldsStayStable();
    testDeadlineCopyAvoidsLegalConclusions();
  });
}

void testCategoryDefaultsOverrideFamilyDefaults() {
  final snapshot = buildReimbursementDeadlineSnapshot(
    requestCreatedAt: DateTime.utc(2026, 6, 1),
    submittedAt: DateTime.utc(2026, 6, 3),
    familyDefaults: const ReimbursementDeadlineDefaults(
      noticePeriod: Duration(days: 30),
      paymentPeriod: Duration(days: 30),
    ),
    categoryDefaults: const ReimbursementDeadlineDefaults(
      paymentPeriod: Duration(days: 14),
    ),
  );

  expectEqual(snapshot.noticeDueAt, DateTime.utc(2026, 7, 1));
  expectEqual(snapshot.paymentDueAt, DateTime.utc(2026, 6, 17));
  expectEqual(snapshot.submittedAt, DateTime.utc(2026, 6, 3));
}

void testDueSoonAndOverdueStatesUseOpenDatesOnly() {
  final dueSoon = buildReimbursementDeadlineSnapshot(
    requestCreatedAt: DateTime.utc(2026, 6, 1),
    noticeDueAt: DateTime.utc(2026, 6, 10),
  );

  expectEqual(
    dueSoon.timingState(now: DateTime.utc(2026, 6, 8)),
    ReimbursementDeadlineTimingState.dueSoon,
  );

  final overdue = buildReimbursementDeadlineSnapshot(
    requestCreatedAt: DateTime.utc(2026, 6, 1),
    submittedAt: DateTime.utc(2026, 6, 4),
    paymentDueAt: DateTime.utc(2026, 6, 20),
  );

  expectEqual(
    overdue.timingState(now: DateTime.utc(2026, 6, 21)),
    ReimbursementDeadlineTimingState.overdue,
  );
  expectTrue(overdue.isOverdue(DateTime.utc(2026, 6, 21)));
}

void testPaidTimingComparesAgainstPaymentDueDate() {
  final paidOnTime = buildReimbursementDeadlineSnapshot(
    requestCreatedAt: DateTime.utc(2026, 6, 1),
    submittedAt: DateTime.utc(2026, 6, 2),
    paymentDueAt: DateTime.utc(2026, 7, 2),
    paidAt: DateTime.utc(2026, 7, 2),
  );

  expectEqual(
    paidOnTime.timingState(now: DateTime.utc(2026, 7, 10)),
    ReimbursementDeadlineTimingState.paidOnTime,
  );

  final paidAfterDueDate = buildReimbursementDeadlineSnapshot(
    requestCreatedAt: DateTime.utc(2026, 6, 1),
    submittedAt: DateTime.utc(2026, 6, 2),
    paymentDueAt: DateTime.utc(2026, 7, 2),
    paidAt: DateTime.utc(2026, 7, 3),
  );

  expectEqual(
    paidAfterDueDate.timingState(now: DateTime.utc(2026, 7, 10)),
    ReimbursementDeadlineTimingState.paidAfterDueDate,
  );
}

void testDeadlineExportFieldsStayStable() {
  expectEqual(reimbursementDeadlineExportFields.length, 4);
  expectTrue(reimbursementDeadlineExportFields.contains('submitted_at'));
  expectTrue(reimbursementDeadlineExportFields.contains('notice_due_at'));
  expectTrue(reimbursementDeadlineExportFields.contains('payment_due_at'));
  expectTrue(reimbursementDeadlineExportFields.contains('paid_at'));
}

void testDeadlineCopyAvoidsLegalConclusions() {
  final packet = buildReimbursementRequestPacket(
    packetId: 'packet-deadline',
    createdAt: DateTime.utc(2026, 6, 8),
    deliveryChannel: ReimbursementRequestDeliveryChannel.emailReadyCopy,
    deadlines: buildReimbursementDeadlineSnapshot(
      requestCreatedAt: DateTime.utc(2026, 6, 1),
      noticeDueAt: DateTime.utc(2026, 6, 10),
    ),
    lines: [
      ReimbursementRequestExpenseLine(
        expenseId: 'expense-1',
        title: 'Dentysta',
        childLabel: 'Dziecko',
        categoryLabel: 'Zdrowie',
        incurredOn: DateTime.utc(2026, 6, 1),
        amountCents: 10000,
        requestedShareCents: 5000,
        statusLabel: 'Waiting for response',
        evidenceState: ReimbursementEvidenceState.attached,
      ),
    ],
  );

  final copy = reimbursementRequestShareText(packet).toLowerCase();
  expectTrue(copy.contains('due soon'));
  expectFalse(copy.contains('enforceable'));
  expectFalse(copy.contains('violation'));
  expectFalse(copy.contains('contempt'));
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
