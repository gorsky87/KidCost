import '../expenses/expense_models.dart';

enum ContextLogCategory {
  school,
  medical,
  activity,
  handoff,
  reimbursement,
  other,
}

extension ContextLogCategoryDetails on ContextLogCategory {
  String get id {
    switch (this) {
      case ContextLogCategory.school:
        return 'school';
      case ContextLogCategory.medical:
        return 'medical';
      case ContextLogCategory.activity:
        return 'activity';
      case ContextLogCategory.handoff:
        return 'handoff';
      case ContextLogCategory.reimbursement:
        return 'reimbursement';
      case ContextLogCategory.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case ContextLogCategory.school:
        return 'Szkola';
      case ContextLogCategory.medical:
        return 'Medyczne';
      case ContextLogCategory.activity:
        return 'Zajecia';
      case ContextLogCategory.handoff:
        return 'Odbior/przekazanie';
      case ContextLogCategory.reimbursement:
        return 'Kontekst zwrotu';
      case ContextLogCategory.other:
        return 'Inne';
    }
  }
}

enum ContextLogVisibility { private, shared }

extension ContextLogVisibilityDetails on ContextLogVisibility {
  String get id {
    switch (this) {
      case ContextLogVisibility.private:
        return 'private';
      case ContextLogVisibility.shared:
        return 'shared';
    }
  }

  String get label {
    switch (this) {
      case ContextLogVisibility.private:
        return 'Prywatny';
      case ContextLogVisibility.shared:
        return 'Wspoldzielony';
    }
  }
}

class ContextLogEntry {
  const ContextLogEntry({
    required this.id,
    required this.childName,
    required this.entryDate,
    required this.category,
    required this.visibility,
    required this.note,
    required this.createdAt,
    this.linkedExpenseId,
    this.linkedExpenseTitle,
    this.includeInReport = false,
  });

  factory ContextLogEntry.draft({
    required String childName,
    required String entryDate,
    required ContextLogCategory category,
    required ContextLogVisibility visibility,
    required String note,
    required bool includeInReport,
    ExpenseEntry? linkedExpense,
    DateTime? now,
  }) {
    final createdAt = now ?? DateTime.now();
    return ContextLogEntry(
      id: 'context-${createdAt.microsecondsSinceEpoch}',
      childName: childName.trim(),
      entryDate: entryDate.trim(),
      category: category,
      visibility: visibility,
      note: note.trim(),
      createdAt: createdAt,
      linkedExpenseId: linkedExpense?.id,
      linkedExpenseTitle: linkedExpense?.title,
      includeInReport: includeInReport,
    );
  }

  final String id;
  final String childName;
  final String entryDate;
  final ContextLogCategory category;
  final ContextLogVisibility visibility;
  final String note;
  final DateTime createdAt;
  final String? linkedExpenseId;
  final String? linkedExpenseTitle;
  final bool includeInReport;

  bool get isPrivate => visibility == ContextLogVisibility.private;

  bool get canAppearInSharedReport =>
      includeInReport && visibility == ContextLogVisibility.shared;

  bool get hasLinkedExpense =>
      linkedExpenseId != null && linkedExpenseTitle != null;
}

List<ContextLogEntry> contextLogEntriesForMonth({
  required String month,
  required List<ContextLogEntry> entries,
}) {
  final filtered =
      entries.where((entry) => entry.entryDate.startsWith(month)).toList()
        ..sort((first, second) => first.entryDate.compareTo(second.entryDate));
  return List.unmodifiable(filtered);
}
