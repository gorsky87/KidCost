import 'package:flutter/material.dart';
import 'package:kidcost_domain/domain.dart' as domain;

import '../../expenses/expense_models.dart';
import '../../expenses/expense_visuals.dart';
import '../../premium/premium_discovery.dart';

enum _ExpenseSort { newest, oldest, highestAmount, lowestAmount }

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({
    required this.expenses,
    this.isLoading = false,
    this.errorMessage,
    this.showExpenseHistoryPremiumHint = false,
    this.onExpenseChanged,
    this.onPremiumHintDismissed,
    super.key,
  });

  final List<ExpenseEntry> expenses;
  final bool isLoading;
  final String? errorMessage;
  final bool showExpenseHistoryPremiumHint;
  final ValueChanged<ExpenseEntry>? onExpenseChanged;
  final ValueChanged<PremiumDiscoveryPoint>? onPremiumHintDismissed;

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
            _ExpenseCard(
              expense: expense,
              onExpenseChanged: widget.onExpenseChanged,
              showExpenseHistoryPremiumHint:
                  widget.showExpenseHistoryPremiumHint,
              onPremiumHintDismissed: () => widget.onPremiumHintDismissed?.call(
                PremiumDiscoveryPoint.expenseHistory,
              ),
            ),
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
  const _ExpenseCard({
    required this.expense,
    required this.onExpenseChanged,
    required this.showExpenseHistoryPremiumHint,
    required this.onPremiumHintDismissed,
  });

  final ExpenseEntry expense;
  final ValueChanged<ExpenseEntry>? onExpenseChanged;
  final bool showExpenseHistoryPremiumHint;
  final VoidCallback onPremiumHintDismissed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              expense.category.icon,
              color: expense.category.accentColor,
            ),
            title: Text(expense.title),
            subtitle: Text(
              [
                expense.category.label,
                expense.childName,
                expense.expenseDate,
                'Zaplacil: ${expense.paidBy.label}',
                if (expense.paidBy.isManual) 'platnik bez konta',
                expense.visibility.label,
                if (expense.sourceTemplateName != null)
                  'Szablon: ${expense.sourceTemplateName}',
                if (expense.attachment != null)
                  expense.attachment!.status == AttachmentStatus.uploaded
                      ? 'Zalacznik: ${expense.attachment!.fileName}'
                      : 'Zalacznik: blad uploadu',
                if (expense.attachment?.evidence?.type != null)
                  'Dowod: ${expense.attachment!.evidence!.type!.label}',
              ].join(' • '),
            ),
            trailing: Text(
              formatCents(expense.amountCents),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () => _showExpenseDetails(context, expense),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ExpenseStatusBadge(status: expense.status),
                _ExpenseVisibilityBadge(visibility: expense.visibility),
              ],
            ),
          ),
        ],
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
                  _ExpenseStatusPanel(status: expense.status),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Nazwa', value: expense.title),
                  _DetailRow(
                    label: 'Kwota',
                    value: formatCents(expense.amountCents),
                  ),
                  _DetailRow(label: 'Kategoria', value: expense.category.label),
                  _DetailRow(label: 'Dziecko', value: expense.childName),
                  _DetailRow(label: 'Placacy', value: expense.paidBy.label),
                  if (expense.sourceTemplateName != null)
                    _DetailRow(
                      label: 'Zrodlo',
                      value: 'Szablon: ${expense.sourceTemplateName}',
                    ),
                  _DetailRow(
                    label: 'Widocznosc',
                    value: expense.visibility.description,
                  ),
                  _DetailRow(label: 'Data', value: expense.expenseDate),
                  if (!expense.status.canEdit)
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_outline),
                      title: Text('Edycja zablokowana'),
                      subtitle: Text(
                        'Kwota, data i kategoria sa zamrozone po reakcji na koszt.',
                      ),
                    ),
                  const SizedBox(height: 12),
                  _AttachmentPreview(attachment: expense.attachment),
                  if (expense.attachment?.evidence?.hasDetails == true) ...[
                    const SizedBox(height: 12),
                    _EvidenceDetails(attachment: expense.attachment!),
                  ],
                  const SizedBox(height: 16),
                  _StatusActionsSection(
                    expense: expense,
                    onExpenseChanged: onExpenseChanged,
                  ),
                  const SizedBox(height: 16),
                  _StatusHistoryPlaceholder(expense: expense),
                  if (showExpenseHistoryPremiumHint) ...[
                    const SizedBox(height: 12),
                    PremiumDiscoveryCard(
                      point: PremiumDiscoveryPoint.expenseHistory,
                      onDismiss: onPremiumHintDismissed,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExpenseVisibilityBadge extends StatelessWidget {
  const _ExpenseVisibilityBadge({required this.visibility});

  final ExpenseVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final color = visibility == ExpenseVisibility.privateAuthor
        ? Colors.deepPurple
        : Theme.of(context).colorScheme.primary;
    return Semantics(
      container: true,
      label: 'Widocznosc kosztu: ${visibility.label}',
      child: ExcludeSemantics(
        child: Chip(
          avatar: Icon(Icons.visibility_outlined, color: color, size: 18),
          label: Text(visibility.label),
          side: BorderSide(color: color.withValues(alpha: 0.32)),
          backgroundColor: color.withValues(alpha: 0.1),
          labelStyle: TextStyle(color: color),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _ExpenseStatusPanel extends StatelessWidget {
  const _ExpenseStatusPanel({required this.status});

  final ExpenseStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.accentColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExpenseStatusBadge(status: status),
            const SizedBox(height: 8),
            Text(status.description),
          ],
        ),
      ),
    );
  }
}

class _ExpenseStatusBadge extends StatelessWidget {
  const _ExpenseStatusBadge({required this.status});

  final ExpenseStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.accentColor;
    return Semantics(
      container: true,
      label: 'Status kosztu: ${status.label}',
      child: ExcludeSemantics(
        child: Chip(
          avatar: Icon(status.icon, color: color, size: 18),
          label: Text(status.label),
          side: BorderSide(color: color.withValues(alpha: 0.32)),
          backgroundColor: color.withValues(alpha: 0.1),
          labelStyle: TextStyle(color: color),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _StatusActionsSection extends StatelessWidget {
  const _StatusActionsSection({
    required this.expense,
    required this.onExpenseChanged,
  });

  final ExpenseEntry expense;
  final ValueChanged<ExpenseEntry>? onExpenseChanged;

  @override
  Widget build(BuildContext context) {
    final isAuthor = expense.paidBy.isCurrentUser;
    final actions = _actionsForCurrentUser(isAuthor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Akcje', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          isAuthor ? 'Twoja rola: autor kosztu' : 'Twoja rola: drugi rodzic',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        _ActionGroup(
          actions: actions,
          onSelected: onExpenseChanged == null
              ? null
              : (action) => _applyAction(context, action),
        ),
      ],
    );
  }

  List<_StatusAction> _actionsForCurrentUser(bool isAuthor) {
    switch (expense.status) {
      case ExpenseStatus.pending:
        if (isAuthor) {
          return const [
            _StatusAction(
              label: 'Edytuj koszt',
              icon: Icons.edit_outlined,
              targetStatus: ExpenseStatus.pending,
            ),
          ];
        }
        return const [
          _StatusAction(
            label: 'Zaakceptuj koszt',
            icon: Icons.check_circle_outline,
            targetStatus: ExpenseStatus.accepted,
          ),
          _StatusAction(
            label: 'Oznacz jako sporne',
            icon: Icons.report_problem_outlined,
            targetStatus: ExpenseStatus.disputed,
            requiresComment: true,
          ),
        ];
      case ExpenseStatus.accepted:
        return const [
          _StatusAction(
            label: 'Oznacz jako rozliczone',
            icon: Icons.task_alt_outlined,
            targetStatus: ExpenseStatus.settled,
          ),
        ];
      case ExpenseStatus.disputed:
        if (isAuthor) {
          return const [
            _StatusAction(
              label: 'Dodaj korekte po wyjasnieniu',
              icon: Icons.edit_note_outlined,
              targetStatus: ExpenseStatus.disputed,
            ),
          ];
        }
        return const [
          _StatusAction(
            label: 'Potwierdz po wyjasnieniu',
            icon: Icons.check_circle_outline,
            targetStatus: ExpenseStatus.accepted,
          ),
        ];
      case ExpenseStatus.settled:
        return const [];
    }
  }

  Future<void> _applyAction(BuildContext context, _StatusAction action) async {
    if (action.targetStatus == expense.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edycja kosztu zostanie dodana osobno.')),
      );
      return;
    }

    final comment = action.requiresComment
        ? await _askForDisputeComment(context)
        : null;
    if (!context.mounted) {
      return;
    }
    if (action.requiresComment && comment == null) {
      return;
    }
    if (!_isStatusTransitionAllowed(action.targetStatus, comment: comment)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ta zmiana statusu nie jest dostepna.')),
      );
      return;
    }

    onExpenseChanged!(
      expense.copyWith(status: action.targetStatus, statusComment: comment),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status zmieniony: ${action.targetStatus.label}.'),
      ),
    );
  }

  bool _isStatusTransitionAllowed(
    ExpenseStatus targetStatus, {
    String? comment,
  }) {
    final actor = expense.paidBy.isCurrentUser
        ? domain.ExpenseStatusActor.author
        : domain.ExpenseStatusActor.counterparty;
    return domain.canTransitionExpenseStatus(
      domain.ExpenseStatusTransition(
        from: expense.status.toDomainStatus(),
        to: targetStatus.toDomainStatus(),
        actor: actor,
        comment: comment,
      ),
    );
  }

  Future<String?> _askForDisputeComment(BuildContext context) async {
    var comment = '';
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Komentarz do sporu'),
          content: TextField(
            key: const Key('expense-dispute-comment'),
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            onChanged: (value) => comment = value,
            decoration: const InputDecoration(
              labelText: 'Co wymaga wyjasnienia?',
              hintText: 'Np. brakuje potwierdzenia platnosci',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                final normalizedComment = comment.trim();
                if (normalizedComment.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(normalizedComment);
              },
              child: const Text('Zapisz spor'),
            ),
          ],
        );
      },
    );
  }
}

