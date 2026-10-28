import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../controllers/tracker_controller.dart';
import '../dialogs/backup_restore_dialog.dart';

class SummaryTab extends StatelessWidget {
  const SummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TrackerController.to;
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;
    final themeController = ThemeController.to;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        final totalIncome = controller.totalIncome;
        final totalExpenses = controller.totalExpenses;
        final netCashflow = totalIncome - totalExpenses;
        final spendingByTag = controller.spendingByTag;

        return ScreenContainer(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CASH FLOW OVERVIEW
              Text(
                'Financial Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              AppSizes.gapH12,

              BorderlessCard(
                child: Column(
                  children: [
                    _SummaryRow(
                      title: 'Total Income',
                      amountText: CurrencyFormatter.format(totalIncome),
                      color: const Color(0xFF16A34A),
                      icon: Icons.arrow_downward_rounded,
                    ),
                    const Divider(height: 20),
                    _SummaryRow(
                      title: 'Total Expenses',
                      amountText: CurrencyFormatter.format(totalExpenses),
                      color: const Color(0xFFDC2626),
                      icon: Icons.arrow_upward_rounded,
                    ),
                    const Divider(height: 20),
                    _SummaryRow(
                      title: 'Net Cash Flow',
                      amountText: CurrencyFormatter.format(netCashflow),
                      color: netCashflow >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      icon: netCashflow >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              AppSizes.gapH24,

              // 2. SPENDING BY TAG / CATEGORY
              Text(
                'Spending by Tag / Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              AppSizes.gapH12,

              if (spendingByTag.isEmpty)
                BorderlessCard(
                  padding: const EdgeInsets.all(AppSizes.p20),
                  child: Center(
                    child: Text(
                      'No expense records yet to analyze.',
                      style: TextStyle(fontSize: 13, color: customColors.subtleText),
                    ),
                  ),
                )
              else
                BorderlessCard(
                  child: Column(
                    children: spendingByTag.entries.map((entry) {
                      final percentage = totalExpenses > 0 ? (entry.value / totalExpenses) : 0.0;
                      final categoryColor = AppColors.getCategoryColor(entry.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: categoryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${CurrencyFormatter.format(entry.value)} (${(percentage * 100).toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: customColors.subtleText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                minHeight: 6,
                                backgroundColor: customColors.surfaceHover,
                                valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              AppSizes.gapH24,

              // 4. DATA BACKUP & LOCAL STORAGE
              Text(
                'Local Storage & Backup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              AppSizes.gapH12,

              BorderlessCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All records are securely stored offline in device local storage.',
                      style: TextStyle(fontSize: 13, color: customColors.subtleText),
                    ),
                    AppSizes.gapH12,
                    AppButton.outline(
                      text: 'Backup & Restore Data (JSON)',
                      prefixIcon: const Icon(Icons.backup_outlined, size: 16),
                      isFullWidth: true,
                      onPressed: () => BackupRestoreDialog.show(context),
                    ),
                  ],
                ),
              ),
              AppSizes.gapH24,

              // 5. THEME & APPEARANCE QUICK TOGGLE
              Text(
                'App Theme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              AppSizes.gapH12,

              BorderlessCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.isDarkMode ? 'Dark Mode Active' : 'Light Mode Active',
                          style: TextStyle(
                            fontSize: 12,
                            color: customColors.subtleText,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        AppFilterPill(
                          label: 'Light',
                          isSelected: !context.isDarkMode,
                          onTap: () => themeController.setThemeMode(ThemeMode.light),
                        ),
                        AppSizes.gapW8,
                        AppFilterPill(
                          label: 'Dark',
                          isSelected: context.isDarkMode,
                          onTap: () => themeController.setThemeMode(ThemeMode.dark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSizes.gapH32,
            ],
          ),
        );
      }),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.title,
    required this.amountText,
    required this.color,
    required this.icon,
    this.isBold = false,
  });

  final String title;
  final String amountText;
  final Color color;
  final IconData icon;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        AppSizes.gapW8,
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          amountText,
          style: TextStyle(
            fontSize: isBold ? 16 : 14.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
