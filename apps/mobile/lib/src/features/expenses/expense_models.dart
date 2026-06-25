import 'dart:typed_data';

import 'package:kidcost_domain/domain.dart' as domain;

import '../child_info/child_info_models.dart';

class ExpenseCategory {
  const ExpenseCategory({required this.id, required this.label});

  final String id;
  final String label;
}

const expenseCategories = [
  ExpenseCategory(id: 'food', label: 'Jedzenie'),
  ExpenseCategory(id: 'clothes', label: 'Ubrania'),
  ExpenseCategory(id: 'school', label: 'Szkola/przedszkole'),
  ExpenseCategory(id: 'health', label: 'Lekarze i leki'),
  ExpenseCategory(id: 'activities', label: 'Zajecia dodatkowe'),
  ExpenseCategory(id: 'holiday', label: 'Wakacje'),
  ExpenseCategory(id: 'transport', label: 'Transport'),
  ExpenseCategory(id: 'other', label: 'Inne'),
];

class ExpenseCalendarEventLink {
  const ExpenseCalendarEventLink({
    required this.id,
    required this.title,
    required this.eventDate,
    this.isRemoved = false,
  });

  final String id;
  final String title;
  final String eventDate;
  final bool isRemoved;

  String get displayLabel {
    final suffix = isRemoved ? ' (wydarzenie usuniete)' : '';
    return '$eventDate - $title$suffix';
  }
}

