import 'package:flutter/material.dart';

import '../../custody/custody_models.dart';
import '../../onboarding/onboarding_profile.dart';

class CustodyCalendarScreen extends StatefulWidget {
  const CustodyCalendarScreen({
    required this.profile,
    required this.userEmail,
    required this.custodyDays,
    required this.onCustodyDaysChanged,
    this.currentDate,
    super.key,
  });

  final OnboardingProfile profile;
  final String userEmail;
  final List<CustodyDay> custodyDays;
  final ValueChanged<List<CustodyDay>> onCustodyDaysChanged;
  final DateTime? currentDate;

  @override
  State<CustodyCalendarScreen> createState() => _CustodyCalendarScreenState();
}

class _CustodyCalendarScreenState extends State<CustodyCalendarScreen> {
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  late DateTime _visibleMonth;
  late final List<CustodyParent> _parents;
  late CustodyParent _selectedParent;
  String? _dateError;

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
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
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

  Future<void> _editDay(DateTime date) async {
    final formattedDate = formatCustodyDate(date);
    final existing = widget.custodyDays
        .where((day) => day.date == formattedDate)
        .firstOrNull;

    final selected = await showModalBottomSheet<_CustodyEditAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
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
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Usun opieke z dnia'),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(const _CustodyEditAction(remove: true)),
                ),
            ],
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
