import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.onSignOut, super.key});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          leading: Icon(Icons.security_outlined),
          title: Text('Prywatnosc danych rodzinnych'),
          subtitle: Text(
            'Dane beda ograniczone przez RLS i aktywne czlonkostwo w rodzinie.',
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Wyloguj demo'),
          onTap: onSignOut,
        ),
      ],
    );
  }
}
