enum SettlementExpenseStatus { active, disputed, deleted }

enum SettlementAllocationState {
  unpaid,
  partiallyPaid,
  settled,
  overpaid,
  disputed,
  excludedDeleted,
}

enum PaymentProofAttachmentKind {
  bankTransferConfirmation,
  blikConfirmation,
  cashReceipt,
  checkImage,
  paypalConfirmation,
  other,
}

enum PaymentProofUploadState { uploading, uploaded, failedUpload, removed }

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

class PaymentProofAttachmentInput {
  const PaymentProofAttachmentInput({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.kind,
    required this.uploadState,
    this.storagePath,
    this.failureReason,
  });

  final String id;
  final String fileName;
  final String contentType;
  final PaymentProofAttachmentKind kind;
  final PaymentProofUploadState uploadState;
  final String? storagePath;
  final String? failureReason;

  bool get isReportable => uploadState == PaymentProofUploadState.uploaded;

  bool get canRetryUpload =>
      uploadState == PaymentProofUploadState.failedUpload;
}

class PaymentProofInput {
  const PaymentProofInput({
    required this.methodLabel,
    required this.settledAt,
    required this.attachments,
    this.referenceNote,
  });

  final String methodLabel;
  final DateTime settledAt;
  final List<PaymentProofAttachmentInput> attachments;
  final String? referenceNote;

  bool get hasReportableAttachments =>
      attachments.any((attachment) => attachment.isReportable);

  List<PaymentProofAttachmentInput> get reportableAttachments =>
      List.unmodifiable(
        attachments.where((attachment) => attachment.isReportable),
      );
}

class ReimbursementPaymentInput {
  const ReimbursementPaymentInput({
    required this.id,
    required this.amountCents,
    required this.paidBy,
    required this.paidTo,
    required this.paidAt,
    required this.allocations,
    this.paymentProof,
  });

  final String id;
  final int amountCents;
  final String paidBy;
  final String paidTo;
  final DateTime paidAt;
  final List<PaymentAllocationInput> allocations;
  final PaymentProofInput? paymentProof;

  bool get hasPaymentProof => paymentProof?.hasReportableAttachments ?? false;
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

const paymentProofAuditEvents = {
  'payment_proof_added',
  'payment_proof_removed',
  'payment_proof_replaced',
  'payment_proof_upload_failed',
};

const paymentProofSupportedContentTypes = {
  'application/pdf',
  'image/jpeg',
  'image/png',
};

const paymentProofReportMarker = 'Dowod platnosci dolaczony';

const paymentProofPrivacyCopy =
    'Potwierdzenie przelewu, BLIK, gotowki lub nazwany przelew bankowy jest '
    'zalacznikiem do rodzinnego rekordu rozliczenia; nie jest ocena prawna, '
    'certyfikacja sadowa ani gwarancja wystarczalnosci dowodu.';

List<String> validatePaymentProof(PaymentProofInput proof) {
  final errors = <String>[];
  if (proof.methodLabel.trim().isEmpty) {
    errors.add('Payment method cannot be empty.');
  }
  if (proof.attachments.isEmpty) {
    errors.add('Payment proof needs at least one attachment state.');
  }

  for (final attachment in proof.attachments) {
    if (attachment.id.trim().isEmpty) {
      errors.add('Payment proof attachment id cannot be empty.');
    }
    if (attachment.fileName.trim().isEmpty) {
      errors.add('Payment proof attachment file name cannot be empty.');
    }
    final contentType = attachment.contentType.trim().toLowerCase();
    if (!paymentProofSupportedContentTypes.contains(contentType)) {
      errors.add('Unsupported payment proof content type: $contentType.');
    }
    if (attachment.uploadState == PaymentProofUploadState.uploaded &&
        (attachment.storagePath == null ||
            attachment.storagePath!.trim().isEmpty)) {
      errors.add('Uploaded payment proof attachment needs a storage path.');
    }
    if (attachment.uploadState == PaymentProofUploadState.failedUpload &&
        (attachment.failureReason == null ||
            attachment.failureReason!.trim().isEmpty)) {
      errors.add('Failed payment proof upload needs a failure reason.');
    }
  }

  return List.unmodifiable(errors);
}

String paymentProofReportSummary(ReimbursementPaymentInput payment) {
  final proof = payment.paymentProof;
  if (proof == null || !proof.hasReportableAttachments) {
    return 'Brak dowodu platnosci';
  }
  final count = proof.reportableAttachments.length;
  return '$paymentProofReportMarker ($count)';
}

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
    final proofErrors = payment.paymentProof == null
        ? const <String>[]
        : validatePaymentProof(payment.paymentProof!);
    if (proofErrors.isNotEmpty) {
      throw ArgumentError(proofErrors.join(' '));
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
