import 'custody_models.dart';

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
}) {
  final sortedDays = custodyDays.toList()
    ..sort((first, second) => first.date.compareTo(second.date));
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
    final description = privacyMode == CustodyIcsPrivacyMode.detailed
        ? 'Dzien opieki zapisany w KidCost dla: ${day.childName}.'
        : 'Prywatny dzien opieki z KidCost. Szczegoly zostaja w aplikacji.';

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
