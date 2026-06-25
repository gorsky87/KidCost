import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kidcost_domain/domain.dart' as domain;

import '../../custody/custody_ics_export.dart';
import '../../custody/custody_models.dart';
import '../../expenses/expense_models.dart';
import '../../onboarding/onboarding_profile.dart';
import '../../premium/premium_discovery.dart';

class CustodyCalendarScreen extends StatefulWidget {
  const CustodyCalendarScreen({
    required this.profile,
    required this.userEmail,
    required this.custodyDays,
    required this.onCustodyDaysChanged,
    this.expenses = const [],
    this.currentDate,
    this.showCalendarExportPremiumHint = true,
    this.onPremiumHintDismissed,
    this.onCalendarExportPremiumIntent,
    super.key,
  });

  final OnboardingProfile profile;
  final String userEmail;
  final List<CustodyDay> custodyDays;
  final List<ExpenseEntry> expenses;
  final ValueChanged<List<CustodyDay>> onCustodyDaysChanged;
  final DateTime? currentDate;
  final bool showCalendarExportPremiumHint;
  final ValueChanged<PremiumDiscoveryPoint>? onPremiumHintDismissed;
  final ValueChanged<CalendarExportPremiumIntent>?
  onCalendarExportPremiumIntent;

  @override
  State<CustodyCalendarScreen> createState() => _CustodyCalendarScreenState();
}

class _CustodyCalendarScreenState extends State<CustodyCalendarScreen> {
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _presetStartDateController = TextEditingController();
  late DateTime _visibleMonth;
  late final List<CustodyParent> _parents;
  late CustodyParent _selectedParent;
  late CustodyParent _presetFirstParent;
  CustodyPresetType _selectedPresetType = CustodyPresetType.alternatingWeeks;
  List<CustodyDay> _presetPreviewDays = const [];
  String? _dateError;
  String? _presetError;

