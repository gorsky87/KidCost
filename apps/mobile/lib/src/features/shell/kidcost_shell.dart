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
import '../reports/context_log_models.dart';
import '../reports/support_context_models.dart';
import '../settlements/settlement_split_rule.dart';
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
    required this.contextLogEntries,
    required this.supportContextEntries,
    required this.onExpenseSaved,
    required this.onExpenseChanged,
    required this.onExpenseTemplateSaved,
    required this.onPlannedPurchaseSaved,
    required this.onPlannedPurchaseChanged,
    required this.onPlannedPurchaseConverted,
    required this.onCustodyDaysChanged,
    required this.onContextLogEntrySaved,
    required this.onSupportContextEntrySaved,
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
  final List<ContextLogEntry> contextLogEntries;
  final List<SupportPaymentContextEntry> supportContextEntries;
  final ValueChanged<ExpenseEntry> onExpenseSaved;
  final ValueChanged<ExpenseEntry> onExpenseChanged;
  final ValueChanged<ExpenseTemplate> onExpenseTemplateSaved;
  final ValueChanged<PlannedPurchase> onPlannedPurchaseSaved;
  final ValueChanged<PlannedPurchase> onPlannedPurchaseChanged;
  final ValueChanged<PlannedPurchase> onPlannedPurchaseConverted;
  final ValueChanged<List<CustodyDay>> onCustodyDaysChanged;
  final ValueChanged<ContextLogEntry> onContextLogEntrySaved;
  final ValueChanged<SupportPaymentContextEntry> onSupportContextEntrySaved;
  final Future<void> Function() onSignOut;
  final AppTelemetry telemetry;
  final DateTime? currentDate;

  @override
  State<KidCostShell> createState() => _KidCostShellState();
}

