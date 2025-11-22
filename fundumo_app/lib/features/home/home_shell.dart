import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard/dashboard_page.dart';
import '../envelopes/envelopes_view.dart';
import '../saving_goals/saving_goals_view.dart';
import '../settings/settings_view.dart';
import '../shared/shared_view.dart';
import '../side_gigs/side_gigs_view.dart';
import '../subscriptions/subscriptions_view.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  late final List<_ShellDestination> _destinations = [
    _ShellDestination(
      title: 'Fundumo Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      builder: (context, ref) => const ShellPage(
        body: DashboardView(),
      ),
    ),
    _ShellDestination(
      title: 'Envelopes',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      builder: (context, ref) => ShellPage(
        body: const EnvelopesView(),
        fab: const EnvelopesFab(),
      ),
    ),
    _ShellDestination(
      title: 'Subscriptions',
      icon: Icons.subscriptions_outlined,
      selectedIcon: Icons.subscriptions,
      builder: (context, ref) => const ShellPage(
        body: SubscriptionsView(),
      ),
    ),
    _ShellDestination(
      title: 'Side gigs',
      icon: Icons.timer_outlined,
      selectedIcon: Icons.timer,
      builder: (context, ref) => ShellPage(
        body: const SideGigsView(),
        fab: const SideGigsFab(),
      ),
    ),
    _ShellDestination(
      title: 'Saving goals',
      icon: Icons.savings_outlined,
      selectedIcon: Icons.savings,
      builder: (context, ref) => ShellPage(
        body: const SavingGoalsView(),
        fab: const SavingGoalsFab(),
      ),
    ),
    _ShellDestination(
      title: 'Shared & receipts',
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
      builder: (context, ref) => ShellPage(
        body: const SharedFinancesView(),
        fab: const SharedFinancesFab(),
      ),
    ),
  _ShellDestination(
    title: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    builder: (context, ref) => const ShellPage(
      body: SettingsView(),
    ),
  ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = _destinations
        .map((destination) => destination.builder(context, ref))
        .toList(growable: false);
    final currentPage = pages[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[_currentIndex].title),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages.map((page) => page.body).toList(growable: false),
      ),
      floatingActionButton: currentPage.fab,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == _currentIndex) {
            return;
          }
          setState(() => _currentIndex = index);
        },
        destinations: _destinations
            .map(
              (destination) => NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.title,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final ShellPage Function(BuildContext, WidgetRef) builder;
}

class ShellPage {
  const ShellPage({
    required this.body,
    this.fab,
  });

  final Widget body;
  final Widget? fab;
}

