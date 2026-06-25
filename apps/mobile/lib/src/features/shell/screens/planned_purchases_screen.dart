import 'package:flutter/material.dart';

import '../../expenses/expense_models.dart';
import '../../onboarding/onboarding_profile.dart';
import '../../planned_purchases/planned_purchase_models.dart';

class PlannedPurchasesScreen extends StatefulWidget {
  const PlannedPurchasesScreen({
    required this.profile,
    required this.plannedPurchases,
    required this.onPlannedPurchaseSaved,
    required this.onPlannedPurchaseChanged,
    required this.onConvertToExpense,
    this.currentDate,
    super.key,
  });

  final OnboardingProfile profile;
  final List<PlannedPurchase> plannedPurchases;
  final ValueChanged<PlannedPurchase> onPlannedPurchaseSaved;
  final ValueChanged<PlannedPurchase> onPlannedPurchaseChanged;
  final ValueChanged<PlannedPurchase> onConvertToExpense;
  final DateTime? currentDate;

  @override
  State<PlannedPurchasesScreen> createState() => _PlannedPurchasesScreenState();
}

class _PlannedPurchasesScreenState extends State<PlannedPurchasesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _targetDateController = TextEditingController();
  final _deadlineController = TextEditingController();
  ExpenseCategory _category = expenseCategories.first;
  int _splitPercent = 50;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _targetDateController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final openPlans = widget.plannedPurchases
        .where((plan) => plan.status.isOpen)
        .toList();
    final closedPlans = widget.plannedPurchases
        .where((plan) => !plan.status.isOpen)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Planowane zakupy',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Uzgodnij wydatek przed zakupem. Plan nie zmienia salda, dopoki nie zamienisz go w koszt.',
        ),
        const SizedBox(height: 12),
        _PlannedPurchaseForm(
          formKey: _formKey,
          titleController: _titleController,
          amountController: _amountController,
          targetDateController: _targetDateController,
          deadlineController: _deadlineController,
          category: _category,
          splitPercent: _splitPercent,
          onCategoryChanged: (category) {
            if (category == null) return;
            setState(() => _category = category);
          },
          onSplitChanged: (value) => setState(() => _splitPercent = value),
          onSubmit: _savePlan,
        ),
        const SizedBox(height: 12),
        _SummaryCard(plannedPurchases: widget.plannedPurchases),
        const SizedBox(height: 12),
        if (openPlans.isEmpty)
          const _EmptyPlansCard()
        else
          for (final plan in openPlans) ...[
            _PlannedPurchaseCard(
              plan: plan,
              onApprove: () =>
                  _changeStatus(plan, PlannedPurchaseStatus.approved),
              onDecline: () =>
                  _openReasonSheet(plan, PlannedPurchaseStatus.declined),
              onAskClarification: () => _openReasonSheet(
                plan,
                PlannedPurchaseStatus.clarificationRequested,
              ),
              onConvert: plan.status.canConvert
                  ? () => widget.onConvertToExpense(plan)
                  : null,
            ),
          ],
        if (closedPlans.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Historia planow',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final plan in closedPlans)
            _PlannedPurchaseCard(
              plan: plan,
              onApprove: null,
              onDecline: null,
              onAskClarification: null,
              onConvert: null,
            ),
        ],
      ],
    );
  }

  void _savePlan() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = widget.currentDate ?? DateTime.now();
    final plan = PlannedPurchase(
      id: 'planned-${now.microsecondsSinceEpoch}',
      title: _titleController.text.trim(),
      estimatedAmountCents: parseAmountToCents(_amountController.text),
      category: _category,
      childName: widget.profile.childName,
      targetDate: _targetDateController.text.trim(),
      approvalDeadline: _deadlineController.text.trim(),
      proposedSplitPercent: _splitPercent,
      createdAt: now,
    );
    widget.onPlannedPurchaseSaved(plan);
    _titleController.clear();
    _amountController.clear();
    _targetDateController.clear();
    _deadlineController.clear();
    setState(() {
      _category = expenseCategories.first;
      _splitPercent = 50;
    });
  }

  void _changeStatus(
    PlannedPurchase plan,
    PlannedPurchaseStatus status, {
    PlannedPurchaseReason? reason,
    String? note,
  }) {
    widget.onPlannedPurchaseChanged(
      plan.copyWith(
        status: status,
        reason: reason,
        note: note,
        clearReason: reason == null,
        clearNote: note == null || note.trim().isEmpty,
      ),
    );
  }

  Future<void> _openReasonSheet(
    PlannedPurchase plan,
    PlannedPurchaseStatus status,
  ) async {
    final result = await showModalBottomSheet<_ReasonResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReasonSheet(status: status),
    );
    if (result == null) {
      return;
    }
    _changeStatus(plan, status, reason: result.reason, note: result.note);
  }
}

