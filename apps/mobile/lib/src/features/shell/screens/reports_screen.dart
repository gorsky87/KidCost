import 'package:flutter/material.dart';
import 'package:kidcost_domain/domain.dart' as domain;

import '../../expenses/expense_models.dart';
import '../../premium/premium_discovery.dart';

enum _ReportMode { monthly, annual }

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
  _ReportMode _reportMode = _ReportMode.monthly;
  String? _selectedMonth;
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final months = _reportMonths();
    final month = _selectedMonth ?? months.first;
    final monthlyReport = MonthlyExpenseReport.fromExpenses(
      month: month,
      expenses: widget.expenses,
    );
    final years = _reportYears();
    final year = _selectedYear ?? years.first;
    final annualReport = AnnualExpenseReport.fromExpenses(
      year: year,
      expenses: widget.expenses,
      generatedAt: widget.currentDate ?? DateTime.now(),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _reportMode == _ReportMode.monthly
              ? 'Raport miesieczny'
              : 'Raport roczny',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<_ReportMode>(
          segments: const [
            ButtonSegment(
              value: _ReportMode.monthly,
              icon: Icon(Icons.calendar_month_outlined),
              label: Text('Miesiac'),
            ),
            ButtonSegment(
              value: _ReportMode.annual,
              icon: Icon(Icons.event_note_outlined),
              label: Text('Rok'),
            ),
          ],
          selected: {_reportMode},
          onSelectionChanged: (selection) {
            setState(() => _reportMode = selection.first);
          },
        ),
        const SizedBox(height: 12),
        if (_reportMode == _ReportMode.monthly)
          _MonthlyReportView(
            months: months,
            month: month,
            report: monthlyReport,
            showPremiumHint: widget.showReportExportPremiumHint,
            onMonthChanged: (value) => setState(() => _selectedMonth = value),
            onPremiumHintDismissed: () => widget.onPremiumHintDismissed?.call(
              PremiumDiscoveryPoint.reportExport,
            ),
          )
        else
          _AnnualReportView(
            years: years,
            year: year,
            report: annualReport,
            showPremiumHint: widget.showReportExportPremiumHint,
            onYearChanged: (value) => setState(() => _selectedYear = value),
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

  List<int> _reportYears() {
    final years = <int>{
      (widget.currentDate ?? DateTime.now()).year,
      for (final expense in widget.expenses)
        int.tryParse(expense.expenseDate.split('-').first) ??
            (widget.currentDate ?? DateTime.now()).year,
    }.toList()..sort((first, second) => second.compareTo(first));
    return years;
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

class _MonthlyReportView extends StatelessWidget {
  const _MonthlyReportView({
    required this.months,
    required this.month,
    required this.report,
    required this.showPremiumHint,
    required this.onMonthChanged,
    required this.onPremiumHintDismissed,
  });

  final List<String> months;
  final String month;
  final MonthlyExpenseReport report;
  final bool showPremiumHint;
  final ValueChanged<String> onMonthChanged;
  final VoidCallback onPremiumHintDismissed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              onMonthChanged(value);
            }
          },
        ),
        const SizedBox(height: 16),
        _ReportSummaryCard(report: report),
        const SizedBox(height: 12),
        _SettlementStatusCard(report: report),
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
          title: 'Eksport',
          fileName: report.fileName,
          csv: report.toCsv(),
          showPremiumHint: showPremiumHint,
          onPremiumHintDismissed: onPremiumHintDismissed,
        ),
        const SizedBox(height: 12),
        _ProfessionalAccessCard(periodLabel: report.month),
      ],
    );
  }
}

class _AnnualReportView extends StatelessWidget {
  const _AnnualReportView({
    required this.years,
    required this.year,
    required this.report,
    required this.showPremiumHint,
    required this.onYearChanged,
    required this.onPremiumHintDismissed,
  });

