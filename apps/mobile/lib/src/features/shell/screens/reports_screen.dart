import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kidcost_domain/domain.dart' as domain;

import '../../../telemetry/app_telemetry.dart';
import '../../custody/custody_models.dart';
import '../../expenses/expense_models.dart';
import '../../planned_purchases/planned_purchase_models.dart';
import '../../premium/premium_discovery.dart';
import '../../reports/mediation_report_pass.dart';

enum _ReportMode { monthly, annual }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    required this.expenses,
    this.plannedPurchases = const [],
    this.custodyDays = const [],
    this.currentDate,
    this.initialMediationReportPass,
    this.showReportExportPremiumHint = false,
    this.onOpenExpenseFilter,
    this.onPremiumHintDismissed,
    this.telemetry = const NoopTelemetry(),
    super.key,
  });

  final List<ExpenseEntry> expenses;
  final List<PlannedPurchase> plannedPurchases;
  final List<CustodyDay> custodyDays;
  final DateTime? currentDate;
  final MediationReportPass? initialMediationReportPass;
  final bool showReportExportPremiumHint;
  final ValueChanged<ExpenseListFilterRequest>? onOpenExpenseFilter;
  final ValueChanged<PremiumDiscoveryPoint>? onPremiumHintDismissed;
  final AppTelemetry telemetry;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportMode _reportMode = _ReportMode.monthly;
  String? _selectedMonth;
  int? _selectedYear;
  MediationReportPass? _mediationReportPass;
  PolishReportContext _polishReportContext = const PolishReportContext();
  bool _includeParentingTimeContext = true;

  void _updatePolishReportContext(PolishReportContext value) {
    setState(() => _polishReportContext = value);
    unawaited(
      widget.telemetry.track(
        TelemetryEvent.polishReportContextUpdated,
        parameters: value.analyticsProperties,
      ),
    );
  }

  void _updateParentingTimeContextEnabled(
    bool value,
    ParentingTimeReportContext context,
  ) {
    setState(() => _includeParentingTimeContext = value);
    unawaited(
      widget.telemetry.track(
        TelemetryEvent.parentingTimeReportToggled,
        parameters: {
          'parenting_time_context_enabled': value,
          'range_type': 'monthly',
          'custody_day_count': context.scheduledDayCount,
          'source': context.sourceCode,
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _mediationReportPass = widget.initialMediationReportPass;
  }

  @override
  Widget build(BuildContext context) {
    final months = _reportMonths();
    final month = _selectedMonth ?? months.first;
    final monthlyReport = MonthlyExpenseReport.fromExpenses(
      month: month,
      expenses: widget.expenses,
    );
    final monthlyPlans = widget.plannedPurchases
        .where((plan) => _monthFromDate(plan.targetDate) == month)
        .toList();
    final parentingTimeContext = ParentingTimeReportContext.fromCustodyDays(
      month: month,
      custodyDays: widget.custodyDays,
    );
    final previousMonthlyReport = MonthlyExpenseReport.fromExpenses(
      month: _previousMonthLabel(month),
      expenses: widget.expenses,
    );
    final years = _reportYears();
    final year = _selectedYear ?? years.first;
    final annualReport = AnnualExpenseReport.fromExpenses(
      year: year,
      expenses: widget.expenses,
      generatedAt: widget.currentDate ?? DateTime.now(),
    );
    final annualPlans = widget.plannedPurchases
        .where((plan) => _yearFromDate(plan.targetDate) == year)
        .toList();

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
            previousReport: previousMonthlyReport,
            plannedPurchases: monthlyPlans,
            parentingTimeContext: parentingTimeContext,
            includeParentingTimeContext: _includeParentingTimeContext,
            polishContext: _polishReportContext,
            now: widget.currentDate ?? DateTime.now(),
            mediationReportPass: _mediationReportPass,
            onMediationReportPassChanged: (pass) {
              setState(() => _mediationReportPass = pass);
            },
            showPremiumHint: widget.showReportExportPremiumHint,
            onMonthChanged: (value) => setState(() => _selectedMonth = value),
            onPolishContextChanged: (context) {
              _updatePolishReportContext(context);
            },
            onParentingTimeContextEnabledChanged: (value) {
              _updateParentingTimeContextEnabled(value, parentingTimeContext);
            },
            onOpenExpenseFilter: widget.onOpenExpenseFilter,
            onPremiumHintDismissed: () => widget.onPremiumHintDismissed?.call(
              PremiumDiscoveryPoint.reportExport,
            ),
          )
        else
          _AnnualReportView(
            years: years,
            year: year,
            report: annualReport,
            plannedPurchases: annualPlans,
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
      for (final plan in widget.plannedPurchases)
        _monthFromDate(plan.targetDate),
      for (final day in widget.custodyDays) _monthFromDate(day.date),
    }.toList()..sort((first, second) => second.compareTo(first));
    return months;
  }

  List<int> _reportYears() {
    final years = <int>{
      (widget.currentDate ?? DateTime.now()).year,
      for (final expense in widget.expenses)
        int.tryParse(expense.expenseDate.split('-').first) ??
            (widget.currentDate ?? DateTime.now()).year,
      for (final plan in widget.plannedPurchases)
        _yearFromDate(plan.targetDate) ??
            (widget.currentDate ?? DateTime.now()).year,
      for (final day in widget.custodyDays)
        _yearFromDate(day.date) ?? (widget.currentDate ?? DateTime.now()).year,
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

  int? _yearFromDate(String date) {
    return int.tryParse(date.split('-').first);
  }

  String _previousMonthLabel(String month) {
    final parsed = DateTime.tryParse('$month-01');
    if (parsed == null) {
      return month;
    }
    final previous = DateTime(parsed.year, parsed.month - 1);
    return _monthLabel(previous);
  }
}

class _MonthlyReportView extends StatelessWidget {
  const _MonthlyReportView({
    required this.months,
    required this.month,
    required this.report,
    required this.previousReport,
    required this.plannedPurchases,
    required this.parentingTimeContext,
    required this.includeParentingTimeContext,
    required this.polishContext,
    required this.now,
    required this.mediationReportPass,
    required this.onMediationReportPassChanged,
    required this.showPremiumHint,
    required this.onMonthChanged,
    required this.onPolishContextChanged,
    required this.onParentingTimeContextEnabledChanged,
    required this.onOpenExpenseFilter,
    required this.onPremiumHintDismissed,
  });

  final List<String> months;
  final String month;
  final MonthlyExpenseReport report;
  final MonthlyExpenseReport previousReport;
  final List<PlannedPurchase> plannedPurchases;
  final ParentingTimeReportContext parentingTimeContext;
  final bool includeParentingTimeContext;
  final PolishReportContext polishContext;
  final DateTime now;
  final MediationReportPass? mediationReportPass;
  final ValueChanged<MediationReportPass?> onMediationReportPassChanged;
  final bool showPremiumHint;
  final ValueChanged<String> onMonthChanged;
  final ValueChanged<PolishReportContext> onPolishContextChanged;
  final ValueChanged<bool> onParentingTimeContextEnabledChanged;
  final ValueChanged<ExpenseListFilterRequest>? onOpenExpenseFilter;
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
        _MonthlyInsightsCard(
          report: report,
          previousReport: previousReport,
          onOpenExpenseFilter: onOpenExpenseFilter,
        ),
        const SizedBox(height: 12),
        _ReportSummaryCard(report: report),
        const SizedBox(height: 12),
        _SettlementStatusCard(report: report),
        const SizedBox(height: 12),
        _ParentingTimeReportToggleCard(
          includeContext: includeParentingTimeContext,
          contextData: parentingTimeContext,
          onChanged: onParentingTimeContextEnabledChanged,
        ),
        if (includeParentingTimeContext) ...[
          const SizedBox(height: 12),
          _ParentingTimeReportCard(contextData: parentingTimeContext),
        ],
        const SizedBox(height: 12),
        _PolishReportContextCard(
          contextData: polishContext,
          onChanged: onPolishContextChanged,
        ),
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
        _PlannedPurchasesReportCard(
          title: 'Planowane zakupy w miesiacu',
          plannedPurchases: plannedPurchases,
        ),
        const SizedBox(height: 12),
        _ExportCard(
          title: 'Eksport',
          fileName: report.fileName,
          csv: report.toCsv(
            polishContext: polishContext,
            parentingTimeContext: includeParentingTimeContext
                ? parentingTimeContext
                : null,
          ),
          showPremiumHint: showPremiumHint,
          onPremiumHintDismissed: onPremiumHintDismissed,
        ),
        const SizedBox(height: 12),
        _MediationReportPassCard(
          report: report,
          now: now,
          pass: mediationReportPass,
          onPassChanged: onMediationReportPassChanged,
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
    required this.plannedPurchases,
    required this.showPremiumHint,
    required this.onYearChanged,
    required this.onPremiumHintDismissed,
  });

  final List<int> years;
  final int year;
  final AnnualExpenseReport report;
  final List<PlannedPurchase> plannedPurchases;
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
        _PlannedPurchasesReportCard(
          title: 'Planowane zakupy w roku',
          plannedPurchases: plannedPurchases,
        ),
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

class _PlannedPurchasesReportCard extends StatelessWidget {
  const _PlannedPurchasesReportCard({
    required this.title,
    required this.plannedPurchases,
  });

  final String title;
  final List<PlannedPurchase> plannedPurchases;

  @override
  Widget build(BuildContext context) {
    final estimatedCents = plannedPurchases.fold<int>(
      0,
      (sum, plan) => sum + plan.estimatedAmountCents,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.playlist_add_check_outlined),
              title: Text(title),
              subtitle: Text(
                plannedPurchases.isEmpty
                    ? 'Brak planow w tym okresie. Saldo pokazuje tylko poniesione koszty.'
                    : '${plannedPurchases.length} planow, ${formatCents(estimatedCents)} poza saldem.',
              ),
            ),
            for (final plan in plannedPurchases)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.shopping_bag_outlined),
                title: Text(plan.title),
                subtitle: Text(
                  '${plan.status.label} - ${plan.category.label} - zakup ${plan.targetDate}',
                ),
                trailing: Text(formatCents(plan.estimatedAmountCents)),
              ),
          ],
        ),
      ),
    );
  }
}

