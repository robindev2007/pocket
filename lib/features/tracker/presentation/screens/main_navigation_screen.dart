import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/theme.dart';
import '../../../../data/models/transaction_model.dart';
import '../../controllers/tracker_controller.dart';
import '../dialogs/add_edit_transaction_dialog.dart';
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
    final controller = Get.put(TrackerController());
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
      // Floating Action Button shown ONLY on Home dashboard (tab 0)
      floatingActionButton: _currentIndex == 0
          ? Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onPressed: () => AddEditTransactionDialog.show(
                  context,
                  initialType: TransactionType.expense,
                ),
                child: const Icon(Icons.add, size: 28),
              ),
            )
          : null,
      // Clean, Minimal Bottom Bar matching screenshot
      bottomNavigationBar: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1420) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _NavBarItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'HOME',
                isSelected: _currentIndex == 0,
                onTap: () => _onTabTapped(0),
              ),
              _NavBarItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'STATS',
                isSelected: _currentIndex == 1,
                onTap: () => _onTabTapped(1),
              ),
              _NavBarItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'DEBTS',
                isSelected: _currentIndex == 2,
                onTap: () => _onTabTapped(2),
              ),
              _NavBarItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'PROFILE',
                isSelected: _currentIndex == 3,
                onTap: () => _onTabTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final customColors = context.customColors;

    const activeColor = Color(0xFF3B82F6);
    final inactiveColor = customColors.subtleText;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.6,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
