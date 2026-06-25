import '../expenses/expense_models.dart';

enum PlannedPurchaseStatus {
  draft,
  requested,
  approved,
  declined,
  clarificationRequested,
  converted,
  expired,
}

extension PlannedPurchaseStatusDetails on PlannedPurchaseStatus {
  String get label {
    switch (this) {
      case PlannedPurchaseStatus.draft:
        return 'Szkic';
      case PlannedPurchaseStatus.requested:
        return 'Wyslane do akceptacji';
      case PlannedPurchaseStatus.approved:
        return 'Zaakceptowane';
      case PlannedPurchaseStatus.declined:
        return 'Odrzucone';
      case PlannedPurchaseStatus.clarificationRequested:
        return 'Do wyjasnienia';
      case PlannedPurchaseStatus.converted:
        return 'Zamienione w koszt';
      case PlannedPurchaseStatus.expired:
        return 'Po terminie';
    }
  }

  bool get canConvert => this == PlannedPurchaseStatus.approved;

  bool get isOpen {
    switch (this) {
      case PlannedPurchaseStatus.draft:
      case PlannedPurchaseStatus.requested:
      case PlannedPurchaseStatus.approved:
      case PlannedPurchaseStatus.clarificationRequested:
        return true;
      case PlannedPurchaseStatus.declined:
      case PlannedPurchaseStatus.converted:
      case PlannedPurchaseStatus.expired:
        return false;
    }
  }
}

enum PlannedPurchaseReason {
  tooExpensive,
  needDetails,
  timing,
  alreadyCovered,
  other,
}

extension PlannedPurchaseReasonDetails on PlannedPurchaseReason {
  String get label {
    switch (this) {
      case PlannedPurchaseReason.tooExpensive:
        return 'Za drogie';
      case PlannedPurchaseReason.needDetails:
        return 'Potrzebne szczegoly';
      case PlannedPurchaseReason.timing:
        return 'Inny termin';
      case PlannedPurchaseReason.alreadyCovered:
        return 'Juz pokryte';
      case PlannedPurchaseReason.other:
        return 'Inny powod';
    }
  }

  String get code {
    switch (this) {
      case PlannedPurchaseReason.tooExpensive:
        return 'too_expensive';
      case PlannedPurchaseReason.needDetails:
        return 'need_details';
      case PlannedPurchaseReason.timing:
        return 'timing';
      case PlannedPurchaseReason.alreadyCovered:
        return 'already_covered';
      case PlannedPurchaseReason.other:
        return 'other';
    }
  }
}

class PlannedPurchase {
  const PlannedPurchase({
    required this.id,
    required this.title,
    required this.estimatedAmountCents,
    required this.category,
    required this.childName,
    required this.targetDate,
    required this.approvalDeadline,
    required this.proposedSplitPercent,
    required this.createdAt,
    this.status = PlannedPurchaseStatus.requested,
    this.reason,
    this.note,
    this.convertedExpenseId,
  });

  final String id;
  final String title;
  final int estimatedAmountCents;
  final ExpenseCategory category;
  final String childName;
  final String targetDate;
  final String approvalDeadline;
  final int proposedSplitPercent;
  final DateTime createdAt;
  final PlannedPurchaseStatus status;
  final PlannedPurchaseReason? reason;
  final String? note;
  final String? convertedExpenseId;

  int get requestedShareCents =>
      (estimatedAmountCents * proposedSplitPercent / 100).round();

  PlannedPurchase copyWith({
    String? title,
    int? estimatedAmountCents,
    ExpenseCategory? category,
    String? childName,
    String? targetDate,
    String? approvalDeadline,
    int? proposedSplitPercent,
    PlannedPurchaseStatus? status,
    PlannedPurchaseReason? reason,
    String? note,
    String? convertedExpenseId,
    bool clearReason = false,
    bool clearNote = false,
  }) {
    return PlannedPurchase(
      id: id,
      title: title ?? this.title,
      estimatedAmountCents: estimatedAmountCents ?? this.estimatedAmountCents,
      category: category ?? this.category,
      childName: childName ?? this.childName,
      targetDate: targetDate ?? this.targetDate,
      approvalDeadline: approvalDeadline ?? this.approvalDeadline,
      proposedSplitPercent: proposedSplitPercent ?? this.proposedSplitPercent,
      createdAt: createdAt,
      status: status ?? this.status,
      reason: clearReason ? null : reason ?? this.reason,
      note: clearNote ? null : note ?? this.note,
      convertedExpenseId: convertedExpenseId ?? this.convertedExpenseId,
    );
  }
}