class ParentingTimeReportContext {
  const ParentingTimeReportContext({
    required this.month,
    required this.startDate,
    required this.endDate,
    required this.summaries,
    required this.scheduledDayCount,
  });

  factory ParentingTimeReportContext.fromCustodyDays({
    required String month,
    required List<CustodyDay> custodyDays,
  }) {
    final monthDays =
        custodyDays.where((day) => day.date.startsWith(month)).toList()
          ..sort((first, second) => first.date.compareTo(second.date));
    final totals = <String, int>{};
    for (final day in monthDays) {
      totals.update(day.parent.label, (value) => value + 1, ifAbsent: () => 1);
    }
    final scheduledDayCount = monthDays.length;
    final summaries =
        totals.entries.map((entry) {
          final percent = scheduledDayCount == 0
              ? 0
              : ((entry.value / scheduledDayCount) * 100).round();
          return ParentingTimeParentSummary(
            parentLabel: entry.key,
            scheduledDays: entry.value,
            scheduledPercent: percent,
          );
        }).toList()..sort((first, second) {
          final byDays = second.scheduledDays.compareTo(first.scheduledDays);
          if (byDays != 0) return byDays;
          return first.parentLabel.compareTo(second.parentLabel);
        });

    return ParentingTimeReportContext(
      month: month,
      startDate: '$month-01',
      endDate: _endDateForMonth(month),
      summaries: List.unmodifiable(summaries),
      scheduledDayCount: scheduledDayCount,
    );
  }

