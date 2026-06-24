import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import 'auth_repository.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    required this.config,
    required this.isDemoMode,
    required this.onSignIn,
    required this.onSignUp,
    this.startupMessage,
    super.key,
  });

  final AppConfig config;
  final bool isDemoMode;
  final String? startupMessage;
  final Future<AuthSession> Function({
    required String email,
    required String password,
  })
  onSignIn;
  final Future<AuthSession> Function({
    required String email,
    required String password,
  })
  onSignUp;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _isSubmitting = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final actionLabel = _isRegistering ? 'Utworz konto' : 'Zaloguj';

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
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.mail_outline),
                      errorText: _emailHasText || _message == null
                          ? null
                          : 'Podaj email.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Haslo',
                      prefixIcon: const Icon(Icons.lock_outline),
                      helperText: _isRegistering ? 'Minimum 6 znakow.' : null,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_isRegistering ? Icons.person_add : Icons.login),
                    label: Text(actionLabel),
                  ),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _isRegistering = !_isRegistering;
                              _message = null;
                            });
                          },
                    child: Text(
                      _isRegistering
                          ? 'Masz konto? Zaloguj sie'
                          : 'Nie masz konta? Utworz konto',
                    ),
                  ),
                  if (_visibleMessage != null) ...[
                    const SizedBox(height: 8),
                    _AuthMessage(message: _visibleMessage!),
                  ],
                  const SizedBox(height: 16),
                  _ConfigurationStatus(
                    config: widget.config,
                    isDemoMode: widget.isDemoMode,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _emailHasText => _emailController.text.trim().isNotEmpty;

  String? get _visibleMessage => _message ?? widget.startupMessage;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _message = 'Podaj email i haslo.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      if (_isRegistering) {
        await widget.onSignUp(email: email, password: password);
      } else {
        await widget.onSignIn(email: email, password: password);
      }
    } on AuthFailure catch (error) {
      if (!mounted) return;
      setState(() => _message = error.userMessage);
    } catch (_) {
      if (!mounted) return;
      setState(
        () =>
            _message = const AuthFailure(AuthFailureReason.unknown).userMessage,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _ConfigurationStatus extends StatelessWidget {
  const _ConfigurationStatus({required this.config, required this.isDemoMode});

  final AppConfig config;
  final bool isDemoMode;

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
                    : isDemoMode
                    ? 'Tryb demo bez sekretow. Ten sam flow email/haslo dziala lokalnie.'
                    : 'Supabase podlacz przez --dart-define.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colors.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
