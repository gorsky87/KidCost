import 'package:flutter/material.dart';

import '../../expenses/expense_models.dart';
import '../../premium/premium_discovery.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    required this.expenses,
    this.currentDate,
    this.showReportExportPremiumHint = false,
    this.onPremiumHintDismissed,
    super.key,
  });

  final List<ExpenseEntry> expenses;
  final DateTime? currentDate;
  final bool showReportExportPremiumHint;
  final ValueChanged<PremiumDiscoveryPoint>? onPremiumHintDismissed;

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
          _BreakdownCard(
            title: 'Zaplacone przez rodzicow',
            values: report.byPayer,
          ),
          _BreakdownCard(title: 'Koszty dzieci', values: report.byChild),
          _BreakdownCard(title: 'Kategorie kosztow', values: report.byCategory),
          _ExpenseStatusCard(report: report),
        ],
        const SizedBox(height: 12),
        _ExportCard(
          report: report,
          showPremiumHint: widget.showReportExportPremiumHint,
          onPremiumHintDismissed: () => widget.onPremiumHintDismissed?.call(
            PremiumDiscoveryPoint.reportExport,
          ),
        ),
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
    required this.settledCents,
    required this.currentUserPaidCents,
    required this.coParentPaidCents,
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
    var settledCents = 0;
    var currentUserPaidCents = 0;

    for (final expense in monthExpenses) {
      totalCents += expense.amountCents;
      if (expense.paidBy.isCurrentUser) {
        currentUserPaidCents += expense.amountCents;
      }
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
      if (expense.status == ExpenseStatus.settled) {
        settledCents += expense.amountCents;
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
      settledCents: settledCents,
      currentUserPaidCents: currentUserPaidCents,
      coParentPaidCents: totalCents - currentUserPaidCents,
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
  final int settledCents;
  final int currentUserPaidCents;
  final int coParentPaidCents;

  String get fileName => 'kidcost-report-$month.csv';

  int get currentUserShareCents => totalCents ~/ 2;

  int get currentUserDifferenceCents =>
      currentUserPaidCents - currentUserShareCents;

  String get balanceText {
    if (totalCents == 0) {
      return 'Brak kosztow do wyrownania';
    }

    final difference = currentUserDifferenceCents;
    if (difference == 0) {
      return 'Jestescie rozliczeni na zero';
    }
    if (difference > 0) {
      return 'Drugi rodzic oddaje Tobie ${formatCents(difference)}';
    }
    return 'Ty oddajesz drugiemu rodzicowi ${formatCents(-difference)}';
  }

  String get differenceText {
    final difference = currentUserDifferenceCents;
    if (difference == 0) {
      return 'Twoje platnosci sa rowne Twojemu udzialowi.';
    }
    if (difference > 0) {
      return 'Zaplaciles o ${formatCents(difference)} wiecej niz Twoj udzial.';
    }
    return 'Zaplaciles o ${formatCents(-difference)} mniej niz Twoj udzial.';
  }

  String toCsv() {
    final rows = [
      [
        'data',
        'tytul',
        'dziecko',
        'kategoria',
        'placacy',
        'status',
        'typ_dowodu',
        'kwota',
      ],
      for (final expense in expenses)
        [
          expense.expenseDate,
          expense.title,
          expense.childName,
          expense.category.label,
          expense.paidBy.label,
          expense.status.label,
          expense.attachment?.evidence?.type?.label ?? '',
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
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Do wyrownania'),
            subtitle: Text(report.balanceText),
            trailing: Text(report.month),
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Zaplacone razem'),
            trailing: Text(formatCents(report.totalCents)),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Zaplaciles Ty'),
            trailing: Text(formatCents(report.currentUserPaidCents)),
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Zaplacil drugi rodzic'),
            trailing: Text(formatCents(report.coParentPaidCents)),
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart_outline),
            title: const Text('Twoj udzial'),
            subtitle: const Text('Liczymy prosty podzial 50/50.'),
            trailing: Text(formatCents(report.currentUserShareCents)),
          ),
          ListTile(
            leading: const Icon(Icons.compare_arrows_outlined),
            title: const Text('Roznica'),
            subtitle: Text(report.differenceText),
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_outlined),
            title: const Text('Wymaga wyjasnienia'),
            trailing: Text(formatCents(report.disputedCents)),
          ),
          ListTile(
            leading: const Icon(Icons.pending_actions_outlined),
            title: const Text('Do akceptacji'),
            trailing: Text(formatCents(report.pendingCents)),
          ),
          ListTile(
            leading: const Icon(Icons.task_alt_outlined),
            title: const Text('Rozliczone'),
            trailing: Text(formatCents(report.settledCents)),
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
  const _ExportCard({
    required this.report,
    required this.showPremiumHint,
    required this.onPremiumHintDismissed,
  });

  final MonthlyExpenseReport report;
  final bool showPremiumHint;
  final VoidCallback onPremiumHintDismissed;

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
            if (showPremiumHint) ...[
              const SizedBox(height: 8),
              PremiumDiscoveryCard(
                point: PremiumDiscoveryPoint.reportExport,
                onDismiss: onPremiumHintDismissed,
              ),
            ],
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
