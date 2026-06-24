import 'package:flutter/material.dart';

import '../../custody/custody_models.dart';
import '../../expenses/expense_models.dart';
import '../../onboarding/onboarding_profile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.profile,
    required this.expenses,
    required this.custodyDays,
    required this.onAddExpense,
    required this.onOpenExpenses,
    required this.onOpenReports,
    required this.onOpenFamily,
    this.currentDate,
    super.key,
  });

  final OnboardingProfile profile;
  final List<ExpenseEntry> expenses;
  final List<CustodyDay> custodyDays;
  final VoidCallback onAddExpense;
  final VoidCallback onOpenExpenses;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenFamily;
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
    final upcomingCustodyDays = _upcomingCustodyDays(
      custodyDays,
      currentDate ?? DateTime.now(),
    );

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
        Text('Waluta rozliczen: ${profile.familyCurrency}'),
        const SizedBox(height: 16),
        if (profile.isSoloFamily) ...[
          _SoloFamilyCard(profile: profile, onOpenFamily: onOpenFamily),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: onAddExpense,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Dodaj koszt'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onOpenReports,
          icon: const Icon(Icons.summarize_outlined),
          label: const Text('Raport miesiaca'),
        ),
        const SizedBox(height: 12),
        _MetricTile(
          icon: Icons.swap_horiz,
          title: profile.isSoloFamily ? 'Saldo robocze' : 'Kto komu oddaje',
          value: summary.balanceText(profile),
          helper: profile.isSoloFamily
              ? 'Prywatny szkic 50/50 widoczny tylko dla Ciebie.'
              : 'Liczymy prosty podzial 50/50 w ${profile.familyCurrency}.',
        ),
        const SizedBox(height: 8),
        _NeedsAttentionCard(
          expenses: monthExpenses,
          onAddExpense: onAddExpense,
          onOpenExpenses: onOpenExpenses,
        ),
        if (monthExpenses.isEmpty) ...[
          const SizedBox(height: 8),
          _EmptyDashboardState(onAddExpense: onAddExpense),
        ],
        _MetricTile(
          icon: Icons.calendar_month_outlined,
          title: 'Wydatki w tym miesiacu (${profile.familyCurrency})',
          value: formatCents(
            summary.totalCents,
            currencyCode: profile.familyCurrency,
          ),
          helper: month.label,
        ),
        _MetricTile(
          icon: Icons.person_outline,
          title: 'Ty zaplaciles',
          value: formatCents(
            summary.currentUserPaidCents,
            currencyCode: profile.familyCurrency,
          ),
        ),
        _MetricTile(
          icon: Icons.group_outlined,
          title: _coParentPaidTitle(profile.coParentLabel),
          value: formatCents(
            summary.coParentPaidCents,
            currencyCode: profile.familyCurrency,
          ),
        ),
        const SizedBox(height: 8),
        _UpcomingCustodyCard(custodyDays: upcomingCustodyDays),
        const SizedBox(height: 8),
        if (monthExpenses.isNotEmpty)
          _RecentExpenses(expenses: recentExpenses.take(5).toList()),
      ],
    );
  }
}

String _coParentPaidTitle(String label) {
  if (label == 'Drugi rodzic') {
    return 'Drugi rodzic zaplacil';
  }
  return '$label zaplacil(a)';
}

class _NeedsAttentionCard extends StatelessWidget {
  const _NeedsAttentionCard({
    required this.expenses,
    required this.onAddExpense,
    required this.onOpenExpenses,
  });

  final List<ExpenseEntry> expenses;
  final VoidCallback onAddExpense;
  final VoidCallback onOpenExpenses;

  @override
  Widget build(BuildContext context) {
    final items = _AttentionItem.fromExpenses(expenses).take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wymaga uwagi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              _AttentionEmptyState(
                hasExpenses: expenses.isNotEmpty,
                onAddExpense: onAddExpense,
                onOpenExpenses: onOpenExpenses,
              )
            else
              for (final item in items) ...[
                _AttentionRow(item: item, onPressed: onOpenExpenses),
                if (item != items.last) const Divider(height: 16),
              ],
          ],
        ),
      ),
    );
  }
}

class _AttentionEmptyState extends StatelessWidget {
  const _AttentionEmptyState({
    required this.hasExpenses,
    required this.onAddExpense,
    required this.onOpenExpenses,
  });