class _KidCostShellState extends State<KidCostShell>
    with WidgetsBindingObserver {
  _DestinationKey _selectedKey = _DestinationKey.dashboard;
  ExpenseTemplate? _pendingTemplate;
  ExpenseListFilterRequest? _expenseFilterRequest;
  List<ChildInfoCard> _childInfoCards = const [];
  List<ExpenseCategory> _customExpenseCategories = const [];
  final Set<PremiumDiscoveryPoint> _dismissedPremiumHints = {};
  bool _hideSensitivePreview = false;
  SettlementSplitRule _settlementSplitRule = SettlementSplitRule.equal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _trackDestination(_selectedKey);
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
      AppLifecycleState.paused => _destinationFor(
        _selectedKey,
      ).protectsBackgroundPreview,
      AppLifecycleState.resumed || AppLifecycleState.detached => false,
    };
    if (_hideSensitivePreview != shouldHide) {
      setState(() => _hideSensitivePreview = shouldHide);
    }
  }

  List<_Destination> get _destinations {
    final destinations = [
      _Destination(
        key: _DestinationKey.dashboard,
        label: 'Start',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        screen: DashboardScreen(
          profile: widget.onboardingProfile,
          expenses: widget.expenses,
          settlementSplitRule: _settlementSplitRule,
          custodyDays: widget.custodyDays,
          currentDate: widget.currentDate,
          onAddExpense: () {
            _startQuickExpenseDraft('manual_expense');
          },
          onQuickReceiptDraft: () {
            _startQuickExpenseDraft('receipt_draft');
          },
          onOpenExpenses: () {
            _selectDestination(_DestinationKey.expenses);
          },
          onOpenReports: () {
            _selectDestination(_DestinationKey.reports);
          },
          onOpenFamily: () {
            _selectDestination(_DestinationKey.family);
          },
        ),
      ),
      _Destination(
        key: _DestinationKey.expenses,
        label: 'Koszty',
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        screen: ExpensesScreen(
          expenses: widget.expenses,
          availableCategories: _activeExpenseCategories,
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
        key: _DestinationKey.addExpense,
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
          availableCategories: _activeExpenseCategories,
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
        key: _DestinationKey.templates,
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
              _selectedKey = _DestinationKey.addExpense;
            });
          },
        ),
      ),
      _Destination(
        key: _DestinationKey.custody,
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
        key: _DestinationKey.reports,
        label: 'Raporty',
        icon: Icons.summarize_outlined,
        selectedIcon: Icons.summarize,
        screen: ReportsScreen(
          expenses: widget.expenses,
          plannedPurchases: widget.plannedPurchases,
          custodyDays: widget.custodyDays,
          contextLogEntries: widget.contextLogEntries,
          supportContextEntries: widget.supportContextEntries,
          currentDate: widget.currentDate,
          onContextLogEntrySaved: widget.onContextLogEntrySaved,
          onSupportContextEntrySaved: widget.onSupportContextEntrySaved,
          showReportExportPremiumHint: !_isPremiumHintDismissed(
            PremiumDiscoveryPoint.reportExport,
          ),
          onOpenExpenseFilter: (request) {
            setState(() {
              _expenseFilterRequest = request;
              _selectedKey = _DestinationKey.expenses;
            });
          },
          onPremiumHintDismissed: _dismissPremiumHint,
          telemetry: widget.telemetry,
        ),
      ),
      _Destination(
        key: _DestinationKey.family,
        label: 'Rodzina',
        icon: Icons.group_outlined,
        selectedIcon: Icons.group,
        screen: FamilyScreen(
          profile: widget.onboardingProfile,
          childInfoCards: _childInfoCards,
          customExpenseCategories: _customExpenseCategories,
          onChildInfoCardsChanged: (cards) {
            setState(() => _childInfoCards = List.unmodifiable(cards));
          },
          onCustomExpenseCategoriesChanged: (categories) {
            setState(
              () => _customExpenseCategories = List.unmodifiable(categories),
            );
          },
        ),
      ),
      _Destination(
        key: _DestinationKey.plans,
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
        key: _DestinationKey.costPlan,
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
        key: _DestinationKey.settings,
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
          settlementSplitRule: _settlementSplitRule,
          onSettlementSplitRuleChanged: (rule) {
            setState(() => _settlementSplitRule = rule);
          },
          onSignOut: widget.onSignOut,
        ),
      ),
    ];
    return [
      ...destinations,
      _Destination(
        key: _DestinationKey.more,
        label: 'Wiecej',
        icon: Icons.more_horiz_outlined,
        selectedIcon: Icons.more_horiz,
        protectsBackgroundPreview: false,
        screen: _MoreDestinationsScreen(
          destinations: _overflowDestinations(destinations),
          onDestinationSelected: _selectDestination,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    final destination = _destinationFor(_selectedKey, destinations);
    final bodyIndex = destinations.indexWhere(
      (item) => item.key == destination.key,
    );
    final navigationDestinations = _navigationDestinations(destinations);
    final selectedNavigationIndex = _selectedNavigationIndex(
      navigationDestinations,
      destination.key,
    );
    final isOverflowDestination = !_primaryNavigationKeys.contains(
      destination.key,
    );

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(destination.label),
            leading: isOverflowDestination
                ? IconButton(
                    tooltip: 'Wroc do Wiecej',
                    onPressed: () => _selectDestination(_DestinationKey.more),
                    icon: const Icon(Icons.arrow_back),
                  )
                : null,
          ),
          body: IndexedStack(
            index: bodyIndex,
            children: [for (final item in destinations) item.screen],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedNavigationIndex,
            onDestinationSelected: (index) =>
                _selectDestination(navigationDestinations[index].key),
            destinations: [
              for (final item in navigationDestinations)
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

  List<ExpenseCategory> get _activeExpenseCategories =>
      activeExpenseCategories(_customExpenseCategories);

  List<_Destination> _overflowDestinations(List<_Destination> destinations) {
    return destinations
        .where((item) => !_primaryNavigationKeys.contains(item.key))
        .where((item) => item.key != _DestinationKey.more)
        .toList(growable: false);
  }

  _Destination _destinationFor(
    _DestinationKey key, [
    List<_Destination>? destinations,
  ]) {
    final items = destinations ?? _destinations;
    return items.firstWhere((item) => item.key == key);
  }

  List<_Destination> _navigationDestinations(List<_Destination> destinations) {
    return [
      for (final key in _primaryNavigationKeys)
        destinations.firstWhere((item) => item.key == key),
    ];
  }

  int _selectedNavigationIndex(
    List<_Destination> navigationDestinations,
    _DestinationKey selectedKey,
  ) {
    final directIndex = navigationDestinations.indexWhere(
      (item) => item.key == selectedKey,
    );
    if (directIndex >= 0) {
      return directIndex;
    }
    return navigationDestinations.indexWhere(
      (item) => item.key == _DestinationKey.more,
    );
  }

  void _selectDestination(_DestinationKey key) {
    setState(() {
      _selectedKey = key;
      _hideSensitivePreview = false;
    });
    _trackDestination(key);
  }

  void _trackDestination(_DestinationKey key) {
    if (key == _DestinationKey.dashboard) {
      unawaited(
        widget.telemetry.track(
          TelemetryEvent.balanceViewed,
          parameters: {'screen': 'dashboard'},
        ),
      );
    }
    if (key == _DestinationKey.reports) {
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
      _selectedKey = _DestinationKey.addExpense;
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

enum _DestinationKey {
  dashboard,
  expenses,
  addExpense,
  reports,
  more,
  templates,
  custody,
  family,
  plans,
  costPlan,
  settings,
}

const _primaryNavigationKeys = [
  _DestinationKey.dashboard,
  _DestinationKey.expenses,
  _DestinationKey.addExpense,
  _DestinationKey.reports,
  _DestinationKey.more,
];

class _Destination {
  const _Destination({
    required this.key,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
    this.protectsBackgroundPreview = true,
  });

  final _DestinationKey key;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  final bool protectsBackgroundPreview;
}

class _MoreDestinationsScreen extends StatelessWidget {
  const _MoreDestinationsScreen({
    required this.destinations,
    required this.onDestinationSelected,
  });

  final List<_Destination> destinations;
  final ValueChanged<_DestinationKey> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: destinations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final destination = destinations[index];
        return ListTile(
          key: ValueKey('more-destination-${destination.key.name}'),
          leading: Icon(destination.icon),
          title: Text(destination.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onDestinationSelected(destination.key),
        );
      },
    );
  }
}
