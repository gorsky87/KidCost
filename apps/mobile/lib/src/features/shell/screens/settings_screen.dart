import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.userEmail,
    required this.isDemoSession,
    required this.onSignOut,
    super.key,
  });

  final String userEmail;
  final bool isDemoSession;
  final Future<void> Function() onSignOut;

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
        ListTile(
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(userEmail),
          subtitle: Text(
            isDemoSession
                ? 'Sesja demo w tym uruchomieniu aplikacji.'
                : 'Sesja Supabase zapisana lokalnie.',
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Wyloguj'),
          onTap: onSignOut,
        ),
      ],
    );
  }
}