class _PlannedPurchaseForm extends StatelessWidget {
  const _PlannedPurchaseForm({
    required this.formKey,
    required this.titleController,
    required this.amountController,
    required this.targetDateController,
    required this.deadlineController,
    required this.category,
    required this.splitPercent,
    required this.onCategoryChanged,
    required this.onSplitChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController targetDateController;
  final TextEditingController deadlineController;
  final ExpenseCategory category;
  final int splitPercent;
  final ValueChanged<ExpenseCategory?> onCategoryChanged;
  final ValueChanged<int> onSplitChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_turned_in_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nowy plan zakupu',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('planned-purchase-title-field'),
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Co trzeba kupic',
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
                textInputAction: TextInputAction.next,
                validator: _requiredText,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('planned-purchase-amount-field'),
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Szacowana kwota',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: 'PLN',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _amountValidator,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExpenseCategory>(
                key: const Key('planned-purchase-category-field'),
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Kategoria',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final category in expenseCategories)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                ],
                onChanged: onCategoryChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('planned-purchase-target-date-field'),
                controller: targetDateController,
                decoration: const InputDecoration(
                  labelText: 'Planowany zakup',
                  hintText: '2026-09-01',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                validator: _dateValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('planned-purchase-deadline-field'),
                controller: deadlineController,
                decoration: const InputDecoration(
                  labelText: 'Termin odpowiedzi',
                  hintText: '2026-08-25',
                  prefixIcon: Icon(Icons.hourglass_bottom_outlined),
                ),
                validator: _dateValidator,
              ),
              const SizedBox(height: 12),
              Text('Udzial drugiego rodzica: $splitPercent%'),
              Slider(
                value: splitPercent.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$splitPercent%',
                onChanged: (value) => onSplitChanged(value.round()),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('planned-purchase-submit-button'),
                onPressed: onSubmit,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Wyslij plan do akceptacji'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.plannedPurchases});

  final List<PlannedPurchase> plannedPurchases;

  @override
  Widget build(BuildContext context) {
    final openCount = plannedPurchases
        .where((plan) => plan.status.isOpen)
        .length;
    final estimatedCents = plannedPurchases
        .where((plan) => plan.status.isOpen)
        .fold<int>(0, (sum, plan) => sum + plan.estimatedAmountCents);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$openCount otwarte plany',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Szacunek ${formatCents(estimatedCents)} poza saldem rodziny.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlansCard extends StatelessWidget {
  const _EmptyPlansCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.playlist_add_check_outlined),
        title: Text('Brak planow zakupow'),
        subtitle: Text(
          'Dodaj zakup, ktory wymaga zgody przed faktycznym kosztem.',
        ),
      ),
    );
  }
}

class _PlannedPurchaseCard extends StatelessWidget {
  const _PlannedPurchaseCard({
    required this.plan,
    required this.onApprove,
    required this.onDecline,
    required this.onAskClarification,
    required this.onConvert,
  });

  final PlannedPurchase plan;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final VoidCallback? onAskClarification;
  final VoidCallback? onConvert;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shopping_bag_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(plan.status.label),
                    ],
                  ),
                ),
                Text(formatCents(plan.estimatedAmountCents)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(plan.category.label)),
                Chip(label: Text('Zakup ${plan.targetDate}')),
                Chip(label: Text('Odpowiedz do ${plan.approvalDeadline}')),
                Chip(label: Text('Udzial ${plan.proposedSplitPercent}%')),
              ],
            ),
            if (plan.reason != null || (plan.note?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text(
                [
                  if (plan.reason != null) plan.reason!.label,
                  if (plan.note?.isNotEmpty ?? false) plan.note!,
                ].join(': '),
              ),
            ],
            if (onApprove != null ||
                onDecline != null ||
                onAskClarification != null ||
                onConvert != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onApprove != null)
                    FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Akceptuj'),
                    ),
                  if (onAskClarification != null)
                    OutlinedButton.icon(
                      onPressed: onAskClarification,
                      icon: const Icon(Icons.help_outline),
                      label: const Text('Popros o szczegoly'),
                    ),
                  if (onDecline != null)
                    OutlinedButton.icon(
                      onPressed: onDecline,
                      icon: const Icon(Icons.block_outlined),
                      label: const Text('Odrzuc'),
                    ),
                  if (onConvert != null)
                    FilledButton.icon(
                      key: Key('convert-planned-purchase-${plan.id}'),
                      onPressed: onConvert,
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Zamien w koszt'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({required this.status});

  final PlannedPurchaseStatus status;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  PlannedPurchaseReason _reason = PlannedPurchaseReason.needDetails;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.status == PlannedPurchaseStatus.declined
        ? 'Powod odrzucenia'
        : 'O co prosisz?';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<PlannedPurchaseReason>(
              initialValue: _reason,
              decoration: const InputDecoration(
                labelText: 'Powod',
                prefixIcon: Icon(Icons.label_outline),
              ),
              items: [
                for (final reason in PlannedPurchaseReason.values)
                  DropdownMenuItem(value: reason, child: Text(reason.label)),
              ],
              onChanged: (reason) {
                if (reason == null) return;
                setState(() => _reason = reason);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Krotka notatka opcjonalna',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLength: 160,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(_ReasonResult(_reason, _noteController.text.trim()));
              },
              icon: const Icon(Icons.check_outlined),
              label: const Text('Zapisz powod'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonResult {
  const _ReasonResult(this.reason, this.note);

  final PlannedPurchaseReason reason;
  final String note;
}

String? _requiredText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Uzupelnij pole.';
  }
  return null;
}

String? _dateValidator(String? value) {
  final requiredError = _requiredText(value);
  if (requiredError != null) {
    return requiredError;
  }
  final normalized = value!.trim();
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(normalized)) {
    return 'Uzyj formatu RRRR-MM-DD.';
  }
  return null;
}

String? _amountValidator(String? value) {
  final requiredError = _requiredText(value);
  if (requiredError != null) {
    return requiredError;
  }
  try {
    parseAmountToCents(value!);
  } on FormatException {
    return 'Podaj kwote wieksza od 0.';
  }
  return null;
}
