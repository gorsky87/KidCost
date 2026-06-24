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
    this.attachment,
  });

  final String id;
  final int amountCents;
  final String expenseDate;
  final String childName;
  final ExpenseCategory category;
  final ExpensePayer paidBy;
  final String title;
  final DateTime createdAt;
  final ExpenseAttachment? attachment;
}

class ExpensePayer {
  const ExpensePayer({
    required this.id,
    required this.label,
    required this.isCurrentUser,
  });

  final String id;
  final String label;
  final bool isCurrentUser;
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
