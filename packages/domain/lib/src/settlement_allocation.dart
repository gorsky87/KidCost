enum SettlementExpenseStatus { active, disputed, deleted }

enum SettlementAllocationState {
  unpaid,
  partiallyPaid,
  settled,
  overpaid,
  disputed,
  excludedDeleted,
}

class SettlementExpenseInput {
  const SettlementExpenseInput({
    required this.id,
    required this.owedCents,
    this.status = SettlementExpenseStatus.active,
  });

  final String id;
  final int owedCents;
  final SettlementExpenseStatus status;
}

class PaymentAllocationInput {
  const PaymentAllocationInput({
    required this.amountCents,
    this.expenseId,
    this.periodStart,
    this.periodEnd,
  });

  final int amountCents;
  final String? expenseId;
  final String? periodStart;
  final String? periodEnd;
}

class ReimbursementPaymentInput {
  const ReimbursementPaymentInput({
    required this.id,
    required this.amountCents,
    required this.paidBy,
    required this.paidTo,
    required this.paidAt,
    required this.allocations,
  });

  final String id;
  final int amountCents;
  final String paidBy;
  final String paidTo;
  final DateTime paidAt;
  final List<PaymentAllocationInput> allocations;
}

class ExpenseAllocationResult {
  const ExpenseAllocationResult({
    required this.expenseId,
    required this.owedCents,
    required this.allocatedCents,
    required this.remainingCents,
    required this.state,
  });

  final String expenseId;
  final int owedCents;
  final int allocatedCents;
  final int remainingCents;
  final SettlementAllocationState state;
}

class SettlementAllocationSummary {
  const SettlementAllocationSummary({
    required this.expenses,
    required this.unallocatedCents,
    required this.arrearsCents,
  });

  final List<ExpenseAllocationResult> expenses;
  final int unallocatedCents;
  final int arrearsCents;
}

const partialSettlementUiStates = {
  SettlementAllocationState.unpaid: 'Do zaplaty',
  SettlementAllocationState.partiallyPaid: 'Czesciowo zaplacone',
  SettlementAllocationState.settled: 'Rozliczone',
  SettlementAllocationState.overpaid: 'Nadplata do wyjasnienia',
  SettlementAllocationState.disputed: 'Sporne - nie rozliczaj automatycznie',
  SettlementAllocationState.excludedDeleted: 'Usuniete - poza saldem',
};

const partialSettlementAuditEvents = {
  'payment_allocation_created',
  'payment_allocation_changed',
  'payment_allocation_removed',
  'payment_allocation_overpaid',
};

SettlementAllocationSummary allocateReimbursementPayments({
  required Iterable<SettlementExpenseInput> expenses,
  required Iterable<ReimbursementPaymentInput> payments,
}) {
  final expenseById = <String, SettlementExpenseInput>{};
  for (final expense in expenses) {
    final id = expense.id.trim();
    if (id.isEmpty) throw ArgumentError('Expense id cannot be empty.');
    if (expense.owedCents <= 0) {
      throw ArgumentError('Owed amount must be greater than zero.');
    }
    expenseById[id] = expense;
  }

  final allocatedByExpense = <String, int>{};
  var unallocated = 0;
  for (final payment in payments) {
    if (payment.amountCents <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }
    if (payment.paidBy.trim().isEmpty || payment.paidTo.trim().isEmpty) {
      throw ArgumentError('Payment participants cannot be empty.');
    }

    var allocatedFromPayment = 0;
    for (final allocation in payment.allocations) {
      if (allocation.amountCents <= 0) {
        throw ArgumentError('Allocation amount must be greater than zero.');
      }
      allocatedFromPayment += allocation.amountCents;
      final expenseId = allocation.expenseId?.trim();
      if (expenseId == null || expenseId.isEmpty) {
        unallocated += allocation.amountCents;
        continue;
      }
      if (!expenseById.containsKey(expenseId)) {
        unallocated += allocation.amountCents;
        continue;
      }
      allocatedByExpense[expenseId] =
          (allocatedByExpense[expenseId] ?? 0) + allocation.amountCents;
    }
    if (allocatedFromPayment > payment.amountCents) {
      throw ArgumentError('Allocations cannot exceed payment amount.');
    }
    unallocated += payment.amountCents - allocatedFromPayment;
  }

  final results = <ExpenseAllocationResult>[];
  var arrears = 0;
  for (final expense in expenseById.values) {
    final allocated = allocatedByExpense[expense.id] ?? 0;
    final remaining = expense.owedCents - allocated;
    final state = _allocationState(expense, allocated);
    if (state == SettlementAllocationState.unpaid ||
        state == SettlementAllocationState.partiallyPaid) {
      arrears += remaining;
    }
    results.add(
      ExpenseAllocationResult(
        expenseId: expense.id,
        owedCents: expense.owedCents,
        allocatedCents: allocated,
        remainingCents: remaining < 0 ? 0 : remaining,
        state: state,
      ),
    );
  }

  return SettlementAllocationSummary(
    expenses: List.unmodifiable(results),
    unallocatedCents: unallocated,
    arrearsCents: arrears,
  );
}

SettlementAllocationState _allocationState(
  SettlementExpenseInput expense,
  int allocatedCents,
) {
  if (expense.status == SettlementExpenseStatus.deleted) {
    return SettlementAllocationState.excludedDeleted;
  }
  if (expense.status == SettlementExpenseStatus.disputed) {
    return SettlementAllocationState.disputed;
  }
  if (allocatedCents == 0) return SettlementAllocationState.unpaid;
  if (allocatedCents < expense.owedCents) {
    return SettlementAllocationState.partiallyPaid;
  }
  if (allocatedCents == expense.owedCents) {
    return SettlementAllocationState.settled;
  }
  return SettlementAllocationState.overpaid;
}
