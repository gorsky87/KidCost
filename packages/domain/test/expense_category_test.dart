import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('archiving a family category keeps historical expense labels', () {
    const schoolTrips = FamilyExpenseCategory(
      id: 'cat-school-trips',
      familyId: 'family-1',
      name: 'Wycieczki szkolne',
      reportGroup: 'Szkola',
    );

    final archivedSchoolTrips = schoolTrips.archive();
    final historicalExpense = CategorizedExpenseInput(
      id: 'expense-1',
      amountCents: 12500,
      category: schoolTrips.snapshotForExpense(),
    );

    expectEqual(archivedSchoolTrips.canBeUsedForNewExpense, false);
    expectEqual(
      activeFamilyExpenseCategories([archivedSchoolTrips]).isEmpty,
      true,
    );
    expectEqual(historicalExpense.category.name, 'Wycieczki szkolne');
    expectEqual(historicalExpense.category.reportGroup, 'Szkola');
    expectEqual(
      totalsByExpenseCategoryName([historicalExpense])['Wycieczki szkolne'],
      12500,
    );
  });
}

void expectEqual(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected <$expected>, got <$actual>.');
  }
}
