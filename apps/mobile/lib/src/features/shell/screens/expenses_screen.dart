import 'package:flutter/material.dart';

import '../../expenses/expense_models.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({required this.expenses, super.key});

  final List<ExpenseEntry> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.receipt_long_outlined),
            title: Text('Brak kosztow'),
            subtitle: Text(
              'Lista bedzie pokazywac koszty, statusy i zalaczniki.',
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final expense in expenses.reversed)
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(expense.title),
              subtitle: Text(
                [
                  expense.category.label,
                  expense.expenseDate,
                  'Zaplacil: ${expense.paidBy.label}',
                  if (expense.attachment != null)
                    expense.attachment!.status == AttachmentStatus.uploaded
                        ? 'Zalacznik: ${expense.attachment!.fileName}'
                        : 'Zalacznik: blad uploadu',
                ].join(' • '),
              ),
              trailing: Text(formatCents(expense.amountCents)),
            ),
          ),
      ],
    );
  }
}
