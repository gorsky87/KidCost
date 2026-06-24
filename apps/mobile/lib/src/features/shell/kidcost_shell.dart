import 'package:flutter/material.dart';

import '../onboarding/onboarding_profile.dart';
import 'screens/add_expense_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/family_screen.dart';
import 'screens/settings_screen.dart';

class KidCostShell extends StatefulWidget {
  const KidCostShell({
    required this.userEmail,
    required this.isDemoSession,
    required this.onboardingProfile,
    required this.onSignOut,
    super.key,
  });

  final String userEmail;
  final bool isDemoSession;
  final OnboardingProfile onboardingProfile;
  final Future<void> Function() onSignOut;

  @override
  State<KidCostShell> createState() => _KidCostShellState();
}

class _KidCostShellState extends State<KidCostShell> {
  int _selectedIndex = 0;

  late final List<_Destination> _destinations = [
    _Destination(
      label: 'Start',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      screen: DashboardScreen(profile: widget.onboardingProfile),
    ),
    _Destination(
      label: 'Koszty',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      screen: ExpensesScreen(),
    ),
    _Destination(
      label: 'Dodaj',
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle,
      screen: AddExpenseScreen(),
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
