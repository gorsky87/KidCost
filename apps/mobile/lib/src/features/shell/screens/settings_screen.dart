import 'package:flutter/material.dart';
import 'package:kidcost_domain/domain.dart' as domain;

import '../../premium/premium_discovery.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.userEmail,
    required this.isDemoSession,
    required this.onSignOut,
    this.showAccountPlanPremiumHint = false,
    this.onPremiumHintDismissed,
    super.key,
  });

  final String userEmail;
  final bool isDemoSession;
  final Future<void> Function() onSignOut;
  final bool showAccountPlanPremiumHint;
  final ValueChanged<PremiumDiscoveryPoint>? onPremiumHintDismissed;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _newExpensePush = true;
  bool _statusPush = true;
  bool _balanceReminderPush = false;
  bool _permissionPromptSeen = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          leading: Icon(Icons.notifications_active_outlined),
          title: Text('Powiadomienia'),
          subtitle: Text(
            'Neutralne alerty bez kwot, opisow kosztow i danych dziecka na ekranie blokady.',
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.receipt_long_outlined),
          title: const Text('Nowy koszt od drugiego rodzica'),
          subtitle: const Text('Krotki alert, gdy pojawi sie wpis do reakcji.'),
          value: _newExpensePush,
          onChanged: _setNewExpensePush,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.swap_horiz_outlined),
          title: const Text('Zmiana statusu kosztu'),
          subtitle: const Text(
            'Informacja o akceptacji, sporze lub rozliczeniu.',
          ),
          value: _statusPush,
          onChanged: _setStatusPush,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.account_balance_wallet_outlined),
          title: const Text('Przypomnienie o saldzie'),
          subtitle: const Text('Opcjonalny sygnal o nierozliczonym bilansie.'),
          value: _balanceReminderPush,
          onChanged: _setBalanceReminderPush,
        ),
        ListTile(
          leading: const Icon(Icons.touch_app_outlined),
          title: Text(
            _permissionPromptSeen
                ? 'Zgoda systemowa bedzie podlaczona z FCM'
                : 'Wlacz powiadomienia po pierwszym koszcie',
          ),
          subtitle: const Text(
            'Brak zgody nie blokuje dodawania kosztow ani raportow.',
          ),
          onTap: () {
            setState(() => _permissionPromptSeen = true);
            _showComingSoon(
              context,
              'Poprosimy o zgode dopiero w kontekscie wspolnego kosztu.',
            );
          },
        ),
        const Divider(),
        if (widget.showAccountPlanPremiumHint) ...[
          PremiumDiscoveryCard(
            point: PremiumDiscoveryPoint.accountPlan,
            onDismiss: () => widget.onPremiumHintDismissed?.call(
              PremiumDiscoveryPoint.accountPlan,
            ),
          ),
          const SizedBox(height: 8),
        ],
        const _PlanComparisonCard(),
        const Divider(),
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
          title: Text(widget.userEmail),
          subtitle: Text(
            widget.isDemoSession
                ? 'Sesja demo w tym uruchomieniu aplikacji.'
                : 'Sesja Supabase zapisana lokalnie.',
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Wyloguj'),
          onTap: widget.onSignOut,
        ),
      ],
    );
  }

  void _setNewExpensePush(bool value) {
    setState(() => _newExpensePush = value);
  }

  void _setStatusPush(bool value) {
    setState(() => _statusPush = value);
  }

  void _setBalanceReminderPush(bool value) {
    setState(() => _balanceReminderPush = value);
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PlanComparisonCard extends StatelessWidget {
  const _PlanComparisonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.compare_arrows_outlined),
              title: Text('Zakres MVP i przyszlego Premium'),
              subtitle: Text(
                'Bez cen i bez blokowania podstawowych przeplywow.',
              ),
            ),
            _PlanRow(title: 'MVP/basic', body: domain.freePlanSummaryText()),
            _PlanRow(
              title: 'Kandydaci Premium',
              body: domain.premiumPlanSummaryText(),
            ),
            _PlanRow(
              title: 'Downgrade',
              body: domain.downgradeProtectionSummaryText(),
            ),
            _PlanRow(
              title: 'Platnik rodzinny',
              body: domain.familyBillingPolicy.summary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle_outline),
      title: Text(title),
      subtitle: Text(body),
    );
  }
}
