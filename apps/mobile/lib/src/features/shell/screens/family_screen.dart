import 'package:flutter/material.dart';

import '../../child_info/child_info_models.dart';
import '../../expenses/expense_models.dart';
import '../../onboarding/onboarding_profile.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({
    required this.profile,
    this.childInfoCards = const [],
    this.customExpenseCategories = const [],
    this.onChildInfoCardsChanged,
    this.onCustomExpenseCategoriesChanged,
    super.key,
  });

  final OnboardingProfile profile;
  final List<ChildInfoCard> childInfoCards;
  final List<ExpenseCategory> customExpenseCategories;
  final ValueChanged<List<ChildInfoCard>>? onChildInfoCardsChanged;
  final ValueChanged<List<ExpenseCategory>>? onCustomExpenseCategoriesChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.home_outlined),
          title: Text(profile.familyName),
          subtitle: const Text('Aktywna rodzina kosztow.'),
        ),
        ListTile(
          leading: const Icon(Icons.child_care_outlined),
          title: Text(profile.childName),
          subtitle: Text(profile.childBirthDate ?? 'Data urodzenia niepodana.'),
        ),
        const Divider(),
        _ChildInfoCardsSection(
          cards: childInfoCards,
          onCardsChanged: onChildInfoCardsChanged,
        ),
        const Divider(),
        _FamilyExpenseCategoriesSection(
          categories: customExpenseCategories,
          onCategoriesChanged: onCustomExpenseCategoriesChanged,
        ),
        const Divider(),
        if (profile.isSoloFamily) ...[
          ListTile(
            leading: const Icon(Icons.lock_person_outlined),
            title: const Text('Tryb solo'),
            subtitle: Text(
              'Koszty solo sa prywatne dla autora. Reczna etykieta: ${profile.coParentLabel}.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.person_add_alt_1_outlined),
            title: Text('Pokaz podsumowanie i zapros wspolrodzica'),
            subtitle: Text(
              'Zaproszenie przygotujemy bez automatycznego udostepniania prywatnych notatek autora.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.account_tree_outlined),
            title: Text('Mapowanie po akceptacji'),
            subtitle: Text(
              'Reczna etykieta zostanie polaczona z prawdziwym kontem dopiero po potwierdzeniu uzytkownika.',
            ),
          ),
        ] else
          ListTile(
            leading: const Icon(Icons.mark_email_read_outlined),
            title: Text(profile.coParentEmail ?? 'Zaproszenie przygotowane'),
            subtitle: Text(
              'Kod ${profile.inviteCode} nie ujawnia danych rodzinnych przed akceptacja.',
            ),
          ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Backend zaproszen'),
          subtitle: const Text(
            'Wysylka email zostanie podlaczona po stronie Supabase.',
          ),
        ),
      ],
    );
  }
}

class _FamilyExpenseCategoriesSection extends StatelessWidget {
  const _FamilyExpenseCategoriesSection({
    required this.categories,
    required this.onCategoriesChanged,
  });

  final List<ExpenseCategory> categories;
  final ValueChanged<List<ExpenseCategory>>? onCategoriesChanged;

  @override
  Widget build(BuildContext context) {
    final activeCount = categories
        .where((category) => category.canBeUsedForNewExpense)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.category_outlined),
              title: const Text('Rodzinne kategorie kosztow'),
              subtitle: Text(
                activeCount == 0
                    ? 'Dodaj lokalne nazwy kategorii do formularza i filtrow.'
                    : 'Aktywne kategorie rodzinne: $activeCount.',
              ),
              trailing: IconButton(
                key: const Key('add-family-expense-category-button'),
                tooltip: 'Dodaj kategorie',
                onPressed: onCategoriesChanged == null
                    ? null
                    : () => _openEditor(context),
                icon: const Icon(Icons.add),
              ),
            ),
            if (categories.isEmpty)
              const Text(
                'Kategorie rodzinne pomagaja nazwac koszty po Waszemu; nie rozstrzygaja obowiazku zwrotu.',
              )
            else
              for (final category in categories)
                ListTile(
                  key: Key('family-expense-category-${category.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    category.isArchived
                        ? Icons.inventory_2_outlined
                        : Icons.label_outline,
                  ),
                  title: Text(category.label),
                  subtitle: Text(_subtitleFor(category)),
                  onTap: onCategoriesChanged == null
                      ? null
                      : () => _openEditor(context, category: category),
                  trailing: onCategoriesChanged == null || category.isArchived
                      ? null
                      : IconButton(
                          key: Key('archive-family-category-${category.id}'),
                          tooltip: 'Archiwizuj kategorie',
                          onPressed: () => _archive(category),
                          icon: const Icon(Icons.inventory_2_outlined),
                        ),
                ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onCategoriesChanged == null
                  ? null
                  : () => _openEditor(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Dodaj kategorie kosztu'),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(ExpenseCategory category) {
    final parts = <String>[
      if (category.reportGroup?.trim().isNotEmpty == true)
        'Grupa raportowa: ${category.reportGroup}',
      category.isArchived ? 'Archiwalna' : 'Widoczna w nowych kosztach',
    ];
    return parts.join(' - ');
  }

  Future<void> _openEditor(
    BuildContext context, {
    ExpenseCategory? category,
  }) async {
    final result = await showDialog<ExpenseCategory>(
      context: context,
      builder: (context) => _FamilyExpenseCategoryDialog(category: category),
    );
    if (result == null) return;

    final updated = [
      for (final existing in categories)
        if (existing.id == result.id) result else existing,
      if (category == null) result,
    ];
    onCategoriesChanged?.call(updated);
  }

  void _archive(ExpenseCategory category) {
    final updated = [
      for (final existing in categories)
        if (existing.id == category.id) existing.archive() else existing,
    ];
    onCategoriesChanged?.call(updated);
  }
}

