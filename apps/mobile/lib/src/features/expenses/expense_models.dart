import 'dart:typed_data';

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
    this.visibility = ExpenseVisibility.sharedFamily,
    this.attachment,
    this.sourceTemplateId,
    this.sourceTemplateName,
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
  final ExpenseVisibility visibility;
  final ExpenseAttachment? attachment;
  final String? sourceTemplateId;
  final String? sourceTemplateName;
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
    this.storagePath,
    this.errorMessage,
  });

  final String fileName;
  final String contentType;
  final AttachmentStatus status;
  final String? storagePath;
  final String? errorMessage;
}

enum AttachmentStatus { uploaded, failed }

enum ExpenseStatus { pending, accepted, disputed, settled }

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

String formatCents(int cents) {
  final whole = cents ~/ 100;
  final fraction = (cents % 100).abs().toString().padLeft(2, '0');
  return '$whole,$fraction zl';
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
