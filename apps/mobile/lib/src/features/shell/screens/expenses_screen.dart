import 'package:flutter/material.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
}
