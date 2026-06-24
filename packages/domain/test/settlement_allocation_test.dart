import 'package:kidcost_domain/domain.dart';

void main() {
  testPartialPaymentLeavesArrears();
  testOnePaymentCanCoverMultipleExpenses();
  testOverpaymentAndUnallocatedPaymentAreVisible();
  testDisputedAndDeletedExpensesAreNotAutoSettled();
}

void testPartialPaymentLeavesArrears() {
  final summary = allocateReimbursementPayments(
    expenses: const [SettlementExpenseInput(id: 'e1', owedCents: 5000)],
    payments: [
      ReimbursementPaymentInput(
        id: 'p1',
        amountCents: 2000,
        paidBy: 'mom',
        paidTo: 'dad',
        paidAt: DateTime.utc(2026, 6, 24),
        allocations: const [
          PaymentAllocationInput(expenseId: 'e1', amountCents: 2000),
        ],
      ),
    ],
  );

  expectEqual(summary.arrearsCents, 3000);
  expectEqual(summary.expenses.single.remainingCents, 3000);
  expectEqual(
    summary.expenses.single.state,
    SettlementAllocationState.partiallyPaid,
  );
}

void testOnePaymentCanCoverMultipleExpenses() {
  final summary = allocateReimbursementPayments(
    expenses: const [
      SettlementExpenseInput(id: 'e1', owedCents: 3000),
      SettlementExpenseInput(id: 'e2', owedCents: 2000),
    ],
    payments: [
      ReimbursementPaymentInput(
        id: 'p1',
        amountCents: 5000,
        paidBy: 'mom',
        paidTo: 'dad',
        paidAt: DateTime.utc(2026, 6, 24),
        allocations: const [
          PaymentAllocationInput(expenseId: 'e1', amountCents: 3000),
          PaymentAllocationInput(expenseId: 'e2', amountCents: 2000),
        ],
      ),
    ],
  );

  expectEqual(summary.arrearsCents, 0);
  expectEqual(summary.expenses[0].state, SettlementAllocationState.settled);
  expectEqual(summary.expenses[1].state, SettlementAllocationState.settled);
}

void testOverpaymentAndUnallocatedPaymentAreVisible() {
  final summary = allocateReimbursementPayments(
    expenses: const [SettlementExpenseInput(id: 'e1', owedCents: 3000)],
    payments: [
      ReimbursementPaymentInput(
        id: 'p1',
        amountCents: 6000,
        paidBy: 'mom',
        paidTo: 'dad',
        paidAt: DateTime.utc(2026, 6, 24),
        allocations: const [
          PaymentAllocationInput(expenseId: 'e1', amountCents: 4000),
        ],
      ),
    ],
  );

  expectEqual(summary.unallocatedCents, 2000);
  expectEqual(
    summary.expenses.single.state,
    SettlementAllocationState.overpaid,
  );
}

void testDisputedAndDeletedExpensesAreNotAutoSettled() {
  final summary = allocateReimbursementPayments(
    expenses: const [
      SettlementExpenseInput(
        id: 'disputed',
        owedCents: 1000,
        status: SettlementExpenseStatus.disputed,
      ),
      SettlementExpenseInput(
        id: 'deleted',
        owedCents: 1000,
        status: SettlementExpenseStatus.deleted,
      ),
    ],
    payments: const [],
  );

  expectEqual(summary.arrearsCents, 0);
  expectEqual(summary.expenses[0].state, SettlementAllocationState.disputed);
  expectEqual(
    summary.expenses[1].state,
    SettlementAllocationState.excludedDeleted,
  );
}

void expectEqual(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected <$expected>, got <$actual>.');
  }
}