  final String month;
  final String startDate;
  final String endDate;
  final List<ParentingTimeParentSummary> summaries;
  final int scheduledDayCount;

  String get sourceLabel => 'Kalendarz opieki KidCost';
  String get sourceCode => 'kidcost_custody_calendar';
  String get rangeLabel => '$startDate - $endDate';
  bool get hasScheduledDays => scheduledDayCount > 0;
}

class ParentingTimeParentSummary {
  const ParentingTimeParentSummary({
    required this.parentLabel,
    required this.scheduledDays,
    required this.scheduledPercent,
  });

  final String parentLabel;
  final int scheduledDays;
  final int scheduledPercent;
}

const parentingTimeReportDisclaimer =
    'Kontekst czasu opieki jest informacyjny. Nie wylicza alimentow, 800+, ulg podatkowych ani uprawnien prawnych i nie jest dokumentem sadowym.';

String _endDateForMonth(String month) {
  final parsed = DateTime.tryParse('$month-01');
  if (parsed == null) {
    return month;
  }
  final lastDay = DateTime.utc(parsed.year, parsed.month + 1, 0);
  return [
    lastDay.year.toString().padLeft(4, '0'),
    lastDay.month.toString().padLeft(2, '0'),
    lastDay.day.toString().padLeft(2, '0'),
  ].join('-');
}

class _ParentingTimeReportToggleCard extends StatelessWidget {
  const _ParentingTimeReportToggleCard({
    required this.includeContext,
    required this.contextData,
    required this.onChanged,
  });

  final bool includeContext;
  final ParentingTimeReportContext contextData;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        key: const Key('parenting-time-context-toggle'),
        value: includeContext,
        onChanged: onChanged,
        secondary: const Icon(Icons.family_restroom_outlined),
        title: const Text('Dolacz kontekst czasu opieki'),
        subtitle: Text(
          contextData.hasScheduledDays
              ? '${contextData.scheduledDayCount} dni z ${contextData.sourceLabel}; bez zmiany salda.'
              : 'Brak dni opieki w tym miesiacu; saldo pozostaje finansowe.',
        ),
      ),
    );
  }
}

class _ParentingTimeReportCard extends StatelessWidget {
  const _ParentingTimeReportCard({required this.contextData});

  final ParentingTimeReportContext contextData;

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
              leading: const Icon(Icons.calendar_view_month_outlined),
              title: const Text('Kontekst czasu opieki'),
              subtitle: Text(
                'Zakres ${contextData.rangeLabel}; zrodlo: ${contextData.sourceLabel}.',
              ),
            ),
            if (contextData.summaries.isEmpty)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Brak zaplanowanych dni opieki'),
                subtitle: Text(
                  'Dodaj dni w kalendarzu opieki, aby raport pokazal neutralny snapshot.',
                ),
              )
            else
              for (final summary in contextData.summaries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(summary.parentLabel),
                  subtitle: LinearProgressIndicator(
                    value: summary.scheduledPercent / 100,
                  ),
                  trailing: Text(
                    '${summary.scheduledDays} dni (${summary.scheduledPercent}%)',
                  ),
                ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline),
              title: Text('Wyjatki i swieta'),
              subtitle: Text(
                'Brak osobnych wyjatkow w modelu MVP; pokazujemy zaplanowane dni z kalendarza.',
              ),
            ),
            const Text(parentingTimeReportDisclaimer),
          ],
        ),
      ),
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

class PolishReportContext {
  const PolishReportContext({
    this.eightHundredPlus = 'unknown',
    this.dobryStart = 'unknown',
    this.childTaxReliefNote = false,
    this.alternatingCustodyNote = false,
    this.freeTextAssumption = '',
  });

  final String eightHundredPlus;
  final String dobryStart;
  final bool childTaxReliefNote;
  final bool alternatingCustodyNote;
  final String freeTextAssumption;

