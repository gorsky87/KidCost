import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Podsumowanie miesiaca',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        const _MetricTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Wydatki razem',
          value: '0,00 zl',
        ),
        const _MetricTile(
          icon: Icons.swap_horiz,
          title: 'Saldo 50/50',
          value: 'Brak kosztow',
        ),
        const _MetricTile(
          icon: Icons.receipt_long_outlined,
          title: 'Ostatnie koszty',
          value: 'Dodaj pierwszy koszt, aby zobaczyc demo przeplywu.',
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
