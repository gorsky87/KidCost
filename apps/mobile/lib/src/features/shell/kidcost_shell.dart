import 'dart:async';

import 'package:flutter/material.dart';

import '../custody/custody_models.dart';
import '../expenses/attachment_storage.dart';
import '../expenses/expense_models.dart';
import '../onboarding/onboarding_profile.dart';
import '../premium/premium_discovery.dart';
import '../../telemetry/app_telemetry.dart';
import 'screens/add_expense_screen.dart';
import 'screens/custody_calendar_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expense_templates_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/family_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

class KidCostShell extends StatefulWidget {
  const KidCostShell({
    required this.userEmail,
    required this.isDemoSession,
    required this.onboardingProfile,
    required this.attachmentStorage,
    required this.expenses,
    required this.expenseTemplates,
    required this.custodyDays,
    required this.onExpenseSaved,
    required this.onExpenseTemplateSaved,
    required this.onCustodyDaysChanged,
    required this.onSignOut,
    required this.telemetry,
    super.key,
  });

  final String userEmail;
  final bool isDemoSession;
  final OnboardingProfile onboardingProfile;
  final AttachmentStorage attachmentStorage;
  final List<ExpenseEntry> expenses;
  final List<ExpenseTemplate> expenseTemplates;
  final List<CustodyDay> custodyDays;
  final ValueChanged<ExpenseEntry> onExpenseSaved;
  final ValueChanged<ExpenseTemplate> onExpenseTemplateSaved;
  final ValueChanged<List<CustodyDay>> onCustodyDaysChanged;
  final Future<void> Function() onSignOut;
  final AppTelemetry telemetry;

  @override
  State<KidCostShell> createState() => _KidCostShellState();
}

class _KidCostShellState extends State<KidCostShell> {
  int _selectedIndex = 0;
  ExpenseTemplate? _pendingTemplate;
  final Set<PremiumDiscoveryPoint> _dismissedPremiumHints = {};

  @override
  void initState() {
    super.initState();
    _trackDestination(0);
  }

  List<_Destination> get _destinations => [
    _Destination(
      label: 'Start',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      screen: DashboardScreen(
        profile: widget.onboardingProfile,
        expenses: widget.expenses,
        custodyDays: widget.custodyDays,
        onAddExpense: () {
          setState(() => _selectedIndex = 2);
        },
        onOpenReports: () {
          setState(() => _selectedIndex = 5);
        },
        onOpenFamily: () {
          setState(() => _selectedIndex = 6);
        },
      ),
    ),
    _Destination(
      label: 'Koszty',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      screen: ExpensesScreen(
        expenses: widget.expenses,
        showExpenseHistoryPremiumHint: !_isPremiumHintDismissed(
          PremiumDiscoveryPoint.expenseHistory,
        ),
        onPremiumHintDismissed: _dismissPremiumHint,
      ),
    ),
    _Destination(
      label: 'Dodaj',
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle,
      screen: AddExpenseScreen(
        key: ValueKey(_pendingTemplate?.id ?? 'blank-expense-form'),
        profile: widget.onboardingProfile,
        userEmail: widget.userEmail,
        attachmentStorage: widget.attachmentStorage,
        initialTemplate: _pendingTemplate,
        showReceiptOcrPremiumHint: !_isPremiumHintDismissed(
          PremiumDiscoveryPoint.receiptOcr,
        ),
        onPremiumHintDismissed: _dismissPremiumHint,
        onExpenseSaved: (expense) {
          widget.onExpenseSaved(expense);
          setState(() => _pendingTemplate = null);
        },
      ),
    ),
    _Destination(
      label: 'Szablony',
      icon: Icons.event_repeat_outlined,
      selectedIcon: Icons.event_repeat,
      screen: ExpenseTemplatesScreen(
        profile: widget.onboardingProfile,
        userEmail: widget.userEmail,
        templates: widget.expenseTemplates,
        onTemplateSaved: widget.onExpenseTemplateSaved,
        onCreateExpenseFromTemplate: (template) {
          setState(() {
            _pendingTemplate = template;
            _selectedIndex = 2;
          });
        },
      ),
    ),
    _Destination(
      label: 'Opieka',
      icon: Icons.event_available_outlined,
      selectedIcon: Icons.event_available,
      screen: CustodyCalendarScreen(
        profile: widget.onboardingProfile,
        userEmail: widget.userEmail,
        custodyDays: widget.custodyDays,
        onCustodyDaysChanged: widget.onCustodyDaysChanged,
      ),
    ),
    _Destination(
      label: 'Raporty',
      icon: Icons.summarize_outlined,
      selectedIcon: Icons.summarize,
      screen: ReportsScreen(
        expenses: widget.expenses,
        showReportExportPremiumHint: !_isPremiumHintDismissed(
          PremiumDiscoveryPoint.reportExport,
        ),
        onPremiumHintDismissed: _dismissPremiumHint,
      ),
    ),
    _Destination(
      label: 'Rodzina',
      icon: Icons.group_outlined,
      selectedIcon: Icons.group,
      screen: FamilyScreen(profile: widget.onboardingProfile),
    ),
    _Destination(
      label: 'Ustawienia',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      screen: SettingsScreen(
        userEmail: widget.userEmail,
        isDemoSession: widget.isDemoSession,
        showAccountPlanPremiumHint: !_isPremiumHintDismissed(
          PremiumDiscoveryPoint.accountPlan,
        ),
        onPremiumHintDismissed: _dismissPremiumHint,
        onSignOut: widget.onSignOut,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final destination = _destinations[_selectedIndex];

    return Scaffold(
      appBar: AppBar(title: Text(destination.label)),
      body: IndexedStack(
        index: _selectedIndex,
        children: [for (final item in _destinations) item.screen],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          _trackDestination(index);
        },
        destinations: [
          for (final item in _destinations)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }

  void _trackDestination(int index) {
    final item = _destinations[index];
    if (item.label == 'Start') {
      unawaited(
        widget.telemetry.track(
          TelemetryEvent.balanceViewed,
          parameters: {'screen': 'dashboard'},
        ),
      );
    }
    if (item.label == 'Raporty') {
      unawaited(
        widget.telemetry.track(
          TelemetryEvent.reportViewed,
          parameters: {'screen': 'reports'},
        ),
      );
    }
  }

  bool _isPremiumHintDismissed(PremiumDiscoveryPoint point) {
    return _dismissedPremiumHints.contains(point);
  }

  void _dismissPremiumHint(PremiumDiscoveryPoint point) {
    setState(() => _dismissedPremiumHints.add(point));
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}