class _FamilyExpenseCategoryDialog extends StatefulWidget {
  const _FamilyExpenseCategoryDialog({this.category});

  final ExpenseCategory? category;

  @override
  State<_FamilyExpenseCategoryDialog> createState() =>
      _FamilyExpenseCategoryDialogState();
}

class _FamilyExpenseCategoryDialogState
    extends State<_FamilyExpenseCategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _reportGroupController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.label ?? '');
    _reportGroupController = TextEditingController(
      text: category?.reportGroup ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reportGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.category == null ? 'Nowa kategoria' : 'Edytuj kategorie',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('family-expense-category-name-field'),
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nazwa kategorii',
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('family-expense-category-report-group-field'),
              controller: _reportGroupController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Grupa raportowa opcjonalnie',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(onPressed: _save, child: const Text('Zapisz kategorie')),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Podaj nazwe kategorii.');
      return;
    }

    final reportGroup = _reportGroupController.text.trim();
    final now = DateTime.now();
    Navigator.of(context).pop(
      ExpenseCategory(
        id:
            widget.category?.id ??
            'family-category-${now.microsecondsSinceEpoch}',
        label: name,
        reportGroup: reportGroup.isEmpty ? null : reportGroup,
        isArchived: widget.category?.isArchived ?? false,
      ),
    );
  }
}

class _ChildInfoCardsSection extends StatelessWidget {
  const _ChildInfoCardsSection({
    required this.cards,
    required this.onCardsChanged,
  });

  final List<ChildInfoCard> cards;
  final ValueChanged<List<ChildInfoCard>>? onCardsChanged;

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
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Karty informacji dziecka'),
              subtitle: const Text(
                'Waski vault: szkola, zdrowie, rozmiary, alergie i zajecia.',
              ),
              trailing: IconButton(
                tooltip: 'Dodaj karte',
                onPressed: onCardsChanged == null
                    ? null
                    : () => _openEditor(context),
                icon: const Icon(Icons.add),
              ),
            ),
            if (cards.isEmpty)
              const Text(
                'Dodaj pierwsza karte, aby podpowiadac kontekst przy kosztach.',
              )
            else
              for (final card in cards)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    card.isShared ? Icons.groups_outlined : Icons.lock_outline,
                  ),
                  title: Text(card.title),
                  subtitle: Text(
                    '${card.type.label} - ${card.visibilityLabel}',
                  ),
                  onTap: onCardsChanged == null
                      ? null
                      : () => _openEditor(context, card: card),
                ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onCardsChanged == null
                  ? null
                  : () => _openEditor(context),
              icon: const Icon(Icons.add_card_outlined),
              label: const Text('Dodaj karte informacji'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {ChildInfoCard? card}) async {
    final result = await showDialog<ChildInfoCard>(
      context: context,
      builder: (context) => _ChildInfoCardDialog(card: card),
    );
    if (result == null) return;

    final updated = [
      for (final existing in cards)
        if (existing.id == result.id) result else existing,
      if (card == null) result,
    ];
    onCardsChanged?.call(updated);
  }
}

class _ChildInfoCardDialog extends StatefulWidget {
  const _ChildInfoCardDialog({this.card});

  final ChildInfoCard? card;

  @override
  State<_ChildInfoCardDialog> createState() => _ChildInfoCardDialogState();
}

class _ChildInfoCardDialogState extends State<_ChildInfoCardDialog> {
  late ChildInfoCardType _type;
  late bool _isShared;
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    _type = card?.type ?? ChildInfoCardType.school;
    _isShared = card?.isShared ?? true;
    _titleController = TextEditingController(text: card?.title ?? '');
    _noteController = TextEditingController(text: card?.note ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.card == null ? 'Nowa karta' : 'Edytuj karte'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ChildInfoCardType>(
              key: const Key('child-info-type-picker'),
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Typ karty'),
              items: [
                for (final type in ChildInfoCardType.values)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: (type) {
                if (type != null) {
                  setState(() => _type = type);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('child-info-title-field'),
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tytul',
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('child-info-note-field'),
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Krotka informacja',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Wspoldzielona w rodzinie'),
              subtitle: const Text('Wylacz, jesli to prywatna notatka autora.'),
              value: _isShared,
              onChanged: (value) => setState(() => _isShared = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(onPressed: _save, child: const Text('Zapisz karte')),
      ],
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();
    if (title.isEmpty || note.isEmpty) {
      setState(() => _errorText = 'Podaj tytul i tresc karty.');
      return;
    }

    final now = DateTime.now();
    Navigator.of(context).pop(
      ChildInfoCard(
        id: widget.card?.id ?? 'child-info-${now.microsecondsSinceEpoch}',
        type: _type,
        title: title,
        note: note,
        isShared: _isShared,
        updatedAt: now,
      ),
    );
  }
}