extension _ExpenseStatusDomainMapping on ExpenseStatus {
  domain.ExpenseStatus toDomainStatus() {
    switch (this) {
      case ExpenseStatus.pending:
        return domain.ExpenseStatus.pending;
      case ExpenseStatus.accepted:
        return domain.ExpenseStatus.accepted;
      case ExpenseStatus.disputed:
        return domain.ExpenseStatus.disputed;
      case ExpenseStatus.settled:
        return domain.ExpenseStatus.settled;
    }
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.actions, required this.onSelected});

  final List<_StatusAction> actions;
  final ValueChanged<_StatusAction>? onSelected;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.lock_outline),
        title: Text('Brak dostepnych akcji'),
        subtitle: Text('Ten status nie pozwala na kolejna akcje w MVP.'),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final action in actions)
          OutlinedButton.icon(
            onPressed: onSelected == null ? null : () => onSelected!(action),
            icon: Icon(action.icon),
            label: Text(action.label),
          ),
      ],
    );
  }
}

class _StatusAction {
  const _StatusAction({
    required this.label,
    required this.icon,
    required this.targetStatus,
    this.requiresComment = false,
  });

  final String label;
  final IconData icon;
  final ExpenseStatus targetStatus;
  final bool requiresComment;
}

class _StatusHistoryPlaceholder extends StatelessWidget {
  const _StatusHistoryPlaceholder({required this.expense});

