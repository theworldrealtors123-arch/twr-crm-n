import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../auth/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../leads/leads_list_screen.dart';
import '../profile/profile_screen.dart';

/// Bottom navigation shell. Destinations are built from the signed-in user's
/// role so Day 2 modules can be added without touching the screens.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.watch<AuthProvider>().user;

    final List<_Destination> destinations = <_Destination>[
      _Destination(
        label: 'Home',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        builder: () => DashboardScreen(
          onSeeAllLeads: () => setState(() => _index = 1),
        ),
      ),
      _Destination(
        label: 'Leads',
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        builder: () => const LeadsListScreen(),
      ),
      _Destination(
        label: 'Profile',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        builder: () => const ProfileScreen(),
      ),
    ];

    // Role-aware: reserved for Day 2 modules (Reports, Users, Attendance).
    final List<_Destination> visible = destinations
        .where((_Destination destination) =>
            destination.roles == null ||
            (user != null && destination.roles!.contains(user.role)))
        .toList();

    final int safeIndex = _index.clamp(0, visible.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: visible.map((_Destination d) => d.builder()).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        key: const Key('main_bottom_nav'),
        currentIndex: safeIndex,
        onTap: (int value) => setState(() => _index = value),
        items: visible
            .map(
              (_Destination destination) => BottomNavigationBarItem(
                icon: Icon(destination.icon),
                activeIcon: Icon(destination.activeIcon),
                label: destination.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.builder,
    this.roles,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget Function() builder;

  /// null means "visible to every role".
  final List<String>? roles;
}
