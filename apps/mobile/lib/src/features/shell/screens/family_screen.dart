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
        if (profile.invitationSkipped)
          const ListTile(
            leading: Icon(Icons.person_add_alt_1_outlined),
            title: Text('Zaproszenie pominiete'),
            subtitle: Text(
              'Mozesz wrocic do zaproszenia drugiego rodzica pozniej.',
            ),
          )
        else
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
