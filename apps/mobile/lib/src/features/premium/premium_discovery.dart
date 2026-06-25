import 'package:flutter/material.dart';

enum PremiumDiscoveryPoint {
  receiptOcr,
  reportExport,
  calendarExport,
  expenseHistory,
  accountPlan,
}

class PremiumDiscoveryMessage {
  const PremiumDiscoveryMessage({
    required this.title,
    required this.body,
    required this.freeBaseline,
    required this.candidateFeature,
  });

  final String title;
  final String body;
  final String freeBaseline;
  final String candidateFeature;
}

extension PremiumDiscoveryPointDetails on PremiumDiscoveryPoint {
  PremiumDiscoveryMessage get message {
    switch (this) {
      case PremiumDiscoveryPoint.receiptOcr:
        return const PremiumDiscoveryMessage(
          title: 'Szybsze przepisywanie paragonow',
          body:
              'W przyszlosci OCR moze podpowiedziec kwote, date i sprzedawce po dodaniu zdjecia.',
          freeBaseline:
              'Dodawanie kosztu, paragonu i reczne pola zostaja w podstawowym przeplywie.',
          candidateFeature: 'Kandydat Premium: OCR i review pol przed zapisem.',
        );
      case PremiumDiscoveryPoint.reportExport:
        return const PremiumDiscoveryMessage(
          title: 'Raport gotowy do rozmowy',
          body:
              'Rozszerzony eksport moze zebrac PDF, CSV i dowody w jeden spokojny pakiet.',
          freeBaseline:
              'Podglad raportu i podstawowy CSV zostaja dostepne bez blokowania.',
          candidateFeature: 'Kandydat Premium: PDF, pakiet dowodow i historia.',
        );
      case PremiumDiscoveryPoint.calendarExport:
        return const PremiumDiscoveryMessage(
          title: 'Kalendarz poza KidCost',
          body:
              'Eksport ICS moze przeniesc plan opieki do Apple, Google lub Outlook bez pokazywania szczegolow kosztow.',
          freeBaseline:
              'Tworzenie i przegladanie dni opieki w aplikacji zostaje w podstawowym przeplywie.',
          candidateFeature:
              'Kandydat Premium: manualny eksport ICS i przyszly feed subskrybowany.',
        );
      case PremiumDiscoveryPoint.expenseHistory:
        return const PremiumDiscoveryMessage(
          title: 'Pelniejsza historia kosztu',
          body:
              'Zaawansowana historia moze pokazac statusy, komentarze i dowody w jednej osi czasu.',
          freeBaseline:
              'Status kosztu i podstawowe szczegoly pozostaja widoczne zawsze.',
          candidateFeature:
              'Kandydat Premium: zaawansowana historia i eksport.',
        );
      case PremiumDiscoveryPoint.accountPlan:
        return const PremiumDiscoveryMessage(
          title: 'Premium bez presji',
          body:
              'Plan platny powinien pojawiac sie dopiero przy naturalnych momentach wartosci.',
          freeBaseline:
              'Koszty, saldo, zalaczniki i podstawowe raporty nie sa paywallem MVP.',
          candidateFeature:
              'Kandydaci Premium: OCR, PDF, bundles, wiekszy storage.',
        );
    }
  }
}

class PremiumDiscoveryCard extends StatelessWidget {
  const PremiumDiscoveryCard({
    required this.point,
    required this.onDismiss,
    this.compact = false,
    super.key,
  });

  final PremiumDiscoveryPoint point;
  final VoidCallback onDismiss;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final message = point.message;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: Key('premium-discovery-dismiss-${point.name}'),
                  tooltip: 'Ukryj na teraz',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(message.body),
            const SizedBox(height: 8),
            Text(
              message.freeBaseline,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              message.candidateFeature,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ukrycie obowiazuje tylko w tej sesji; docelowo zapiszemy je w profilu.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
