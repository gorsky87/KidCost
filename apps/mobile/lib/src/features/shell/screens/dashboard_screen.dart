import 'package:flutter/material.dart';

import '../../expenses/expense_models.dart';
import '../../onboarding/onboarding_profile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.profile,
    required this.expenses,
    super.key,
  });

  final OnboardingProfile profile;
  final List<ExpenseEntry> expenses;

  @override
  Widget build(BuildContext context) {
    final totalCents = expenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amountCents,
    );
    final userPaidCents = expenses
        .where((expense) => expense.paidBy.isCurrentUser)
        .fold<int>(0, (sum, expense) => sum + expense.amountCents);
    final halfCents = totalCents ~/ 2;
    final netCents = userPaidCents - halfCents;
    final balanceText = expenses.isEmpty
        ? 'Brak kosztow'
        : netCents >= 0
        ? 'Drugi rodzic oddaje ${formatCents(netCents)}'
        : 'Ty oddajesz ${formatCents(-netCents)}';

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
        _MetricTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Wydatki razem',
          value: formatCents(totalCents),
        ),
        _MetricTile(
          icon: Icons.swap_horiz,
          title: 'Saldo 50/50',
          value: balanceText,
        ),
        _MetricTile(
          icon: Icons.receipt_long_outlined,
          title: expenses.isEmpty ? 'Dodaj pierwszy koszt' : 'Ostatnie koszty',
          value: expenses.isEmpty
              ? 'Onboarding gotowy. Zapisz pierwszy koszt, aby zobaczyc saldo i historie.'
              : '${expenses.length} kosztow w historii.',
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
