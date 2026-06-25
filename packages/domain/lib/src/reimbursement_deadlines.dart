enum ReimbursementDeadlineTimingState {
  noDates,
  dueSoon,
  overdue,
  paidOnTime,
  paidAfterDueDate,
}

class ReimbursementDeadlineDefaults {
  const ReimbursementDeadlineDefaults({this.noticePeriod, this.paymentPeriod});

  final Duration? noticePeriod;
  final Duration? paymentPeriod;

  bool get hasAnyDefault => noticePeriod != null || paymentPeriod != null;
}

class ReimbursementDeadlineSnapshot {
  const ReimbursementDeadlineSnapshot({
    this.submittedAt,
    this.noticeDueAt,
    this.paymentDueAt,
    this.paidAt,
  });

  final DateTime? submittedAt;
  final DateTime? noticeDueAt;
  final DateTime? paymentDueAt;
  final DateTime? paidAt;

  ReimbursementDeadlineTimingState timingState({
    required DateTime now,
    Duration dueSoonWindow = const Duration(days: 3),
  }) {
    final normalizedNow = now.toUtc();
    final normalizedPaidAt = paidAt?.toUtc();
    final normalizedPaymentDueAt = paymentDueAt?.toUtc();

    if (normalizedPaidAt != null && normalizedPaymentDueAt != null) {
      return normalizedPaidAt.isAfter(normalizedPaymentDueAt)
          ? ReimbursementDeadlineTimingState.paidAfterDueDate
          : ReimbursementDeadlineTimingState.paidOnTime;
    }

    final nextDueAt = _nextOpenDueAt;
    if (nextDueAt == null) {
      return ReimbursementDeadlineTimingState.noDates;
    }

    if (nextDueAt.isBefore(normalizedNow)) {
      return ReimbursementDeadlineTimingState.overdue;
    }

    if (!nextDueAt.isAfter(normalizedNow.add(dueSoonWindow))) {
      return ReimbursementDeadlineTimingState.dueSoon;
    }

    return ReimbursementDeadlineTimingState.noDates;
  }

  bool isOverdue(DateTime now) {
    return timingState(now: now) == ReimbursementDeadlineTimingState.overdue;
  }

  DateTime? get _nextOpenDueAt {
    final normalizedSubmittedAt = submittedAt?.toUtc();
    final normalizedNoticeDueAt = noticeDueAt?.toUtc();
    final normalizedPaymentDueAt = paymentDueAt?.toUtc();

    final candidates = <DateTime>[];
    if (normalizedSubmittedAt == null && normalizedNoticeDueAt != null) {
      candidates.add(normalizedNoticeDueAt);
    }
    if (paidAt == null && normalizedPaymentDueAt != null) {
      candidates.add(normalizedPaymentDueAt);
    }
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.first;
  }
}

const reimbursementDeadlineTimingLabels = {
  ReimbursementDeadlineTimingState.noDates: 'No timing date',
  ReimbursementDeadlineTimingState.dueSoon: 'Due soon',
  ReimbursementDeadlineTimingState.overdue: 'Overdue',
  ReimbursementDeadlineTimingState.paidOnTime: 'Paid on time',
  ReimbursementDeadlineTimingState.paidAfterDueDate: 'Paid after due date',
};

const reimbursementDeadlineExportFields = [
  'submitted_at',
  'notice_due_at',
  'payment_due_at',
  'paid_at',
];

ReimbursementDeadlineDefaults mergeReimbursementDeadlineDefaults({
  ReimbursementDeadlineDefaults? familyDefaults,
  ReimbursementDeadlineDefaults? categoryDefaults,
}) {
  return ReimbursementDeadlineDefaults(
    noticePeriod:
        categoryDefaults?.noticePeriod ?? familyDefaults?.noticePeriod,
    paymentPeriod:
        categoryDefaults?.paymentPeriod ?? familyDefaults?.paymentPeriod,
  );
}

ReimbursementDeadlineSnapshot buildReimbursementDeadlineSnapshot({
  required DateTime requestCreatedAt,
  DateTime? submittedAt,
  DateTime? noticeDueAt,
  DateTime? paymentDueAt,
  DateTime? paidAt,
  ReimbursementDeadlineDefaults? familyDefaults,
  ReimbursementDeadlineDefaults? categoryDefaults,
}) {
  final defaults = mergeReimbursementDeadlineDefaults(
    familyDefaults: familyDefaults,
    categoryDefaults: categoryDefaults,
  );

  final normalizedSubmittedAt = submittedAt?.toUtc();
  final inheritedNoticeDueAt =
      noticeDueAt?.toUtc() ??
      _addPositiveDuration(requestCreatedAt.toUtc(), defaults.noticePeriod);
  final inheritedPaymentDueAt =
      paymentDueAt?.toUtc() ??
      (normalizedSubmittedAt == null
          ? null
          : _addPositiveDuration(
              normalizedSubmittedAt,
              defaults.paymentPeriod,
            ));

  return ReimbursementDeadlineSnapshot(
    submittedAt: normalizedSubmittedAt,
    noticeDueAt: inheritedNoticeDueAt,
    paymentDueAt: inheritedPaymentDueAt,
    paidAt: paidAt?.toUtc(),
  );
}

DateTime? _addPositiveDuration(DateTime base, Duration? duration) {
  if (duration == null) return null;
  if (duration.isNegative || duration == Duration.zero) {
    throw ArgumentError('Deadline default must be greater than zero.');
  }
  return base.add(duration);
}
