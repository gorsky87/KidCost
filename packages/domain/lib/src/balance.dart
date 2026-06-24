class ExpenseInput {
  const ExpenseInput({
    required this.id,
    required this.amountCents,
    required this.paidBy,
    required this.status,
    this.childId,
  });

  final String id;
  final int amountCents;
  final String paidBy;
  final String status;
  final String? childId;
}

class SplitRule {
  const SplitRule._(this.weights);

  factory SplitRule.equal(Iterable<String> participantIds) {
    final ids = _normalizeIds(participantIds);
    return SplitRule._({for (final id in ids) id: 1});
  }

  factory SplitRule.custom(Map<String, int> weights) {
    if (weights.isEmpty) {
      throw ArgumentError('Split weights cannot be empty.');
    }

    final normalized = <String, int>{};
    for (final entry in weights.entries) {
      final id = entry.key.trim();
      if (id.isEmpty) {
        throw ArgumentError('Participant id cannot be empty.');
      }
      if (entry.value <= 0) {
        throw ArgumentError('Split weight must be greater than zero.');
      }
      normalized[id] = entry.value;
    }

    return SplitRule._(Map.unmodifiable(normalized));
  }

  final Map<String, int> weights;

  List<String> get participantIds => weights.keys.toList()..sort();
}

class ParticipantBalance {
  const ParticipantBalance({
    required this.participantId,
    required this.spentCents,
    required this.targetShareCents,
    required this.netCents,
  });

  final String participantId;
  final int spentCents;
  final int targetShareCents;

  /// Positive means this participant should receive money.
  /// Negative means this participant should pay money.
  final int netCents;
}

class BalanceTransfer {
  const BalanceTransfer({
    required this.fromParticipantId,
    required this.toParticipantId,
    required this.amountCents,
  });

  final String fromParticipantId;
  final String toParticipantId;
  final int amountCents;
}

class BalanceResult {
  const BalanceResult({
    required this.totalCents,
    required this.spentByParticipant,
    required this.targetShareByParticipant,
    required this.participantBalances,
    required this.transfers,
  });

  final int totalCents;
  final Map<String, int> spentByParticipant;
  final Map<String, int> targetShareByParticipant;
  final List<ParticipantBalance> participantBalances;
  final List<BalanceTransfer> transfers;
}

const defaultBalanceStatuses = {'pending', 'accepted', 'settled'};
const ignoredBalanceStatuses = {'cancelled', 'deleted', 'removed', 'void'};

BalanceResult calculateBalance({
  required Iterable<ExpenseInput> expenses,
  required SplitRule splitRule,
  Set<String> includedStatuses = defaultBalanceStatuses,
}) {
  final participantIds = splitRule.participantIds;
  if (participantIds.isEmpty) {
    throw ArgumentError('At least one participant is required.');
  }

  final spent = {for (final id in participantIds) id: 0};
  var total = 0;

  for (final expense in expenses) {
    if (expense.amountCents <= 0) {
      throw ArgumentError('Expense amount must be greater than zero.');
    }

    final status = expense.status.trim().toLowerCase();
    if (!includedStatuses.contains(status) ||
        ignoredBalanceStatuses.contains(status)) {
      continue;
    }

    if (!spent.containsKey(expense.paidBy)) {
      spent[expense.paidBy] = 0;
    }

    spent[expense.paidBy] = spent[expense.paidBy]! + expense.amountCents;
    total += expense.amountCents;
  }

  final allParticipantIds = spent.keys.toList()..sort();
  final targetShares = _allocateTargetShares(
    totalCents: total,
    participantIds: allParticipantIds,
    weights: splitRule.weights,
  );

  final balances = <ParticipantBalance>[
    for (final id in allParticipantIds)
      ParticipantBalance(
        participantId: id,
        spentCents: spent[id] ?? 0,
        targetShareCents: targetShares[id] ?? 0,
        netCents: (spent[id] ?? 0) - (targetShares[id] ?? 0),
      ),
  ];

  return BalanceResult(
    totalCents: total,
    spentByParticipant: Map.unmodifiable(spent),
    targetShareByParticipant: Map.unmodifiable(targetShares),
    participantBalances: List.unmodifiable(balances),
    transfers: List.unmodifiable(_buildTransfers(balances)),
  );
}