  bool get hasAnyContext =>
      eightHundredPlus != 'unknown' ||
      dobryStart != 'unknown' ||
      childTaxReliefNote ||
      alternatingCustodyNote ||
      freeTextAssumption.trim().isNotEmpty;

  Map<String, Object> get analyticsProperties => {
    'benefit_800_context': eightHundredPlus,
    'dobry_start_context': dobryStart,
    'has_child_tax_relief_note': childTaxReliefNote,
    'has_alternating_custody_note': alternatingCustodyNote,
    'has_free_text_assumption': freeTextAssumption.trim().isNotEmpty,
  };

  PolishReportContext copyWith({
    String? eightHundredPlus,
    String? dobryStart,
    bool? childTaxReliefNote,
    bool? alternatingCustodyNote,
    String? freeTextAssumption,
  }) {
    return PolishReportContext(
      eightHundredPlus: eightHundredPlus ?? this.eightHundredPlus,
      dobryStart: dobryStart ?? this.dobryStart,
      childTaxReliefNote: childTaxReliefNote ?? this.childTaxReliefNote,
      alternatingCustodyNote:
          alternatingCustodyNote ?? this.alternatingCustodyNote,
      freeTextAssumption: freeTextAssumption ?? this.freeTextAssumption,
    );
  }
}

const polishReportDisclaimer =
    'KidCost porzadkuje dane finansowe i zalozenia wpisane przez rodzica. Nie udziela porad prawnych ani podatkowych.';

const _benefit800Options = {
  'unknown': '800+: nie zaznaczono',
  'parent_a': '800+: rodzic A',
  'parent_b': '800+: rodzic B',
  'split': '800+: podzial / opieka naprzemienna',
};

const _dobryStartOptions = {
  'unknown': 'Dobry Start: nie zaznaczono',
  'yes': 'Dobry Start: odnotowano',
  'no': 'Dobry Start: nie dotyczy',
};

class _PolishReportContextCard extends StatelessWidget {
  const _PolishReportContextCard({
    required this.contextData,
    required this.onChanged,
  });

