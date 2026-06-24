import 'package:flutter/material.dart';

import '../../config/app_config.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({
    required this.config,
    required this.onDemoSignIn,
    super.key,
  });

  final AppConfig config;
  final VoidCallback onDemoSignIn;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('KidCost', style: textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text(
                    'Wspolne koszty dziecka, spokojniejsze rozliczenia.',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  const TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Haslo',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onDemoSignIn,
                    icon: const Icon(Icons.login),
                    label: const Text('Wejdz do demo'),
                  ),
                  const SizedBox(height: 16),
                  _ConfigurationStatus(config: config),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigurationStatus extends StatelessWidget {
  const _ConfigurationStatus({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final isConfigured = config.hasSupabaseConfig;
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isConfigured
            ? colors.secondaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isConfigured
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              color: isConfigured
                  ? colors.onSecondaryContainer
                  : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isConfigured
                    ? 'Konfiguracja Supabase jest dostepna dla aplikacji.'
                    : 'Demo dziala bez sekretow. Supabase podlacz przez --dart-define.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
