import 'custody_models.dart';
import '../expenses/expense_models.dart';

enum CustodyIcsPrivacyMode { neutral, detailed }

class CustodyIcsExport {
  const CustodyIcsExport({
    required this.fileName,
    required this.content,
    required this.eventCount,
    required this.privacyMode,
  });

  final String fileName;
  final String content;
  final int eventCount;
  final CustodyIcsPrivacyMode privacyMode;
}

CustodyIcsExport buildCustodyIcsExport({
  required Iterable<CustodyDay> custodyDays,
  required CustodyIcsPrivacyMode privacyMode,
  required DateTime generatedAt,
  Iterable<ExpenseEntry> linkedExpenses = const [],
  bool includeLinkedExpenseContext = false,
}) {
  final sortedDays = custodyDays.toList()
    ..sort((first, second) => first.date.compareTo(second.date));
  final expensesByEventId = <String, List<ExpenseEntry>>{};
  for (final expense in linkedExpenses) {
    final eventId = expense.calendarEventId;
    if (eventId == null) {
      continue;
    }
    expensesByEventId.putIfAbsent(eventId, () => []).add(expense);
  }
  final timestamp = _formatUtcTimestamp(generatedAt.toUtc());
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//KidCost//Custody Calendar Export//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'X-KIDCOST-EXPORT:custody-calendar',
    'X-KIDCOST-PRIVACY:${privacyMode.name}',
  ];

  for (final day in sortedDays) {
    final start = parseCustodyDate(day.date);
    if (start == null) {
      continue;
    }
    final end = start.add(const Duration(days: 1));
    final summary = privacyMode == CustodyIcsPrivacyMode.detailed
        ? 'Opieka: ${day.parent.label}'
        : 'KidCost plan opieki';
    final linkedDayExpenses = expensesByEventId[day.id] ?? const [];
    final description = _eventDescription(
      day: day,
      privacyMode: privacyMode,
      linkedExpenses: linkedDayExpenses,
      includeLinkedExpenseContext: includeLinkedExpenseContext,
    );

    lines.addAll([
      'BEGIN:VEVENT',
      'UID:${_escapeText(day.id)}@kidcost.app',
      'DTSTAMP:$timestamp',
      'DTSTART;VALUE=DATE:${_formatDate(start)}',
      'DTEND;VALUE=DATE:${_formatDate(end)}',
      'SUMMARY:${_escapeText(summary)}',
      'DESCRIPTION:${_escapeText(description)}',
      'TRANSP:TRANSPARENT',
      'END:VEVENT',
    ]);
  }

  lines.add('END:VCALENDAR');
  final firstDate = sortedDays.isEmpty ? 'empty' : sortedDays.first.date;
  final lastDate = sortedDays.isEmpty ? 'empty' : sortedDays.last.date;
  return CustodyIcsExport(
    fileName: 'kidcost-custody-$firstDate-$lastDate.ics',
    content: '${lines.join('\r\n')}\r\n',
    eventCount: lines.where((line) => line == 'BEGIN:VEVENT').length,
    privacyMode: privacyMode,
  );
}

String _eventDescription({
  required CustodyDay day,
  required CustodyIcsPrivacyMode privacyMode,
  required List<ExpenseEntry> linkedExpenses,
  required bool includeLinkedExpenseContext,
}) {
  if (privacyMode != CustodyIcsPrivacyMode.detailed) {
    return 'Prywatny dzien opieki z KidCost. Szczegoly zostaja w aplikacji.';
  }

  final details = <String>[
    'Dzien opieki zapisany w KidCost dla: ${day.childName}.',
  ];
  if (includeLinkedExpenseContext && linkedExpenses.isNotEmpty) {
    final expenseLabels = linkedExpenses
        .map((expense) {
          return '${expense.title} (${expense.category.label}, ${expense.status.label})';
        })
        .join('; ');
    details.add('Powiazane koszty: $expenseLabels.');
  }
  if (!includeLinkedExpenseContext && linkedExpenses.isNotEmpty) {
    details.add('Powiazane koszty zostaly pominiete w tym eksporcie.');
  }
  return details.join(' ');
}

String _formatDate(DateTime date) {
  return [
    date.year.toString().padLeft(4, '0'),
    date.month.toString().padLeft(2, '0'),
    date.day.toString().padLeft(2, '0'),
  ].join();
}

String _formatUtcTimestamp(DateTime date) {
  return [
    _formatDate(date),
    'T',
    date.hour.toString().padLeft(2, '0'),
    date.minute.toString().padLeft(2, '0'),
    date.second.toString().padLeft(2, '0'),
    'Z',
  ].join();
}

String _escapeText(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('\n', r'\n')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,');
}
