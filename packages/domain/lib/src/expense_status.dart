enum ExpenseStatus {
  pending('pending'),
  accepted('accepted'),
  disputed('disputed'),
  settled('settled');

  const ExpenseStatus(this.wireName);

  final String wireName;

  static ExpenseStatus parse(String value) {
    final normalized = value.trim().toLowerCase();
    for (final status in ExpenseStatus.values) {
      if (status.wireName == normalized) {
        return status;
      }
    }
    throw ArgumentError('Unknown expense status: $value.');
  }
}

enum ExpenseStatusActor { author, counterparty, system }

class ExpenseStatusTransition {
  const ExpenseStatusTransition({
    required this.from,
    required this.to,
    required this.actor,
    this.comment,
  });

  final ExpenseStatus from;
  final ExpenseStatus to;
  final ExpenseStatusActor actor;
  final String? comment;
}

class ExpenseStatusEvent {
  const ExpenseStatusEvent({
    required this.expenseId,
    required this.from,
    required this.to,
    required this.actorId,
    required this.actor,
    required this.occurredAt,
    this.comment,
  });

  final String expenseId;
  final ExpenseStatus from;
  final ExpenseStatus to;
  final String actorId;
  final ExpenseStatusActor actor;
  final DateTime occurredAt;
  final String? comment;
}

bool canTransitionExpenseStatus(ExpenseStatusTransition transition) {
  if (transition.from == transition.to) {
    return false;
  }

  if (_requiresCounterparty(transition) &&
      transition.actor != ExpenseStatusActor.counterparty) {
    return false;
  }

  if (_requiresDisputeComment(transition) &&
      (transition.comment == null || transition.comment!.trim().isEmpty)) {
    return false;
  }

  return _allowedTransitions[transition.from]?.contains(transition.to) ?? false;
}

bool canEditExpenseCoreFields(ExpenseStatus status) {
  return status == ExpenseStatus.pending;
}

ExpenseStatusEvent buildExpenseStatusEvent({
  required String expenseId,
  required ExpenseStatus from,
  required ExpenseStatus to,
  required String actorId,
  required ExpenseStatusActor actor,
  required DateTime occurredAt,
  String? comment,
}) {
  final transition = ExpenseStatusTransition(
    from: from,
    to: to,
    actor: actor,
    comment: comment,
  );
  if (!canTransitionExpenseStatus(transition)) {
    throw ArgumentError('Expense status transition is not allowed.');
  }

  final normalizedExpenseId = expenseId.trim();
  final normalizedActorId = actorId.trim();
  if (normalizedExpenseId.isEmpty) {
    throw ArgumentError('Expense id cannot be empty.');
  }
  if (normalizedActorId.isEmpty) {
    throw ArgumentError('Actor id cannot be empty.');
  }

  return ExpenseStatusEvent(
    expenseId: normalizedExpenseId,
    from: from,
    to: to,
    actorId: normalizedActorId,
    actor: actor,
    occurredAt: occurredAt.toUtc(),
    comment: comment?.trim(),
  );
}

const _allowedTransitions = {
  ExpenseStatus.pending: {ExpenseStatus.accepted, ExpenseStatus.disputed},
  ExpenseStatus.accepted: {ExpenseStatus.settled},
  ExpenseStatus.disputed: {ExpenseStatus.accepted},
  ExpenseStatus.settled: <ExpenseStatus>{},
};

bool _requiresCounterparty(ExpenseStatusTransition transition) {
  return transition.from == ExpenseStatus.pending &&
      (transition.to == ExpenseStatus.accepted ||
          transition.to == ExpenseStatus.disputed);
}

bool _requiresDisputeComment(ExpenseStatusTransition transition) {
  return transition.to == ExpenseStatus.disputed;
}
