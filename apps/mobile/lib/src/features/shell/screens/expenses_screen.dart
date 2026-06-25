import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kidcost_domain/domain.dart' as domain;

import '../../../telemetry/app_telemetry.dart';
import '../../child_info/child_info_models.dart';
import '../../expenses/expense_models.dart';
import '../../expenses/expense_visuals.dart';
import '../../premium/premium_discovery.dart';

enum _ExpenseSort { newest, oldest, highestAmount, lowestAmount }

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({
    required this.expenses,
    this.isLoading = false,
    this.errorMessage,
    this.initialFilterRequest,
    this.currentDate,
    this.showExpenseHistoryPremiumHint = false,
    this.showHistoricalImportPremiumHint = false,
    this.telemetry = const NoopTelemetry(),
    this.onExpenseChanged,
    this.onPremiumHintDismissed,
    super.key,
  });

  final List<ExpenseEntry> expenses;
  final bool isLoading;
  final String? errorMessage;
  final ExpenseListFilterRequest? initialFilterRequest;
  final DateTime? currentDate;
  final bool showExpenseHistoryPremiumHint;
  final bool showHistoricalImportPremiumHint;
  final AppTelemetry telemetry;
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
  bool _showOverdueReimbursements = false;
  bool _showHistoricalImportPreview = false;
  _ExpenseSort _sort = _ExpenseSort.newest;

  void _openHistoricalImportPreview() {
    setState(() => _showHistoricalImportPreview = true);
    unawaited(
      widget.telemetry.track(
        TelemetryEvent.historicalImportPreviewed,
        parameters: _historicalImportTelemetryProperties(),
      ),
    );
  }

  Map<String, Object> _historicalImportTelemetryProperties() {
    const preview = HistoricalImportPreview.sample;
    return {
      'import_type': 'csv_preview',
      'import_row_count': preview.rows.length,
      'import_file_count': preview.batchReceiptFileCount,
      'import_error_count': preview.validationErrorCount,
      'import_duplicate_count': preview.duplicateWarningCount,
      'draft_expense_count': preview.draftExpenseCount,
      'feature': 'historical_import',
      'surface': 'expenses',
    };
  }

  @override
  void initState() {
    super.initState();
    _applyFilterRequest(widget.initialFilterRequest);
  }

  @override
  void didUpdateWidget(covariant ExpensesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
      widget.initialFilterRequest,
      oldWidget.initialFilterRequest,
    )) {
      _applyFilterRequest(widget.initialFilterRequest);
    }
  }

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

    final activeDrafts = _activeDrafts();
    final submittedExpenses = _submittedExpenses();

    if (submittedExpenses.isEmpty && activeDrafts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HistoricalImportActivationCard(
            showPremiumHint: widget.showHistoricalImportPremiumHint,
            showPreview: _showHistoricalImportPreview,
            onPreview: _openHistoricalImportPreview,
            onCancelPreview: () {
              setState(() => _showHistoricalImportPreview = false);
            },
            onPremiumHintDismissed: () => widget.onPremiumHintDismissed?.call(
              PremiumDiscoveryPoint.historicalImport,
            ),
          ),
          const SizedBox(height: 12),
          const _EmptyExpensesTile(
            title: 'Brak kosztow',
            subtitle: 'Lista bedzie pokazywac koszty, statusy i zalaczniki.',
          ),
        ],
      );
    }

    final filteredExpenses = _filteredAndSortedExpenses();
    final now = widget.currentDate ?? DateTime.now();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeDrafts.isNotEmpty) ...[
          _DraftInboxCard(
            drafts: activeDrafts,
            onExpenseChanged: widget.onExpenseChanged,
          ),
          const SizedBox(height: 16),
        ],
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
              now: now,
              onExpenseChanged: widget.onExpenseChanged,
              showExpenseHistoryPremiumHint:
                  widget.showExpenseHistoryPremiumHint,
              onPremiumHintDismissed: () => widget.onPremiumHintDismissed?.call(
                PremiumDiscoveryPoint.expenseHistory,
              ),
            ),
        if (widget.showHistoricalImportPremiumHint ||
            _showHistoricalImportPreview) ...[
          const SizedBox(height: 12),
          _HistoricalImportActivationCard(
            showPremiumHint: widget.showHistoricalImportPremiumHint,
            showPreview: _showHistoricalImportPreview,
            onPreview: _openHistoricalImportPreview,
            onCancelPreview: () {
              setState(() => _showHistoricalImportPreview = false);
            },
            onPremiumHintDismissed: () => widget.onPremiumHintDismissed?.call(
              PremiumDiscoveryPoint.historicalImport,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    final submittedExpenses = _submittedExpenses();
    final months = _uniqueValues(
      submittedExpenses.map((expense) => _monthFromDate(expense.expenseDate)),
    );
    final children = _uniqueValues(
      submittedExpenses.map((expense) => expense.childName),
    );
    final payers = _uniqueValues(
      submittedExpenses.map((expense) => expense.paidBy.label),
    );
    final hasFilters =
        _monthFilter != null ||
        _childFilter != null ||
        _categoryFilter != null ||
        _statusFilter != null ||
        _payerFilter != null ||
        _showOverdueReimbursements;

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
              initiallyExpanded: _showOverdueReimbursements,
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
                SwitchListTile(
                  key: const Key('expense-overdue-filter'),
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.pending_actions_outlined),
                  title: const Text('Po terminie'),
                  subtitle: const Text(
                    'Pokaz tylko prosby, ktorych otwarty termin juz minal.',
                  ),
                  value: _showOverdueReimbursements,
                  onChanged: (value) {
                    setState(() => _showOverdueReimbursements = value);
                  },
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
    final filtered = _submittedExpenses().where((expense) {
      final month = _monthFromDate(expense.expenseDate);
      return (_monthFilter == null || month == _monthFilter) &&
          (_childFilter == null || expense.childName == _childFilter) &&
          (_categoryFilter == null || expense.category.id == _categoryFilter) &&
          (_statusFilter == null || expense.status == _statusFilter) &&
          (_payerFilter == null || expense.paidBy.label == _payerFilter) &&
          (!_showOverdueReimbursements ||
              (expense.reimbursementDeadlines?.isOverdue(
                    widget.currentDate ?? DateTime.now(),
                  ) ==
                  true));
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

  List<ExpenseEntry> _activeDrafts() {
    return widget.expenses
        .where((expense) => expense.isPrivateDraft && !expense.isArchivedDraft)
        .toList()
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
  }

  List<ExpenseEntry> _submittedExpenses() {
    return widget.expenses
        .where((expense) => !expense.isPrivateDraft && !expense.isArchivedDraft)
        .toList();
  }

  void _clearFilters() {
    setState(() {
      _monthFilter = null;
      _childFilter = null;
      _categoryFilter = null;
      _statusFilter = null;
      _payerFilter = null;
      _showOverdueReimbursements = false;
    });
  }

  void _applyFilterRequest(ExpenseListFilterRequest? request) {
    if (request == null) {
      return;
    }
    _monthFilter = request.month;
    _childFilter = request.childName;
    _categoryFilter = request.categoryId;
    _statusFilter = request.status;
    _payerFilter = request.payerLabel;
    _showOverdueReimbursements = request.showOverdueReimbursements;
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

class HistoricalImportPreview {
  const HistoricalImportPreview({
    required this.rows,
    required this.batchReceiptFileCount,
  });

  final List<HistoricalImportDraftRow> rows;
  final int batchReceiptFileCount;

  int get validationErrorCount =>
      rows.where((row) => row.validationError != null).length;

  int get duplicateWarningCount =>
      rows.where((row) => row.duplicateWarning != null).length;

  int get draftExpenseCount => rows.where((row) => row.canBecomeDraft).length;

  static const sample = HistoricalImportPreview(
    batchReceiptFileCount: 2,
    rows: [
      HistoricalImportDraftRow(
        sourceRow: 1,
        mappedDate: '2026-05-04',
        mappedAmount: '84,20 PLN',
        mappedCategory: 'Szkola/przedszkole',
        statusLabel: 'Szkic do potwierdzenia',
      ),
      HistoricalImportDraftRow(
        sourceRow: 2,
        mappedDate: '2026-05-05',
        mappedAmount: '129,00 PLN',
        mappedCategory: 'Lekarze i leki',
        statusLabel: 'Wymaga sprawdzenia',
        duplicateWarning: 'Mozliwy duplikat: Apteka z 2026-05-05.',
      ),
      HistoricalImportDraftRow(
        sourceRow: 3,
        mappedDate: '',
        mappedAmount: 'brak kwoty',
        mappedCategory: 'Inne',
        statusLabel: 'Blad walidacji',
        validationError: 'Brakuje daty albo kwoty.',
      ),
    ],
  );
}

class HistoricalImportDraftRow {
  const HistoricalImportDraftRow({
    required this.sourceRow,
    required this.mappedDate,
    required this.mappedAmount,
    required this.mappedCategory,
    required this.statusLabel,
    this.validationError,
    this.duplicateWarning,
  });

  final int sourceRow;
  final String mappedDate;
  final String mappedAmount;
  final String mappedCategory;
  final String statusLabel;
  final String? validationError;
  final String? duplicateWarning;

  bool get canBecomeDraft => validationError == null;
}

class _DraftInboxCard extends StatelessWidget {
  const _DraftInboxCard({required this.drafts, required this.onExpenseChanged});

  final List<ExpenseEntry> drafts;
  final ValueChanged<ExpenseEntry>? onExpenseChanged;

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
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Needs review'),
              subtitle: const Text(
                'Prywatne szkice nie zmieniaja salda, raportow ani widocznosci drugiego rodzica.',
              ),
              trailing: Chip(label: Text('${drafts.length}')),
            ),
            for (final draft in drafts) ...[
              const Divider(height: 16),
              _DraftInboxRow(
                draft: draft,
                onMarkReviewed: onExpenseChanged == null
                    ? null
                    : () => onExpenseChanged!(
                        draft.copyWith(clearDraftReview: true),
                      ),
                onArchive: onExpenseChanged == null
                    ? null
                    : () => _confirmArchive(context, draft),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext context, ExpenseEntry draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archiwizowac szkic?'),
        content: const Text(
          'Szkic zniknie z listy potrzebujacej sprawdzenia. Zalacznik nie zostanie wyslany ani udostepniony.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archiwizuj'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final review = draft.draftReview;
    if (review == null) {
      return;
    }
    onExpenseChanged?.call(
      draft.copyWith(
        draftReview: review.copyWith(archivedAt: DateTime.now().toUtc()),
      ),
    );
  }
}

class _DraftInboxRow extends StatelessWidget {
  const _DraftInboxRow({
    required this.draft,
    required this.onMarkReviewed,
    required this.onArchive,
  });

  final ExpenseEntry draft;
  final VoidCallback? onMarkReviewed;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final review = draft.draftReview!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text(draft.title),
          subtitle: Text(
            [
              review.primaryIssue.label,
              review.primaryIssue.helper,
              'Captured: ${_formatDraftDate(review.capturedAt)}',
              if (draft.attachment != null)
                draft.attachment!.status == AttachmentStatus.uploaded
                    ? 'Attachment ready'
                    : 'Attachment blocked',
            ].join('\n'),
          ),
          trailing: Text(formatCents(draft.amountCents)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: onMarkReviewed,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Mark reviewed'),
            ),
            OutlinedButton.icon(
              onPressed: onArchive,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive'),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDraftDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

class _HistoricalImportActivationCard extends StatelessWidget {
  const _HistoricalImportActivationCard({
    required this.showPremiumHint,
    required this.showPreview,
    required this.onPreview,
    required this.onCancelPreview,
    required this.onPremiumHintDismissed,
  });

  final bool showPremiumHint;
  final bool showPreview;
  final VoidCallback onPreview;
  final VoidCallback onCancelPreview;
  final VoidCallback onPremiumHintDismissed;

  @override
  Widget build(BuildContext context) {
    const preview = HistoricalImportPreview.sample;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Import historycznych kosztow'),
              subtitle: const Text(
                'CSV, arkusze i batch paragonow zaczynaja jako szkice do potwierdzenia.',
              ),
            ),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Free: 3 wiersze preview')),
                Chip(label: Text('Trial/Premium: bulk import')),
                Chip(label: Text('Manualny koszt zostaje free')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mapowanie MVP: data, kwota, waluta, placacy, dziecko, kategoria, merchant, notatka, status i referencja zalacznika.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (showPremiumHint) ...[
              const SizedBox(height: 8),
              PremiumDiscoveryCard(
                point: PremiumDiscoveryPoint.historicalImport,
                compact: true,
                onDismiss: onPremiumHintDismissed,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('historical-import-preview-button'),
                  onPressed: onPreview,
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Podglad importu CSV'),
                ),
                if (showPreview)
                  TextButton.icon(
                    key: const Key('historical-import-cancel-button'),
                    onPressed: onCancelPreview,
                    icon: const Icon(Icons.undo_outlined),
                    label: const Text('Anuluj preview'),
                  ),
              ],
            ),
            if (showPreview) ...[
              const SizedBox(height: 12),
              _HistoricalImportPreviewPanel(preview: preview),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoricalImportPreviewPanel extends StatelessWidget {
  const _HistoricalImportPreviewPanel({required this.preview});

  final HistoricalImportPreview preview;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Preview importu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Nie zapisujemy finalnych kosztow bez potwierdzenia. Popraw bledy albo anuluj preview, zeby wrocic bez zmian.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('${preview.rows.length} wiersze')),
                Chip(label: Text('${preview.draftExpenseCount} szkice')),
                Chip(
                  label: Text(
                    '${preview.batchReceiptFileCount} pliki paragonow',
                  ),
                ),
                Chip(label: Text('${preview.validationErrorCount} bledy')),
                Chip(
                  label: Text(
                    '${preview.duplicateWarningCount} ostrzezenia duplikatu',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final row in preview.rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text(row.sourceRow.toString())),
                title: Text(row.statusLabel),
                subtitle: Text(
                  [
                    if (row.mappedDate.isNotEmpty) row.mappedDate,
                    row.mappedAmount,
                    row.mappedCategory,
                    if (row.duplicateWarning != null) row.duplicateWarning!,
                    if (row.validationError != null) row.validationError!,
                  ].join(' • '),
                ),
              ),
            Builder(
              builder: (context) {
                return OutlinedButton.icon(
                  key: const Key('historical-import-draft-button'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Utworzono by szkice do potwierdzenia, nie finalne koszty.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Utworz szkice do potwierdzenia'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.now,
    required this.onExpenseChanged,
    required this.showExpenseHistoryPremiumHint,
    required this.onPremiumHintDismissed,
  });

  final ExpenseEntry expense;
  final DateTime now;
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
                'Data platnosci: ${expense.expenseDate}',
                if (expense.hasServicePeriod)
                  'Okres uslugi: ${expense.servicePeriod!.summaryLabel}',
                'Zaplacil: ${expense.paidBy.label}',
                if (expense.paidBy.isManual) 'platnik bez konta',
                expense.visibility.label,
                if (expense.sourceTemplateName != null)
                  'Szablon: ${expense.sourceTemplateName}',
                if (expense.originalReceiptAmountLabel != null)
                  'Paragon: ${expense.originalReceiptAmountLabel}',
                if (expense.attachment != null)
                  expense.attachment!.status == AttachmentStatus.uploaded
                      ? 'Zalacznik: ${expense.attachment!.fileName}'
                      : 'Zalacznik: blad uploadu',
                if (expense.attachment?.evidence?.type != null)
                  'Dowod: ${expense.attachment!.evidence!.type!.label}',
                if (expense.isPayProviderRequest)
                  'Platnosc do dostawcy: ${expense.providerPayment!.providerName}',
                if (expense.hasReimbursementDeadlines)
                  'Termin: ${_deadlineTimingLabel(expense, now)}',
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
                if (expense.status == ExpenseStatus.disputed &&
                    expense.disputeDetails != null)
                  _DisputeReasonBadge(details: expense.disputeDetails!),
                _ExpenseVisibilityBadge(visibility: expense.visibility),
                if (expense.isPayProviderRequest)
                  _ProviderPaymentBadge(details: expense.providerPayment!),
                if (expense.hasReimbursementDeadlines)
                  _ReimbursementDeadlineBadge(expense: expense, now: now),
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
                  _ExpenseStatusPanel(expense: expense),
                  if (expense.isPayProviderRequest) ...[
                    const SizedBox(height: 12),
                    _ProviderPaymentPanel(details: expense.providerPayment!),
                  ],
                  if (expense.hasReimbursementDeadlines) ...[
                    const SizedBox(height: 12),
                    _ReimbursementDeadlinePanel(expense: expense, now: now),
                  ],
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Nazwa', value: expense.title),
                  _DetailRow(
                    label: 'Kwota rozliczenia',
                    value: expense.isPayProviderRequest
                        ? '${formatCents(expense.amountCents)} (kontekst kosztu)'
                        : formatCents(expense.amountCents),
                  ),
                  if (expense.hasLineItems) ...[
                    const SizedBox(height: 8),
                    _ExpenseLineItemsDetails(expense: expense),
                  ],
                  if (expense.hasMedicalPacket) ...[
                    const SizedBox(height: 8),
                    _MedicalExpensePacketDetails(
                      packet: expense.medicalPacket!,
                    ),
                  ],
                  if (expense.originalReceiptAmountLabel != null)
                    _DetailRow(
                      label: 'Kwota na paragonie',
                      value:
                          '${expense.originalReceiptAmountLabel} (informacyjnie, bez przeliczenia kursu)',
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
                  _DetailRow(
                    label: 'Data platnosci',
                    value: expense.expenseDate,
                  ),
                  if (expense.hasServicePeriod)
                    _ServicePeriodDetails(period: expense.servicePeriod!),
                  if (expense.childInfoCard != null) ...[
                    const SizedBox(height: 8),
                    _ChildInfoCardContext(link: expense.childInfoCard!),
                  ],
                  if (expense.relatedExpense != null) ...[
                    const SizedBox(height: 8),
                    _RelatedRecordsSection(link: expense.relatedExpense!),
                  ],
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
                  if (expense.verification?.hasDetails == true) ...[
                    const SizedBox(height: 12),
                    _EvidenceDetails(
                      title: 'Pola weryfikacyjne',
                      evidence: expense.verification!,
                    ),
                  ],
                  if (expense.attachment?.evidence?.hasDetails == true) ...[
                    const SizedBox(height: 12),
                    _EvidenceDetails(
                      title: 'Dowod kosztu',
                      evidence: expense.attachment!.evidence!,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _StatusActionsSection(
                    expense: expense,
                    onExpenseChanged: onExpenseChanged,
                  ),
                  const SizedBox(height: 16),
                  _ReimbursementComposerSection(expense: expense),
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

  static String _deadlineTimingLabel(ExpenseEntry expense, DateTime now) {
    final state = expense.reimbursementDeadlines?.timingState(now: now);
    return reimbursementDeadlineTimingLabelFor(state);
  }
}

String reimbursementDeadlineTimingLabelFor(
  domain.ReimbursementDeadlineTimingState? state,
) {
  switch (state) {
    case domain.ReimbursementDeadlineTimingState.dueSoon:
      return 'Termin blisko';
    case domain.ReimbursementDeadlineTimingState.overdue:
      return 'Po terminie';
    case domain.ReimbursementDeadlineTimingState.paidOnTime:
      return 'Zaplacone w terminie';
    case domain.ReimbursementDeadlineTimingState.paidAfterDueDate:
      return 'Zaplacone po terminie';
    case domain.ReimbursementDeadlineTimingState.noDates:
    case null:
      return 'Bez terminu';
  }
}

class _ServicePeriodDetails extends StatelessWidget {
  const _ServicePeriodDetails({required this.period});

  final ExpenseServicePeriod period;

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
              leading: Icon(Icons.date_range_outlined),
              title: Text('Okres i zakres uslugi'),
              subtitle: Text(
                'To opisuje, co pokrywa koszt. Nie zmienia statusu akceptacji.',
              ),
            ),
            if (period.startDate != null)
              _DetailRow(label: 'Poczatek', value: period.startDate!),
            if (period.endDate != null)
              _DetailRow(label: 'Koniec', value: period.endDate!),
            if (period.quantityLabel != null)
              _DetailRow(label: 'Ilosc', value: period.quantityLabel!),
            if (period.scopeNote != null)
              _DetailRow(label: 'Zakres', value: period.scopeNote!),
          ],
        ),
      ),
    );
  }
}

class _ExpenseLineItemsDetails extends StatelessWidget {
  const _ExpenseLineItemsDetails({required this.expense});

  final ExpenseEntry expense;

  @override
  Widget build(BuildContext context) {
    final differenceCents = expense.lineItemsDifferenceCents;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.splitscreen_outlined),
              title: const Text('Pozycje rachunku'),
              subtitle: Text(
                'Suma ${formatCents(expense.lineItemsTotalCents)}, reimbursable ${formatCents(expense.lineItemsReimbursableCents)}.',
              ),
            ),
            if (differenceCents != 0)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.warning_amber_outlined),
                title: const Text('Roznica do wyjasnienia'),
                subtitle: Text(formatCents(differenceCents.abs())),
              ),
            for (final item in expense.lineItems)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.isReimbursable
                      ? Icons.check_circle_outline
                      : Icons.remove_circle_outline,
                ),
                title: Text(item.description),
                subtitle: Text(
                  '${item.childName} - ${item.category.label} - ${item.splitLabel}',
                ),
                trailing: Text(item.amountLabel),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProviderPaymentBadge extends StatelessWidget {
  const _ProviderPaymentBadge({required this.details});

  final ProviderPaymentDetails details;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Platnosc dostawcy: ${details.status.label}',
      child: ExcludeSemantics(
        child: Chip(
          avatar: Icon(
            Icons.storefront_outlined,
            color: Theme.of(context).colorScheme.secondary,
            size: 18,
          ),
          label: Text(details.status.label),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.32),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
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

class _ProviderPaymentPanel extends StatelessWidget {
  const _ProviderPaymentPanel({required this.details});

  final ProviderPaymentDetails details;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProviderPaymentBadge(details: details),
            const SizedBox(height: 8),
            Text(
              'Prosba kieruje platnosc do dostawcy, nie jako zwrot gotowki dla rodzica. KidCost zapisuje status, ale nie waliduje rachunku.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _DetailRow(label: 'Dostawca', value: details.providerName),
            _DetailRow(
              label: 'Kwota do dostawcy',
              value: details.amountDueLabel,
            ),
            _DetailRow(label: 'Termin dostawcy', value: details.dueDate),
            if (details.paymentReference?.isNotEmpty == true)
              _DetailRow(
                label: 'Tytul/notatka',
                value: details.paymentReference!,
              ),
          ],
        ),
      ),
    );
  }
}

class _MedicalExpensePacketDetails extends StatelessWidget {
  const _MedicalExpensePacketDetails({required this.packet});

  final MedicalExpensePacket packet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pakiet medyczny / EOB',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Kontekst medyczny porzadkuje rachunek, EOB i kwote pacjenta; KidCost nie ocenia ubezpieczenia ani uprawnien prawnych.',
            ),
            const SizedBox(height: 8),
            if (_hasValue(packet.serviceDate))
              _DetailRow(label: 'Data uslugi', value: packet.serviceDate!),
            if (_hasValue(packet.providerName))
              _DetailRow(label: 'Dostawca', value: packet.providerName!),
            if (_hasValue(packet.patientName))
              _DetailRow(label: 'Pacjent', value: packet.patientName!),
            if (packet.grossBilledLabel != null)
              _DetailRow(
                label: 'Kwota brutto',
                value: packet.grossBilledLabel!,
              ),
            if (packet.coveredAmountLabel != null)
              _DetailRow(label: 'Pokryte', value: packet.coveredAmountLabel!),
            if (packet.patientResponsibilityLabel != null)
              _DetailRow(
                label: 'Odpowiedzialnosc pacjenta',
                value: packet.patientResponsibilityLabel!,
              ),
            _DetailRow(
              label: 'Proszone do zwrotu',
              value: packet.requestedReimbursementLabel,
            ),
            if (!packet.isResponsibilityConsistent)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline),
                title: Text('Kwoty wymagaja sprawdzenia'),
                subtitle: Text(
                  'Kwota brutto minus pokrycie nie zgadza sie z odpowiedzialnoscia pacjenta.',
                ),
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

class _ReimbursementDeadlineBadge extends StatelessWidget {
  const _ReimbursementDeadlineBadge({required this.expense, required this.now});

  final ExpenseEntry expense;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final state = expense.reimbursementDeadlines?.timingState(now: now);
    final color = switch (state) {
      domain.ReimbursementDeadlineTimingState.overdue => Theme.of(
        context,
      ).colorScheme.error,
      domain.ReimbursementDeadlineTimingState.dueSoon => Colors.amber.shade800,
      domain.ReimbursementDeadlineTimingState.paidOnTime => Colors.green,
      domain.ReimbursementDeadlineTimingState.paidAfterDueDate =>
        Colors.deepOrange,
      _ => Theme.of(context).colorScheme.primary,
    };
    final label = reimbursementDeadlineTimingLabelFor(state);
    return Semantics(
      container: true,
      label: 'Termin zwrotu: $label',
      child: ExcludeSemantics(
        child: Chip(
          avatar: Icon(Icons.pending_actions_outlined, color: color, size: 18),
          label: Text(label),
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
  const _ExpenseStatusPanel({required this.expense});

  final ExpenseEntry expense;

  @override
  Widget build(BuildContext context) {
    final status = expense.status;
    final color = status.accentColor;
    final disputeDetails = expense.disputeDetails;
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
            if (status == ExpenseStatus.disputed && disputeDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                disputeDetails.summaryText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: const Icon(Icons.task_alt_outlined, size: 18),
                  label: Text(disputeDetails.reason.responseCta),
                  onPressed: () {},
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DisputeReasonBadge extends StatelessWidget {
  const _DisputeReasonBadge({required this.details});

  final ExpenseDisputeDetails details;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Semantics(
      container: true,
      label: 'Powod sporu: ${details.reason.label}',
      child: ExcludeSemantics(
        child: Chip(
          avatar: Icon(Icons.rule_outlined, color: color, size: 18),
          label: Text('Spor: ${details.reason.label}'),
          side: BorderSide(color: color.withValues(alpha: 0.32)),
          backgroundColor: color.withValues(alpha: 0.1),
          labelStyle: TextStyle(color: color),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _ReimbursementDeadlinePanel extends StatelessWidget {
  const _ReimbursementDeadlinePanel({required this.expense, required this.now});

  final ExpenseEntry expense;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final deadlines = expense.reimbursementDeadlines;
    if (deadlines == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReimbursementDeadlineBadge(expense: expense, now: now),
            const SizedBox(height: 8),
            Text(
              'Daty pomagaja pilnowac ustalen rodziny. KidCost nie ocenia skutkow prawnych terminu.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Data zgloszenia',
              value: _formatDeadlineDate(deadlines.submittedAt),
            ),
            _DetailRow(
              label: 'Termin dokumentow',
              value: _formatDeadlineDate(deadlines.noticeDueAt),
            ),
            _DetailRow(
              label: 'Termin platnosci',
              value: _formatDeadlineDate(deadlines.paymentDueAt),
            ),
            _DetailRow(
              label: 'Data zaplaty',
              value: _formatDeadlineDate(deadlines.paidAt),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDeadlineDate(DateTime? date) {
  if (date == null) {
    return 'Nie ustawiono';
  }
  final utc = date.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${utc.month.toString().padLeft(2, '0')}-'
      '${utc.day.toString().padLeft(2, '0')}';
}

class _ChildInfoCardContext extends StatelessWidget {
  const _ChildInfoCardContext({required this.link});

  final ChildInfoCardLink link;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          link.isShared ? Icons.badge_outlined : Icons.lock_outline,
        ),
        title: Text('Kontekst dziecka: ${link.title}'),
        subtitle: Text(
          '${link.typeLabel} - karta ${link.visibilityLabel}. Tresc zostaje w profilu dziecka.',
        ),
      ),
    );
  }
}

class _RelatedRecordsSection extends StatelessWidget {
  const _RelatedRecordsSection({required this.link});

  final ExpenseRelatedRecordLink link;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.link_outlined),
        title: const Text('Related records'),
        subtitle: Text('${link.title}\n${link.summary}'),
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

    final disputeDetails = action.requiresComment
        ? await _askForDisputeDetails(context)
        : null;
    final comment = disputeDetails?.transitionComment;
    if (!context.mounted) {
      return;
    }
    if (action.requiresComment && disputeDetails == null) {
      return;
    }
    if (!_isStatusTransitionAllowed(action.targetStatus, comment: comment)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ta zmiana statusu nie jest dostepna.')),
      );
      return;
    }

    onExpenseChanged!(
      expense.copyWith(
        status: action.targetStatus,
        statusComment: comment,
        disputeDetails: disputeDetails,
        clearStatusComment: action.targetStatus != ExpenseStatus.disputed,
        clearDisputeDetails: action.targetStatus != ExpenseStatus.disputed,
      ),
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

  Future<ExpenseDisputeDetails?> _askForDisputeDetails(
    BuildContext context,
  ) async {
    var selectedReason = ExpenseDisputeReason.missingProof;
    var correctionRequest = '';
    var comment = '';
    return showModalBottomSheet<ExpenseDisputeDetails>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Powod sporu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Wybierz jeden konkretny powod, zeby druga strona wiedziala, co poprawic.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final reason in ExpenseDisputeReason.values)
                            ChoiceChip(
                              key: Key('expense-dispute-reason-${reason.id}'),
                              label: Text(reason.label),
                              selected: selectedReason == reason,
                              onSelected: (_) {
                                setModalState(() => selectedReason = reason);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('expense-dispute-request'),
                        minLines: 1,
                        maxLines: 2,
                        onChanged: (value) => correctionRequest = value,
                        decoration: InputDecoration(
                          labelText: 'O co prosisz?',
                          hintText: selectedReason.requestHint,
                          prefixIcon: const Icon(Icons.task_alt_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('expense-dispute-comment'),
                        minLines: 2,
                        maxLines: 4,
                        onChanged: (value) => comment = value,
                        decoration: const InputDecoration(
                          labelText: 'Dodatkowy komentarz (opcjonalnie)',
                          hintText: 'Krotko i rzeczowo, bez pelnego czatu',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Anuluj'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop(
                                ExpenseDisputeDetails(
                                  reason: selectedReason,
                                  correctionRequest:
                                      correctionRequest.trim().isEmpty
                                      ? null
                                      : correctionRequest.trim(),
                                  comment: comment.trim().isEmpty
                                      ? null
                                      : comment.trim(),
                                ),
                              );
                            },
                            child: const Text('Zapisz spor'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReimbursementComposerSection extends StatefulWidget {
  const _ReimbursementComposerSection({required this.expense});

  final ExpenseEntry expense;

  @override
  State<_ReimbursementComposerSection> createState() =>
      _ReimbursementComposerSectionState();
}

class _ReimbursementComposerSectionState
    extends State<_ReimbursementComposerSection> {
  late _ReimbursementMessageTemplate _selectedTemplate;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = _reimbursementTemplates.first;
    _messageController = TextEditingController(
      text: _selectedTemplate.messageFor(widget.expense),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final warnings = toneWarningsFor(_messageController.text);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_note_outlined),
              title: const Text('Neutralna prosba o zwrot'),
              subtitle: const Text(
                'Wybierz spokojny szablon, edytuj tresc i skopiuj dopiero po sprawdzeniu. KidCost nie wysyla tej wiadomosci automatycznie.',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final template in _reimbursementTemplates)
                  ChoiceChip(
                    label: Text(template.label),
                    selected: template == _selectedTemplate,
                    onSelected: (_) => _selectTemplate(template),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('reimbursement-message-preview'),
              controller: _messageController,
              minLines: 5,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Podglad wiadomosci',
                helperText: 'Mozesz zmienic kazde zdanie przed kopiowaniem.',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (warnings.isEmpty)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.check_circle_outline),
                title: Text('Ton wyglada neutralnie'),
                subtitle: Text(
                  'Sprawdzilismy tylko lokalne reguly interpunkcji i slow ryzyka.',
                ),
              )
            else
              for (final warning in warnings)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.warning_amber_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Sprawdz ton'),
                  subtitle: Text(warning),
                ),
            const SizedBox(height: 8),
            Text(
              'To nie jest porada prawna ani gwarancja odpowiedzi. KidCost nie zapisuje tresci wiadomosci w analityce.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('copy-reimbursement-message'),
              onPressed: () => _copyMessage(context),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Kopiuj wiadomosc'),
            ),
          ],
        ),
      ),
    );
  }

  void _selectTemplate(_ReimbursementMessageTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _messageController.text = template.messageFor(widget.expense);
    });
  }

  Future<void> _copyMessage(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _messageController.text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wiadomosc skopiowana do schowka.')),
    );
  }
}

@visibleForTesting
List<String> toneWarningsFor(String message) {
  final normalized = message.trim();
  if (normalized.isEmpty) {
    return const ['Wiadomosc jest pusta. Dodaj neutralna prosbe lub pytanie.'];
  }

  final lower = normalized.toLowerCase();
  final warnings = <String>[];
  if (normalized.contains('!!!') || normalized.contains('???')) {
    warnings.add('Usun nadmiar wykrzyknikow lub pytajnikow.');
  }
  if (RegExp(r'\b(musisz|natychmiast|oddaj|zaplac teraz)\b').hasMatch(lower)) {
    warnings.add('Zamien nakaz na spokojna prosbe o sprawdzenie kosztu.');
  }
  final lettersOnly = normalized.replaceAll(RegExp(r'[^A-Za-z]'), '');
  if (lettersOnly.length >= 12 && lettersOnly == lettersOnly.toUpperCase()) {
    warnings.add('Unikaj pisania calej wiadomosci wielkimi literami.');
  }
  return warnings;
}

const _reimbursementTemplates = [
  _ReimbursementMessageTemplate(
    label: 'Pierwsza prosba',
    buildMessage: _buildFirstRequestMessage,
  ),
  _ReimbursementMessageTemplate(
    label: 'Delikatne przypomnienie',
    buildMessage: _buildGentleReminderMessage,
  ),
  _ReimbursementMessageTemplate(
    label: 'Brak dowodu',
    buildMessage: _buildMissingReceiptMessage,
  ),
  _ReimbursementMessageTemplate(
    label: 'Termin platnosci',
    buildMessage: _buildDueDateReminderMessage,
  ),
];

class _ReimbursementMessageTemplate {
  const _ReimbursementMessageTemplate({
    required this.label,
    required this.buildMessage,
  });

  final String label;
  final String Function(ExpenseEntry expense) buildMessage;

  String messageFor(ExpenseEntry expense) => buildMessage(expense);
}

String _buildFirstRequestMessage(ExpenseEntry expense) {
  return [
    'Czesc, dodalem koszt "${expense.title}" za ${formatCents(expense.amountCents)}.',
    'Dotyczy: ${expense.childName}, ${expense.category.label}, data ${expense.expenseDate}.',
    'Prosze sprawdz, czy szczegoly i zalacznik wygladaja poprawnie.',
    'Jesli wszystko sie zgadza, daj prosze znac lub rozlicz swoj udzial.',
  ].join('\n');
}

String _buildGentleReminderMessage(ExpenseEntry expense) {
  return [
    'Czesc, przypominam spokojnie o koszcie "${expense.title}".',
    'W KidCost nadal ma status: ${expense.status.label}.',
    'Prosze zerknij, kiedy bedziesz miec chwile.',
  ].join('\n');
}

String _buildMissingReceiptMessage(ExpenseEntry expense) {
  final hasAttachment = expense.attachment?.status == AttachmentStatus.uploaded;
  return [
    'Czesc, chce uporzadkowac koszt "${expense.title}".',
    hasAttachment
        ? 'Zalacznik jest juz dodany, ale prosze sprawdz czy wystarcza do rozliczenia.'
        : 'Brakuje jeszcze dowodu kosztu, wiec prosze napisz, jaki dokument bedzie najlepszy do dolaczenia.',
    'Zalezy mi, zeby zapis byl jasny dla nas obojga.',
  ].join('\n');
}

String _buildDueDateReminderMessage(ExpenseEntry expense) {
  final dueDate = _formatDeadlineDate(
    expense.reimbursementDeadlines?.paymentDueAt,
  );
  return [
    'Czesc, wracam do kosztu "${expense.title}" za ${formatCents(expense.amountCents)}.',
    dueDate == 'Nie ustawiono'
        ? 'Nie mam tu ustawionego terminu platnosci, wiec prosze sprawdzmy wspolnie najblizszy wygodny termin.'
        : 'W KidCost termin platnosci jest zapisany jako $dueDate.',
    'Daj prosze znac, jesli cos wymaga korekty przed rozliczeniem.',
  ].join('\n');
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
          if (expense.disputeDetails != null)
            expense.disputeDetails!.summaryText,
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
  const _EvidenceDetails({required this.title, required this.evidence});

  final String title;
  final EvidenceMetadata evidence;

  @override
  Widget build(BuildContext context) {
    if (!evidence.hasDetails) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'To pomaga uporzadkowac dokumenty; nie jest porada prawna.',
            ),
            const SizedBox(height: 8),
            if (evidence.type != null)
              _DetailRow(label: 'Typ', value: evidence.type!.label),
            if (_hasValue(evidence.serviceDate))
              _DetailRow(label: 'Data uslugi', value: evidence.serviceDate!),
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
