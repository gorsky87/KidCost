import 'package:flutter/material.dart';

import '../../expenses/expense_models.dart';
import '../../expenses/proof_library_models.dart';

class ProofLibraryScreen extends StatefulWidget {
  const ProofLibraryScreen({
    required this.expenses,
    this.initialFilter = const ProofLibraryFilter(),
    this.reportedProofIds = const {},
    this.showReportInclusionState = false,
    super.key,
  });

  final List<ExpenseEntry> expenses;
  final ProofLibraryFilter initialFilter;
  final Set<String> reportedProofIds;
  final bool showReportInclusionState;

  @override
  State<ProofLibraryScreen> createState() => _ProofLibraryScreenState();
}

class _ProofLibraryScreenState extends State<ProofLibraryScreen> {
  late ProofLibraryFilter _filter = widget.initialFilter;
  late final TextEditingController _queryController = TextEditingController(
    text: widget.initialFilter.query,
  );

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = proofRecordsFromExpenses(widget.expenses);
    final filteredRecords = filterProofRecords(
      records: records,
      filter: _filter,
      reportedProofIds: widget.reportedProofIds,
    );
    final missingProofCount = widget.expenses.length - records.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Biblioteka dowodow',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Badge.count(
              count: filteredRecords.length,
              child: const Icon(Icons.folder_copy_outlined),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Szukaj paragonow, faktur, potwierdzen platnosci i PDF bez zmiany statusu kosztu.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _ProofFilterCard(
          records: records,
          filter: _filter,
          queryController: _queryController,
          showReportInclusionState: widget.showReportInclusionState,
          onChanged: (filter) => setState(() => _filter = filter),
          onClear: () {
            _queryController.clear();
            setState(() => _filter = const ProofLibraryFilter());
          },
        ),
        const SizedBox(height: 12),
        if (missingProofCount > 0) ...[
          _MissingProofsNotice(count: missingProofCount),
          const SizedBox(height: 12),
        ],
        if (records.isEmpty)
          _ProofEmptyState(
            title: 'Brak dowodow',
            subtitle: missingProofCount == 1
                ? '1 koszt nie ma jeszcze zalacznika ani metadanych dowodu.'
                : '$missingProofCount koszty nie maja jeszcze zalacznikow ani metadanych dowodu.',
          )
        else if (filteredRecords.isEmpty)
          _ProofEmptyState(
            title: 'Brak dowodow dla filtrow',
            subtitle: 'Zmien kryteria albo wyczysc filtry.',
            action: OutlinedButton.icon(
              onPressed: () {
                _queryController.clear();
                setState(() => _filter = const ProofLibraryFilter());
              },
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Wyczysc filtry'),
            ),
          )
        else
          for (final record in filteredRecords)
            _ProofRecordCard(
              record: record,
              includedInReport: widget.reportedProofIds.contains(record.id),
              showReportInclusionState: widget.showReportInclusionState,
            ),
      ],
    );
  }
}

class _ProofFilterCard extends StatelessWidget {
  const _ProofFilterCard({
    required this.records,
    required this.filter,
    required this.queryController,
    required this.showReportInclusionState,
    required this.onChanged,
    required this.onClear,
  });

