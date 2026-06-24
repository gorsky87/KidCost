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

enum CustodyPresetType { alternatingWeeks, twoTwoThree, weekdaysWeekends }

class CustodyPresetDefinition {
  const CustodyPresetDefinition({
    required this.type,
    required this.label,
    required this.description,
  });

  final CustodyPresetType type;
  final String label;
  final String description;
}

const custodyPresetDefinitions = [
  CustodyPresetDefinition(
    type: CustodyPresetType.alternatingWeeks,
    label: 'Tydzien na tydzien',
    description: 'Zmiana rodzica co 7 dni.',
  ),
  CustodyPresetDefinition(
    type: CustodyPresetType.twoTwoThree,
    label: '2-2-3',
    description: 'Dwa dni, dwa dni, trzy dni i zamiana w kolejnym tygodniu.',
  ),
  CustodyPresetDefinition(
    type: CustodyPresetType.weekdaysWeekends,
    label: 'Dni robocze / weekendy',
    description: 'Rodzic startujacy ma dni robocze, drugi rodzic weekendy.',
  ),
];

List<CustodyDay> buildCustodyPresetDays({
  required CustodyPresetType presetType,
  required DateTime startDate,
  required int dayCount,
  required String childName,
  required CustodyParent firstParent,
  required CustodyParent secondParent,
  DateTime? createdAt,
}) {
  if (dayCount <= 0) {
    return const [];
  }

  final created = createdAt ?? DateTime.now().toUtc();
  return [
    for (var index = 0; index < dayCount; index++)
      _buildPresetDay(
        presetType: presetType,
        date: startDate.add(Duration(days: index)),
        index: index,
        childName: childName,
        firstParent: firstParent,
        secondParent: secondParent,
        createdAt: created,
      ),
  ];
}

CustodyDay _buildPresetDay({
  required CustodyPresetType presetType,
  required DateTime date,
  required int index,
  required String childName,
  required CustodyParent firstParent,
  required CustodyParent secondParent,
  required DateTime createdAt,
}) {
  final parent = switch (presetType) {
    CustodyPresetType.alternatingWeeks =>
      (index ~/ 7).isEven ? firstParent : secondParent,
    CustodyPresetType.twoTwoThree =>
      const [0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1][index % 14] == 0
          ? firstParent
          : secondParent,
    CustodyPresetType.weekdaysWeekends =>
      date.weekday <= DateTime.friday ? firstParent : secondParent,
  };
  final formattedDate = formatCustodyDate(date);
  return CustodyDay(
    id: 'custody-$formattedDate',
    date: formattedDate,
    childName: childName,
    parent: parent,
    createdAt: createdAt,
  );
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