  final ExpenseEntry expense;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history_outlined),
      title: const Text('Historia statusu'),
      subtitle: Text(
        [
          expense.status.historyPlaceholder,
          if (expense.statusComment != null)
            'Komentarz: ${expense.statusComment}',
        ].join('\n'),
      ),
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
        subtitle: Text(
          '${attachment.errorMessage ?? attachment.fileName} Koszt zostal zapisany.',
        ),
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
      subtitle: Text(
        [
          if (attachment.evidence?.type != null)
            'Typ dowodu: ${attachment.evidence!.type!.label}',
          attachment.storagePath == null
              ? 'Plik zapisany.'
              : 'Upload zakonczony: ${attachment.storagePath}',
        ].join(' • '),
      ),
    );
  }
}

class _EvidenceDetails extends StatelessWidget {
  const _EvidenceDetails({required this.attachment});

  final ExpenseAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final evidence = attachment.evidence;
    if (evidence == null || !evidence.hasDetails) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dowod kosztu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'To pomaga uporzadkowac dokumenty; nie jest porada prawna.',
            ),
            const SizedBox(height: 8),
            if (evidence.type != null)
              _DetailRow(label: 'Typ', value: evidence.type!.label),
            if (_hasValue(evidence.documentDate))
              _DetailRow(label: 'Data dok.', value: evidence.documentDate!),
            if (_hasValue(evidence.merchant))
              _DetailRow(label: 'Wystawca', value: evidence.merchant!),
            if (_hasValue(evidence.documentNumber))
              _DetailRow(label: 'Numer', value: evidence.documentNumber!),
            if (_hasValue(evidence.paymentMethod))
              _DetailRow(label: 'Platnosc', value: evidence.paymentMethod!),
            if (evidence.buyerNamePresent != null)
              _DetailRow(
                label: 'Kupujacy',
                value: evidence.buyerNamePresent!
                    ? 'Jest na dokumencie'
                    : 'Nie zaznaczono',
              ),
          ],
        ),
      ),
    );
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
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