class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.amountCents,
    required this.expenseDate,
    required this.childName,
    required this.category,
    required this.paidBy,
    required this.title,
    required this.createdAt,
    this.status = ExpenseStatus.pending,
    this.statusComment,
    this.disputeDetails,
    this.visibility = ExpenseVisibility.sharedFamily,
    this.attachment,
    this.sourceTemplateId,
    this.sourceTemplateName,
    this.originalReceiptAmountCents,
    this.originalReceiptCurrency,
    this.calendarEvent,
    this.childInfoCard,
    this.verification,
    this.relatedExpense,
    this.reimbursementDeadlines,
    this.reimbursementRequestKind = ReimbursementRequestKind.reimburseParent,
    this.providerPayment,
    this.draftReview,
    this.lineItems = const [],
  });

  final String id;
  final int amountCents;
  final String expenseDate;
  final String childName;
  final ExpenseCategory category;
  final ExpensePayer paidBy;
  final String title;
  final DateTime createdAt;
  final ExpenseStatus status;
  final String? statusComment;
  final ExpenseDisputeDetails? disputeDetails;
  final ExpenseVisibility visibility;
  final ExpenseAttachment? attachment;
  final String? sourceTemplateId;
  final String? sourceTemplateName;
  final int? originalReceiptAmountCents;
  final String? originalReceiptCurrency;
  final ExpenseCalendarEventLink? calendarEvent;
  final ChildInfoCardLink? childInfoCard;
  final EvidenceMetadata? verification;
  final ExpenseRelatedRecordLink? relatedExpense;
  final domain.ReimbursementDeadlineSnapshot? reimbursementDeadlines;
  final ReimbursementRequestKind reimbursementRequestKind;
  final ProviderPaymentDetails? providerPayment;
  final ExpenseDraftReview? draftReview;
  final List<ExpenseLineItem> lineItems;

  String? get calendarEventId => calendarEvent?.id;
  String? get calendarEventTitle => calendarEvent?.title;
  String? get calendarEventDate => calendarEvent?.eventDate;
  String? get childInfoCardId => childInfoCard?.id;
  String? get relatedExpenseId => relatedExpense?.id;

  EvidenceMetadata? get searchableEvidence =>
      verification ?? attachment?.evidence;

  bool get isPayProviderRequest =>
      reimbursementRequestKind == ReimbursementRequestKind.payProvider &&
      providerPayment != null;

  bool get isPrivateDraft => draftReview != null;

  bool get isArchivedDraft => draftReview?.archivedAt != null;

  bool get hasLineItems => lineItems.isNotEmpty;

  int get lineItemsTotalCents =>
      lineItems.fold(0, (sum, item) => sum + item.amountCents);

  int get lineItemsReimbursableCents => lineItems.fold(
    0,
    (sum, item) => sum + (item.isReimbursable ? item.amountCents : 0),
  );

  int get lineItemsDifferenceCents => amountCents - lineItemsTotalCents;

  int get providerPaymentDueCents =>
      isPayProviderRequest ? providerPayment!.amountDueCents : 0;

  int get settlementBalanceAmountCents =>
      isPayProviderRequest || isPrivateDraft ? 0 : amountCents;

  bool get hasReimbursementDeadlines {
    final deadlines = reimbursementDeadlines;
    return deadlines != null &&
        (deadlines.submittedAt != null ||
            deadlines.noticeDueAt != null ||
            deadlines.paymentDueAt != null ||
            deadlines.paidAt != null);
  }

  bool get hasOriginalReceiptAmount =>
      originalReceiptAmountCents != null &&
      originalReceiptCurrency != null &&
      originalReceiptCurrency!.trim().isNotEmpty;

  String? get originalReceiptAmountLabel {
    if (!hasOriginalReceiptAmount) {
      return null;
    }
    return formatCents(
      originalReceiptAmountCents!,
      currencyCode: originalReceiptCurrency!,
    );
  }

  ExpenseEntry copyWith({
    int? amountCents,
    String? expenseDate,
    String? childName,
    ExpenseCategory? category,
    ExpensePayer? paidBy,
    String? title,
    ExpenseStatus? status,
    String? statusComment,
    ExpenseDisputeDetails? disputeDetails,
    bool clearStatusComment = false,
    bool clearDisputeDetails = false,
    ExpenseVisibility? visibility,
    ExpenseAttachment? attachment,
    String? sourceTemplateId,
    String? sourceTemplateName,
    int? originalReceiptAmountCents,
    String? originalReceiptCurrency,
    ExpenseCalendarEventLink? calendarEvent,
    ChildInfoCardLink? childInfoCard,
    EvidenceMetadata? verification,
    ExpenseRelatedRecordLink? relatedExpense,
    domain.ReimbursementDeadlineSnapshot? reimbursementDeadlines,
    ReimbursementRequestKind? reimbursementRequestKind,
    ProviderPaymentDetails? providerPayment,
    ExpenseDraftReview? draftReview,
    bool clearDraftReview = false,
    List<ExpenseLineItem>? lineItems,
  }) {
    return ExpenseEntry(
      id: id,
      amountCents: amountCents ?? this.amountCents,
      expenseDate: expenseDate ?? this.expenseDate,
      childName: childName ?? this.childName,
      category: category ?? this.category,
      paidBy: paidBy ?? this.paidBy,
      title: title ?? this.title,
      createdAt: createdAt,
      status: status ?? this.status,
      statusComment: clearStatusComment
          ? null
          : statusComment ?? this.statusComment,
      disputeDetails: clearDisputeDetails
          ? null
          : disputeDetails ?? this.disputeDetails,
      visibility: visibility ?? this.visibility,
      attachment: attachment ?? this.attachment,
      sourceTemplateId: sourceTemplateId ?? this.sourceTemplateId,
      sourceTemplateName: sourceTemplateName ?? this.sourceTemplateName,
      originalReceiptAmountCents:
          originalReceiptAmountCents ?? this.originalReceiptAmountCents,
      originalReceiptCurrency:
          originalReceiptCurrency ?? this.originalReceiptCurrency,
      calendarEvent: calendarEvent ?? this.calendarEvent,
      childInfoCard: childInfoCard ?? this.childInfoCard,
      verification: verification ?? this.verification,
      relatedExpense: relatedExpense ?? this.relatedExpense,
      reimbursementDeadlines:
          reimbursementDeadlines ?? this.reimbursementDeadlines,
      reimbursementRequestKind:
          reimbursementRequestKind ?? this.reimbursementRequestKind,
      providerPayment: providerPayment ?? this.providerPayment,
      draftReview: clearDraftReview ? null : draftReview ?? this.draftReview,
      lineItems: lineItems ?? this.lineItems,
    );
  }
}

class ExpenseLineItem {
  const ExpenseLineItem({
    required this.id,
    required this.description,
    required this.amountCents,
    required this.category,
    required this.childName,
    required this.isReimbursable,
    this.splitPercent,
  });

  final String id;
  final String description;
  final int amountCents;
  final ExpenseCategory category;
  final String childName;
  final bool isReimbursable;
  final int? splitPercent;

  String get amountLabel => formatCents(amountCents);

  String get splitLabel =>
      splitPercent == null ? 'Domyslny podzial' : 'Podzial $splitPercent%';
}

