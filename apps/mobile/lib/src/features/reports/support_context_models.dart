import '../expenses/expense_models.dart';

enum SupportContextVisibility { private, shared, exportOnly }

extension SupportContextVisibilityDetails on SupportContextVisibility {
  String get id {
    switch (this) {
      case SupportContextVisibility.private:
        return 'private';
      case SupportContextVisibility.shared:
        return 'shared';
      case SupportContextVisibility.exportOnly:
        return 'export_only';
    }
  }

  String get label {
    switch (this) {
      case SupportContextVisibility.private:
        return 'Prywatny';
      case SupportContextVisibility.shared:
        return 'Wspoldzielony';
      case SupportContextVisibility.exportOnly:
        return 'Tylko eksport';
    }
  }
}

class SupportPaymentContextEntry {
  const SupportPaymentContextEntry({
    required this.id,
    required this.payer,
    required this.recipient,
    required this.familyContext,
    required this.amountCents,
    required this.currencyCode,
    required this.paymentDate,
    required this.periodCovered,
    required this.visibility,
    required this.includeInReport,
    required this.hasProofAttachment,
    required this.note,
    required this.createdAt,
  });

  factory SupportPaymentContextEntry.draft({
    required String payer,
    required String recipient,
    required String familyContext,
    required int amountCents,
    required String currencyCode,
    required String paymentDate,
    required String periodCovered,
    required SupportContextVisibility visibility,
    required bool includeInReport,
    required bool hasProofAttachment,
    required String note,
    DateTime? now,
  }) {
    final createdAt = now ?? DateTime.now();
    return SupportPaymentContextEntry(
      id: 'support-${createdAt.microsecondsSinceEpoch}',
      payer: payer.trim(),
      recipient: recipient.trim(),
      familyContext: familyContext.trim(),
      amountCents: amountCents,
      currencyCode: currencyCode.trim().isEmpty ? 'PLN' : currencyCode.trim(),
      paymentDate: paymentDate.trim(),
      periodCovered: periodCovered.trim(),
      visibility: visibility,
      includeInReport: includeInReport,
      hasProofAttachment: hasProofAttachment,
      note: note.trim(),
      createdAt: createdAt,
    );
  }

  final String id;
  final String payer;
  final String recipient;
  final String familyContext;
  final int amountCents;
  final String currencyCode;
  final String paymentDate;
  final String periodCovered;
  final SupportContextVisibility visibility;
  final bool includeInReport;
  final bool hasProofAttachment;
  final String note;
  final DateTime createdAt;

  bool get isPrivate => visibility == SupportContextVisibility.private;

  bool get canAppearInSharedReport =>
      includeInReport && visibility != SupportContextVisibility.private;

  String get amountLabel =>
      formatCents(amountCents, currencyCode: currencyCode);

  Map<String, Object> get analyticsProperties => {
    'support_context_visibility': visibility.id,
    'include_context_in_report': includeInReport,
    'has_attachment_context': hasProofAttachment,
  };
}

List<SupportPaymentContextEntry> supportContextEntriesForMonth({
  required String month,
  required List<SupportPaymentContextEntry> entries,
}) {
  final filtered =
      entries.where((entry) => entry.paymentDate.startsWith(month)).toList()
        ..sort(
          (first, second) => first.paymentDate.compareTo(second.paymentDate),
        );
  return List.unmodifiable(filtered);
}
