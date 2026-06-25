import 'dart:async';

import 'package:flutter/material.dart';

import '../child_info/child_info_models.dart';
import '../custody/custody_models.dart';
import '../expenses/attachment_storage.dart';
import '../expenses/expense_models.dart';
import '../onboarding/onboarding_profile.dart';
import '../planned_purchases/planned_purchase_models.dart';
import '../premium/premium_discovery.dart';
import '../privacy/private_preview_protection.dart';
import '../../telemetry/app_telemetry.dart';
import 'screens/add_expense_screen.dart';
import 'screens/custody_calendar_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expense_templates_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/family_screen.dart';
import 'screens/monthly_cost_plan_screen.dart';
import 'screens/planned_purchases_screen.dart';
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
    required this.plannedPurchases,
    required this.custodyDays,
    required this.onExpenseSaved,
    required this.onExpenseChanged,
    required this.onExpenseTemplateSaved,
    required this.onPlannedPurchaseSaved,
    required this.onPlannedPurchaseChanged,
    required this.onPlannedPurchaseConverted,
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
  final List<PlannedPurchase> plannedPurchases;
  final List<CustodyDay> custodyDays;
  final ValueChanged<ExpenseEntry> onExpenseSaved;
  final ValueChanged<ExpenseEntry> onExpenseChanged;
  final ValueChanged<ExpenseTemplate> onExpenseTemplateSaved;
  final ValueChanged<PlannedPurchase> onPlannedPurchaseSaved;
  final ValueChanged<PlannedPurchase> onPlannedPurchaseChanged;
  final ValueChanged<PlannedPurchase> onPlannedPurchaseConverted;
  final ValueChanged<List<CustodyDay>> onCustodyDaysChanged;
  final Future<void> Function() onSignOut;
  final AppTelemetry telemetry;
  final DateTime? currentDate;

  @override
  State<KidCostShell> createState() => _KidCostShellState();
}

class _KidCostShellState extends State<KidCostShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  ExpenseTemplate? _pendingTemplate;
  ExpenseListFilterRequest? _expenseFilterRequest;
  List<ChildInfoCard> _childInfoCards = const [];
  final Set<PremiumDiscoveryPoint> _dismissedPremiumHints = {};
  bool _hideSensitivePreview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _trackDestination(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final shouldHide = switch (state) {
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden ||
      AppLifecycleState.paused =>
        _destinations[_selectedIndex].protectsBackgroundPreview,
      AppLifecycleState.resumed || AppLifecycleState.detached => false,
    };
    if (_hideSensitivePreview != shouldHide) {
      setState(() => _hideSensitivePreview = shouldHide);
    }
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
        currentDate: widget.currentDate,
        onExpenseChanged: widget.onExpenseChanged,
        showExpenseHistoryPremiumHint: !_isPremiumHintDismissed(
          PremiumDiscoveryPoint.expenseHistory,
        ),
        showHistoricalImportPremiumHint: !_isPremiumHintDismissed(
          PremiumDiscoveryPoint.historicalImport,
        ),
        telemetry: widget.telemetry,
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
        showCalendarExportPremiumHint: !_isPremiumHintDismissed(
          PremiumDiscoveryPoint.calendarExport,
        ),
        onPremiumHintDismissed: _dismissPremiumHint,
        onCalendarExportPremiumIntent: _trackCalendarExportPremiumIntent,
        onCustodyDaysChanged: widget.onCustodyDaysChanged,
      ),
    ),
    _Destination(
      label: 'Raporty',
      icon: Icons.summarize_outlined,
      selectedIcon: Icons.summarize,
      screen: ReportsScreen(
        expenses: widget.expenses,
        plannedPurchases: widget.plannedPurchases,
        custodyDays: widget.custodyDays,
        currentDate: widget.currentDate,
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
        telemetry: widget.telemetry,
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
      label: 'Plany',
      icon: Icons.playlist_add_outlined,
      selectedIcon: Icons.playlist_add_check,
      screen: PlannedPurchasesScreen(
        profile: widget.onboardingProfile,
        plannedPurchases: widget.plannedPurchases,
        currentDate: widget.currentDate,
        onPlannedPurchaseSaved: widget.onPlannedPurchaseSaved,
        onPlannedPurchaseChanged: widget.onPlannedPurchaseChanged,
        onConvertToExpense: widget.onPlannedPurchaseConverted,
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
      protectsBackgroundPreview: false,
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

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text(destination.label)),
          body: IndexedStack(
            index: _selectedIndex,
            children: [for (final item in _destinations) item.screen],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
                _hideSensitivePreview = false;
              });
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
        ),
        if (_hideSensitivePreview)
          const Positioned.fill(child: PrivatePreviewProtection()),
      ],
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

  void _trackCalendarExportPremiumIntent(CalendarExportPremiumIntent intent) {
    unawaited(
      widget.telemetry.track(
        TelemetryEvent.premiumFeatureIntent,
        parameters: {
          'feature': 'calendar_ics_export',
          'surface': 'custody_calendar',
          'trigger': 'calendar_export_intent',
          'export_format': intent.exportFormat,
          'custody_day_count': intent.custodyDaysCount,
          'has_detailed_export': intent.includeDetailedExpenseContext,
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
    this.protectsBackgroundPreview = true,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  final bool protectsBackgroundPreview;
}
