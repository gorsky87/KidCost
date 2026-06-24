import 'dart:async';

import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/custody/custody_models.dart';
import 'features/expenses/attachment_storage.dart';
import 'features/expenses/expense_models.dart';
import 'features/onboarding/family_onboarding_screen.dart';
import 'features/onboarding/onboarding_profile.dart';
import 'features/shell/kidcost_shell.dart';
import 'telemetry/app_telemetry.dart';
import 'theme/kidcost_theme.dart';

class KidCostApp extends StatefulWidget {
  const KidCostApp({
    required this.authRepository,
    required this.attachmentStorage,
    AppTelemetry? telemetry,
    this.config,
    super.key,
  }) : telemetry = telemetry ?? const NoopTelemetry();

  final AuthRepository authRepository;
  final AttachmentStorage attachmentStorage;
  final AppTelemetry telemetry;
  final AppConfig? config;

  @override
  State<KidCostApp> createState() => _KidCostAppState();
}

class _KidCostAppState extends State<KidCostApp> {
  late final AppConfig _config;
  StreamSubscription<AuthSession?>? _authSubscription;
  AuthSession? _session;
  OnboardingProfile? _onboardingProfile;
  List<ExpenseEntry> _expenses = const [];
  List<CustodyDay> _custodyDays = const [];
  bool _isLoading = true;
  String? _startupMessage;

  @override
  void initState() {
    super.initState();
    _config = widget.config ?? AppConfig.fromEnvironment();
    _authSubscription = widget.authRepository.authStateChanges.listen((
      session,
    ) {
      if (!mounted) return;
      setState(() {
        _session = session;
        _isLoading = false;
        _startupMessage = null;
      });
    });
    _restoreSession();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    widget.authRepository.dispose();
    widget.telemetry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KidCost',
      debugShowCheckedModeBanner: false,
      theme: KidCostTheme.light(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_isLoading) {
      return const _StartupLoader();
    }

    final session = _session;
    if (session != null) {
      final profile = _onboardingProfile;
      if (profile == null) {
        return FamilyOnboardingScreen(
          userEmail: session.email,
          onComplete: (profile) {
            unawaited(
              widget.telemetry.track(
                TelemetryEvent.familyCreated,
                parameters: {
                  'is_demo': session.isDemo,
                  'release_channel': _config.releaseChannel,
                  'invitation_skipped': profile.invitationSkipped,
                },
              ),
            );
            unawaited(
              widget.telemetry.track(
                TelemetryEvent.childAdded,
                parameters: {
                  'is_demo': session.isDemo,
                  'release_channel': _config.releaseChannel,
                },
              ),
            );
            setState(() => _onboardingProfile = profile);
          },
        );
      }

      return KidCostShell(
        userEmail: session.email,
        isDemoSession: session.isDemo,
        onboardingProfile: profile,
        attachmentStorage: widget.attachmentStorage,
        expenses: _expenses,
        custodyDays: _custodyDays,
        onExpenseSaved: (expense) {
          unawaited(
            widget.telemetry.track(
              TelemetryEvent.expenseCreated,
              parameters: {
                'category_id': expense.category.id,
                'status': expense.status.name,
                'has_attachment': expense.attachment != null,
                'release_channel': _config.releaseChannel,
              },
            ),
          );
          if (expense.attachment != null) {
            unawaited(
              widget.telemetry.track(
                TelemetryEvent.receiptAttached,
                parameters: {
                  'content_type': expense.attachment!.contentType,
                  'release_channel': _config.releaseChannel,
                },
              ),
            );
          }
          setState(() => _expenses = [..._expenses, expense]);
        },
        onCustodyDaysChanged: (custodyDays) {
          setState(() => _custodyDays = custodyDays);
        },
        onSignOut: _signOut,
        telemetry: widget.telemetry,
      );
    }

    return SignInScreen(
      config: _config,
      isDemoMode: !widget.authRepository.isConfigured,
      startupMessage: _startupMessage,
      onSignIn: _signIn,
      onSignUp: _signUp,
    );
  }

  Future<void> _restoreSession() async {
    try {
      final session = await widget.authRepository.restoreSession();
      if (!mounted) return;
      setState(() {
        _session = session;
        _isLoading = false;
      });
    } on AuthFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _session = null;
        _isLoading = false;
        _startupMessage = error.userMessage;
      });
    } catch (error, stackTrace) {
      widget.telemetry.recordError(
        error,
        stackTrace,
        reason: 'restore_session_failed',
      );
      if (!mounted) return;
      setState(() {
        _session = null;
        _isLoading = false;
        _startupMessage = const AuthFailure(
          AuthFailureReason.unknown,
        ).userMessage;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await widget.authRepository.signOut();
      if (!mounted) return;
      setState(() {
        _session = null;
        _onboardingProfile = null;
        _expenses = const [];
        _custodyDays = const [];
        _isLoading = false;
      });
    } on AuthFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _startupMessage = error.userMessage;
      });
    }
  }

  Future<AuthSession> _signIn({
    required String email,
    required String password,
  }) async {
    final session = await widget.authRepository.signIn(
      email: email,
      password: password,
    );
    if (mounted) {
      setState(() => _session = session);
    }
    return session;
  }

  Future<AuthSession> _signUp({
    required String email,
    required String password,
  }) async {
    unawaited(
      widget.telemetry.track(
        TelemetryEvent.signupStarted,
        parameters: {'release_channel': _config.releaseChannel},
      ),
    );
    final session = await widget.authRepository.signUp(
      email: email,
      password: password,
    );
    unawaited(
      widget.telemetry.track(
        TelemetryEvent.signupCompleted,
        parameters: {
          'is_demo': session.isDemo,
          'release_channel': _config.releaseChannel,
        },
      ),
    );
    if (mounted) {
      setState(() => _session = session);
    }
    return session;
  }
}

class _StartupLoader extends StatelessWidget {
  const _StartupLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ladowanie sesji'),
          ],
        ),
      ),
    );
  }
}
