import 'package:flutter/material.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          leading: Icon(Icons.child_care_outlined),
          title: Text('Dziecko testowe'),
          subtitle: Text('Onboarding rodziny zostanie podpiety do Supabase.'),
        ),
        ListTile(
          leading: Icon(Icons.person_add_alt_1_outlined),
          title: Text('Zapros drugi rodzic'),
          subtitle: Text(
            'Token zaproszenia jest juz zaprojektowany w backendzie.',
          ),
        ),
      ],
    );
  }
}