  final List<ProofRecord> records;
  final ProofLibraryFilter filter;
  final TextEditingController queryController;
  final bool showReportInclusionState;
  final ValueChanged<ProofLibraryFilter> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final months = _uniqueValues(records.map((record) => record.month));
    final children = _uniqueValues(records.map((record) => record.childName));
    final categories =
        {
            for (final record in records) record.category.id: record.category,
          }.values.toList()
          ..sort((first, second) => first.label.compareTo(second.label));
    final evidenceTypes = {
      for (final record in records)
        if (record.evidenceType != null) record.evidenceType!,
    }.toList()..sort((first, second) => first.label.compareTo(second.label));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Filtry dowodow',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: filter.hasActiveFilters ? onClear : null,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Wyczysc'),
                ),
              ],
            ),
            TextField(
              key: const Key('proof-library-search-field'),
              controller: queryController,
              decoration: const InputDecoration(
                labelText: 'Szukaj po opisie, dostawcy lub numerze dokumentu',
                prefixIcon: Icon(Icons.search_outlined),
              ),
              onChanged: (query) => onChanged(filter.copyWith(query: query)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('proof-library-month-filter'),
              initialValue: filter.month,
              decoration: const InputDecoration(
                labelText: 'Miesiac',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                for (final month in months)
                  DropdownMenuItem(value: month, child: Text(month)),
              ],
              onChanged: (value) => onChanged(
                filter.copyWith(month: value, clearMonth: value == null),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('proof-library-child-filter'),
              initialValue: filter.childName,
              decoration: const InputDecoration(
                labelText: 'Dziecko',
                prefixIcon: Icon(Icons.child_care_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                for (final child in children)
                  DropdownMenuItem(value: child, child: Text(child)),
              ],
              onChanged: (value) => onChanged(
                filter.copyWith(
                  childName: value,
                  clearChildName: value == null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('proof-library-category-filter'),
              initialValue: filter.categoryId,
              decoration: const InputDecoration(
                labelText: 'Kategoria',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                for (final category in categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.label),
                  ),
              ],
              onChanged: (value) => onChanged(
                filter.copyWith(
                  categoryId: value,
                  clearCategoryId: value == null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseStatus>(
              key: const Key('proof-library-status-filter'),
              initialValue: filter.status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.verified_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                for (final status in ExpenseStatus.values)
                  DropdownMenuItem(value: status, child: Text(status.label)),
              ],
              onChanged: (value) => onChanged(
                filter.copyWith(status: value, clearStatus: value == null),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EvidenceType>(
              key: const Key('proof-library-type-filter'),
              initialValue: filter.evidenceType,
              decoration: const InputDecoration(
                labelText: 'Typ dowodu',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                for (final type in evidenceTypes)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: (value) => onChanged(
                filter.copyWith(
                  evidenceType: value,
                  clearEvidenceType: value == null,
                ),
              ),
            ),
            if (showReportInclusionState) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<bool>(
                key: const Key('proof-library-report-inclusion-filter'),
                initialValue: filter.includedInReport,
                decoration: const InputDecoration(
                  labelText: 'Stan w raporcie',
                  prefixIcon: Icon(Icons.library_add_check_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Wszystkie')),
                  DropdownMenuItem(
                    value: true,
                    child: Text('Uwzglednione w raporcie'),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text('Nieoznaczone w raporcie'),
                  ),
                ],
                onChanged: (value) => onChanged(
                  filter.copyWith(
                    includedInReport: value,
                    clearIncludedInReport: value == null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _uniqueValues(Iterable<String> values) {
    return values.toSet().toList()
      ..sort((first, second) => second.compareTo(first));
  }
}

class _MissingProofsNotice extends StatelessWidget {
  const _MissingProofsNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final subtitle = count == 1
        ? '1 koszt jest widoczny w historii, ale nie trafi do biblioteki dowodow, dopoki nie dostanie pliku albo metadanych dowodu.'
        : '$count koszty sa widoczne w historii, ale nie trafia do biblioteki dowodow, dopoki nie dostana pliku albo metadanych dowodu.';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('Brakujace dowody'),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _ProofRecordCard extends StatelessWidget {
  const _ProofRecordCard({
    required this.record,
    required this.includedInReport,
    required this.showReportInclusionState,
  });

  final ProofRecord record;
  final bool includedInReport;
  final bool showReportInclusionState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          record.hasUploadedAttachment
              ? Icons.attachment_outlined
              : Icons.warning_amber_outlined,
        ),
        title: Text(record.expenseTitle),
        subtitle: Text(
          [
            record.sourceLabel,
            record.childName,
            record.category.label,
            record.month,
            record.proofTypeLabel,
            record.attachmentStateLabel,
            if (showReportInclusionState)
              includedInReport
                  ? 'Uwzglednione w raporcie'
                  : 'Nieoznaczone w raporcie',
          ].join(' • '),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(record.amountLabel),
            const SizedBox(height: 4),
            Text(record.status.label),
          ],
        ),
      ),
    );
  }
}

class _ProofEmptyState extends StatelessWidget {
  const _ProofEmptyState({
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_off_outlined),
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
