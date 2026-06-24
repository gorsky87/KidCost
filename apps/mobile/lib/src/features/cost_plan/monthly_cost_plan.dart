import '../expenses/expense_models.dart';

const monthlyCostPlanDisclaimer =
    'To roboczy material organizacyjny; nie jest porada prawna, kalkulatorem naleznych alimentow ani gwarancja wyniku w sprawie alimentacyjnej.';

class MonthlyCostPlanCategory {
  const MonthlyCostPlanCategory({
    required this.id,
    required this.label,
    required this.expenseCategoryIds,
  });

  final String id;
  final String label;
  final Set<String> expenseCategoryIds;
}

const monthlyCostPlanCategories = [
  MonthlyCostPlanCategory(
    id: 'education_care',
    label: 'Edukacja/opieka',
    expenseCategoryIds: {'school'},
  ),
  MonthlyCostPlanCategory(
    id: 'activities',
    label: 'Zajecia',
    expenseCategoryIds: {'activities'},
  ),
  MonthlyCostPlanCategory(
    id: 'food',
    label: 'Wyzywienie',
    expenseCategoryIds: {'food'},
  ),
  MonthlyCostPlanCategory(
    id: 'health',
    label: 'Zdrowie',
    expenseCategoryIds: {'health'},
  ),
  MonthlyCostPlanCategory(
    id: 'clothes',
    label: 'Ubrania/obuwie',
    expenseCategoryIds: {'clothes'},
  ),
  MonthlyCostPlanCategory(
    id: 'transport',
    label: 'Dojazdy',
    expenseCategoryIds: {'transport'},
  ),
  MonthlyCostPlanCategory(
    id: 'holidays',
    label: 'Wakacje/ferie',
    expenseCategoryIds: {'holiday'},
  ),
  MonthlyCostPlanCategory(
    id: 'entertainment',
    label: 'Rozrywka',
    expenseCategoryIds: {'other'},
  ),
  MonthlyCostPlanCategory(
    id: 'housing_share',
    label: 'Udzial w kosztach mieszkaniowych',
    expenseCategoryIds: {'housing'},
  ),
];

class MonthlyCostPlanLine {
  const MonthlyCostPlanLine({
    required this.category,
    required this.plannedCents,
    required this.actualCents,
  });

  final MonthlyCostPlanCategory category;
  final int plannedCents;
  final int actualCents;

  int get differenceCents => actualCents - plannedCents;
}

class MonthlyCostPlanSummary {
  const MonthlyCostPlanSummary({
    required this.childName,
    required this.month,
    required this.lines,
  });

  final String childName;
  final String month;
  final List<MonthlyCostPlanLine> lines;

  int get plannedTotalCents {
    return lines.fold(0, (total, line) => total + line.plannedCents);
  }

  int get actualTotalCents {
    return lines.fold(0, (total, line) => total + line.actualCents);
  }

  int get differenceTotalCents => actualTotalCents - plannedTotalCents;

  String toTextExport() {
    final buffer = StringBuffer()
      ..writeln('KidCost - miesieczny kosztorys dziecka')
      ..writeln('Dziecko: $childName')
      ..writeln('Miesiac: $month')
      ..writeln('Plan: ${formatCents(plannedTotalCents)}')
      ..writeln('Faktycznie: ${formatCents(actualTotalCents)}')
      ..writeln('Roznica: ${formatSignedCents(differenceTotalCents)}')
      ..writeln()
      ..writeln('Kategorie:');

    for (final line in lines) {
      buffer.writeln(
        '- ${line.category.label}: plan ${formatCents(line.plannedCents)}, faktycznie ${formatCents(line.actualCents)}, roznica ${formatSignedCents(line.differenceCents)}',
      );
    }

    buffer
      ..writeln()
      ..writeln(monthlyCostPlanDisclaimer);
    return buffer.toString().trim();
  }

  static MonthlyCostPlanSummary fromExpenses({
    required String childName,
    required String month,
    required Map<String, int> plannedCentsByCategoryId,
    required List<ExpenseEntry> expenses,
  }) {
    final monthExpenses = expenses.where((expense) {
      final expenseMonth = expense.expenseDate.length >= 7
          ? expense.expenseDate.substring(0, 7)
          : expense.expenseDate;
      return expenseMonth == month && expense.childName == childName;
    }).toList();

    return MonthlyCostPlanSummary(
      childName: childName,
      month: month,
      lines: [
        for (final category in monthlyCostPlanCategories)
          MonthlyCostPlanLine(
            category: category,
            plannedCents: plannedCentsByCategoryId[category.id] ?? 0,
            actualCents: monthExpenses
                .where(
                  (expense) =>
                      category.expenseCategoryIds.contains(expense.category.id),
                )
                .fold(0, (total, expense) => total + expense.amountCents),
          ),
      ],
    );
  }
}

int parseOptionalPlanAmountToCents(String value) {
  if (value.trim().isEmpty) {
    return 0;
  }
  return parseAmountToCents(value);
}

String formatSignedCents(int cents) {
  if (cents == 0) {
    return formatCents(0);
  }
  final sign = cents > 0 ? '+' : '-';
  return '$sign${formatCents(cents.abs())}';
}
