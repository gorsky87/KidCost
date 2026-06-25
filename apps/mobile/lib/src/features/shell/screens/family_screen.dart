import 'package:flutter/material.dart';

import '../../child_info/child_info_models.dart';
import '../../onboarding/onboarding_profile.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({
    required this.profile,
    this.childInfoCards = const [],
    this.onChildInfoCardsChanged,
    super.key,
  });

  final OnboardingProfile profile;
  final List<ChildInfoCard> childInfoCards;
  final ValueChanged<List<ChildInfoCard>>? onChildInfoCardsChanged;

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
