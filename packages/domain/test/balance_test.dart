import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testEqualSplitExample();
    testOneParentPaidEverything();
    testNoExpenses();
    testMultipleChildrenAreAggregated();
    testDifferentStatuses();
    testStatusMatchingIsCaseInsensitive();
    testIgnoredStatusesStayOutOfCustomIncludedSet();
    testSettlementReducesOpenTransfer();
    testSettlementCanFullyCloseTransfer();
    testCustomSplit();
    testChangingSplitFromEqualToSeventyThirtyRecalculatesBalance();
    testCustomSplitRejectsInvalidParticipants();
    testRoundingIsDeterministic();
    testDecimalParser();
  });
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

void testStatusMatchingIsCaseInsensitive() {
  final result = calculateBalance(
    splitRule: SplitRule.equal(['dad', 'mom']),
    expenses: const [
      ExpenseInput(
        id: 'accepted-uppercase',
        amountCents: 1000,
        paidBy: 'dad',
        status: ' ACCEPTED ',
      ),
      ExpenseInput(
        id: 'pending-mixed-case',
        amountCents: 1000,
        paidBy: 'mom',
        status: 'Pending',
      ),
    ],
  );

  expectEqual(result.totalCents, 2000);
  expectEqual(result.transfers.length, 0);
}

void testIgnoredStatusesStayOutOfCustomIncludedSet() {
  final result = calculateBalance(
    splitRule: SplitRule.equal(['dad', 'mom']),
    includedStatuses: const {'accepted', 'deleted', 'void'},
    expenses: const [
      ExpenseInput(
        id: 'accepted',
        amountCents: 1000,
        paidBy: 'dad',
        status: 'accepted',
      ),
      ExpenseInput(
        id: 'deleted',
        amountCents: 9000,
        paidBy: 'mom',
        status: 'deleted',
      ),
      ExpenseInput(
        id: 'void',
        amountCents: 9000,
        paidBy: 'mom',
        status: 'void',
      ),
    ],
  );

  expectEqual(result.totalCents, 1000);
  expectEqual(result.spentByParticipant['dad'], 1000);
  expectEqual(result.spentByParticipant['mom'], 0);
}

void testSettlementReducesOpenTransfer() {
  final result = calculateBalance(
    splitRule: SplitRule.equal(['dad', 'mom']),
    expenses: const [
      ExpenseInput(
        id: 'e1',
        amountCents: 6000,
        paidBy: 'dad',
        status: 'accepted',
      ),
    ],
    settlements: const [
      SettlementInput(
        id: 's1',
        amountCents: 1000,
        paidBy: 'mom',
        paidTo: 'dad',
      ),
    ],
  );

  expectEqual(result.transfers.length, 1);
  expectEqual(result.transfers.single.fromParticipantId, 'mom');
  expectEqual(result.transfers.single.toParticipantId, 'dad');
  expectEqual(result.transfers.single.amountCents, 2000);
}

void testSettlementCanFullyCloseTransfer() {
  final result = calculateBalance(
    splitRule: SplitRule.equal(['dad', 'mom']),
    expenses: const [
      ExpenseInput(
        id: 'e1',
        amountCents: 6000,
        paidBy: 'dad',
        status: 'accepted',
      ),
    ],
    settlements: const [
      SettlementInput(
        id: 's1',
        amountCents: 3000,
        paidBy: 'mom',
        paidTo: 'dad',
      ),
    ],
  );

  expectEqual(result.transfers.length, 0);
  expectEqual(
    result.participantBalances
        .where((balance) => balance.participantId == 'mom')
        .single
        .netCents,
    0,
  );
  expectEqual(
    result.participantBalances
        .where((balance) => balance.participantId == 'dad')
        .single
        .netCents,
    0,
  );
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

void testChangingSplitFromEqualToSeventyThirtyRecalculatesBalance() {
  const expenses = [
    ExpenseInput(
      id: 'school-fee',
      amountCents: 10000,
      paidBy: 'dad',
      status: 'accepted',
    ),
  ];

  final equalSplit = calculateBalance(
    splitRule: SplitRule.equal(['dad', 'mom']),
    expenses: expenses,
  );
  final seventyThirtySplit = calculateBalance(
    splitRule: SplitRule.custom({'dad': 70, 'mom': 30}),
    expenses: expenses,
  );

  expectEqual(equalSplit.targetShareByParticipant['dad'], 5000);
  expectEqual(equalSplit.targetShareByParticipant['mom'], 5000);
  expectEqual(equalSplit.transfers.single.amountCents, 5000);

  expectEqual(seventyThirtySplit.targetShareByParticipant['dad'], 7000);
  expectEqual(seventyThirtySplit.targetShareByParticipant['mom'], 3000);
  expectEqual(seventyThirtySplit.transfers.single.amountCents, 3000);
}

void testCustomSplitRejectsInvalidParticipants() {
  expectThrows(() => SplitRule.custom({' ': 1}));
  expectThrows(() => SplitRule.custom({'dad': 0, 'mom': 1}));
  expectThrows(() => SplitRule.custom({'dad': -1, 'mom': 1}));
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
