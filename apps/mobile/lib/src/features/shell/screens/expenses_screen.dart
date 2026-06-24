import 'package:flutter/material.dart';

import '../../expenses/expense_models.dart';

enum _ExpenseSort { newest, oldest, highestAmount, lowestAmount }

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({
    required this.expenses,
    this.isLoading = false,
    this.errorMessage,
    super.key,
  });

  final List<ExpenseEntry> expenses;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String? _monthFilter;
  String? _childFilter;
  String? _categoryFilter;
  ExpenseStatus? _statusFilter;
  String? _payerFilter;
  _ExpenseSort _sort = _ExpenseSort.newest;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Ladowanie kosztow'),
            subtitle: Text('Pobieramy historie wydatkow.'),
          ),
        ],
      );
    }

    final errorMessage = widget.errorMessage;
    if (errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.error_outline),
            title: const Text('Nie udalo sie pobrac kosztow'),
            subtitle: Text(errorMessage),
          ),
        ],
      );
    }

    if (widget.expenses.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _EmptyExpensesTile(
            title: 'Brak kosztow',
            subtitle: 'Lista bedzie pokazywac koszty, statusy i zalaczniki.',
          ),
        ],
      );
    }

    final filteredExpenses = _filteredAndSortedExpenses();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFilters(context),
        const SizedBox(height: 16),
        if (filteredExpenses.isEmpty)
          _EmptyExpensesTile(
            title: 'Brak kosztow dla filtrow',
            subtitle: 'Zmien kryteria albo wyczysc wszystkie filtry.',
            action: OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Wyczysc filtry'),
            ),
          )
        else
          for (final expense in filteredExpenses)
            _ExpenseCard(expense: expense),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    final months = _uniqueValues(
      widget.expenses.map((expense) => _monthFromDate(expense.expenseDate)),
    );
    final children = _uniqueValues(
      widget.expenses.map((expense) => expense.childName),
    );
    final payers = _uniqueValues(
      widget.expenses.map((expense) => expense.paidBy.label),
    );
    final hasFilters =
        _monthFilter != null ||
        _childFilter != null ||
        _categoryFilter != null ||
        _statusFilter != null ||
        _payerFilter != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Filtry', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: hasFilters ? _clearFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Wyczysc'),
                ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              initiallyExpanded: hasFilters,
              title: const Text('Pokaz filtry i sortowanie'),
              children: [
                DropdownButtonFormField<String>(
                  key: const Key('expense-month-filter'),
                  initialValue: _monthFilter,
                  decoration: const InputDecoration(
                    labelText: 'Miesiac',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Wszystkie'),
                    ),
                    for (final month in months)
                      DropdownMenuItem(value: month, child: Text(month)),
                  ],
                  onChanged: (value) => setState(() => _monthFilter = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('expense-child-filter'),
                  initialValue: _childFilter,
                  decoration: const InputDecoration(
                    labelText: 'Dziecko',
                    prefixIcon: Icon(Icons.child_care_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Wszystkie'),
                    ),
                    for (final child in children)
                      DropdownMenuItem(value: child, child: Text(child)),
                  ],
                  onChanged: (value) => setState(() => _childFilter = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('expense-category-filter'),
                  initialValue: _categoryFilter,
                  decoration: const InputDecoration(
                    labelText: 'Kategoria',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Wszystkie'),
                    ),
                    for (final category in expenseCategories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(category.label),
                      ),
                  ],
                  onChanged: (value) => setState(() => _categoryFilter = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ExpenseStatus>(
                  key: const Key('expense-status-filter'),
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.verified_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Wszystkie'),
                    ),
                    for (final status in ExpenseStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: (value) => setState(() => _statusFilter = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('expense-payer-filter'),
                  initialValue: _payerFilter,
                  decoration: const InputDecoration(
                    labelText: 'Placacy',
                    prefixIcon: Icon(Icons.account_circle_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Wszyscy')),
                    for (final payer in payers)
                      DropdownMenuItem(value: payer, child: Text(payer)),
                  ],
                  onChanged: (value) => setState(() => _payerFilter = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<_ExpenseSort>(
                  key: const Key('expense-sort'),
                  initialValue: _sort,
                  decoration: const InputDecoration(
                    labelText: 'Sortowanie',
                    prefixIcon: Icon(Icons.sort_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: _ExpenseSort.newest,
                      child: Text('Data: najnowsze'),
                    ),
                    DropdownMenuItem(
                      value: _ExpenseSort.oldest,
                      child: Text('Data: najstarsze'),
                    ),
                    DropdownMenuItem(
                      value: _ExpenseSort.highestAmount,
                      child: Text('Kwota: najwyzsza'),
                    ),
                    DropdownMenuItem(
                      value: _ExpenseSort.lowestAmount,
                      child: Text('Kwota: najnizsza'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sort = value);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<ExpenseEntry> _filteredAndSortedExpenses() {
    final filtered = widget.expenses.where((expense) {
      final month = _monthFromDate(expense.expenseDate);
      return (_monthFilter == null || month == _monthFilter) &&
          (_childFilter == null || expense.childName == _childFilter) &&
          (_categoryFilter == null || expense.category.id == _categoryFilter) &&
          (_statusFilter == null || expense.status == _statusFilter) &&
          (_payerFilter == null || expense.paidBy.label == _payerFilter);
    }).toList();

    filtered.sort((first, second) {
      switch (_sort) {
        case _ExpenseSort.newest:
          return second.expenseDate.compareTo(first.expenseDate);
        case _ExpenseSort.oldest:
          return first.expenseDate.compareTo(second.expenseDate);
        case _ExpenseSort.highestAmount:
          return second.amountCents.compareTo(first.amountCents);
        case _ExpenseSort.lowestAmount:
          return first.amountCents.compareTo(second.amountCents);
      }
    });

    return filtered;
  }

  void _clearFilters() {
    setState(() {
      _monthFilter = null;
      _childFilter = null;
      _categoryFilter = null;
      _statusFilter = null;
      _payerFilter = null;
    });
  }

  String _monthFromDate(String date) {
    if (date.length < 7) {
      return date;
    }
    return date.substring(0, 7);
  }

  List<String> _uniqueValues(Iterable<String> values) {
    return values.toSet().toList()..sort();
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expense});

  final ExpenseEntry expense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text(expense.title),
        subtitle: Text(
          [
            expense.category.label,
            expense.childName,
            expense.expenseDate,
            'Zaplacil: ${expense.paidBy.label}',
            'Status: ${expense.status.label}',
            if (expense.attachment != null)
              expense.attachment!.status == AttachmentStatus.uploaded
                  ? 'Zalacznik: ${expense.attachment!.fileName}'
                  : 'Zalacznik: blad uploadu',
          ].join(' • '),
        ),
        trailing: Text(
          formatCents(expense.amountCents),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        onTap: () => _showExpenseDetails(context, expense),
      ),
    );
  }

  void _showExpenseDetails(BuildContext context, ExpenseEntry expense) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Szczegoly kosztu',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Nazwa', value: expense.title),
                  _DetailRow(
                    label: 'Kwota',
                    value: formatCents(expense.amountCents),
                  ),
                  _DetailRow(label: 'Kategoria', value: expense.category.label),
                  _DetailRow(label: 'Dziecko', value: expense.childName),
                  _DetailRow(label: 'Placacy', value: expense.paidBy.label),
                  _DetailRow(label: 'Data', value: expense.expenseDate),
                  _DetailRow(label: 'Status', value: expense.status.label),
                  const SizedBox(height: 12),
                  _AttachmentPreview(attachment: expense.attachment),
                  const SizedBox(height: 16),
                  if (expense.status.canEdit)
                    FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Edycja kosztu bedzie dostepna po podpieciu backendu.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edytuj koszt'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Edycja zablokowana przez status'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.attachment});

  final ExpenseAttachment? attachment;

  @override
  Widget build(BuildContext context) {
    final attachment = this.attachment;
    if (attachment == null) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.attach_file),
        title: Text('Brak zalacznika'),
        subtitle: Text('Do tego kosztu nie dodano pliku.'),
      );
    }

    if (attachment.status == AttachmentStatus.failed) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.cloud_off_outlined),
        title: Text('Zalacznik wymaga ponowienia'),
        subtitle: Text(attachment.errorMessage ?? attachment.fileName),
      );
    }

    final isImage = attachment.contentType.startsWith('image/');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
      ),
      title: Text(
        isImage
            ? 'Podglad zalacznika: ${attachment.fileName}'
            : 'Podglad PDF: ${attachment.fileName}',
      ),
      subtitle: Text(attachment.storagePath ?? 'Plik zapisany.'),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EmptyExpensesTile extends StatelessWidget {
  const _EmptyExpensesTile({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(title),
              subtitle: Text(subtitle),
            ),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}