  final PolishReportContext contextData;
  final ValueChanged<PolishReportContext> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        key: const Key('polish-report-context-card'),
        leading: const Icon(Icons.info_outline),
        title: const Text('Zalozenia i swiadczenia PL'),
        subtitle: Text(
          contextData.hasAnyContext
              ? 'Kontekst uzytkownika, bez zmiany salda.'
              : 'Opcjonalny kontekst 800+, Dobry Start, PIT i opieki.',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ta sekcja opisuje zalozenia wpisane przez uzytkownika. Nie zmienia kosztow, salda ani zwrotow.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('polish-800-context-picker'),
                initialValue: contextData.eightHundredPlus,
                decoration: const InputDecoration(
                  labelText: '800+',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                ),
                items: [
                  for (final entry in _benefit800Options.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onChanged(contextData.copyWith(eightHundredPlus: value));
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('polish-dobry-start-picker'),
                initialValue: contextData.dobryStart,
                decoration: const InputDecoration(
                  labelText: 'Dobry Start',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: [
                  for (final entry in _dobryStartOptions.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onChanged(contextData.copyWith(dobryStart: value));
                  }
                },
              ),
              SwitchListTile(
                key: const Key('polish-child-tax-relief-switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Ulga na dziecko odnotowana'),
                subtitle: const Text(
                  'Kontekst uzytkownika, nie wyliczenie PIT.',
                ),
                value: contextData.childTaxReliefNote,
                onChanged: (value) {
                  onChanged(contextData.copyWith(childTaxReliefNote: value));
                },
              ),
              SwitchListTile(
                key: const Key('polish-alternating-custody-switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Opieka naprzemienna odnotowana'),
                subtitle: const Text(
                  'Bez interpretacji prawnej lub podatkowej.',
                ),
                value: contextData.alternatingCustodyNote,
                onChanged: (value) {
                  onChanged(
                    contextData.copyWith(alternatingCustodyNote: value),
                  );
                },
              ),
              TextFormField(
                key: const Key('polish-free-text-assumption-field'),
                initialValue: contextData.freeTextAssumption,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Wlasne zalozenie',
                  helperText: 'Nie trafia do payloadu analytics.',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                onChanged: (value) {
                  onChanged(contextData.copyWith(freeTextAssumption: value));
                },
              ),
              const SizedBox(height: 8),
              const Text(polishReportDisclaimer),
              const SizedBox(height: 4),
              Text(
                'English fallback: user-entered Polish benefit and tax context; not legal or tax advice.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
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
    required this.byStatus,
    required this.disputedCents,
    required this.pendingCents,
    required this.settledCents,
    required this.currentUserPaidCents,
    required this.coParentPaidCents,
    required this.providerPaymentDueCents,
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
    final byStatus = <String, int>{};
    var totalCents = 0;
    var disputedCents = 0;
    var pendingCents = 0;
    var settledCents = 0;
    var currentUserPaidCents = 0;
    var providerPaymentDueCents = 0;

    for (final expense in monthExpenses) {
      final balanceAmountCents = expense.settlementBalanceAmountCents;
      providerPaymentDueCents += expense.providerPaymentDueCents;
      totalCents += balanceAmountCents;
      if (expense.paidBy.isCurrentUser) {
        currentUserPaidCents += balanceAmountCents;
      }
      if (balanceAmountCents > 0) {
        byPayer.update(
          expense.paidBy.label,
          (value) => value + balanceAmountCents,
          ifAbsent: () => balanceAmountCents,
        );
        byChild.update(
          expense.childName,
          (value) => value + balanceAmountCents,
          ifAbsent: () => balanceAmountCents,
        );
        byCategory.update(
          expense.category.label,
          (value) => value + balanceAmountCents,
          ifAbsent: () => balanceAmountCents,
        );
        byStatus.update(
          expense.status.label,
          (value) => value + balanceAmountCents,
          ifAbsent: () => balanceAmountCents,
        );
      }

      if (expense.status == ExpenseStatus.disputed) {
        disputedCents += balanceAmountCents;
      }
      if (expense.status == ExpenseStatus.pending) {
        pendingCents += balanceAmountCents;
      }
      if (expense.status == ExpenseStatus.settled) {
        settledCents += balanceAmountCents;
      }
    }

    return MonthlyExpenseReport(
      month: month,
      expenses: monthExpenses,
      totalCents: totalCents,
      byPayer: _sortedTotals(byPayer),
      byChild: _sortedTotals(byChild),
      byCategory: _sortedTotals(byCategory),
      byStatus: _sortedTotals(byStatus),
      disputedCents: disputedCents,
      pendingCents: pendingCents,
      settledCents: settledCents,
      currentUserPaidCents: currentUserPaidCents,
      coParentPaidCents: totalCents - currentUserPaidCents,
      providerPaymentDueCents: providerPaymentDueCents,
    );
  }

  final String month;
  final List<ExpenseEntry> expenses;
  final int totalCents;
  final Map<String, int> byPayer;
  final Map<String, int> byChild;
  final Map<String, int> byCategory;
  final Map<String, int> byStatus;
  final int disputedCents;
  final int pendingCents;
  final int settledCents;
  final int currentUserPaidCents;
  final int coParentPaidCents;
  final int providerPaymentDueCents;

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

  String toCsv({
    PolishReportContext? polishContext,
    ParentingTimeReportContext? parentingTimeContext,
  }) {
    final rows = [
      [
        'data',
        'tytul',
        'dziecko',
        'kategoria',
        'placacy',
        'status',
        'dispute_reason',
        'dispute_request',
        'request_type',
        'provider_name',
        'provider_reference',
        'provider_due_date',
        'provider_amount_due',
        'provider_status',
        'submitted_at',
        'notice_due_at',
        'payment_due_at',
        'paid_at',
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
          expense.disputeDetails?.reason.label ?? '',
          expense.disputeDetails?.correctionRequest ?? '',
          expense.reimbursementRequestKind.id,
          expense.providerPayment?.providerName ?? '',
          expense.providerPayment?.paymentReference ?? '',
          expense.providerPayment?.dueDate ?? '',
          expense.providerPayment?.amountDueLabel ?? '',
          expense.providerPayment?.status.label ?? '',
          _csvDate(expense.reimbursementDeadlines?.submittedAt),
          _csvDate(expense.reimbursementDeadlines?.noticeDueAt),
          _csvDate(expense.reimbursementDeadlines?.paymentDueAt),
          _csvDate(expense.reimbursementDeadlines?.paidAt),
          expense.calendarEventDate ?? '',
          expense.calendarEventTitle ?? '',
          expense.attachment?.evidence?.type?.label ?? '',
          formatCents(expense.amountCents),
          expense.originalReceiptAmountLabel ?? '',
        ],
      if (polishContext != null) ...[
        const <String>[],
        ['sekcja', 'zalozenia_i_swiadczenia_pl'],
        ['disclaimer', polishReportDisclaimer],
        ['800_plus', _benefit800Options[polishContext.eightHundredPlus] ?? ''],
        ['dobry_start', _dobryStartOptions[polishContext.dobryStart] ?? ''],
        [
          'ulga_na_dziecko',
          polishContext.childTaxReliefNote ? 'odnotowana' : 'nie_zaznaczono',
        ],
        [
          'opieka_naprzemienna',
          polishContext.alternatingCustodyNote
              ? 'odnotowana'
              : 'nie_zaznaczono',
        ],
        ['wlasne_zalozenie', polishContext.freeTextAssumption.trim()],
      ],
      if (parentingTimeContext != null) ...[
        const <String>[],
        ['sekcja', 'czas_opieki'],
        ['zakres', parentingTimeContext.rangeLabel],
        ['zrodlo', parentingTimeContext.sourceLabel],
        ['disclaimer', parentingTimeReportDisclaimer],
        const ['rodzic', 'zaplanowane_dni', 'zaplanowany_procent'],
        for (final summary in parentingTimeContext.summaries)
          [
            summary.parentLabel,
            summary.scheduledDays.toString(),
            '${summary.scheduledPercent}%',
          ],
        if (parentingTimeContext.summaries.isEmpty)
          const ['brak_danych', '0', '0%'],
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

  static String _csvDate(DateTime? date) {
    if (date == null) {
      return '';
    }
    final utc = date.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}';
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
    required this.providerPaymentDueCents,
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
    var providerPaymentDueCents = 0;

    for (final expense in yearExpenses) {
      final balanceAmountCents = expense.settlementBalanceAmountCents;
      providerPaymentDueCents += expense.providerPaymentDueCents;
      totalCents += balanceAmountCents;
      if (expense.paidBy.isCurrentUser) {
        currentUserPaidCents += balanceAmountCents;
      }
      if (balanceAmountCents > 0) {
        byPayer.update(
          expense.paidBy.label,
          (value) => value + balanceAmountCents,
          ifAbsent: () => balanceAmountCents,
        );
        byChild.update(
          expense.childName,
          (value) => value + balanceAmountCents,
          ifAbsent: () => balanceAmountCents,
        );
        byCategory.update(
          expense.category.label,
          (value) => value + balanceAmountCents,
          ifAbsent: () => balanceAmountCents,
        );
        byStatus.update(
          expense.status.label,
          (value) => value + balanceAmountCents,
          ifAbsent: () => balanceAmountCents,
        );
      }

      if (expense.status == ExpenseStatus.disputed) {
        disputedCents += balanceAmountCents;
      }
      if (expense.status == ExpenseStatus.pending) {
        pendingCents += balanceAmountCents;
      }
      if (expense.status == ExpenseStatus.settled) {
        settledCents += balanceAmountCents;
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
      providerPaymentDueCents: providerPaymentDueCents,
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
  final int providerPaymentDueCents;

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
        'dispute_reason',
        'dispute_request',
        'request_type',
        'provider_name',
        'provider_reference',
        'provider_due_date',
        'provider_amount_due',
        'provider_status',
        'submitted_at',
        'notice_due_at',
        'payment_due_at',
        'paid_at',
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
          expense.disputeDetails?.reason.label ?? '',
          expense.disputeDetails?.correctionRequest ?? '',
          expense.reimbursementRequestKind.id,
          expense.providerPayment?.providerName ?? '',
          expense.providerPayment?.paymentReference ?? '',
          expense.providerPayment?.dueDate ?? '',
          expense.providerPayment?.amountDueLabel ?? '',
          expense.providerPayment?.status.label ?? '',
          MonthlyExpenseReport._csvDate(
            expense.reimbursementDeadlines?.submittedAt,
          ),
          MonthlyExpenseReport._csvDate(
            expense.reimbursementDeadlines?.noticeDueAt,
          ),
          MonthlyExpenseReport._csvDate(
            expense.reimbursementDeadlines?.paymentDueAt,
          ),
          MonthlyExpenseReport._csvDate(expense.reimbursementDeadlines?.paidAt),
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

class _MonthlyInsightsCard extends StatelessWidget {
  const _MonthlyInsightsCard({
    required this.report,
    required this.previousReport,
    required this.onOpenExpenseFilter,
  });

  final MonthlyExpenseReport report;
  final MonthlyExpenseReport previousReport;
  final ValueChanged<ExpenseListFilterRequest>? onOpenExpenseFilter;

  @override
  Widget build(BuildContext context) {
    final hasExpenses = report.expenses.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Miesieczne insighty'),
              subtitle: Text(_trendText),
              trailing: Text(formatCents(report.totalCents)),
            ),
            if (!hasExpenses)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Brak wzorca kosztow'),
                subtitle: Text(
                  'Dodaj pierwszy koszt w tym miesiacu, a zobaczysz podzialy po dziecku, kategorii i statusie.',
                ),
              )
            else ...[
              _InsightBreakdownSection(
                title: 'Najwieksze kategorie',
                values: report.byCategory,
                totalCents: report.totalCents,
                requestFor: (label) => ExpenseListFilterRequest(
                  month: report.month,
                  categoryId: _categoryIdForLabel(label),
                ),
                onOpenExpenseFilter: onOpenExpenseFilter,
              ),
              _InsightBreakdownSection(
                title: 'Dzieci',
                values: report.byChild,
                totalCents: report.totalCents,
                requestFor: (label) => ExpenseListFilterRequest(
                  month: report.month,
                  childName: label,
                ),
                onOpenExpenseFilter: onOpenExpenseFilter,
              ),
              _InsightBreakdownSection(
                title: 'Placacy',
                values: report.byPayer,
                totalCents: report.totalCents,
                requestFor: (label) => ExpenseListFilterRequest(
                  month: report.month,
                  payerLabel: label,
                ),
                onOpenExpenseFilter: onOpenExpenseFilter,
              ),
              _InsightBreakdownSection(
                title: 'Statusy',
                values: report.byStatus,
                totalCents: report.totalCents,
                requestFor: (label) => ExpenseListFilterRequest(
                  month: report.month,
                  status: _statusForLabel(label),
                ),
                onOpenExpenseFilter: onOpenExpenseFilter,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _trendText {
    if (previousReport.totalCents == 0 && report.totalCents == 0) {
      return 'Brak kosztow w tym i poprzednim miesiacu.';
    }
    if (previousReport.totalCents == 0) {
      return 'Pierwszy miesiac z kosztami do porownania.';
    }
    final difference = report.totalCents - previousReport.totalCents;
    if (difference == 0) {
      return 'Tyle samo co w poprzednim miesiacu.';
    }
    final direction = difference > 0 ? 'wiecej' : 'mniej';
    return '${formatCents(difference.abs())} $direction niz w poprzednim miesiacu.';
  }

  String? _categoryIdForLabel(String label) {
    for (final category in expenseCategories) {
      if (category.label == label) {
        return category.id;
      }
    }
    return null;
  }

  ExpenseStatus? _statusForLabel(String label) {
    for (final status in ExpenseStatus.values) {
      if (status.label == label) {
        return status;
      }
    }
    return null;
  }
}

class _InsightBreakdownSection extends StatelessWidget {
  const _InsightBreakdownSection({
    required this.title,
    required this.values,
    required this.totalCents,
    required this.requestFor,
    required this.onOpenExpenseFilter,
  });

  final String title;
  final Map<String, int> values;
  final int totalCents;
  final ExpenseListFilterRequest Function(String label) requestFor;
  final ValueChanged<ExpenseListFilterRequest>? onOpenExpenseFilter;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList()
      ..sort((first, second) {
        final byAmount = second.value.compareTo(first.value);
        if (byAmount != 0) {
          return byAmount;
        }
        return first.key.compareTo(second.key);
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        for (final entry in entries)
          _InsightBreakdownRow(
            label: entry.key,
            amountCents: entry.value,
            totalCents: totalCents,
            onTap: onOpenExpenseFilter == null
                ? null
                : () => onOpenExpenseFilter!(requestFor(entry.key)),
          ),
      ],
    );
  }
}

class _InsightBreakdownRow extends StatelessWidget {
  const _InsightBreakdownRow({
    required this.label,
    required this.amountCents,
    required this.totalCents,
    required this.onTap,
  });

  final String label;
  final int amountCents;
  final int totalCents;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final share = totalCents == 0 ? 0.0 : amountCents / totalCents;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: LinearProgressIndicator(value: share.clamp(0.0, 1.0)),
      trailing: Text(formatCents(amountCents)),
      onTap: onTap,
    );
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
                    if (expense.disputeDetails != null)
                      'spor: ${expense.disputeDetails!.reason.label}',
                    if (expense.disputeDetails?.correctionRequest != null)
                      'prosba: ${expense.disputeDetails!.correctionRequest}',
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
                    if (expense.disputeDetails != null)
                      'spor: ${expense.disputeDetails!.reason.label}',
                    if (expense.disputeDetails?.correctionRequest != null)
                      'prosba: ${expense.disputeDetails!.correctionRequest}',
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

class _MediationReportPassCard extends StatelessWidget {
  const _MediationReportPassCard({
    required this.report,
    required this.now,
    required this.pass,
    required this.onPassChanged,
  });

  final MonthlyExpenseReport report;
  final DateTime now;
  final MediationReportPass? pass;
  final ValueChanged<MediationReportPass?> onPassChanged;

  @override
  Widget build(BuildContext context) {
    final activePass = pass;
    final state = activePass?.stateAt(now) ?? MediationReportPassState.locked;
    final packet = MediationReportPacket(
      rangeLabel: report.month,
      expenses: report.expenses,
      generatedAt: now,
      isRedactedPreview: state != MediationReportPassState.active,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.balance_outlined),
              title: const Text('Jednorazowy pakiet mediacyjny'),
              subtitle: Text(
                '$mediationReportPassPriceHypothesis. Wazny $mediationReportPassExpiryDays dni, '
                '$mediationReportPassRegenerationLimit regeneracje, pobrania przez $mediationReportPassDownloadWindowDays dni.',
              ),
            ),
            Text(mediationReportPassFreeAccessCopy),
            const SizedBox(height: 6),
            Text(
              mediationReportPassLegalCopy,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _MediationPacketPreview(packet: packet),
            const SizedBox(height: 12),
            _MediationPassStateBanner(pass: activePass, state: state),
            const SizedBox(height: 12),
            _MediationPassActions(
              state: state,
              pass: activePass,
              onPurchase: () {
                onPassChanged(MediationReportPass.purchase(now));
              },
              onGenerate: activePass == null
                  ? null
                  : () {
                      onPassChanged(activePass.useRegeneration());
                      _showGeneratedPacket(context, packet.copyUnlocked());
                    },
              onRefund: activePass == null
                  ? null
                  : () {
                      onPassChanged(
                        MediationReportPass(
                          purchasedAt: activePass.purchasedAt,
                          expiresAt: activePass.expiresAt,
                          downloadsAvailableUntil:
                              activePass.downloadsAvailableUntil,
                          regenerationsRemaining:
                              activePass.regenerationsRemaining,
                          refunded: true,
                        ),
                      );
                    },
            ),
            const SizedBox(height: 12),
            const _MediationPassEdgeCases(),
            const SizedBox(height: 12),
            const _MediationPassAnalytics(),
          ],
        ),
      ),
    );
  }

  void _showGeneratedPacket(
    BuildContext context,
    MediationReportPacket packet,
  ) {
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
                  'Pakiet mediacyjny wygenerowany',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(packet.fileName),
                const SizedBox(height: 8),
                Text(packet.csvFileName),
                const SizedBox(height: 12),
                const Text(mediationReportPassLegalCopy),
                const SizedBox(height: 12),
                for (final expense in packet.expenses)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(expense.title),
                    subtitle: Text(
                      '${expense.expenseDate} - ${expense.status.label}',
                    ),
                    trailing: Text(formatCents(expense.amountCents)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension on MediationReportPacket {
  MediationReportPacket copyUnlocked() {
    return MediationReportPacket(
      rangeLabel: rangeLabel,
      expenses: expenses,
      generatedAt: generatedAt,
      isRedactedPreview: false,
    );
  }
}

class _MediationPacketPreview extends StatelessWidget {
  const _MediationPacketPreview({required this.packet});

  final MediationReportPacket packet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              packet.isRedactedPreview
                  ? Icons.visibility_off_outlined
                  : Icons.description_outlined,
            ),
            title: Text(packet.previewTitle),
            subtitle: Text(
              packet.isRedactedPreview
                  ? 'Podglad ukrywa szczegoly rekordow przed zakupem passu.'
                  : 'Zakres ${packet.rangeLabel} jest odblokowany dla tego passu.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Koszty w pakiecie'),
            trailing: Text(packet.expenses.length.toString()),
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Suma'),
            trailing: Text(
              packet.isRedactedPreview
                  ? 'Ukryta w preview'
                  : formatCents(packet.totalCents),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_outlined),
            title: const Text('Otwarte lub sporne pozycje'),
            trailing: Text(
              (packet.pendingCount + packet.disputedCount).toString(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.attachment_outlined),
            title: const Text('Indeks dowodow'),
            trailing: Text(packet.receiptCount.toString()),
          ),
        ],
      ),
    );
  }
}

class _MediationPassStateBanner extends StatelessWidget {
  const _MediationPassStateBanner({required this.pass, required this.state});

  final MediationReportPass? pass;
  final MediationReportPassState state;

  @override
  Widget build(BuildContext context) {
    final text = switch (state) {
      MediationReportPassState.locked =>
        'Preview jest darmowy. Zakup passu odblokuje jeden pakiet dla tego zakresu.',
      MediationReportPassState.active =>
        'Pass aktywny do ${pass!.expiresAt.toIso8601String().substring(0, 10)}. Pozostale regeneracje: ${pass!.regenerationsRemaining}.',
      MediationReportPassState.exhausted =>
        'Limit regeneracji zostal wykorzystany. Pobrania poprzednich plikow sa dostepne do ${pass!.downloadsAvailableUntil.toIso8601String().substring(0, 10)}.',
      MediationReportPassState.expired =>
        'Pass wygasl albo zostal zwrocony. Dane i podstawowy CSV nadal sa dostepne.',
    };
    return Semantics(
      container: true,
      liveRegion: true,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          state == MediationReportPassState.active
              ? Icons.lock_open_outlined
              : Icons.lock_outline,
        ),
        title: Text(_stateLabel(state)),
        subtitle: Text(text),
      ),
    );
  }

  String _stateLabel(MediationReportPassState state) {
    return switch (state) {
      MediationReportPassState.locked => 'Pass nieaktywny',
      MediationReportPassState.active => 'Pass aktywny',
      MediationReportPassState.exhausted => 'Limit regeneracji',
      MediationReportPassState.expired => 'Pass wygasl',
    };
  }
}

class _MediationPassActions extends StatelessWidget {
  const _MediationPassActions({
    required this.state,
    required this.pass,
    required this.onPurchase,
    required this.onGenerate,
    required this.onRefund,
  });