  final bool hasExpenses;
  final VoidCallback onAddExpense;
  final VoidCallback onOpenExpenses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          hasExpenses
              ? 'Nie ma teraz kosztow blokujacych rozliczenie.'
              : 'Dodaj pierwszy koszt, aby zobaczyc tu sprawy do sprawdzenia.',
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: hasExpenses ? onOpenExpenses : onAddExpense,
          icon: Icon(
            hasExpenses
                ? Icons.receipt_long_outlined
                : Icons.add_circle_outline,
          ),
          label: Text(hasExpenses ? 'Przejrzyj koszty' : 'Dodaj koszt'),
        ),
      ],
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item, required this.onPressed});

  final _AttentionItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(item.icon),
            title: Text(item.title),
            subtitle: Text('${item.reason}\n${item.expense.expenseDate}'),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: onPressed,
              child: Text(item.actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionItem {
  const _AttentionItem({
    required this.expense,
    required this.priority,
    required this.icon,
    required this.title,
    required this.reason,
    required this.actionLabel,
  });

  final ExpenseEntry expense;
  final int priority;
  final IconData icon;
  final String title;
  final String reason;
  final String actionLabel;

  static List<_AttentionItem> fromExpenses(List<ExpenseEntry> expenses) {
    final items = <_AttentionItem>[];

    for (final expense in expenses) {
      final item = _AttentionItem._fromExpense(expense);
      if (item != null) {
        items.add(item);
      }
    }

    items.sort((first, second) {
      final priority = first.priority.compareTo(second.priority);
      if (priority != 0) {
        return priority;
      }
      final date = second.expense.expenseDate.compareTo(
        first.expense.expenseDate,
      );
      if (date != 0) {
        return date;
      }
      return second.expense.createdAt.compareTo(first.expense.createdAt);
    });

    return items;
  }

  static _AttentionItem? _fromExpense(ExpenseEntry expense) {
    if (expense.status == ExpenseStatus.disputed) {
      return _AttentionItem(
        expense: expense,
        priority: 0,
        icon: Icons.report_problem_outlined,
        title: expense.title,
        reason: 'Spor wymaga wyjasnienia',
        actionLabel: 'Otworz',
      );
    }

    if (expense.status == ExpenseStatus.pending &&
        !expense.paidBy.isCurrentUser) {
      return _AttentionItem(
        expense: expense,
        priority: 1,
        icon: Icons.fact_check_outlined,
        title: expense.title,
        reason: 'Koszt od drugiego rodzica czeka na decyzje',
        actionLabel: 'Sprawdz',
      );
    }

    if (expense.status == ExpenseStatus.accepted) {
      return _AttentionItem(
        expense: expense,
        priority: 2,
        icon: Icons.payments_outlined,
        title: expense.title,
        reason: 'Zaakceptowany koszt czeka na rozliczenie',
        actionLabel: 'Rozlicz',
      );
    }

    if (expense.status == ExpenseStatus.pending &&
        expense.attachment == null &&
        expense.paidBy.isCurrentUser) {
      return _AttentionItem(
        expense: expense,
        priority: 3,
        icon: Icons.attach_file_outlined,
        title: expense.title,
        reason: 'Brakuje dowodu kosztu',
        actionLabel: 'Uzupelnij',
      );
    }

    return null;
  }
}

class _SoloFamilyCard extends StatelessWidget {
  const _SoloFamilyCard({required this.profile, required this.onOpenFamily});

  final OnboardingProfile profile;
  final VoidCallback onOpenFamily;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_person_outlined),
              title: const Text('Pracujesz solo'),
              subtitle: Text(
                'Koszty sa prywatne dla autora. Etykieta drugiego rodzica: ${profile.coParentLabel}.',
              ),
            ),
            OutlinedButton.icon(
              onPressed: onOpenFamily,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Pokaz podsumowanie i zapros wspolrodzica'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCustodyCard extends StatelessWidget {
  const _UpcomingCustodyCard({required this.custodyDays});

  final List<CustodyDay> custodyDays;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Najblizsza opieka',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (custodyDays.isEmpty)
              const Text(
                'Dodaj dni opieki w zakladce Opieka, aby widziec plan na start.',
              )
            else
              for (final day in custodyDays)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(day.date),
                  subtitle: Text('${day.childName} • ${day.parent.label}'),
                ),
          ],
        ),
      ),
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

  String balanceText(OnboardingProfile profile) {
    if (totalCents == 0) {
      return profile.isSoloFamily
          ? 'Brak kosztow w saldzie roboczym'
          : 'Brak kosztow do wyrownania';
    }

    final halfCents = totalCents ~/ 2;
    final currentUserShare = currentUserPaidCents - halfCents;
    if (currentUserShare == 0) {
      return profile.isSoloFamily
          ? 'Roboczo: saldo wychodzi na zero'
          : 'Jestescie rozliczeni na zero';
    }

    if (currentUserShare > 0) {
      final prefix = profile.isSoloFamily ? 'Roboczo: ' : '';
      return '$prefix${profile.coParentLabel} oddaje Tobie ${formatCents(currentUserShare, currencyCode: profile.familyCurrency)}';
    }

    final prefix = profile.isSoloFamily ? 'Roboczo: ' : '';
    return '${prefix}Ty oddajesz ${_coParentDativeLabel(profile.coParentLabel)} ${formatCents(-currentUserShare, currencyCode: profile.familyCurrency)}';
  }
}

String _coParentDativeLabel(String label) {
  if (label == 'Drugi rodzic') {
    return 'drugiemu rodzicowi';
  }
  return label;
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

List<CustodyDay> _upcomingCustodyDays(
  List<CustodyDay> custodyDays,
  DateTime currentDate,
) {
  final today = DateTime.utc(
    currentDate.year,
    currentDate.month,
    currentDate.day,
  );
  final sorted = [...custodyDays]
    ..sort((first, second) => first.date.compareTo(second.date));

  return sorted
      .where((day) {
        final parsed = parseCustodyDate(day.date);
        return parsed != null && !parsed.isBefore(today);
      })
      .take(5)
      .toList();
}
