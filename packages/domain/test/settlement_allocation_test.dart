import 'package:kidcost_domain/domain.dart';

void main() {
  testPartialPaymentLeavesArrears();
  testOnePaymentCanCoverMultipleExpenses();
  testOverpaymentAndUnallocatedPaymentAreVisible();
  testDisputedAndDeletedExpensesAreNotAutoSettled();
  testPaymentProofAttachmentsAreReferencedBySettlement();
  testPaymentProofValidationKeepsFailedAndRemovedStatesExplicit();
  testPaymentProofCopyAndAuditEventsStayConservative();
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

void testPaymentProofAttachmentsAreReferencedBySettlement() {
  final payment = ReimbursementPaymentInput(
    id: 'p1',
    amountCents: 5000,
    paidBy: 'mom',
    paidTo: 'dad',
    paidAt: DateTime.utc(2026, 6, 24),
    allocations: const [
      PaymentAllocationInput(expenseId: 'e1', amountCents: 5000),
    ],
    paymentProof: PaymentProofInput(
      methodLabel: 'Przelew bankowy',
      referenceNote: 'Zwrot za czerwiec',
      settledAt: DateTime.utc(2026, 6, 25),
      attachments: const [
        PaymentProofAttachmentInput(
          id: 'proof-1',
          fileName: 'potwierdzenie-przelewu.pdf',
          contentType: 'application/pdf',
          kind: PaymentProofAttachmentKind.bankTransferConfirmation,
          uploadState: PaymentProofUploadState.uploaded,
          storagePath: 'families/f1/settlements/p1/proof-1.pdf',
        ),
        PaymentProofAttachmentInput(
          id: 'proof-2',
          fileName: 'blik.png',
          contentType: 'image/png',
          kind: PaymentProofAttachmentKind.blikConfirmation,
          uploadState: PaymentProofUploadState.uploaded,
          storagePath: 'families/f1/settlements/p1/proof-2.png',
        ),
      ],
    ),
  );

  final summary = allocateReimbursementPayments(
    expenses: const [SettlementExpenseInput(id: 'e1', owedCents: 5000)],
    payments: [payment],
  );

  expectEqual(summary.arrearsCents, 0);
  expectEqual(payment.hasPaymentProof, true);
  expectEqual(payment.paymentProof!.reportableAttachments.length, 2);
  expectEqual(
    paymentProofReportSummary(payment),
    'Dowod platnosci dolaczony (2)',
  );
}

void testPaymentProofValidationKeepsFailedAndRemovedStatesExplicit() {
  final proof = PaymentProofInput(
    methodLabel: 'Gotowka',
    settledAt: DateTime.utc(2026, 6, 25),
    attachments: const [
      PaymentProofAttachmentInput(
        id: 'failed',
        fileName: 'gotowka.jpg',
        contentType: 'image/jpeg',
        kind: PaymentProofAttachmentKind.cashReceipt,
        uploadState: PaymentProofUploadState.failedUpload,
        failureReason: 'Network timeout',
      ),
      PaymentProofAttachmentInput(
        id: 'removed',
        fileName: 'stare-potwierdzenie.pdf',
        contentType: 'application/pdf',
        kind: PaymentProofAttachmentKind.other,
        uploadState: PaymentProofUploadState.removed,
      ),
    ],
  );

  expectEqual(validatePaymentProof(proof).isEmpty, true);
  expectEqual(proof.hasReportableAttachments, false);
  expectEqual(proof.attachments.first.canRetryUpload, true);
}

void testPaymentProofCopyAndAuditEventsStayConservative() {
  expectEqual(paymentProofAuditEvents.contains('payment_proof_added'), true);
  expectEqual(paymentProofAuditEvents.contains('payment_proof_removed'), true);
  expectEqual(paymentProofAuditEvents.contains('payment_proof_replaced'), true);
  expectEqual(
    paymentProofAuditEvents.contains('payment_proof_upload_failed'),
    true,
  );
  expectEqual(paymentProofPrivacyCopy.contains('ocena prawna'), true);
  expectEqual(paymentProofPrivacyCopy.contains('certyfikacja sadowa'), true);
}

void expectEqual(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected <$expected>, got <$actual>.');
  }
}