  @override
  void initState() {
    super.initState();
    final now = widget.currentDate ?? DateTime.now();
    _visibleMonth = DateTime.utc(now.year, now.month);
    _parents = [
      CustodyParent(id: 'self', label: widget.userEmail, isCurrentUser: true),
      const CustodyParent(
        id: 'co-parent',
        label: 'Drugi rodzic',
        isCurrentUser: false,
      ),
    ];
    _selectedParent = _parents.first;
    _presetFirstParent = _parents.first;
    _presetStartDateController.text = formatCustodyDate(
      DateTime.utc(now.year, now.month, now.day),
    );
    _refreshPresetPreview();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _presetStartDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthDays = _daysForMonth(_visibleMonth);
    final custodyByDate = {for (final day in widget.custodyDays) day.date: day};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Kalendarz opieki',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('Rodzina: ${widget.profile.familyName}'),
        Text('Dziecko: ${widget.profile.childName}'),
        const SizedBox(height: 8),
        const Text(
          'MVP zapisuje plan dla jednej rodziny i jednego dziecka w tej sesji aplikacji.',
        ),
        if (widget.custodyDays.isEmpty) ...[
          const SizedBox(height: 16),
          const _EmptyCustodyCalendarIntro(),
        ],
        const SizedBox(height: 16),
        _MonthHeader(
          visibleMonth: _visibleMonth,
          onPrevious: () => setState(() {
            _visibleMonth = DateTime.utc(
              _visibleMonth.year,
              _visibleMonth.month - 1,
            );
          }),
          onNext: () => setState(() {
            _visibleMonth = DateTime.utc(
              _visibleMonth.year,
              _visibleMonth.month + 1,
            );
          }),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.72,
          children: [
            for (final label in const [
              'Pn',
              'Wt',
              'Sr',
              'Cz',
              'Pt',
              'Sb',
              'Nd',
            ])
              Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            for (final day in monthDays)
              _DayCell(
                day: day,
                custodyDay: custodyByDate[formatCustodyDate(day)],
                onTap: () => _editDay(day),
              ),
          ],
        ),
        if (widget.showCalendarExportPremiumHint) ...[
          const SizedBox(height: 16),
          _CalendarExportPremiumSection(
            custodyDaysCount: widget.custodyDays.length,
            onIntent: _showCalendarExportPremiumIntent,
            onDismiss: () => widget.onPremiumHintDismissed?.call(
              PremiumDiscoveryPoint.calendarExport,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _CustodyPresetCard(
          startDateController: _presetStartDateController,
          presetDefinitions: custodyPresetDefinitions,
          selectedPresetType: _selectedPresetType,
          parents: _parents,
          firstParent: _presetFirstParent,
          previewDays: _presetPreviewDays,
          presetError: _presetError,
          onPresetChanged: (presetType) {
            if (presetType != null) {
              setState(() {
                _selectedPresetType = presetType;
                _refreshPresetPreview();
              });
            }
          },
          onFirstParentChanged: (parent) {
            if (parent != null) {
              setState(() {
                _presetFirstParent = parent;
                _refreshPresetPreview();
              });
            }
          },
          onPreview: () => setState(_refreshPresetPreview),
          onApply: _applyPresetPreview,
        ),
        const SizedBox(height: 16),
        _AddCustodyRangeCard(
          startDateController: _startDateController,
          endDateController: _endDateController,
          parents: _parents,
          selectedParent: _selectedParent,
          dateError: _dateError,
          onParentChanged: (parent) {
            if (parent != null) {
              setState(() => _selectedParent = parent);
            }
          },
          onSave: _saveRange,
        ),
      ],
    );
  }

  CustodyParent get _presetSecondParent =>
      _parents.firstWhere((parent) => parent.id != _presetFirstParent.id);

  List<DateTime> _daysForMonth(DateTime month) {
    final firstDay = DateTime.utc(month.year, month.month);
    final leadingEmptyDays = firstDay.weekday - 1;
    final daysInMonth = DateTime.utc(month.year, month.month + 1, 0).day;
    return [
      for (var index = 0; index < leadingEmptyDays; index++)
        DateTime.utc(month.year, month.month, -leadingEmptyDays + index + 1),
      for (var day = 1; day <= daysInMonth; day++)
        DateTime.utc(month.year, month.month, day),
    ];
  }

  void _saveRange() {
    final start = parseCustodyDate(_startDateController.text);
    final end = _endDateController.text.trim().isEmpty
        ? start
        : parseCustodyDate(_endDateController.text);

    setState(() {
      _dateError = start == null || end == null || end.isBefore(start)
          ? 'Podaj poprawna date lub zakres RRRR-MM-DD.'
          : null;
    });

    if (start == null || end == null || end.isBefore(start)) {
      return;
    }

    final updated = [...widget.custodyDays];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      _upsertDay(updated, cursor, _selectedParent);
      cursor = cursor.add(const Duration(days: 1));
    }

    widget.onCustodyDaysChanged(updated);
    _startDateController.clear();
    _endDateController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Plan opieki zapisany.')));
  }

  void _refreshPresetPreview() {
    final start = parseCustodyDate(_presetStartDateController.text);
    if (start == null) {
      _presetPreviewDays = const [];
      _presetError = 'Podaj date startu RRRR-MM-DD.';
      return;
    }

    _presetError = null;
    _presetPreviewDays = buildCustodyPresetDays(
      presetType: _selectedPresetType,
      startDate: start,
      dayCount: 14,
      childName: widget.profile.childName,
      firstParent: _presetFirstParent,
      secondParent: _presetSecondParent,
    );
  }

  void _applyPresetPreview() {
    setState(_refreshPresetPreview);
    if (_presetPreviewDays.isEmpty || _presetError != null) {
      return;
    }

    final start = parseCustodyDate(_presetStartDateController.text);
    final updated = [...widget.custodyDays];
    for (final previewDay in _presetPreviewDays) {
      final date = parseCustodyDate(previewDay.date);
      if (date != null) {
        _upsertDay(updated, date, previewDay.parent);
      }
    }

    if (start != null) {
      _visibleMonth = DateTime.utc(start.year, start.month);
    }
    widget.onCustodyDaysChanged(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preset opieki zastosowany na 14 dni.')),
    );
  }

