import 'package:flutter/material.dart';

import '../../onboarding/onboarding_profile.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({required this.profile, super.key});

  final OnboardingProfile profile;

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
