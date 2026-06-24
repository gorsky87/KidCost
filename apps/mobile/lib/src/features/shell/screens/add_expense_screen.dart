import 'package:flutter/material.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Nowy koszt', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        const TextField(
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Kwota',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Opis',
            prefixIcon: Icon(Icons.notes_outlined),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Kategoria',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 'school', child: Text('Szkola')),
            DropdownMenuItem(value: 'health', child: Text('Zdrowie')),
            DropdownMenuItem(value: 'clothes', child: Text('Ubrania')),
            DropdownMenuItem(value: 'activity', child: Text('Zajecia')),
          ],
          onChanged: (_) {},
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.attach_file),
          label: const Text('Dodaj paragon'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.save_outlined),
          label: const Text('Zapisz koszt'),
        ),
      ],
    );
  }
}
