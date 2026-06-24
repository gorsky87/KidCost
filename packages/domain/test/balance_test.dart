import 'package:kidcost_domain/domain.dart';

void main() {
  testEqualSplitExample();
  testOneParentPaidEverything();
  testNoExpenses();
  testMultipleChildrenAreAggregated();
  testDifferentStatuses();
  testCustomSplit();
  testRoundingIsDeterministic();
  testDecimalParser();
}

void testEqualSplitExample() {
  final result = calculateBalance(
    splitRule: SplitRule.equal(['dad', 'mom']),
    expenses: const [
      ExpenseInput(
        id: 'e1',
        amountCents: 240000,
        paidBy: 'dad',
        status: 'accepted',
      ),
      ExpenseInput(
        id: 'e2',
        amountCents: 180000,
        paidBy: 'mom',
        status: 'accepted',
      ),
    ],
  );

  expectEqual(result.totalCents, 420000);
  expectEqual(result.spentByParticipant['dad'], 240000);
  expectEqual(result.spentByParticipant['mom'], 180000);
  expectEqual(result.targetShareByParticipant['dad'], 210000);
  expectEqual(result.targetShareByParticipant['mom'], 210000);
  expectEqual(result.transfers.length, 1);
  expectEqual(result.transfers.single.fromParticipantId, 'mom');
  expectEqual(result.transfers.single.toParticipantId, 'dad');
  expectEqual(result.transfers.single.amountCents, 30000);
}

void testOneParentPaidEverything() {
  final result = calculateBalance(
    splitRule: SplitRule.equal(['dad', 'mom']),
    expenses: const [
      ExpenseInput(
        id: 'e1',
        amountCents: 10000,
        paidBy: 'dad',
        status: 'pending',
      ),
    ],
  );

  expectEqual(result.transfers.length, 1);
  expectEqual(result.transfers.single.fromParticipantId, 'mom');
  expectEqual(result.transfers.single.toParticipantId, 'dad');
  expectEqual(result.transfers.single.amountCents, 5000);
}

void testNoExpenses() {
  final result = calculateBalance(
    splitRule: SplitRule.equal(['dad', 'mom']),
    expenses: const [],
  );

  expectEqual(result.totalCents, 0);
  expectEqual(result.transfers.length, 0);
  expectEqual(result.targetShareByParticipant['dad'], 0);
  expectEqual(result.targetShareByParticipant['mom'], 0);
}

void testMultipleChildrenAreAggregated() {
  final result = calculateBalance(
    splitRule: SplitRule.equal(['dad', 'mom']),
    expenses: const [
      ExpenseInput(
        id: 'e1',
        childId: 'child-a',
        amountCents: 3000,
        paidBy: 'dad',
        status: 'accepted',
      ),
      ExpenseInput(
        id: 'e2',
        childId: 'child-b',
        amountCents: 5000,
        paidBy: 'mom',
        status: 'accepted',
      ),
    ],
  );

  expectEqual(result.totalCents, 8000);
  expectEqual(result.transfers.length, 1);
  expectEqual(result.transfers.single.fromParticipantId, 'dad');
  expectEqual(result.transfers.single.toParticipantId, 'mom');
  expectEqual(result.transfers.single.amountCents, 1000);
}

void testDifferentStatuses() {
  final result = calculateBalance(
    splitRule: SplitRule.equal(['dad', 'mom']),
    expenses: const [
      ExpenseInput(
        id: 'pending',
        amountCents: 1000,
        paidBy: 'dad',
        status: 'pending',
      ),
      ExpenseInput(
        id: 'accepted',
        amountCents: 2000,
        paidBy: 'dad',
        status: 'accepted',
      ),
      ExpenseInput(
        id: 'settled',
        amountCents: 3000,
        paidBy: 'mom',
        status: 'settled',
      ),
      ExpenseInput(
        id: 'disputed',
        amountCents: 9000,
        paidBy: 'mom',
        status: 'disputed',
      ),
      ExpenseInput(
        id: 'deleted',
        amountCents: 9000,
        paidBy: 'mom',
        status: 'deleted',
      ),
    ],
  );

  expectEqual(result.totalCents, 6000);
  expectEqual(result.transfers.length, 0);
}

void testCustomSplit() {
  final result = calculateBalance(
    splitRule: SplitRule.custom({'dad': 70, 'mom': 30}),
    expenses: const [
      ExpenseInput(
        id: 'e1',
        amountCents: 10000,
        paidBy: 'dad',
        status: 'accepted',
      ),
    ],
  );

  expectEqual(result.targetShareByParticipant['dad'], 7000);
  expectEqual(result.targetShareByParticipant['mom'], 3000);
  expectEqual(result.transfers.length, 1);
  expectEqual(result.transfers.single.fromParticipantId, 'mom');
  expectEqual(result.transfers.single.toParticipantId, 'dad');
  expectEqual(result.transfers.single.amountCents, 3000);
}

void testRoundingIsDeterministic() {
  final result = calculateBalance(
    splitRule: SplitRule.equal(['a', 'b', 'c']),
    expenses: const [
      ExpenseInput(id: 'e1', amountCents: 100, paidBy: 'a', status: 'accepted'),
    ],
  );

  expectEqual(result.targetShareByParticipant['a'], 34);
  expectEqual(result.targetShareByParticipant['b'], 33);
  expectEqual(result.targetShareByParticipant['c'], 33);
  expectEqual(
    result.targetShareByParticipant.values.fold<int>(
      0,
      (sum, value) => sum + value,
    ),
    100,
  );
}

void testDecimalParser() {
  expectEqual(decimalAmountToCents('42'), 4200);
  expectEqual(decimalAmountToCents('42.5'), 4250);
  expectEqual(decimalAmountToCents('42.50'), 4250);
  expectThrows(() => decimalAmountToCents('42.501'));
  expectThrows(() => decimalAmountToCents('0'));
}

void expectEqual(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected <$expected>, got <$actual>.');
  }
}

void expectThrows(void Function() callback) {
  var didThrow = false;
  try {
    callback();
  } catch (_) {
    didThrow = true;
  }
  if (!didThrow) {
    throw StateError('Expected callback to throw.');
  }
}