  Future<void> _showCalendarExportPremiumIntent() async {
    final generatedAt = widget.currentDate ?? DateTime.now().toUtc();
    final intent = await showDialog<CalendarExportPremiumIntent>(
      context: context,
      builder: (context) {
        return _CalendarExportPreviewDialog(
          custodyDays: widget.custodyDays,
          linkedExpenses: widget.expenses,
          generatedAt: generatedAt,
        );
      },
    );
    if (!mounted || intent == null) {
      return;
    }

    widget.onCalendarExportPremiumIntent?.call(intent);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Intencja eksportu zapisana; plan opieki zostaje dostepny tutaj.',
        ),
      ),
    );
  }

  Future<void> _editDay(DateTime date) async {
    final formattedDate = formatCustodyDate(date);
    final existing = widget.custodyDays
        .where((day) => day.date == formattedDate)
        .firstOrNull;
    final linkedExpenses = existing == null
        ? const <ExpenseEntry>[]
        : widget.expenses
              .where((expense) => expense.calendarEventId == existing.id)
              .toList(growable: false);

    final selected = await showModalBottomSheet<_CustodyEditAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(formattedDate),
                  subtitle: Text(
                    existing == null
                        ? 'Dodaj opieke na ten dzien.'
                        : 'Teraz: ${existing.parent.label}',
                  ),
                ),
                for (final parent in _parents)
                  ListTile(
                    leading: Icon(
                      parent.isCurrentUser
                          ? Icons.person_outline
                          : Icons.group_outlined,
                    ),
                    title: Text(parent.label),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(_CustodyEditAction(parent: parent)),
                  ),
                if (existing != null)
                  _LinkedExpensesForDay(expenses: linkedExpenses),
                if (existing != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Usun opieke z dnia'),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(const _CustodyEditAction(remove: true)),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    final updated = [...widget.custodyDays];
    if (selected.remove) {
      updated.removeWhere((day) => day.date == formattedDate);
    } else {
      final parent = selected.parent;
      if (parent != null) {
        _upsertDay(updated, date, parent);
      }
    }

    widget.onCustodyDaysChanged(updated);
  }

  void _upsertDay(
    List<CustodyDay> custodyDays,
    DateTime date,
    CustodyParent parent,
  ) {
    final formattedDate = formatCustodyDate(date);
    final existingIndex = custodyDays.indexWhere(
      (day) => day.date == formattedDate,
    );
    if (existingIndex >= 0) {
      custodyDays[existingIndex] = custodyDays[existingIndex].copyWith(
        parent: parent,
      );
      return;
    }

    custodyDays.add(
      CustodyDay(
        id: 'custody-$formattedDate',
        date: formattedDate,
        childName: widget.profile.childName,
        parent: parent,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }
}

class CalendarExportPremiumIntent {
  const CalendarExportPremiumIntent({
    required this.custodyDaysCount,
    this.exportFormat = 'ics',
    this.includeDetailedExpenseContext = false,
  });

  final int custodyDaysCount;
  final String exportFormat;
  final bool includeDetailedExpenseContext;
}

class _CalendarExportPremiumSection extends StatelessWidget {
  const _CalendarExportPremiumSection({
    required this.custodyDaysCount,
    required this.onIntent,
    required this.onDismiss,
  });

  final int custodyDaysCount;
  final VoidCallback onIntent;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final entitlement = domain.entitlementDefinitionFor(
      domain.EntitlementFeature.calendarIcsExport,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumDiscoveryCard(
          point: PremiumDiscoveryPoint.calendarExport,
          onDismiss: onDismiss,
          compact: true,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: custodyDaysCount == 0 ? null : onIntent,
          icon: const Icon(Icons.ios_share_outlined),
          label: const Text('Podglad eksportu ICS'),
        ),
        const SizedBox(height: 4),
        Text(
          '${entitlement.free.summary} Eksport uzywa neutralnych tytulow wydarzen.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CalendarExportPreviewDialog extends StatefulWidget {
  const _CalendarExportPreviewDialog({
    required this.custodyDays,
    required this.linkedExpenses,
    required this.generatedAt,
  });

  final List<CustodyDay> custodyDays;
  final List<ExpenseEntry> linkedExpenses;
  final DateTime generatedAt;

  @override
  State<_CalendarExportPreviewDialog> createState() =>
      _CalendarExportPreviewDialogState();
}

class _CalendarExportPreviewDialogState
    extends State<_CalendarExportPreviewDialog> {
  bool _includeDetailedExpenseContext = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final export = buildCustodyIcsExport(
      custodyDays: widget.custodyDays,
      linkedExpenses: widget.linkedExpenses,
      includeLinkedExpenseContext: _includeDetailedExpenseContext,
      privacyMode: _includeDetailedExpenseContext
          ? CustodyIcsPrivacyMode.detailed
          : CustodyIcsPrivacyMode.neutral,
      generatedAt: widget.generatedAt,
    );
    return AlertDialog(
      key: const Key('calendar-export-preview-dialog'),
      icon: Icon(Icons.calendar_month_outlined, color: colors.primary),
      title: const Text('Eksport kalendarza Premium'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gotowe do eksportu: ${export.eventCount} dni opieki w pliku ${export.fileName}.',
            ),
            const SizedBox(height: 12),
            const _CalendarExportPrivacyRow(
              icon: Icons.lock_outline,
              title: 'Domyslnie prywatnie',
              body:
                  'Tytuly wydarzen sa neutralne, bez imion dziecka, kwot, kosztow, lokalizacji i notatek.',
            ),
            const _CalendarExportPrivacyRow(
              icon: Icons.event_available_outlined,
              title: 'Tylko plan opieki',
              body:
                  'Linki do kosztow nie trafia do kalendarza bez osobnej zgody.',
            ),
            CheckboxListTile(
              key: const Key('calendar-ics-include-costs-checkbox'),
              contentPadding: EdgeInsets.zero,
              value: _includeDetailedExpenseContext,
              onChanged: (value) {
                setState(() {
                  _includeDetailedExpenseContext = value ?? false;
                });
              },
              title: const Text('Dolacz szczegoly kosztow'),
              subtitle: Text(
                _includeDetailedExpenseContext
                    ? 'Podglad zawiera powiazane koszty i szczegoly opieki.'
                    : 'Domyslnie wylaczone; wymaga osobnej zgody przed eksportem.',
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              export.content,
              key: const Key('calendar-ics-preview'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Nie teraz'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: export.content));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tresc ICS skopiowana.')),
            );
          },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Kopiuj ICS'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(
            CalendarExportPremiumIntent(
              custodyDaysCount: widget.custodyDays.length,
              includeDetailedExpenseContext: _includeDetailedExpenseContext,
            ),
          ),
          icon: const Icon(Icons.workspace_premium_outlined),
          label: const Text('Zapisz intencje'),
        ),
      ],
    );
  }
}

