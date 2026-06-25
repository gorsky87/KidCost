import 'expense_models.dart';

class ProofRecord {
  const ProofRecord({
    required this.id,
    required this.expenseId,
    required this.expenseTitle,
    required this.expenseDate,
    required this.month,
    required this.childName,
    required this.category,
    required this.status,
    required this.amountCents,
    required this.fileName,
    required this.contentType,
    required this.attachmentStatus,
    required this.evidence,
    required this.providerName,
  });

  factory ProofRecord.fromExpense(ExpenseEntry expense) {
    final attachment = expense.attachment;
    final evidence = attachment?.evidence ?? expense.searchableEvidence;
    return ProofRecord(
      id: 'proof-${expense.id}',
      expenseId: expense.id,
      expenseTitle: expense.title,
      expenseDate: expense.expenseDate,
      month: monthFromIsoDate(expense.expenseDate),
      childName: expense.childName,
      category: expense.category,
      status: expense.status,
      amountCents: expense.amountCents,
      fileName: attachment?.fileName,
      contentType: attachment?.contentType,
      attachmentStatus: attachment?.status,
      evidence: evidence,
      providerName: expense.providerPayment?.providerName,
    );
  }

  final String id;
  final String expenseId;
  final String expenseTitle;
  final String expenseDate;
  final String month;
  final String childName;
  final ExpenseCategory category;
  final ExpenseStatus status;
  final int amountCents;
  final String? fileName;
  final String? contentType;
  final AttachmentStatus? attachmentStatus;
  final EvidenceMetadata? evidence;
  final String? providerName;

  bool get hasAttachment => fileName != null;

  bool get hasUploadedAttachment =>
      attachmentStatus == AttachmentStatus.uploaded;

  EvidenceType? get evidenceType => evidence?.type;

  String get proofTypeLabel {
    final type = evidenceType;
    if (type != null) {
      return type.label;
    }
    final content = contentType ?? '';
    if (content == 'application/pdf') {
      return 'PDF';
    }
    if (content.startsWith('image/')) {
      return 'Zdjecie dowodu';
    }
    return hasAttachment ? 'Zalacznik' : 'Metadane dowodu';
  }

  String get sourceLabel {
    final merchant = evidence?.merchant?.trim();
    if (merchant != null && merchant.isNotEmpty) {
      return merchant;
    }
    final provider = providerName?.trim();
    if (provider != null && provider.isNotEmpty) {
      return provider;
    }
    return expenseTitle;
  }

  String get attachmentStateLabel {
    if (!hasAttachment) {
      return 'Brak pliku, sa tylko metadane';
    }
    if (hasUploadedAttachment) {
      return 'Plik gotowy';
    }
    return 'Plik wymaga ponowienia';
  }

  String get amountLabel => formatCents(amountCents);

  bool matches(ProofLibraryFilter filter) {
    if (filter.month != null && filter.month != month) return false;
    if (filter.childName != null && filter.childName != childName) {
      return false;
    }
    if (filter.categoryId != null && filter.categoryId != category.id) {
      return false;
    }
    if (filter.status != null && filter.status != status) return false;
    if (filter.evidenceType != null && filter.evidenceType != evidenceType) {
      return false;
    }
    if (filter.attachmentFilter != null &&
        !filter.attachmentFilter!.matches(this)) {
      return false;
    }
    final query = filter.normalizedQuery;
    if (query.isNotEmpty && !_searchText.contains(query)) return false;
    return true;
  }

  String get _searchText {
    return [
      expenseTitle,
      childName,
      category.label,
      sourceLabel,
      fileName ?? '',
      evidence?.documentNumber ?? '',
      evidence?.paymentMethod ?? '',
    ].join(' ').toLowerCase();
  }
}

enum ProofAttachmentFilter {
  uploaded('Plik gotowy'),
  needsRetry('Plik wymaga ponowienia'),
  metadataOnly('Tylko metadane');

  const ProofAttachmentFilter(this.label);

  final String label;

  bool matches(ProofRecord record) {
    return switch (this) {
      ProofAttachmentFilter.uploaded => record.hasUploadedAttachment,
      ProofAttachmentFilter.needsRetry =>
        record.hasAttachment && !record.hasUploadedAttachment,
      ProofAttachmentFilter.metadataOnly => !record.hasAttachment,
    };
  }
}

class ProofLibraryFilter {
  const ProofLibraryFilter({
    this.month,
    this.childName,
    this.categoryId,
    this.status,
    this.evidenceType,
    this.attachmentFilter,
    this.includedInReport,
    this.query = '',
  });

  final String? month;
  final String? childName;
  final String? categoryId;
  final ExpenseStatus? status;
  final EvidenceType? evidenceType;
  final ProofAttachmentFilter? attachmentFilter;
  final bool? includedInReport;
  final String query;

  String get normalizedQuery => query.trim().toLowerCase();

  bool get hasActiveFilters {
    return month != null ||
        childName != null ||
        categoryId != null ||
        status != null ||
        evidenceType != null ||
        attachmentFilter != null ||
        includedInReport != null ||
        normalizedQuery.isNotEmpty;
  }

  ProofLibraryFilter copyWith({
    String? month,
    String? childName,
    String? categoryId,
    ExpenseStatus? status,
    EvidenceType? evidenceType,
    ProofAttachmentFilter? attachmentFilter,
    bool? includedInReport,
    String? query,
    bool clearMonth = false,
    bool clearChildName = false,
    bool clearCategoryId = false,
    bool clearStatus = false,
    bool clearEvidenceType = false,
    bool clearAttachmentFilter = false,
    bool clearIncludedInReport = false,
  }) {
    return ProofLibraryFilter(
      month: clearMonth ? null : month ?? this.month,
      childName: clearChildName ? null : childName ?? this.childName,
      categoryId: clearCategoryId ? null : categoryId ?? this.categoryId,
      status: clearStatus ? null : status ?? this.status,
      evidenceType: clearEvidenceType
          ? null
          : evidenceType ?? this.evidenceType,
      attachmentFilter: clearAttachmentFilter
          ? null
          : attachmentFilter ?? this.attachmentFilter,
      includedInReport: clearIncludedInReport
          ? null
          : includedInReport ?? this.includedInReport,
      query: query ?? this.query,
    );
  }
}

List<ProofRecord> proofRecordsFromExpenses(Iterable<ExpenseEntry> expenses) {
  final records = [
    for (final expense in expenses)
      if (expense.attachment != null || expense.searchableEvidence != null)
        ProofRecord.fromExpense(expense),
  ]..sort((first, second) => second.expenseDate.compareTo(first.expenseDate));
  return List.unmodifiable(records);
}

List<ProofRecord> filterProofRecords({
  required Iterable<ProofRecord> records,
  required ProofLibraryFilter filter,
  Set<String> reportedProofIds = const {},
}) {
  return List.unmodifiable(
    records.where((record) {
      if (!record.matches(filter)) return false;
      final includedInReport = filter.includedInReport;
      if (includedInReport != null &&
          reportedProofIds.contains(record.id) != includedInReport) {
        return false;
      }
      return true;
    }),
  );
}

String monthFromIsoDate(String date) {
  if (date.length < 7) return date;
  return date.substring(0, 7);
}
