import 'dart:async';

import 'package:flutter/material.dart';

import '../child_info/child_info_models.dart';
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
import 'screens/monthly_cost_plan_screen.dart';
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
    required this.onExpenseChanged,
    required this.onExpenseTemplateSaved,
    required this.onCustodyDaysChanged,
    required this.onSignOut,
    required this.telemetry,
    this.currentDate,
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
  final ValueChanged<ExpenseEntry> onExpenseChanged;
  final ValueChanged<ExpenseTemplate> onExpenseTemplateSaved;
  final ValueChanged<List<CustodyDay>> onCustodyDaysChanged;
  final Future<void> Function() onSignOut;
  final AppTelemetry telemetry;
  final DateTime? currentDate;

  @override
  State<KidCostShell> createState() => _KidCostShellState();
}

class _KidCostShellState extends State<KidCostShell> {
  int _selectedIndex = 0;
  ExpenseTemplate? _pendingTemplate;
  ExpenseListFilterRequest? _expenseFilterRequest;
  List<ChildInfoCard> _childInfoCards = const [];
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
        currentDate: widget.currentDate,
        onAddExpense: () {
          _startQuickExpenseDraft('manual_expense');
        },
        onQuickReceiptDraft: () {
          _startQuickExpenseDraft('receipt_draft');
        },
        onOpenExpenses: () {
          setState(() => _selectedIndex = 1);
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
        initialFilterRequest: _expenseFilterRequest,
        onExpenseChanged: widget.onExpenseChanged,
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
        currentDate: widget.currentDate,
        calendarEvents: calendarEventsFromCustodyDays(widget.custodyDays),
        childInfoCards: _childInfoCards,
        existingExpenses: widget.expenses,
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
        currentDate: widget.currentDate,
        expenses: widget.expenses,
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
        onOpenExpenseFilter: (request) {
          setState(() {
            _expenseFilterRequest = request;
            _selectedIndex = 1;
          });
        },
        onPremiumHintDismissed: _dismissPremiumHint,
      ),
    ),
    _Destination(
      label: 'Rodzina',
      icon: Icons.group_outlined,
      selectedIcon: Icons.group,
      screen: FamilyScreen(
        profile: widget.onboardingProfile,
        childInfoCards: _childInfoCards,
        onChildInfoCardsChanged: (cards) {
          setState(() => _childInfoCards = List.unmodifiable(cards));
        },
      ),
    ),
    _Destination(
      label: 'Kosztorys',
      icon: Icons.request_quote_outlined,
      selectedIcon: Icons.request_quote,
      screen: MonthlyCostPlanScreen(
        childName: widget.onboardingProfile.childName,
        expenses: widget.expenses,
        currentDate: widget.currentDate,
      ),
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
        telemetry: widget.telemetry,
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

  void _startQuickExpenseDraft(String feature) {
    setState(() {
      _pendingTemplate = null;
      _selectedIndex = 2;
    });
    unawaited(
      widget.telemetry.track(
        TelemetryEvent.quickExpenseStarted,
        parameters: {
          'screen': 'add_expense',
          'surface': 'dashboard',
          'trigger': 'dashboard_quick_entry',
          'feature': feature,
        },
      ),
    );
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