class _CalendarExportPrivacyRow extends StatelessWidget {
  const _CalendarExportPrivacyRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedExpensesForDay extends StatelessWidget {
  const _LinkedExpensesForDay({required this.expenses});

  final List<ExpenseEntry> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const ListTile(
        leading: Icon(Icons.receipt_long_outlined),
        title: Text('Brak kosztow powiazanych z tym dniem'),
        subtitle: Text('Koszty mozna dodac z formularza nowego kosztu.'),
      );
    }

    final totalCents = expenses.fold<int>(
      0,
      (total, expense) => total + expense.amountCents,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text('Powiazane koszty (${expenses.length})'),
          subtitle: Text(
            'Suma: ${formatCents(totalCents)}, udzial drugiego rodzica: ${formatCents(totalCents ~/ 2)}',
          ),
        ),
        for (final expense in expenses)
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: Text(expense.title),
            subtitle: Text(
              '${expense.category.label} - ${expense.status.label}',
            ),
            trailing: Text(formatCents(expense.amountCents)),
          ),
      ],
    );
  }
}

class _EmptyCustodyCalendarIntro extends StatelessWidget {
  const _EmptyCustodyCalendarIntro();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Zacznij od gotowego presetu albo wpisz dni recznie nizej.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.visibleMonth,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime visibleMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label =
        '${visibleMonth.year}-${visibleMonth.month.toString().padLeft(2, '0')}';
    return Row(
      children: [
        IconButton(
          tooltip: 'Poprzedni miesiac',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Center(
            child: Text(label, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        IconButton(
          tooltip: 'Nastepny miesiac',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.onTap, this.custodyDay});

  final DateTime day;
  final CustodyDay? custodyDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final custodyDay = this.custodyDay;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          backgroundColor: custodyDay == null
              ? null
              : Theme.of(context).colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day.day.toString()),
            const SizedBox(height: 2),
            Text(
              custodyDay?.parent.label ?? '-',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustodyPresetCard extends StatelessWidget {
  const _CustodyPresetCard({
    required this.startDateController,
    required this.presetDefinitions,
    required this.selectedPresetType,
    required this.parents,
    required this.firstParent,
    required this.previewDays,
    required this.onPresetChanged,
    required this.onFirstParentChanged,
    required this.onPreview,
    required this.onApply,
    this.presetError,
  });

  final TextEditingController startDateController;
  final List<CustodyPresetDefinition> presetDefinitions;
  final CustodyPresetType selectedPresetType;
  final List<CustodyParent> parents;
  final CustodyParent firstParent;
  final List<CustodyDay> previewDays;
  final ValueChanged<CustodyPresetType?> onPresetChanged;
  final ValueChanged<CustodyParent?> onFirstParentChanged;
  final VoidCallback onPreview;
  final VoidCallback onApply;
  final String? presetError;

  @override
  Widget build(BuildContext context) {
    final selectedDefinition = presetDefinitions.firstWhere(
      (definition) => definition.type == selectedPresetType,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Presety opieki',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(selectedDefinition.description),
            const SizedBox(height: 12),
            DropdownButtonFormField<CustodyPresetType>(
              key: const Key('custody-preset-picker'),
              initialValue: selectedPresetType,
              decoration: const InputDecoration(
                labelText: 'Preset',
                prefixIcon: Icon(Icons.calendar_view_week_outlined),
              ),
              items: [
                for (final definition in presetDefinitions)
                  DropdownMenuItem(
                    value: definition.type,
                    child: Text(definition.label),
                  ),
              ],
              onChanged: onPresetChanged,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('custody-preset-start-date'),
              controller: startDateController,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: 'Start presetu',
                hintText: 'RRRR-MM-DD',
                prefixIcon: const Icon(Icons.event_repeat_outlined),
                errorText: presetError,
              ),
              onChanged: (_) => onPreview(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CustodyParent>(
              key: const Key('custody-preset-first-parent'),
              initialValue: firstParent,
              decoration: const InputDecoration(
                labelText: 'Rodzic startujacy',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: [
                for (final parent in parents)
                  DropdownMenuItem(value: parent, child: Text(parent.label)),
              ],
              onChanged: onFirstParentChanged,
            ),
            const SizedBox(height: 12),
            _PresetPreview(days: previewDays),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Odswiez podglad'),
                ),
                FilledButton.icon(
                  onPressed: previewDays.isEmpty ? null : onApply,
                  icon: const Icon(Icons.done_all_outlined),
                  label: const Text('Zastosuj 14 dni'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetPreview extends StatelessWidget {
  const _PresetPreview({required this.days});

  final List<CustodyDay> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const Text('Podglad pojawi sie po podaniu poprawnej daty.');
    }

    return Semantics(
      label: 'Podglad presetu opieki na 14 dni',
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.05,
        children: [
          for (final day in days)
            Padding(
              padding: const EdgeInsets.all(2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: day.parent.isCurrentUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Center(
                  child: Text(
                    '${day.date.substring(8)}\n${day.parent.isCurrentUser ? 'Ty' : '2R'}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddCustodyRangeCard extends StatelessWidget {
  const _AddCustodyRangeCard({
    required this.startDateController,
    required this.endDateController,
    required this.parents,
    required this.selectedParent,
    required this.onParentChanged,
    required this.onSave,
    this.dateError,
  });

  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final List<CustodyParent> parents;
  final CustodyParent selectedParent;
  final ValueChanged<CustodyParent?> onParentChanged;
  final VoidCallback onSave;
  final String? dateError;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dodaj opieke',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('custody-start-date'),
              controller: startDateController,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: 'Data od',
                hintText: 'RRRR-MM-DD',
                prefixIcon: const Icon(Icons.event_outlined),
                errorText: dateError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('custody-end-date'),
              controller: endDateController,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Data do',
                hintText: 'Puste = jeden dzien',
                prefixIcon: Icon(Icons.date_range_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CustodyParent>(
              key: const Key('custody-parent-picker'),
              initialValue: selectedParent,
              decoration: const InputDecoration(
                labelText: 'Kto ma opieke',
                prefixIcon: Icon(Icons.supervisor_account_outlined),
              ),
              items: [
                for (final parent in parents)
                  DropdownMenuItem(value: parent, child: Text(parent.label)),
              ],
              onChanged: onParentChanged,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Zapisz opieke'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustodyEditAction {
  const _CustodyEditAction({this.parent, this.remove = false});

  final CustodyParent? parent;
  final bool remove;
}
