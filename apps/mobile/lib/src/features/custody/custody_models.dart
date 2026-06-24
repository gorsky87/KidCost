class CustodyParent {
  const CustodyParent({
    required this.id,
    required this.label,
    required this.isCurrentUser,
  });

  final String id;
  final String label;
  final bool isCurrentUser;
}

class CustodyDay {
  const CustodyDay({
    required this.id,
    required this.date,
    required this.childName,
    required this.parent,
    required this.createdAt,
  });

  final String id;
  final String date;
  final String childName;
  final CustodyParent parent;
  final DateTime createdAt;

  CustodyDay copyWith({CustodyParent? parent}) {
    return CustodyDay(
      id: id,
      date: date,
      childName: childName,
      parent: parent ?? this.parent,
      createdAt: createdAt,
    );
  }
}

String formatCustodyDate(DateTime date) {
  return [
    date.year.toString().padLeft(4, '0'),
    date.month.toString().padLeft(2, '0'),
    date.day.toString().padLeft(2, '0'),
  ].join('-');
}

DateTime? parseCustodyDate(String value) {
  final parts = value.trim().split('-');
  if (parts.length != 3) {
    return null;
  }

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }

  final parsed = DateTime.utc(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}
