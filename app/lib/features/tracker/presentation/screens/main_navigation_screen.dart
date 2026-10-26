import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/theme.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../sync/controllers/sync_controller.dart';
import '../../../sync/presentation/widgets/sync_status_badge.dart';
import '../../controllers/tracker_controller.dart';
import '../dialogs/welcome_name_dialog.dart';
import 'dashboard_tab.dart';
import 'debts_tab.dart';
import 'profile_tab.dart';
import 'transactions_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Get.put(AuthController());
    Get.put(TrackerController());
    Get.put(SyncController());
    _checkFirstLaunchOnboarding();
  }

  void _checkFirstLaunchOnboarding() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = TrackerController.to;
      if (controller.isLoading.value) {
        await controller.loadAllData();
      }
      if (controller.userName.isEmpty || !controller.hasCompletedOnboarding) {
        if (mounted) {
          WelcomeNameDialog.show(context);
        }
      }
    });
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final controller = TrackerController.to;
    final themeController = ThemeController.to;
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;
    final isDark = context.isDarkMode;

    final titles = ['Dashboard', 'Transactions', 'Debt Tracker', 'My Profile'];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF090D16)
          : Colors.white,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // No background as requested
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 18,
        title: _currentIndex == 0
            ? Obx(() {
                final name = controller.userName.isNotEmpty
                    ? controller.userName
                    : 'Guest';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: colorScheme.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hello, $name 👋',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: customColors.subtleText,
                        height: 1.1,
                      ),
                    ),
                  ],
                );
              })
            : Text(
                titles[_currentIndex],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colorScheme.onSurface,
                ),
              ),
        actions: [
          const SyncStatusBadge(),
          // Theme Switcher Button matching the circular icon in screenshot
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Toggle Theme Mode',
              icon: Icon(
                context.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                size: 20,
                color: colorScheme.onSurface,
              ),
              onPressed: () => themeController.toggleThemeMode(context),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardTab(onNavigateToTransactions: () => _onTabTapped(1)),
          const TransactionsTab(),
          const DebtsTab(),
          const ProfileTab(),
        ],
      ),
      // Standard, production-grade Flutter BottomNavigationBar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: isDark ? const Color(0xFF0F1420) : Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF3B82F6),
          unselectedItemColor: customColors.subtleText,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 22),
              activeIcon: Icon(Icons.home_rounded, size: 22),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined, size: 22),
              activeIcon: Icon(Icons.bar_chart_rounded, size: 22),
              label: 'STATS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined, size: 22),
              activeIcon: Icon(Icons.account_balance_wallet_rounded, size: 22),
              label: 'DEBTS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 22),
              activeIcon: Icon(Icons.person_rounded, size: 22),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}
