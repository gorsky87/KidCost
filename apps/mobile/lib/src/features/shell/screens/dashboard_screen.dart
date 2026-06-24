import 'package:flutter/material.dart';

import '../../expenses/expense_models.dart';
import '../../onboarding/onboarding_profile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.profile,
    required this.expenses,
    required this.onAddExpense,
    this.currentDate,
    super.key,
  });

  final OnboardingProfile profile;
  final List<ExpenseEntry> expenses;
  final VoidCallback onAddExpense;
  final DateTime? currentDate;

  @override
  Widget build(BuildContext context) {
    final month = _DashboardMonth.fromDate(currentDate ?? DateTime.now());
    final monthExpenses = expenses
        .where((expense) => month.contains(expense.expenseDate))
        .toList();
    final summary = _DashboardSummary.fromExpenses(monthExpenses);
    final recentExpenses = [...monthExpenses]
      ..sort((first, second) {
        final dateComparison = second.expenseDate.compareTo(first.expenseDate);
        if (dateComparison != 0) {
          return dateComparison;
        }
        return second.createdAt.compareTo(first.createdAt);
      });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Podsumowanie miesiaca',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('Rodzina: ${profile.familyName}'),
        Text('Dziecko: ${profile.childName}'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onAddExpense,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Dodaj koszt'),
        ),
        const SizedBox(height: 12),
        _MetricTile(
          icon: Icons.swap_horiz,
          title: 'Kto komu oddaje',
          value: summary.balanceText,
          helper: 'Liczymy prosty podzial 50/50.',
        ),
        if (monthExpenses.isEmpty) ...[
          const SizedBox(height: 8),
          _EmptyDashboardState(onAddExpense: onAddExpense),
        ],
        _MetricTile(
          icon: Icons.calendar_month_outlined,
          title: 'Wydatki w tym miesiacu',
          value: formatCents(summary.totalCents),
          helper: month.label,
        ),
        _MetricTile(
          icon: Icons.person_outline,
          title: 'Ty zaplaciles',
          value: formatCents(summary.currentUserPaidCents),
        ),
        _MetricTile(
          icon: Icons.group_outlined,
          title: 'Drugi rodzic zaplacil',
          value: formatCents(summary.coParentPaidCents),
        ),
        const SizedBox(height: 8),
        if (monthExpenses.isNotEmpty)
          _RecentExpenses(expenses: recentExpenses.take(5).toList()),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
    this.helper,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(helper == null ? value : '$value\n$helper'),
      ),
    );
  }
}

class _RecentExpenses extends StatelessWidget {
  const _RecentExpenses({required this.expenses});

  final List<ExpenseEntry> expenses;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ostatnie koszty',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final expense in expenses)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(expense.title),
                subtitle: Text(
                  '${expense.expenseDate} • ${expense.category.label} • ${expense.paidBy.label}',
                ),
                trailing: Text(formatCents(expense.amountCents)),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState({required this.onAddExpense});

  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.receipt_long_outlined),
              title: Text('Brak kosztow w tym miesiacu'),
              subtitle: Text(
                'Dodaj pierwszy koszt, a od razu zobaczysz kto ile zaplacil i kto komu oddaje.',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onAddExpense,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Dodaj pierwszy koszt'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSummary {
  const _DashboardSummary({
    required this.totalCents,
    required this.currentUserPaidCents,
    required this.coParentPaidCents,
  });

  factory _DashboardSummary.fromExpenses(List<ExpenseEntry> expenses) {
    final totalCents = expenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amountCents,
    );
    final currentUserPaidCents = expenses
        .where((expense) => expense.paidBy.isCurrentUser)
        .fold<int>(0, (sum, expense) => sum + expense.amountCents);

    return _DashboardSummary(
      totalCents: totalCents,
      currentUserPaidCents: currentUserPaidCents,
      coParentPaidCents: totalCents - currentUserPaidCents,
    );
  }

  final int totalCents;
  final int currentUserPaidCents;
  final int coParentPaidCents;

  String get balanceText {
    if (totalCents == 0) {
      return 'Brak kosztow do wyrownania';
    }

    final halfCents = totalCents ~/ 2;
    final currentUserShare = currentUserPaidCents - halfCents;
    if (currentUserShare == 0) {
      return 'Jestescie rozliczeni na zero';
    }

    if (currentUserShare > 0) {
      return 'Drugi rodzic oddaje Tobie ${formatCents(currentUserShare)}';
    }

    return 'Ty oddajesz drugiemu rodzicowi ${formatCents(-currentUserShare)}';
  }
}

class _DashboardMonth {
  const _DashboardMonth({required this.year, required this.month});

  factory _DashboardMonth.fromDate(DateTime date) {
    return _DashboardMonth(year: date.year, month: date.month);
  }

  final int year;
  final int month;

  String get label => '$year-${month.toString().padLeft(2, '0')}';

  bool contains(String expenseDate) {
    return expenseDate.startsWith(label);
  }
}
