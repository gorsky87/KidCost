class FamilyExpenseCategory {
  const FamilyExpenseCategory({
    required this.id,
    required this.familyId,
    required this.name,
    this.reportGroup,
    this.isArchived = false,
  }) : assert(id != ''),
       assert(familyId != ''),
       assert(name != '');

  final String id;
  final String familyId;
  final String name;
  final String? reportGroup;
  final bool isArchived;

  bool get canBeUsedForNewExpense => !isArchived;

  FamilyExpenseCategory archive() => FamilyExpenseCategory(
    id: id,
    familyId: familyId,
    name: name,
    reportGroup: reportGroup,
    isArchived: true,
  );

  ExpenseCategorySnapshot snapshotForExpense() => ExpenseCategorySnapshot(
    categoryId: id,
    name: name,
    reportGroup: reportGroup,
  );
}

class ExpenseCategorySnapshot {
  const ExpenseCategorySnapshot({
    required this.categoryId,
    required this.name,
    this.reportGroup,
  }) : assert(categoryId != ''),
       assert(name != '');

  final String categoryId;
  final String name;
  final String? reportGroup;
}

class CategorizedExpenseInput {
  const CategorizedExpenseInput({
    required this.id,
    required this.amountCents,
    required this.category,
  }) : assert(id != ''),
       assert(amountCents > 0);

  final String id;
  final int amountCents;
  final ExpenseCategorySnapshot category;
}

List<FamilyExpenseCategory> activeFamilyExpenseCategories(
  Iterable<FamilyExpenseCategory> categories,
) => List.unmodifiable(
  categories.where((category) => category.canBeUsedForNewExpense),
);

Map<String, int> totalsByExpenseCategoryName(
  Iterable<CategorizedExpenseInput> expenses,
) {
  final totals = <String, int>{};
  for (final expense in expenses) {
    totals.update(
      expense.category.name,
      (current) => current + expense.amountCents,
      ifAbsent: () => expense.amountCents,
    );
  }
  return Map.unmodifiable(totals);
}
