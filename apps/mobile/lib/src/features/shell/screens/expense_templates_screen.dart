import 'package:flutter/material.dart';

import '../../expenses/expense_models.dart';
import '../../expenses/expense_visuals.dart';
import '../../onboarding/onboarding_profile.dart';
import '../widgets/date_picker_field.dart';

class ExpenseTemplatesScreen extends StatelessWidget {
  const ExpenseTemplatesScreen({
    required this.profile,
    required this.userEmail,
    required this.templates,
    required this.onTemplateSaved,
    required this.onCreateExpenseFromTemplate,
    super.key,
  });

  final OnboardingProfile profile;
  final String userEmail;
  final List<ExpenseTemplate> templates;
  final ValueChanged<ExpenseTemplate> onTemplateSaved;
  final ValueChanged<ExpenseTemplate> onCreateExpenseFromTemplate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Szablony cykliczne',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => _openTemplateForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Nowy'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Dla przedszkola, obiadow, zajec, terapii i innych stalych kosztow.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (templates.isEmpty)
          _EmptyTemplatesCard(onCreate: () => _openTemplateForm(context))
        else
          for (final template in templates)
            _TemplateCard(
              template: template,
              onEdit: () => _openTemplateForm(context, template: template),
              onToggleActive: () {
                onTemplateSaved(
                  template.copyWith(isActive: !template.isActive),
                );
              },
              onCreateExpense: template.isActive
                  ? () => onCreateExpenseFromTemplate(template)
                  : null,
            ),
      ],
    );
  }

  void _openTemplateForm(BuildContext context, {ExpenseTemplate? template}) {
    final payers = [
      ExpensePayer(id: 'self', label: userEmail, isCurrentUser: true),
      ExpensePayer(
        id: profile.isSoloFamily ? 'manual-co-parent' : 'co-parent',
        label: profile.coParentLabel,
        isCurrentUser: false,
        isManual: profile.isSoloFamily,
      ),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _TemplateFormSheet(
          template: template,
          payers: payers,
          onSaved: (savedTemplate) {
            onTemplateSaved(savedTemplate);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onToggleActive,
    required this.onCreateExpense,
  });

  final ExpenseTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback? onCreateExpense;

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
              leading: Icon(
                template.category.icon,
                color: template.category.accentColor,
              ),
              title: Text(template.name),
              subtitle: Text(
                [
                  template.category.label,
                  template.recurrence.label,
                  'nastepny termin: ${template.nextDueDate}',
                  'placi: ${template.paidBy.label}',
                  if (!template.isActive) 'wylaczony',
                ].join(' • '),
              ),
              trailing: Text(
                formatCents(template.amountCents),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onCreateExpense,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Utworz koszt'),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edytuj'),
                ),
                OutlinedButton.icon(
                  onPressed: onToggleActive,
                  icon: Icon(
                    template.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                  label: Text(template.isActive ? 'Wylacz' : 'Wlacz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTemplatesCard extends StatelessWidget {
  const _EmptyTemplatesCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.event_repeat_outlined),
              title: Text('Brak szablonow'),
              subtitle: Text(
                'Dodaj staly koszt i tworz z niego wpis dopiero po potwierdzeniu.',
              ),
            ),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj szablon'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateFormSheet extends StatefulWidget {
  const _TemplateFormSheet({
    required this.payers,
    required this.onSaved,
    this.template,
  });

  final List<ExpensePayer> payers;
  final ExpenseTemplate? template;
  final ValueChanged<ExpenseTemplate> onSaved;

  @override
  State<_TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends State<_TemplateFormSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();
  ExpenseCategory _category = expenseCategories.first;
  ExpenseRecurrence _recurrence = ExpenseRecurrence.monthly;
  late ExpensePayer _payer;
  String? _nameError;
  String? _amountError;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _payer = widget.payers.first;
    final template = widget.template;
    if (template != null) {
      _nameController.text = template.name;
      _amountController.text = formatCents(
        template.amountCents,
      ).replaceAll(' zl', '');
      _dateController.text = template.nextDueDate;
      _noteController.text = template.note ?? '';
      _category = template.category;
      _recurrence = template.recurrence;
      _payer = widget.payers.firstWhere(
        (payer) => payer.id == template.paidBy.id,
        orElse: () => widget.payers.first,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.template == null ? 'Nowy szablon' : 'Edytuj szablon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nazwa',
                prefixIcon: const Icon(Icons.event_repeat_outlined),
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Kwota',
                hintText: '0,00',
                prefixIcon: const Icon(Icons.payments_outlined),
                errorText: _amountError,
              ),
            ),
            const SizedBox(height: 12),
            KidCostDateField(
              fieldKey: const Key('expense-template-next-due-date-field'),
              controller: _dateController,
              labelText: 'Nastepny termin',
              prefixIcon: const Icon(Icons.event_outlined),
              errorText: _dateError,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseRecurrence>(
              initialValue: _recurrence,
              decoration: const InputDecoration(
                labelText: 'Powtarzanie',
                prefixIcon: Icon(Icons.repeat_outlined),
              ),
              items: [
                for (final recurrence in ExpenseRecurrence.values)
                  DropdownMenuItem(
                    value: recurrence,
                    child: Text(recurrence.label),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _recurrence = value);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpensePayer>(
              initialValue: _payer,
              decoration: const InputDecoration(
                labelText: 'Kto zwykle placi',
                prefixIcon: Icon(Icons.account_circle_outlined),
              ),
              items: [
                for (final payer in widget.payers)
                  DropdownMenuItem(value: payer, child: Text(payer.label)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _payer = value);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
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
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Opis do kosztu',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 16),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.fact_check_outlined),
              title: Text('Bez automatycznego ksiegowania'),
              subtitle: Text(
                'Szablon tylko wypelnia formularz. Koszt zapisujesz recznie po sprawdzeniu.',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saveTemplate,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Zapisz szablon'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTemplate() {
    final name = _nameController.text.trim();
    final date = _dateController.text.trim();
    int amountCents;
    try {
      amountCents = parseAmountToCents(_amountController.text);
    } on FormatException {
      amountCents = 0;
    }

    setState(() {
      _nameError = name.isEmpty ? 'Podaj nazwe szablonu.' : null;
      _amountError = amountCents > 0 ? null : 'Podaj kwote wieksza od 0.';
      _dateError = date.isEmpty ? 'Podaj nastepny termin.' : null;
    });

    if (name.isEmpty || amountCents <= 0 || date.isEmpty) {
      return;
    }

    widget.onSaved(
      ExpenseTemplate(
        id:
            widget.template?.id ??
            'template-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        amountCents: amountCents,
        category: _category,
        paidBy: _payer,
        recurrence: _recurrence,
        nextDueDate: date,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        isActive: widget.template?.isActive ?? true,
      ),
    );
  }
}
