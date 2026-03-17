import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'scholarships_screen.dart';
import 'loans_screen.dart';
import 'ai_assistant_screen.dart';
import 'profile_screen.dart';
import 'admin_panel_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabsUser = [
    _NavItem(Icons.school_rounded, 'Scholarships'),
    _NavItem(Icons.account_balance_rounded, 'Loans'),
    _NavItem(Icons.chat_bubble_rounded, 'AI Assistant'),
    _NavItem(Icons.person_rounded, 'Profile'),
  ];

  static const _tabsAdmin = [
    ..._tabsUser,
    _NavItem(Icons.admin_panel_settings_rounded, 'Admin'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isAdmin = app.currentUser?.isAdmin == true;
    final tabs = isAdmin ? _tabsAdmin : _tabsUser;
    final children = [
      const ScholarshipsScreen(),
      const LoansScreen(),
      const AIAssistantScreen(),
      const ProfileScreen(),
      if (isAdmin) const AdminPanelScreen(),
    ];
    final currentIndex = _index.clamp(0, children.length - 1);
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: children,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: tabs.map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label)).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
