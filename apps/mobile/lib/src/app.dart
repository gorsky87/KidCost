import 'dart:async';

import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/expenses/attachment_storage.dart';
import 'features/expenses/expense_models.dart';
import 'features/onboarding/family_onboarding_screen.dart';
import 'features/onboarding/onboarding_profile.dart';
import 'features/shell/kidcost_shell.dart';
import 'theme/kidcost_theme.dart';

class KidCostApp extends StatefulWidget {
  const KidCostApp({
    required this.authRepository,
    required this.attachmentStorage,
    this.config,
    super.key,
  });

  final AuthRepository authRepository;
  final AttachmentStorage attachmentStorage;
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
        onExpenseSaved: (expense) {
          setState(() => _expenses = [..._expenses, expense]);
        },
        onSignOut: _signOut,
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
    } catch (_) {
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
    final session = await widget.authRepository.signUp(
      email: email,
      password: password,
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
