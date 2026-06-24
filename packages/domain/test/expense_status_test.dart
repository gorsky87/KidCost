import 'package:kidcost_domain/domain.dart';

void main() {
  testCounterpartyCanAcceptPendingExpense();
  testAuthorCannotAcceptOwnPendingExpense();
  testDisputeRequiresCounterpartyComment();
  testAcceptedExpenseCanBeSettled();
  testSettledExpenseIsTerminal();
  testDisputedExpenseCanReturnToAccepted();
  testCoreFieldsFreezeAfterReaction();
  testStatusParserNormalizesWireNames();
  testStatusEventNormalizesAuditData();
  testStatusEventRejectsBlankAuditIds();
}

void testCounterpartyCanAcceptPendingExpense() {
  expectTrue(
    canTransitionExpenseStatus(
      const ExpenseStatusTransition(
        from: ExpenseStatus.pending,
        to: ExpenseStatus.accepted,
        actor: ExpenseStatusActor.counterparty,
      ),
    ),
  );
}

void testAuthorCannotAcceptOwnPendingExpense() {
  expectFalse(
    canTransitionExpenseStatus(
      const ExpenseStatusTransition(
        from: ExpenseStatus.pending,
        to: ExpenseStatus.accepted,
        actor: ExpenseStatusActor.author,
      ),
    ),
  );
}

void testDisputeRequiresCounterpartyComment() {
  expectFalse(
    canTransitionExpenseStatus(
      const ExpenseStatusTransition(
        from: ExpenseStatus.pending,
        to: ExpenseStatus.disputed,
        actor: ExpenseStatusActor.counterparty,
      ),
    ),
  );

  expectTrue(
    canTransitionExpenseStatus(
      const ExpenseStatusTransition(
        from: ExpenseStatus.pending,
        to: ExpenseStatus.disputed,
        actor: ExpenseStatusActor.counterparty,
        comment: 'Missing receipt.',
      ),
    ),
  );
}

void testAcceptedExpenseCanBeSettled() {
  expectTrue(
    canTransitionExpenseStatus(
      const ExpenseStatusTransition(
        from: ExpenseStatus.accepted,
        to: ExpenseStatus.settled,
        actor: ExpenseStatusActor.author,
      ),
    ),
  );
}

void testSettledExpenseIsTerminal() {
  expectFalse(
    canTransitionExpenseStatus(
      const ExpenseStatusTransition(
        from: ExpenseStatus.settled,
        to: ExpenseStatus.disputed,
        actor: ExpenseStatusActor.counterparty,
        comment: 'Already paid elsewhere.',
      ),
    ),
  );
}

void testDisputedExpenseCanReturnToAccepted() {
  expectTrue(
    canTransitionExpenseStatus(
      const ExpenseStatusTransition(
        from: ExpenseStatus.disputed,
        to: ExpenseStatus.accepted,
        actor: ExpenseStatusActor.counterparty,
      ),
    ),
  );
}

void testCoreFieldsFreezeAfterReaction() {
  expectTrue(canEditExpenseCoreFields(ExpenseStatus.pending));
  expectFalse(canEditExpenseCoreFields(ExpenseStatus.accepted));
  expectFalse(canEditExpenseCoreFields(ExpenseStatus.disputed));
  expectFalse(canEditExpenseCoreFields(ExpenseStatus.settled));
}

void testStatusParserNormalizesWireNames() {
  expectEqual(ExpenseStatus.parse(' PENDING '), ExpenseStatus.pending);
  expectEqual(ExpenseStatus.parse('Accepted'), ExpenseStatus.accepted);
  expectEqual(ExpenseStatus.parse('disputed'), ExpenseStatus.disputed);
  expectEqual(ExpenseStatus.parse('SETTLED'), ExpenseStatus.settled);
  expectThrows(() => ExpenseStatus.parse('deleted'));
}

void testStatusEventNormalizesAuditData() {
  final event = buildExpenseStatusEvent(
    expenseId: ' expense-1 ',
    from: ExpenseStatus.pending,
    to: ExpenseStatus.disputed,
    actorId: ' parent-2 ',
    actor: ExpenseStatusActor.counterparty,
    occurredAt: DateTime.parse('2026-06-24T12:00:00+02:00'),
    comment: ' Missing receipt. ',
  );

  expectEqual(event.expenseId, 'expense-1');
  expectEqual(event.actorId, 'parent-2');
  expectEqual(event.comment, 'Missing receipt.');
  expectEqual(event.occurredAt.toIso8601String(), '2026-06-24T10:00:00.000Z');
}

void testStatusEventRejectsBlankAuditIds() {
  expectThrows(
    () => buildExpenseStatusEvent(
      expenseId: ' ',
      from: ExpenseStatus.pending,
      to: ExpenseStatus.accepted,
      actorId: 'parent-2',
      actor: ExpenseStatusActor.counterparty,
      occurredAt: DateTime.parse('2026-06-24T12:00:00Z'),
    ),
  );
  expectThrows(
    () => buildExpenseStatusEvent(
      expenseId: 'expense-1',
      from: ExpenseStatus.pending,
      to: ExpenseStatus.accepted,
      actorId: ' ',
      actor: ExpenseStatusActor.counterparty,
      occurredAt: DateTime.parse('2026-06-24T12:00:00Z'),
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
