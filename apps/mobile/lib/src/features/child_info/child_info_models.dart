enum ChildInfoCardType {
  school('school', 'Szkola/przedszkole'),
  medical('medical', 'Opieka medyczna/ubezpieczenie'),
  sizes('sizes', 'Rozmiary'),
  allergies('allergies', 'Alergie/wazne uwagi'),
  activities('activities', 'Zajecia');

  const ChildInfoCardType(this.id, this.label);

  final String id;
  final String label;
}

class ChildInfoCard {
  const ChildInfoCard({
    required this.id,
    required this.type,
    required this.title,
    required this.note,
    required this.isShared,
    required this.updatedAt,
  });

  final String id;
  final ChildInfoCardType type;
  final String title;
  final String note;
  final bool isShared;
  final DateTime updatedAt;

  String get visibilityLabel => isShared ? 'Wspoldzielona' : 'Prywatna';

  ChildInfoCardLink toLink() {
    return ChildInfoCardLink(
      id: id,
      typeLabel: type.label,
      title: title,
      isShared: isShared,
    );
  }

  ChildInfoCard copyWith({
    ChildInfoCardType? type,
    String? title,
    String? note,
    bool? isShared,
    DateTime? updatedAt,
  }) {
    return ChildInfoCard(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      note: note ?? this.note,
      isShared: isShared ?? this.isShared,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ChildInfoCardLink {
  const ChildInfoCardLink({
    required this.id,
    required this.typeLabel,
    required this.title,
    required this.isShared,
  });

  final String id;
  final String typeLabel;
  final String title;
  final bool isShared;

  String get visibilityLabel => isShared ? 'wspoldzielona' : 'prywatna';
}

List<ChildInfoCard> suggestedChildInfoCardsForExpenseCategory({
  required String expenseCategoryId,
  required List<ChildInfoCard> cards,
}) {
  final types = _suggestedTypesByExpenseCategory[expenseCategoryId] ?? const {};
  return [
    for (final card in cards)
      if (types.contains(card.type)) card,
  ];
}

const _suggestedTypesByExpenseCategory = {
  'school': {ChildInfoCardType.school},
  'health': {ChildInfoCardType.medical, ChildInfoCardType.allergies},
  'clothes': {ChildInfoCardType.sizes},
  'activities': {ChildInfoCardType.activities},
  'food': {ChildInfoCardType.allergies},
};