  final MediationReportPassState state;
  final MediationReportPass? pass;
  final VoidCallback onPurchase;
  final VoidCallback? onGenerate;
  final VoidCallback? onRefund;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: state == MediationReportPassState.locked
              ? onPurchase
              : null,
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text('Kup pass demo'),
        ),
        OutlinedButton.icon(
          onPressed: state == MediationReportPassState.active
              ? onGenerate
              : null,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Wygeneruj pakiet'),
        ),
        TextButton.icon(
          onPressed: pass == null || state == MediationReportPassState.expired
              ? null
              : onRefund,
          icon: const Icon(Icons.undo_outlined),
          label: const Text('Oznacz refund'),
        ),
      ],
    );
  }
}

class _MediationPassEdgeCases extends StatelessWidget {
  const _MediationPassEdgeCases();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.rule_outlined),
            title: Text('Zasady entitlement'),
            subtitle: Text(
              'Premium uzytkownik widzi pakiet bez dodatkowego paywalla; free uzytkownik nie traci dostepu do rekordow ani CSV.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.report_problem_outlined),
            title: Text('Edge cases'),
            subtitle: Text(
              'Failed purchase nie tworzy passu. Refund wygasza pass. Usuniete dowody sa oznaczone jako brakujace, a nie ukrywane.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MediationPassAnalytics extends StatelessWidget {
  const _MediationPassAnalytics();

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.analytics_outlined),
      title: const Text('Analityka bez danych wrazliwych'),
      subtitle: const Text(
        'Eventy nie zawieraja nazw dzieci, tresci paragonow ani kwot.',
      ),
      children: [
        ListTile(
          title: const Text('Eventy'),
          subtitle: Text(mediationReportPassTelemetryEvents.join(', ')),
        ),
        ListTile(
          title: const Text('Wymagane properties'),
          subtitle: Text(mediationReportPassTelemetryProperties.join(', ')),
        ),
      ],
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