enum ExpenseDraftIssue {
  child,
  category,
  amount,
  receiptUploadFailed,
  privateDraft,
}

extension ExpenseDraftIssueDetails on ExpenseDraftIssue {
  String get label {
    switch (this) {
      case ExpenseDraftIssue.child:
        return 'Needs child';
      case ExpenseDraftIssue.category:
        return 'Needs category';
      case ExpenseDraftIssue.amount:
        return 'Amount not checked';
      case ExpenseDraftIssue.receiptUploadFailed:
        return 'Receipt upload failed';
      case ExpenseDraftIssue.privateDraft:
        return 'Private draft';
    }
  }

  String get helper {
    switch (this) {
      case ExpenseDraftIssue.child:
        return 'Wybierz dziecko przed udostepnieniem kosztu.';
      case ExpenseDraftIssue.category:
        return 'Potwierdz kategorie przed rozliczeniem.';
      case ExpenseDraftIssue.amount:
        return 'Sprawdz kwote z paragonu lub notatki.';
      case ExpenseDraftIssue.receiptUploadFailed:
        return 'Ponow wysylke zalacznika albo usun dowod.';
      case ExpenseDraftIssue.privateDraft:
        return 'Szkic jest prywatny, dopoki go nie sprawdzisz.';
    }
  }
}

class ExpenseDraftReview {
  const ExpenseDraftReview({
    required this.capturedAt,
    required this.issues,
    this.archivedAt,
  });

  final DateTime capturedAt;
  final List<ExpenseDraftIssue> issues;
  final DateTime? archivedAt;

  ExpenseDraftIssue get primaryIssue =>
      issues.isEmpty ? ExpenseDraftIssue.privateDraft : issues.first;

  bool get isArchived => archivedAt != null;