  final List<int> years;
  final int year;
  final AnnualExpenseReport report;
  final bool showPremiumHint;
  final ValueChanged<int> onYearChanged;
  final VoidCallback onPremiumHintDismissed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          key: const Key('report-year-picker'),
          initialValue: year,
          decoration: const InputDecoration(
            labelText: 'Rok raportu',
            prefixIcon: Icon(Icons.event_note_outlined),
          ),
          items: [
            for (final item in years)
              DropdownMenuItem(value: item, child: Text(item.toString())),
          ],
          onChanged: (value) {
            if (value != null) {
              onYearChanged(value);
            }
          },
        ),
        const SizedBox(height: 16),
        _AnnualReportSummaryCard(report: report),
        const SizedBox(height: 12),
        if (report.expenses.isEmpty)
          const _EmptyAnnualReportCard()
        else ...[
          _BreakdownCard(
            title: 'Rocznie zaplacone przez rodzicow',
            values: report.byPayer,
          ),
          _BreakdownCard(title: 'Roczne koszty dzieci', values: report.byChild),
          _BreakdownCard(
            title: 'Roczne kategorie kosztow',
            values: report.byCategory,
          ),
          _BreakdownCard(title: 'Statusy kosztow', values: report.byStatus),
          _AnnualExpenseListCard(report: report),
        ],
        const SizedBox(height: 12),
        _ExportCard(
          title: 'Eksport roczny',
          fileName: report.fileName,
          csv: report.toCsv(),
          showPremiumHint: showPremiumHint,
          onPremiumHintDismissed: onPremiumHintDismissed,
        ),
        const SizedBox(height: 12),
        _ProfessionalAccessCard(periodLabel: report.year.toString()),
      ],
    );
  }
}

class _SettlementStatusCard extends StatelessWidget {
  const _SettlementStatusCard({required this.report});

  final MonthlyExpenseReport report;

