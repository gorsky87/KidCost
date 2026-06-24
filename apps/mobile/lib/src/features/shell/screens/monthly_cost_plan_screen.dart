import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../cost_plan/monthly_cost_plan.dart';
import '../../expenses/expense_models.dart';

class MonthlyCostPlanScreen extends StatefulWidget {
  const MonthlyCostPlanScreen({
    required this.childName,
    required this.expenses,
    this.currentDate,
    super.key,
  });

  final String childName;
  final List<ExpenseEntry> expenses;
  final DateTime? currentDate;

  @override
  State<MonthlyCostPlanScreen> createState() => _MonthlyCostPlanScreenState();
}

class _MonthlyCostPlanScreenState extends State<MonthlyCostPlanScreen> {
  late final Map<String, TextEditingController> _controllers;
  String? _selectedMonth;
  Map<String, int> _plannedCentsByCategoryId = const {};
  String? _inputError;
  bool _hasSavedPlan = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final category in monthlyCostPlanCategories)
        category.id: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = _availableMonths();
    final month = _selectedMonth ?? months.first;
    final summary = MonthlyCostPlanSummary.fromExpenses(
      childName: widget.childName,
      month: month,
      plannedCentsByCategoryId: _plannedCentsByCategoryId,
      expenses: widget.expenses,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Miesieczny kosztorys dziecka',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Porownaj plan miesiecznych kosztow z faktycznie dodanymi wydatkami KidCost.',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('cost-plan-month-picker'),
          initialValue: month,
          decoration: const InputDecoration(
            labelText: 'Miesiac kosztorysu',
            prefixIcon: Icon(Icons.calendar_month_outlined),
          ),
          items: [
            for (final item in months)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedMonth = value);
          },
        ),
        const SizedBox(height: 12),
        _PlanEditorCard(
          controllers: _controllers,
          inputError: _inputError,
          onSave: _savePlan,
        ),
        const SizedBox(height: 12),
        _PlanTotalsCard(summary: summary, hasSavedPlan: _hasSavedPlan),
        const SizedBox(height: 12),
        _PlanBreakdownCard(summary: summary),
        const SizedBox(height: 12),
        _PlanExportCard(summary: summary),
        const SizedBox(height: 12),
        const _CostPlanDisclaimerCard(),
      ],
    );
  }

  List<String> _availableMonths() {
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

  void _savePlan() {
    try {
      final planned = {
        for (final category in monthlyCostPlanCategories)
          category.id: parseOptionalPlanAmountToCents(
            _controllers[category.id]!.text,
          ),
      };
      setState(() {
        _plannedCentsByCategoryId = planned;
        _hasSavedPlan = true;
        _inputError = null;
      });
    } on FormatException {
      setState(() {
        _inputError = 'Kwoty wpisz jako 1200 albo 1200,50.';
      });
    }
  }
}

class _PlanEditorCard extends StatelessWidget {
  const _PlanEditorCard({
    required this.controllers,
    required this.inputError,
    required this.onSave,
  });

  final Map<String, TextEditingController> controllers;
  final String? inputError;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_note_outlined),
              title: Text('Plan miesieczny per kategoria'),
              subtitle: Text('Puste pola licza sie jako 0 PLN.'),
            ),
            for (final category in monthlyCostPlanCategories) ...[
              TextField(
                key: Key('monthly-plan-field-${category.id}'),
                controller: controllers[category.id],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: category.label,
                  suffixText: 'PLN',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (inputError != null) ...[
              Text(
                inputError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Zapisz plan kosztow'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTotalsCard extends StatelessWidget {
  const _PlanTotalsCard({required this.summary, required this.hasSavedPlan});

  final MonthlyCostPlanSummary summary;
  final bool hasSavedPlan;

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
              leading: const Icon(Icons.summarize_outlined),
              title: Text('Podsumowanie ${summary.month}'),
              subtitle: Text(
                hasSavedPlan
                    ? 'Plan zapisany dla: ${summary.childName}'
                    : 'Wpisz plan, aby zobaczyc roznice wobec kosztow.',
              ),
            ),
            _TotalRow(
              label: 'Plan',
              value: formatCents(summary.plannedTotalCents),
            ),
            _TotalRow(
              label: 'Faktycznie',
              value: formatCents(summary.actualTotalCents),
            ),
            _TotalRow(
              label: 'Roznica',
              value: formatSignedCents(summary.differenceTotalCents),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanBreakdownCard extends StatelessWidget {
  const _PlanBreakdownCard({required this.summary});

  final MonthlyCostPlanSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.table_chart_outlined),
              title: Text('Plan kontra faktyczne koszty'),
              subtitle: Text('Roznica dodatnia oznacza koszty ponad plan.'),
            ),
            for (final line in summary.lines)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(line.category.label),
                subtitle: Text(
                  'Plan ${formatCents(line.plannedCents)} - faktycznie ${formatCents(line.actualCents)}',
                ),
                trailing: Text(formatSignedCents(line.differenceCents)),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanExportCard extends StatelessWidget {
  const _PlanExportCard({required this.summary});

  final MonthlyCostPlanSummary summary;

  @override
  Widget build(BuildContext context) {
    final exportText = summary.toTextExport();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.copy_all_outlined),
              title: Text('Eksport roboczy'),
              subtitle: Text('Tekst do rozmowy, mediacji lub notatek.'),
            ),
            SelectableText(exportText),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: exportText));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kosztorys skopiowany do schowka.'),
                  ),
                );
              },
              icon: const Icon(Icons.content_copy_outlined),
              label: const Text('Kopiuj podsumowanie'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CostPlanDisclaimerCard extends StatelessWidget {
  const _CostPlanDisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.balance_outlined),
        title: Text('Disclaimer'),
        subtitle: Text(monthlyCostPlanDisclaimer),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