  ExpenseDraftReview copyWith({
    DateTime? capturedAt,
    List<ExpenseDraftIssue>? issues,
    DateTime? archivedAt,
  }) {
    return ExpenseDraftReview(
      capturedAt: capturedAt ?? this.capturedAt,
      issues: issues ?? this.issues,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}

enum ReimbursementRequestKind { reimburseParent, payProvider }

extension ReimbursementRequestKindDetails on ReimbursementRequestKind {
  String get id {
    switch (this) {
      case ReimbursementRequestKind.reimburseParent:
        return 'reimburse_parent';
      case ReimbursementRequestKind.payProvider:
        return 'pay_provider';
    }
  }

  String get label {
    switch (this) {
      case ReimbursementRequestKind.reimburseParent:
        return 'Zwrot rodzicowi';
      case ReimbursementRequestKind.payProvider:
        return 'Zaplac dostawcy';
    }
  }

  String get description {
    switch (this) {
      case ReimbursementRequestKind.reimburseParent:
        return 'Drugi rodzic zwraca udzial rodzicowi, ktory zaplacil.';
      case ReimbursementRequestKind.payProvider:
        return 'Drugi rodzic dostaje informacje do platnosci bezposrednio dostawcy.';
    }
  }
}

enum ProviderPaymentStatus {
  sent,
  paidToProvider,
  proofRequested,
  disputed,
  cancelled,
}

extension ProviderPaymentStatusDetails on ProviderPaymentStatus {
  String get id {
    switch (this) {
      case ProviderPaymentStatus.sent:
        return 'sent';
      case ProviderPaymentStatus.paidToProvider:
        return 'paid_to_provider';
      case ProviderPaymentStatus.proofRequested:
        return 'proof_requested';
      case ProviderPaymentStatus.disputed:
        return 'disputed';
      case ProviderPaymentStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case ProviderPaymentStatus.sent:
        return 'Wyslane';
      case ProviderPaymentStatus.paidToProvider:
        return 'Zaplacone dostawcy';
      case ProviderPaymentStatus.proofRequested:
        return 'Poproszono o potwierdzenie';
      case ProviderPaymentStatus.disputed:
        return 'Do wyjasnienia';
      case ProviderPaymentStatus.cancelled:
        return 'Anulowane';
    }
  }
}

class ProviderPaymentDetails {
  const ProviderPaymentDetails({
    required this.providerName,
    required this.amountDueCents,
    required this.dueDate,
    required this.status,
    this.paymentReference,
  });

  final String providerName;
  final int amountDueCents;
  final String dueDate;
  final ProviderPaymentStatus status;
  final String? paymentReference;

  String get amountDueLabel => formatCents(amountDueCents);

  bool get hasDisplayContext =>
      providerName.trim().isNotEmpty &&
      amountDueCents > 0 &&
      dueDate.trim().isNotEmpty;
}

class ExpenseListFilterRequest {
  const ExpenseListFilterRequest({
    required this.month,
    this.childName,
    this.categoryId,
    this.status,
    this.payerLabel,
    this.showOverdueReimbursements = false,
  });

  final String month;
  final String? childName;
  final String? categoryId;
  final ExpenseStatus? status;
  final String? payerLabel;
  final bool showOverdueReimbursements;
}

class ExpenseRelatedRecordLink {
  const ExpenseRelatedRecordLink({
    required this.id,
    required this.title,
    required this.expenseDate,
    required this.amountCents,
    required this.status,
  });

  final String id;
  final String title;
  final String expenseDate;
  final int amountCents;
  final ExpenseStatus status;

  String get summary =>
      '$expenseDate - ${formatCents(amountCents)} - ${status.label}';
}

class ExpenseTemplate {
  const ExpenseTemplate({
    required this.id,
    required this.name,
    required this.amountCents,
    required this.category,
    required this.paidBy,
    required this.recurrence,
    required this.nextDueDate,
    this.note,
    this.isActive = true,
  });

  final String id;
  final String name;
  final int amountCents;
  final ExpenseCategory category;
  final ExpensePayer paidBy;
  final ExpenseRecurrence recurrence;
  final String nextDueDate;
  final String? note;
  final bool isActive;

  ExpenseTemplate copyWith({
    String? name,
    int? amountCents,
    ExpenseCategory? category,
    ExpensePayer? paidBy,
    ExpenseRecurrence? recurrence,
    String? nextDueDate,
    String? note,
    bool? isActive,
  }) {
    return ExpenseTemplate(
      id: id,
      name: name ?? this.name,
      amountCents: amountCents ?? this.amountCents,
      category: category ?? this.category,
      paidBy: paidBy ?? this.paidBy,
      recurrence: recurrence ?? this.recurrence,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum ExpenseRecurrence { weekly, monthly, quarterly, yearly }

extension ExpenseRecurrenceDetails on ExpenseRecurrence {
  String get label {
    switch (this) {
      case ExpenseRecurrence.weekly:
        return 'Co tydzien';
      case ExpenseRecurrence.monthly:
        return 'Co miesiac';
      case ExpenseRecurrence.quarterly:
        return 'Co kwartal';
      case ExpenseRecurrence.yearly:
        return 'Co rok';
    }
  }
}

class ExpensePayer {
  const ExpensePayer({
    required this.id,
    required this.label,
    required this.isCurrentUser,
    this.isManual = false,
  });

  final String id;
  final String label;
  final bool isCurrentUser;
  final bool isManual;

  ExpensePayer copyWith({String? label}) {
    return ExpensePayer(
      id: id,
      label: label ?? this.label,
      isCurrentUser: isCurrentUser,
      isManual: isManual,
    );
  }
}

class AttachmentDraft {
  const AttachmentDraft({
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;
}

class ExpenseAttachment {
  const ExpenseAttachment({
    required this.fileName,
    required this.contentType,
    required this.status,
    this.evidence,
    this.storagePath,
    this.errorMessage,
  });

  final String fileName;
  final String contentType;
  final AttachmentStatus status;
  final EvidenceMetadata? evidence;
  final String? storagePath;
  final String? errorMessage;
}

enum AttachmentStatus { uploaded, failed }

class EvidenceMetadata {
  const EvidenceMetadata({
    this.type,
    this.serviceDate,
    this.documentDate,
    this.merchant,
    this.documentNumber,
    this.paymentMethod,
    this.buyerNamePresent,
  });

  final EvidenceType? type;
  final String? serviceDate;
  final String? documentDate;
  final String? merchant;
  final String? documentNumber;
  final String? paymentMethod;
  final bool? buyerNamePresent;

  bool get hasDetails {
    return type != null ||
        _hasText(serviceDate) ||
        _hasText(documentDate) ||
        _hasText(merchant) ||
        _hasText(documentNumber) ||
        _hasText(paymentMethod) ||
        buyerNamePresent != null;
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

class ExpenseDuplicateCandidate {
  const ExpenseDuplicateCandidate({
    required this.amountCents,
    required this.expenseDate,
    required this.childName,
    required this.category,
    this.verification,
  });

  final int amountCents;
  final String expenseDate;
  final String childName;
  final ExpenseCategory category;
  final EvidenceMetadata? verification;
}

class PotentialDuplicateExpense {
  const PotentialDuplicateExpense({
    required this.expense,
    required this.reasons,
  });

  final ExpenseEntry expense;
  final List<String> reasons;
}

List<PotentialDuplicateExpense> findPotentialDuplicateExpenses({
  required ExpenseDuplicateCandidate candidate,
  required Iterable<ExpenseEntry> existingExpenses,
  int maxResults = 3,
}) {
  if (candidate.amountCents <= 0) {
    return const [];
  }

  final matches = <PotentialDuplicateExpense>[];
  for (final expense in existingExpenses) {
    final reasons = _duplicateReasons(candidate, expense);
    if (reasons.isNotEmpty) {
      matches.add(
        PotentialDuplicateExpense(expense: expense, reasons: reasons),
      );
    }
  }

  matches.sort((left, right) {
    final reasonCount = right.reasons.length.compareTo(left.reasons.length);
    if (reasonCount != 0) return reasonCount;
    return right.expense.expenseDate.compareTo(left.expense.expenseDate);
  });
  return List.unmodifiable(matches.take(maxResults));
}

ExpenseRelatedRecordLink relatedRecordLinkForExpense(ExpenseEntry expense) {
  return ExpenseRelatedRecordLink(
    id: expense.id,
    title: expense.title,
    expenseDate: expense.expenseDate,
    amountCents: expense.amountCents,
    status: expense.status,
  );
}

List<String> _duplicateReasons(
  ExpenseDuplicateCandidate candidate,
  ExpenseEntry expense,
) {
  if (_normalize(candidate.childName) != _normalize(expense.childName)) {
    return const [];
  }
  if (candidate.category.id != expense.category.id) {
    return const [];
  }

  final candidateEvidence = candidate.verification;
  final existingEvidence = expense.searchableEvidence;
  final reasons = <String>['to samo dziecko i kategoria'];

  final candidateDocumentNumber = _normalize(candidateEvidence?.documentNumber);
  final existingDocumentNumber = _normalize(existingEvidence?.documentNumber);
  if (candidateDocumentNumber.isNotEmpty &&
      candidateDocumentNumber == existingDocumentNumber) {
    return List.unmodifiable([...reasons, 'ten sam numer dokumentu']);
  }

  if (!_amountsAreClose(candidate.amountCents, expense.amountCents)) {
    return const [];
  }
  reasons.add('podobna kwota');

  final candidateMerchant = _normalize(candidateEvidence?.merchant);
  final existingMerchant = _normalize(existingEvidence?.merchant);
  final hasSameProvider =
      candidateMerchant.isNotEmpty && candidateMerchant == existingMerchant;
  if (hasSameProvider) {
    reasons.add('ten sam wystawca');
  }

  final hasMatchingDate = _datesOverlap(
    candidateDates: [
      candidateEvidence?.serviceDate,
      candidateEvidence?.documentDate,
      candidate.expenseDate,
    ],
    existingDates: [
      existingEvidence?.serviceDate,
      existingEvidence?.documentDate,
      expense.expenseDate,
    ],
  );
  if (hasMatchingDate) {
    reasons.add('podobna data uslugi lub dokumentu');
  }

  if (!hasSameProvider && !hasMatchingDate) {
    return const [];
  }
  return List.unmodifiable(reasons);
}

bool _amountsAreClose(int candidateAmount, int existingAmount) {
  final difference = (candidateAmount - existingAmount).abs();
  final tolerance = (candidateAmount * 0.02).round();
  return difference <= (tolerance < 100 ? 100 : tolerance);
}

bool _datesOverlap({
  required Iterable<String?> candidateDates,
  required Iterable<String?> existingDates,
}) {
  final parsedCandidateDates = candidateDates
      .map(_parseIsoDate)
      .whereType<DateTime>();
  final parsedExistingDates = existingDates
      .map(_parseIsoDate)
      .whereType<DateTime>();

  for (final candidateDate in parsedCandidateDates) {
    for (final existingDate in parsedExistingDates) {
      if (candidateDate.difference(existingDate).inDays.abs() <= 3) {
        return true;
      }
    }
  }
  return false;
}

DateTime? _parseIsoDate(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}

String _normalize(String? value) {
  return value == null ? '' : value.trim().toLowerCase();
}

enum EvidenceType { receipt, invoice, bankConfirmation, onlineOrder, other }

extension EvidenceTypeDetails on EvidenceType {
  String get id {
    switch (this) {
      case EvidenceType.receipt:
        return 'receipt';
      case EvidenceType.invoice:
        return 'invoice';
      case EvidenceType.bankConfirmation:
        return 'bank_confirmation';
      case EvidenceType.onlineOrder:
        return 'online_order';
      case EvidenceType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case EvidenceType.receipt:
        return 'Paragon';
      case EvidenceType.invoice:
        return 'Faktura imienna';
      case EvidenceType.bankConfirmation:
        return 'Potwierdzenie przelewu';
      case EvidenceType.onlineOrder:
        return 'Zamowienie online';
      case EvidenceType.other:
        return 'Inny dowod';
    }
  }

  String get description {
    switch (this) {
      case EvidenceType.receipt:
        return 'Pomaga pokazac skale wydatkow.';
      case EvidenceType.invoice:
        return 'Porzadkuje dokument wystawiony na konkretnego kupujacego.';
      case EvidenceType.bankConfirmation:
        return 'Laczy koszt z przeplywem platnosci.';
      case EvidenceType.onlineOrder:
        return 'Przydatne przy zakupach internetowych.';
      case EvidenceType.other:
        return 'Uzyj, gdy dokument nie pasuje do listy.';
    }
  }
}

enum ExpenseStatus { pending, accepted, disputed, settled }

enum ExpenseDisputeReason {
  missingProof,
  wrongAmount,
  notAgreed,
  alreadyPaid,
  wrongSplit,
  other;

  String get id {
    switch (this) {
      case ExpenseDisputeReason.missingProof:
        return 'missing_proof';
      case ExpenseDisputeReason.wrongAmount:
        return 'wrong_amount';
      case ExpenseDisputeReason.notAgreed:
        return 'not_agreed';
      case ExpenseDisputeReason.alreadyPaid:
        return 'already_paid';
      case ExpenseDisputeReason.wrongSplit:
        return 'wrong_split';
      case ExpenseDisputeReason.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case ExpenseDisputeReason.missingProof:
        return 'Brakuje dowodu';
      case ExpenseDisputeReason.wrongAmount:
        return 'Kwota sie nie zgadza';
      case ExpenseDisputeReason.notAgreed:
        return 'Nie byl uzgodniony';
      case ExpenseDisputeReason.alreadyPaid:
        return 'Juz zaplacone';
      case ExpenseDisputeReason.wrongSplit:
        return 'Zly podzial';
      case ExpenseDisputeReason.other:
        return 'Inny powod';
    }
  }

  String get requestHint {
    switch (this) {
      case ExpenseDisputeReason.missingProof:
        return 'Np. dodaj paragon';
      case ExpenseDisputeReason.wrongAmount:
        return 'Np. popraw kwote';
      case ExpenseDisputeReason.notAgreed:
        return 'Np. wyjasnij ustalenie';
      case ExpenseDisputeReason.alreadyPaid:
        return 'Np. dolacz potwierdzenie platnosci';
      case ExpenseDisputeReason.wrongSplit:
        return 'Np. wyjasnij podzial';
      case ExpenseDisputeReason.other:
        return 'Np. opisz potrzebna korekte';
    }
  }

  String get responseCta {
    switch (this) {
      case ExpenseDisputeReason.missingProof:
        return 'Dodaj dowod';
      case ExpenseDisputeReason.wrongAmount:
        return 'Popraw kwote';
      case ExpenseDisputeReason.notAgreed:
        return 'Wyjasnij ustalenie';
      case ExpenseDisputeReason.alreadyPaid:
        return 'Sprawdz platnosc';
      case ExpenseDisputeReason.wrongSplit:
        return 'Wyjasnij podzial';
      case ExpenseDisputeReason.other:
        return 'Odpowiedz na prosbe';
    }
  }
}

class ExpenseDisputeDetails {
  const ExpenseDisputeDetails({
    required this.reason,
    this.correctionRequest,
    this.comment,
  });

  final ExpenseDisputeReason reason;
  final String? correctionRequest;
  final String? comment;

  String get summaryText {
    final parts = [
      'Sporne: ${reason.label.toLowerCase()}.',
      if (correctionRequest?.trim().isNotEmpty ?? false)
        'Prosba: ${correctionRequest!.trim()}.',
      if (comment?.trim().isNotEmpty ?? false) comment!.trim(),
    ];
    return parts.join(' ');
  }

  String get transitionComment {
    final request = correctionRequest?.trim();
    if (request != null && request.isNotEmpty) {
      return '${reason.label}: $request';
    }
    return reason.label;
  }
}

enum ExpenseVisibility { privateAuthor, sharedFamily }

extension ExpenseVisibilityDetails on ExpenseVisibility {
  String get label {
    switch (this) {
      case ExpenseVisibility.privateAuthor:
        return 'Prywatny koszt solo';
      case ExpenseVisibility.sharedFamily:
        return 'Wspolna rodzina';
    }
  }

  String get description {
    switch (this) {
      case ExpenseVisibility.privateAuthor:
        return 'Widoczny tylko dla autora do czasu jawnego udostepnienia.';
      case ExpenseVisibility.sharedFamily:
        return 'Widoczny dla aktywnych czlonkow rodziny.';
    }
  }
}

extension ExpenseStatusDetails on ExpenseStatus {
  String get label {
    switch (this) {
      case ExpenseStatus.pending:
        return 'Do akceptacji';
      case ExpenseStatus.accepted:
        return 'Zaakceptowany';
      case ExpenseStatus.disputed:
        return 'Wymaga wyjasnienia';
      case ExpenseStatus.settled:
        return 'Rozliczony';
    }
  }

  String get description {
    switch (this) {
      case ExpenseStatus.pending:
        return 'Czeka na spokojna reakcje drugiego rodzica.';
      case ExpenseStatus.accepted:
        return 'Drugi rodzic potwierdzil koszt.';
      case ExpenseStatus.disputed:
        return 'Koszt zostal oznaczony do wyjasnienia z komentarzem.';
      case ExpenseStatus.settled:
        return 'Koszt zostal juz wyrownany lub ujety w rozliczeniu.';
    }
  }

  String get historyPlaceholder {
    switch (this) {
      case ExpenseStatus.pending:
        return 'Dodano koszt. Historia reakcji pojawi sie po pierwszej akcji.';
      case ExpenseStatus.accepted:
        return 'Koszt zaakceptowany. Pelna historia bedzie dostepna po podpieciu backendu.';
      case ExpenseStatus.disputed:
        return 'Koszt wymaga wyjasnienia. W beta zapisujemy krotki komentarz przy zmianie statusu.';
      case ExpenseStatus.settled:
        return 'Koszt rozliczony. W przyszlosci pokazemy tu powiazane wyrownanie.';
    }
  }

  List<String> get authorActions {
    switch (this) {
      case ExpenseStatus.pending:
        return const ['Edytuj koszt'];
      case ExpenseStatus.accepted:
        return const ['Oznacz jako rozliczone'];
      case ExpenseStatus.disputed:
        return const ['Dodaj korekte po wyjasnieniu'];
      case ExpenseStatus.settled:
        return const [];
    }
  }

  List<String> get counterpartyActions {
    switch (this) {
      case ExpenseStatus.pending:
        return const ['Zaakceptuj koszt', 'Oznacz jako sporne'];
      case ExpenseStatus.accepted:
        return const ['Oznacz jako rozliczone'];
      case ExpenseStatus.disputed:
        return const ['Potwierdz po wyjasnieniu'];
      case ExpenseStatus.settled:
        return const [];
    }
  }

  bool get canEdit {
    switch (this) {
      case ExpenseStatus.pending:
        return true;
      case ExpenseStatus.accepted:
      case ExpenseStatus.disputed:
      case ExpenseStatus.settled:
        return false;
    }
  }
}

String formatCents(int cents, {String currencyCode = 'PLN'}) {
  final whole = cents ~/ 100;
  final fraction = (cents % 100).abs().toString().padLeft(2, '0');
  return '$whole,$fraction $currencyCode';
}

int parseAmountToCents(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  final match = RegExp(
    r'^([0-9]+)(?:[.]([0-9]{1,2}))?$',
  ).firstMatch(normalized);
  if (match == null) {
    throw const FormatException('Amount must have up to two decimals.');
  }

  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final cents = whole * 100 + int.parse(fraction);
  if (cents <= 0) {
    throw const FormatException('Amount must be greater than zero.');
  }
  return cents;
}