  @override
  Widget build(BuildContext context) {
    final openAmount = report.currentUserDifferenceCents.abs();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.payments_outlined),
              title: Text('Zwroty i zaleglosci'),
              subtitle: Text(
                'MVP pokazuje otwarta kwote; alokacje platnosci beda przypinane do kosztow lub okresow.',
              ),
            ),
            _SettlementStateRow(
              label:
                  domain.partialSettlementUiStates[domain
                      .SettlementAllocationState
                      .partiallyPaid]!,
              body:
                  'Czesc zwrotu zaplacona, ale pozostala kwota dalej widoczna jako arrears.',
            ),
            _SettlementStateRow(
              label:
                  domain.partialSettlementUiStates[domain
                      .SettlementAllocationState
                      .settled]!,
              body: 'Pelna kwota przypisana do kosztu lub zestawu kosztow.',
            ),
            _SettlementStateRow(
              label: 'Otwarta kwota w tym raporcie',
              body: formatCents(openAmount),
            ),
            const _SettlementStateRow(
              label: domain.paymentProofReportMarker,
              body:
                  'Raport oznacza zwroty z potwierdzeniem przelewu, BLIK, gotowki, czeku, PayPal albo PDF.',
            ),
            const _SettlementStateRow(
              label: 'Stany zalacznika',
              body:
                  'Dodaj, podejrzyj, zamien albo usun dowod; nieudany upload zostaje widoczny do ponowienia.',
            ),
            const _SettlementStateRow(
              label: 'Bez certyfikacji prawnej',
              body: domain.paymentProofPrivacyCopy,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettlementStateRow extends StatelessWidget {
  const _SettlementStateRow({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle_outline),
      title: Text(label),
      subtitle: Text(body),
    );
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
        'wydarzenie_data',
        'wydarzenie_tytul',
        'typ_dowodu',
        'kwota_pln',
        'oryginalna_kwota_paragonu',
      ],
      for (final expense in expenses)
        [
          expense.expenseDate,
          expense.title,
          expense.childName,
          expense.category.label,
          expense.paidBy.label,
          expense.status.label,
          expense.calendarEventDate ?? '',
          expense.calendarEventTitle ?? '',
          expense.attachment?.evidence?.type?.label ?? '',
          formatCents(expense.amountCents),
          expense.originalReceiptAmountLabel ?? '',
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

class AnnualExpenseReport {
  const AnnualExpenseReport({
    required this.year,
    required this.generatedAt,
    required this.expenses,
    required this.totalCents,
    required this.byPayer,
    required this.byChild,
    required this.byCategory,
    required this.byStatus,
    required this.disputedCents,
    required this.pendingCents,
    required this.unsettledCents,
    required this.currentUserPaidCents,
    required this.coParentPaidCents,
  });

  factory AnnualExpenseReport.fromExpenses({
    required int year,
    required List<ExpenseEntry> expenses,
    required DateTime generatedAt,
  }) {
    final yearPrefix = '$year-';
    final yearExpenses =
        expenses
            .where((expense) => expense.expenseDate.startsWith(yearPrefix))
            .toList()
          ..sort(
            (first, second) => first.expenseDate.compareTo(second.expenseDate),
          );

    final byPayer = <String, int>{};
    final byChild = <String, int>{};
    final byCategory = <String, int>{};
    final byStatus = <String, int>{};
    var totalCents = 0;
    var disputedCents = 0;
    var pendingCents = 0;
    var settledCents = 0;
    var currentUserPaidCents = 0;

    for (final expense in yearExpenses) {
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
      byStatus.update(
        expense.status.label,
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

    return AnnualExpenseReport(
      year: year,
      generatedAt: generatedAt.toUtc(),
      expenses: yearExpenses,
      totalCents: totalCents,
      byPayer: MonthlyExpenseReport._sortedTotals(byPayer),
      byChild: MonthlyExpenseReport._sortedTotals(byChild),
      byCategory: MonthlyExpenseReport._sortedTotals(byCategory),
      byStatus: MonthlyExpenseReport._sortedTotals(byStatus),
      disputedCents: disputedCents,
      pendingCents: pendingCents,
      unsettledCents: totalCents - settledCents,
      currentUserPaidCents: currentUserPaidCents,
      coParentPaidCents: totalCents - currentUserPaidCents,
    );
  }

  final int year;
  final DateTime generatedAt;
  final List<ExpenseEntry> expenses;
  final int totalCents;
  final Map<String, int> byPayer;
  final Map<String, int> byChild;
  final Map<String, int> byCategory;
  final Map<String, int> byStatus;
  final int disputedCents;
  final int pendingCents;
  final int unsettledCents;
  final int currentUserPaidCents;
  final int coParentPaidCents;

  String get fileName => 'kidcost-annual-report-$year.csv';

  String toCsv() {
    final rows = [
      ['generated_at', generatedAt.toIso8601String()],
      ['year', year.toString()],
      const <String>[],
      [
        'data',
        'tytul',
        'dziecko',
        'kategoria',
        'placacy',
        'status',
        'wydarzenie_data',
        'wydarzenie_tytul',
        'typ_dowodu',
        'kwota_pln',
        'oryginalna_kwota_paragonu',
      ],
      for (final expense in expenses)
        [
          expense.expenseDate,
          expense.title,
          expense.childName,
          expense.category.label,
          expense.paidBy.label,
          expense.status.label,
          expense.calendarEventDate ?? '',
          expense.calendarEventTitle ?? '',
          expense.attachment?.evidence?.type?.label ?? '',
          formatCents(expense.amountCents),
          expense.originalReceiptAmountLabel ?? '',
        ],
    ];

    return rows
        .map((row) => row.map(MonthlyExpenseReport._csvCell).join(','))
        .join('\n');
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
          const ListTile(
            leading: Icon(Icons.currency_exchange_outlined),
            title: Text('Waluta raportu: PLN'),
            subtitle: Text(
              'Suma i saldo sa liczone w jednej walucie. Kwoty z paragonow w innych walutach sa tylko informacyjne.',
            ),
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
            leading: const Icon(Icons.rule_folder_outlined),
            title: const Text('Reguly rodzinne'),
            subtitle: Text(
              domain.kidCostSharedExpenseAgreement.reportDisclaimer,
            ),
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

class _AnnualReportSummaryCard extends StatelessWidget {
  const _AnnualReportSummaryCard({required this.report});

  final AnnualExpenseReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: const Text('Suma roczna'),
            subtitle: Text(
              'Wygenerowano ${report.generatedAt.toIso8601String()}',
            ),
            trailing: Text(report.year.toString()),
          ),
          const ListTile(
            leading: Icon(Icons.currency_exchange_outlined),
            title: Text('Waluta raportu: PLN'),
            subtitle: Text(
              'KidCost nie laczy walut w sumach i nie liczy kursow w MVP.',
            ),
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
            leading: const Icon(Icons.warning_amber_outlined),
            title: const Text('Sporne koszty'),
            trailing: Text(formatCents(report.disputedCents)),
          ),
          ListTile(
            leading: const Icon(Icons.pending_actions_outlined),
            title: const Text('Oczekujace koszty'),
            trailing: Text(formatCents(report.pendingCents)),
          ),
          ListTile(
            leading: const Icon(Icons.rule_folder_outlined),
            title: const Text('Nierozliczone koszty'),
            subtitle: const Text('Suma statusow innych niz rozliczone.'),
            trailing: Text(formatCents(report.unsettledCents)),
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

class _AnnualExpenseListCard extends StatelessWidget {
  const _AnnualExpenseListCard({required this.report});

  final AnnualExpenseReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Koszty w roku',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final expense in report.expenses)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(expense.title),
                subtitle: Text(
                  [
                    expense.expenseDate,
                    expense.status.label,
                    if (expense.originalReceiptAmountLabel != null)
                      'paragon: ${expense.originalReceiptAmountLabel}',
                  ].join(' • '),
                ),
                trailing: Text(formatCents(expense.amountCents)),
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
                  [
                    expense.expenseDate,
                    expense.status.label,
                    if (expense.originalReceiptAmountLabel != null)
                      'paragon: ${expense.originalReceiptAmountLabel}',
                  ].join(' • '),
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

class _EmptyAnnualReportCard extends StatelessWidget {
  const _EmptyAnnualReportCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.inbox_outlined),
        title: Text('Brak kosztow w tym roku'),
        subtitle: Text(
          'Raport roczny jest gotowy, ale nie ma jeszcze danych do pokazania.',
        ),
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.title,
    required this.fileName,
    required this.csv,
    required this.showPremiumHint,
    required this.onPremiumHintDismissed,
  });

  final String title;
  final String fileName;
  final String csv;
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
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _showCsvPreview(context),
              icon: const Icon(Icons.table_view_outlined),
              label: Text('CSV: $fileName'),
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
                SelectableText(fileName),
                const SizedBox(height: 12),
                SelectableText(csv),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfessionalAccessCard extends StatelessWidget {
  const _ProfessionalAccessCard({required this.periodLabel});

  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final policy = domain.kidCostProfessionalAccessPolicy;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Dostep mediatora lub prawnika'),
              subtitle: Text(
                'Tylko raport $periodLabel, read-only, wygasa po ${policy.defaultExpiryDays} dniach.',
              ),
            ),
            Text(policy.copy.body),
            const SizedBox(height: 8),
            Text(
              policy.copy.noLegalAdvice,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showProfessionalAccessPreview(context),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Podglad bezpiecznego linku'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfessionalAccessPreview(BuildContext context) {
    final policy = domain.kidCostProfessionalAccessPolicy;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.78,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  policy.copy.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Zakres: raport $periodLabel.'),
                Text('Wygasa po ${policy.defaultExpiryDays} dniach.'),
                const SizedBox(height: 16),
                _AccessPreviewSection(
                  title: 'Uprawnienia',
                  children: [
                    for (final permission in policy.permissions)
                      domain.professionalPermissionLabel(permission),
                  ],
                ),
                _AccessPreviewSection(
                  title: 'Domyslna minimalizacja danych',
                  children: [
                    for (final rule in policy.dataMinimizationRules)
                      domain.professionalDataRuleLabel(rule),
                  ],
                ),
                _AccessPreviewSection(
                  title: 'Audit widoczny dla rodzicow',
                  children: const [
                    'Utworzenie zaproszenia',
                    'Akceptacja zaproszenia',
                    'Kazdy podglad raportu',
                    'Kazde pobranie PDF',
                    'Cofniecie lub wygasniecie dostepu',
                  ],
                ),
                const SizedBox(height: 12),
                Text(policy.copy.noLegalAdvice),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AccessPreviewSection extends StatelessWidget {
  const _AccessPreviewSection({required this.title, required this.children});

  final String title;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          for (final child in children)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(child),
            ),
        ],
      ),
    );
  }
}
