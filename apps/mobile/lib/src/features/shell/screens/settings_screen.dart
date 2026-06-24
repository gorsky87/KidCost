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
            'Dane rodziny widza tylko osoby z aktywnym dostepem do tej rodziny.',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.history_outlined),
          title: Text('Historia zmian'),
          subtitle: Text(
            'Koszty i statusy beda zapisywac kto i kiedy zmienil wpis.',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Eksport danych'),
          subtitle: const Text(
            'Przygotujemy plik z kosztami, statusami i historia rodziny.',
          ),
          onTap: () => _showComingSoon(
            context,
            'Eksport danych bedzie dostepny po podpieciu backendu.',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Polityka prywatnosci'),
          subtitle: const Text('https://kidcost.app/privacy'),
          onTap: () => _showComingSoon(
            context,
            'Polityka prywatnosci jest przygotowana w docs/web/privacy-policy.md.',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Regulamin'),
          subtitle: const Text('https://kidcost.app/terms'),
          onTap: () => _showComingSoon(
            context,
            'Regulamin jest przygotowany w docs/web/terms-of-service.md.',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.support_agent_outlined),
          title: const Text('Kontakt support'),
          subtitle: const Text('support@kidcost.app'),
          onTap: () => _showComingSoon(
            context,
            'Napisz na support@kidcost.app. Nie wysylaj pelnych danych dziecka, jesli nie sa potrzebne.',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.balance_outlined),
          title: Text('Brak porad prawnych'),
          subtitle: Text(
            'KidCost pomaga porzadkowac fakty i dokumenty, ale nie zastepuje porady prawnej.',
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

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
