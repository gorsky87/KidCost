import 'package:flutter/material.dart';

import '../../expenses/expense_models.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({required this.expenses, this.currentDate, super.key});

  final List<ExpenseEntry> expenses;
  final DateTime? currentDate;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final months = _reportMonths();
    final month = _selectedMonth ?? months.first;
    final report = MonthlyExpenseReport.fromExpenses(
      month: month,
      expenses: widget.expenses,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Raport miesieczny',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const Key('report-month-picker'),
          initialValue: month,
          decoration: const InputDecoration(
            labelText: 'Miesiac raportu',
            prefixIcon: Icon(Icons.calendar_month_outlined),
          ),
          items: [
            for (final item in months)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedMonth = value);
            }
          },
        ),
        const SizedBox(height: 16),
        _ReportSummaryCard(report: report),
        const SizedBox(height: 12),
        if (report.expenses.isEmpty)
          const _EmptyReportCard()
        else ...[
          _BreakdownCard(title: 'Suma per rodzic', values: report.byPayer),
          _BreakdownCard(title: 'Suma per dziecko', values: report.byChild),
          _BreakdownCard(
            title: 'Suma per kategoria',
            values: report.byCategory,
          ),
          _ExpenseStatusCard(report: report),
        ],
        const SizedBox(height: 12),
        _ExportCard(report: report),
      ],
    );
  }

  List<String> _reportMonths() {
    final months = <String>{
      _monthLabel(widget.currentDate ?? DateTime.now()),
      for (final expense in widget.expenses)
        _monthFromDate(expense.expenseDate),
    }.toList()..sort((first, second) => second.compareTo(first));
    return months;
  }

  String _monthLabel(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _monthFromDate(String date) {
    if (date.length < 7) {
      return date;
    }
    return date.substring(0, 7);
  }
}

class MonthlyExpenseReport {
  const MonthlyExpenseReport({
    required this.month,
    required this.expenses,
    required this.totalCents,
    required this.byPayer,
    required this.byChild,
    required this.byCategory,
    required this.disputedCents,
    required this.pendingCents,
  });

  factory MonthlyExpenseReport.fromExpenses({
    required String month,
    required List<ExpenseEntry> expenses,
  }) {
    final monthExpenses =
        expenses
            .where((expense) => expense.expenseDate.startsWith(month))
            .toList()
          ..sort(
            (first, second) => first.expenseDate.compareTo(second.expenseDate),
          );

    final byPayer = <String, int>{};
    final byChild = <String, int>{};
    final byCategory = <String, int>{};
    var totalCents = 0;
    var disputedCents = 0;
    var pendingCents = 0;

    for (final expense in monthExpenses) {
      totalCents += expense.amountCents;
      byPayer.update(
        expense.paidBy.label,
        (value) => value + expense.amountCents,
        ifAbsent: () => expense.amountCents,
      );
      byChild.update(
        expense.childName,
        (value) => value + expense.amountCents,
        ifAbsent: () => expense.amountCents,
      );
      byCategory.update(
        expense.category.label,
        (value) => value + expense.amountCents,
        ifAbsent: () => expense.amountCents,
      );

      if (expense.status == ExpenseStatus.disputed) {
        disputedCents += expense.amountCents;
      }
      if (expense.status == ExpenseStatus.pending) {
        pendingCents += expense.amountCents;
      }
    }

    return MonthlyExpenseReport(
      month: month,
      expenses: monthExpenses,
      totalCents: totalCents,
      byPayer: _sortedTotals(byPayer),
      byChild: _sortedTotals(byChild),
      byCategory: _sortedTotals(byCategory),
      disputedCents: disputedCents,
      pendingCents: pendingCents,
    );
  }

  final String month;
  final List<ExpenseEntry> expenses;
  final int totalCents;
  final Map<String, int> byPayer;
  final Map<String, int> byChild;
  final Map<String, int> byCategory;
  final int disputedCents;
  final int pendingCents;

  String get fileName => 'kidcost-report-$month.csv';

  String toCsv() {
    final rows = [
      ['data', 'tytul', 'dziecko', 'kategoria', 'placacy', 'status', 'kwota'],
      for (final expense in expenses)
        [
          expense.expenseDate,
          expense.title,
          expense.childName,
          expense.category.label,
          expense.paidBy.label,
          expense.status.label,
          formatCents(expense.amountCents),
        ],
    ];

    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }

  static Map<String, int> _sortedTotals(Map<String, int> values) {
    final entries = values.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));
    return {for (final entry in entries) entry.key: entry.value};
  }

  static String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({required this.report});

  final MonthlyExpenseReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Suma kosztow'),
            subtitle: Text(report.month),
            trailing: Text(formatCents(report.totalCents)),
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_outlined),
            title: const Text('Koszty sporne'),
            trailing: Text(formatCents(report.disputedCents)),
          ),
          ListTile(
            leading: const Icon(Icons.pending_actions_outlined),
            title: const Text('Koszty nierozliczone'),
            trailing: Text(formatCents(report.pendingCents)),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.title, required this.values});

  final String title;
  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final entry in values.entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.key),
                trailing: Text(formatCents(entry.value)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseStatusCard extends StatelessWidget {
  const _ExpenseStatusCard({required this.report});

  final MonthlyExpenseReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Koszty w raporcie',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final expense in report.expenses)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(expense.title),
                subtitle: Text(
                  '${expense.expenseDate} • ${expense.status.label}',
                ),
                trailing: Text(formatCents(expense.amountCents)),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReportCard extends StatelessWidget {
  const _EmptyReportCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.inbox_outlined),
        title: Text('Brak kosztow w tym miesiacu'),
        subtitle: Text(
          'Raport jest gotowy, ale nie ma jeszcze danych do pokazania.',
        ),
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.report});

  final MonthlyExpenseReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Eksport', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _showCsvPreview(context),
              icon: const Icon(Icons.table_view_outlined),
              label: Text('CSV: ${report.fileName}'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF wymaga generatora'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCsvPreview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.75,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  'Eksport CSV',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                SelectableText(report.fileName),
                const SizedBox(height: 12),
                SelectableText(report.toCsv()),
              ],
            ),
          ),
        );
      },
    );
  }
}
