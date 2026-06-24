import 'package:flutter/material.dart';
import 'package:kidcost_domain/domain.dart' as domain;

class PremiumPaywallScreen extends StatelessWidget {
  const PremiumPaywallScreen({this.onStartTrial, this.onDismiss, super.key});

  final VoidCallback? onStartTrial;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final approved = domain.approvedPaywallTriggers();
    final rejected = domain.rejectedPaywallTriggers();
    final trial = domain.kidCostTrialMessagingPolicy;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Premium po pierwszej wartosci',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Zamknij',
                onPressed: onDismiss ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(trial.primaryCopy),
          const SizedBox(height: 8),
          Text(trial.accessAfterTrialCopy),
          const SizedBox(height: 8),
          Text(trial.reminderCopy),
          const SizedBox(height: 20),
          _SectionTitle(
            icon: Icons.check_circle_outline,
            title: 'Kiedy paywall moze sie pojawic',
          ),
          const SizedBox(height: 8),
          for (final trigger in approved)
            _PolicyRow(title: trigger.label, body: trigger.rationale),
          const SizedBox(height: 12),
          _SectionTitle(
            icon: Icons.block_outlined,
            title: 'Czego nie blokujemy',
          ),
          const SizedBox(height: 8),
          for (final trigger in rejected)
            _PolicyRow(title: trigger.label, body: trigger.rationale),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onStartTrial,
            icon: const Icon(Icons.play_arrow_outlined),
            label: const Text('Zobacz trial'),
          ),
          TextButton(
            onPressed: onDismiss ?? () => Navigator.of(context).maybePop(),
            child: const Text('Nie teraz'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