int decimalAmountToCents(String amount) {
  final value = amount.trim();
  final match = RegExp(r'^([0-9]+)(?:[.]([0-9]{1,2}))?$').firstMatch(value);
  if (match == null) {
    throw ArgumentError(
      'Amount must be a positive decimal with up to 2 places.',
    );
  }

  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final cents = whole * 100 + int.parse(fraction);
  if (cents <= 0) {
    throw ArgumentError('Amount must be greater than zero.');
  }
  return cents;
}

Map<String, int> _allocateTargetShares({
  required int totalCents,
  required List<String> participantIds,
  required Map<String, int> weights,
}) {
  final normalizedWeights = {
    for (final id in participantIds) id: weights[id] ?? 0,
  };

  final totalWeight = normalizedWeights.values.fold<int>(0, (a, b) => a + b);
  if (totalWeight <= 0) {
    throw ArgumentError(
      'Split rule must include at least one positive weight.',
    );
  }

  final shares = <String, int>{};
  final remainders = <_Remainder>[];
  var allocated = 0;

  for (final id in participantIds) {
    final numerator = totalCents * normalizedWeights[id]!;
    final base = numerator ~/ totalWeight;
    final remainder = numerator % totalWeight;
    shares[id] = base;
    allocated += base;
    remainders.add(_Remainder(id, remainder));
  }

  remainders.sort((a, b) {
    final byRemainder = b.remainder.compareTo(a.remainder);
    if (byRemainder != 0) return byRemainder;
    return a.participantId.compareTo(b.participantId);
  });

  var remaining = totalCents - allocated;
  var index = 0;
  while (remaining > 0) {
    final id = remainders[index % remainders.length].participantId;
    shares[id] = shares[id]! + 1;
    remaining -= 1;
    index += 1;
  }

  return shares;
}

List<BalanceTransfer> _buildTransfers(List<ParticipantBalance> balances) {
  final debtors =
      balances
          .where((balance) => balance.netCents < 0)
          .map(
            (balance) => _OpenAmount(balance.participantId, -balance.netCents),
          )
          .toList()
        ..sort((a, b) => a.participantId.compareTo(b.participantId));

  final creditors =
      balances
          .where((balance) => balance.netCents > 0)
          .map(
            (balance) => _OpenAmount(balance.participantId, balance.netCents),
          )
          .toList()
        ..sort((a, b) => a.participantId.compareTo(b.participantId));

  final transfers = <BalanceTransfer>[];
  var debtorIndex = 0;
  var creditorIndex = 0;

  while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
    final debtor = debtors[debtorIndex];
    final creditor = creditors[creditorIndex];
    final amount = debtor.amountCents < creditor.amountCents
        ? debtor.amountCents
        : creditor.amountCents;

    if (amount > 0) {
      transfers.add(
        BalanceTransfer(
          fromParticipantId: debtor.participantId,
          toParticipantId: creditor.participantId,
          amountCents: amount,
        ),
      );
    }

    debtor.amountCents -= amount;
    creditor.amountCents -= amount;

    if (debtor.amountCents == 0) debtorIndex += 1;
    if (creditor.amountCents == 0) creditorIndex += 1;
  }

  return transfers;
}

List<String> _normalizeIds(Iterable<String> ids) {
  final normalized =
      ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList()
        ..sort();
  if (normalized.isEmpty) {
    throw ArgumentError('At least one participant is required.');
  }
  return normalized;
}

class _Remainder {
  const _Remainder(this.participantId, this.remainder);

  final String participantId;
  final int remainder;
}

class _OpenAmount {
  _OpenAmount(this.participantId, this.amountCents);

  final String participantId;
  int amountCents;
}
