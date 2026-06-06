import 'package:flutter/material.dart';
import 'scanner_screen.dart';
import 'soil_scanner_screen.dart';
import 'yield_dashboard.dart';
import 'history_screen.dart';
import 'faq_screen.dart';
import '../theme/app_theme.dart';

import '../theme/localization.dart';

class HomeNav extends StatefulWidget {
  const HomeNav({Key? key}) : super(key: key);

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    YieldDashboard(),
    ScannerScreen(),
    SoilScannerScreen(),
    HistoryScreen(),
    FaqScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    return Scaffold(
      body: _screens[_currentIndex],
      extendBody: true, // Allows background to show under transparent navbar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard_rounded),
              label: local.translate('dashboard'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.energy_savings_leaf_outlined),
              selectedIcon: const Icon(Icons.energy_savings_leaf),
              label: local.translate('leaf_scan'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.landscape_outlined),
              selectedIcon: const Icon(Icons.landscape_rounded),
              label: local.translate('soil_scan'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history_rounded),
              label: local.translate('history'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book_rounded),
              label: local.locale == 'en' ? 'Guide' : 'मार्गदर्शन',
            ),
          ],
        ),
      ),
    );
  }
}
