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
import 'features/planned_purchases/planned_purchase_models.dart';
import 'features/reports/context_log_models.dart';
import 'features/reports/support_context_models.dart';
import 'features/shell/kidcost_shell.dart';
import 'telemetry/app_telemetry.dart';
import 'theme/kidcost_theme.dart';

class KidCostApp extends StatefulWidget {
  const KidCostApp({
    required this.authRepository,
    required this.attachmentStorage,
    AppTelemetry? telemetry,
    this.config,
    this.currentDate,
    super.key,
  }) : telemetry = telemetry ?? const NoopTelemetry();

  final AuthRepository authRepository;
  final AttachmentStorage attachmentStorage;
  final AppTelemetry telemetry;
  final AppConfig? config;
  final DateTime? currentDate;

  @override
  State<KidCostApp> createState() => _KidCostAppState();
}

class _KidCostAppState extends State<KidCostApp> {
  late final AppConfig _config;
  StreamSubscription<AuthSession?>? _authSubscription;
  AuthSession? _session;
  OnboardingProfile? _onboardingProfile;
  List<ExpenseEntry> _expenses = const [];
  List<ExpenseTemplate> _expenseTemplates = const [];
  List<PlannedPurchase> _plannedPurchases = const [];
  List<CustodyDay> _custodyDays = const [];
  List<ContextLogEntry> _contextLogEntries = const [];
  List<SupportPaymentContextEntry> _supportContextEntries = const [];
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
        expenseTemplates: _expenseTemplates,
        plannedPurchases: _plannedPurchases,
        custodyDays: _custodyDays,
        contextLogEntries: _contextLogEntries,
        supportContextEntries: _supportContextEntries,
        onExpenseSaved: (expense) {
          unawaited(
            widget.telemetry.track(
              TelemetryEvent.expenseCreated,
              parameters: {
                'category_id': expense.category.id,
                'status': expense.status.name,
                'has_attachment': expense.attachment != null,
                'has_line_items': expense.hasLineItems,
                'line_item_count': expense.lineItems.length,
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
        onExpenseChanged: (expense) {
          final existingIndex = _expenses.indexWhere(
            (item) => item.id == expense.id,
          );
          if (existingIndex == -1) {
            return;
          }
          final existingExpense = _expenses[existingIndex];
          if (existingExpense.status != expense.status) {
            unawaited(
              widget.telemetry.track(
                TelemetryEvent.expenseStatusChanged,
                parameters: {
                  'from_status': existingExpense.status.name,
                  'to_status': expense.status.name,
                  'actor': existingExpense.paidBy.isCurrentUser
                      ? 'author'
                      : 'counterparty',
                  'has_status_comment':
                      expense.statusComment?.trim().isNotEmpty ?? false,
                  'release_channel': _config.releaseChannel,
                },
              ),
            );
          }
          final updatedExpenses = [..._expenses];
          updatedExpenses[existingIndex] = expense;
          setState(() => _expenses = updatedExpenses);
        },
        onExpenseTemplateSaved: (template) {
          final existingIndex = _expenseTemplates.indexWhere(
            (item) => item.id == template.id,
          );
          if (existingIndex == -1) {
            setState(
              () => _expenseTemplates = [..._expenseTemplates, template],
            );
            return;
          }
          final updatedTemplates = [..._expenseTemplates];
          updatedTemplates[existingIndex] = template;
          setState(() => _expenseTemplates = updatedTemplates);
        },
        onPlannedPurchaseSaved: (plan) {
          unawaited(
            widget.telemetry.track(
              TelemetryEvent.plannedPurchaseCreated,
              parameters: {
                'category_id': plan.category.id,
                'status': plan.status.name,
                'surface': 'planned_purchases',
                'release_channel': _config.releaseChannel,
              },
            ),
          );
          setState(() => _plannedPurchases = [..._plannedPurchases, plan]);
        },
        onPlannedPurchaseChanged: (plan) {
          final existingIndex = _plannedPurchases.indexWhere(
            (item) => item.id == plan.id,
          );
          if (existingIndex == -1) {
            return;
          }
          final existingPlan = _plannedPurchases[existingIndex];
          if (existingPlan.status != plan.status) {
            unawaited(
              widget.telemetry.track(
                TelemetryEvent.plannedPurchaseStatusChanged,
                parameters: {
                  'from_status': existingPlan.status.name,
                  'to_status': plan.status.name,
                  'reason_code': plan.reason?.code,
                  'has_status_comment': plan.note?.trim().isNotEmpty ?? false,
                  'surface': 'planned_purchases',
                  'release_channel': _config.releaseChannel,
                },
              ),
            );
          }
          final updatedPlans = [..._plannedPurchases];
          updatedPlans[existingIndex] = plan;
          setState(() => _plannedPurchases = updatedPlans);
        },
        onPlannedPurchaseConverted: _convertPlannedPurchaseToExpense,
        onCustodyDaysChanged: (custodyDays) {
          setState(() => _custodyDays = custodyDays);
        },
        onContextLogEntrySaved: (entry) {
          unawaited(
            widget.telemetry.track(
              TelemetryEvent.contextLogEntryCreated,
              parameters: {
                'surface': 'reports',
                'context_category': entry.category.id,
                'context_visibility': entry.visibility.id,
                'linked_record_type': entry.hasLinkedExpense
                    ? 'expense'
                    : 'none',
                'include_context_in_report': entry.includeInReport,
                'release_channel': _config.releaseChannel,
              },
            ),
          );
          setState(() => _contextLogEntries = [..._contextLogEntries, entry]);
        },
        onSupportContextEntrySaved: (entry) {
          unawaited(
            widget.telemetry.track(
              TelemetryEvent.supportContextEntryCreated,
              parameters: {
                ...entry.analyticsProperties,
                'surface': 'reports',
                'release_channel': _config.releaseChannel,
              },
            ),
          );
          setState(
            () => _supportContextEntries = [..._supportContextEntries, entry],
          );
        },
        onSignOut: _signOut,
        telemetry: widget.telemetry,
        currentDate: widget.currentDate,
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
        _expenseTemplates = const [];
        _plannedPurchases = const [];
        _custodyDays = const [];
        _contextLogEntries = const [];
        _supportContextEntries = const [];
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

  void _convertPlannedPurchaseToExpense(PlannedPurchase plan) {
    final existingIndex = _plannedPurchases.indexWhere(
      (item) => item.id == plan.id,
    );
    if (existingIndex == -1 || !plan.status.canConvert) {
      return;
    }
    final now = widget.currentDate ?? DateTime.now();
    final expense = ExpenseEntry(
      id: 'expense-from-${plan.id}',
      amountCents: plan.estimatedAmountCents,
      expenseDate: plan.targetDate,
      childName: plan.childName,
      category: plan.category,
      paidBy: const ExpensePayer(id: 'self', label: 'Ty', isCurrentUser: true),
      title: plan.title,
      createdAt: now,
      statusComment: 'Utworzono z zaakceptowanego planu zakupu.',
    );
    final convertedPlan = plan.copyWith(
      status: PlannedPurchaseStatus.converted,
      convertedExpenseId: expense.id,
      clearReason: true,
      clearNote: true,
    );
    final updatedPlans = [..._plannedPurchases];
    updatedPlans[existingIndex] = convertedPlan;
    unawaited(
      widget.telemetry.track(
        TelemetryEvent.plannedPurchaseConverted,
        parameters: {
          'category_id': plan.category.id,
          'from_status': plan.status.name,
          'to_status': convertedPlan.status.name,
          'surface': 'planned_purchases',
          'release_channel': _config.releaseChannel,
        },
      ),
    );
    setState(() {
      _plannedPurchases = updatedPlans;
      _expenses = [..._expenses, expense];
    });
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
