import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../sync/presentation/widgets/item_sync_dot.dart';
import '../../controllers/tracker_controller.dart';
import '../dialogs/add_edit_transaction_dialog.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key, required this.onNavigateToTransactions});

  final VoidCallback onNavigateToTransactions;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  TimePeriod _selectedPeriod = TimePeriod.month;

  static const Map<String, Color> _categoryColorMap = {
    'Food': Color(0xFF10B981),
    'Groceries': Color(0xFF10B981),
    'Transport': Color(0xFFF59E0B),
    'Shopping': Color(0xFFEC4899),
    'Bills': Color(0xFF3B82F6),
    'Rent': Color(0xFF8B5CF6),
    'Entertainment': Color(0xFFA855F7),
    'Health': Color(0xFF06B6D4),
    'Education': Color(0xFFEAB308),
    'Salary': Color(0xFF10B981),
    'Freelance': Color(0xFF3B82F6),
    'Allowance': Color(0xFF06B6D4),
    'Debt Repayment': Color(0xFFF59E0B),
    'Other': Color(0xFF94A3B8),
    'General': Color(0xFF64748B),
  };

  Color _getCategoryColor(String? category) {
    if (category == null) return const Color(0xFF94A3B8);
    return _categoryColorMap[category] ??
        Color((category.hashCode & 0x00FFFFFF) | 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final controller = TrackerController.to;
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        onPressed: () => AddEditTransactionDialog.show(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Obx(() {
        final cashBalance = controller.cashBalance;
        final totalIncome = controller.totalIncome;
        final totalExpenses = controller.totalExpenses;
        final adjustedBalance = controller.adjustedBalance;
        final recentTransactions = controller.recentTransactions;

        // Period-filtered data
        final periodExpense = controller.getTotalExpenseForPeriod(
          _selectedPeriod,
        );
        final periodSpendingMap = controller.getSpendingByTagForPeriod(
          _selectedPeriod,
        );

        final donutItems = periodSpendingMap.entries.map((entry) {
          return CategorySpendingItem(
            category: entry.key,
            amount: entry.value,
            color: _getCategoryColor(entry.key),
          );
        }).toList();

        return ScreenContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. COMPACT HERO TOTAL BALANCE CARD (No border, reduced height)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: customColors.heroCardBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(cashBalance),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(adjustedBalance),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Income
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.south_west_rounded,
                                  size: 11.5,
                                  color: Colors.white70,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'INCOME',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              CurrencyFormatter.format(totalIncome),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        // Middle Divider
                        Container(
                          width: 1,
                          height: 26,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        // Right: Expenses
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.north_east_rounded,
                                  size: 11.5,
                                  color: Colors.white70,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'EXPENSES',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              CurrencyFormatter.format(totalExpenses),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSizes.gapH12,

              // 2. TIME FILTER PILLS (Reusable AppFilterPill style)
              Row(
                children: TimePeriod.values.map((period) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppFilterPill(
                      label: period.displayName,
                      isSelected: period == _selectedPeriod,
                      onTap: () => setState(() => _selectedPeriod = period),
                    ),
                  );
                }).toList(),
              ),
              AppSizes.gapH12,

              // 3. COMPACT MONTHLY SPENDING CARD WITH DONUT CHART (No border, reduced height)
              BorderlessCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedPeriod.displayName}ly Spending',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        InkWell(
                          onTap: widget.onNavigateToTransactions,
                          child: const Row(
                            children: [
                              Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                size: 14,
                                color: Color(0xFF3B82F6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppSizes.gapH12,

                    // Compact Donut Chart
                    Center(
                      child: DonutChartWidget(
                        items: donutItems,
                        totalAmount: periodExpense,
                        size: 140,
                        strokeWidth: 16,
                      ),
                    ),
                    AppSizes.gapH16,

                    // Category Legend Grid
                    if (donutItems.isEmpty)
                      Center(
                        child: Text(
                          'No spending recorded for this ${_selectedPeriod.displayName.toLowerCase()}.',
                          style: TextStyle(
                            fontSize: 12,
                            color: customColors.subtleText,
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 24,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 4,
                            ),
                        itemCount: donutItems.length,
                        itemBuilder: (context, index) {
                          final item = donutItems[index];
                          return Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(item.amount),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: customColors.subtleText,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              AppSizes.gapH16,

              // 4. RECENT TRANSACTIONS HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (controller.transactions.isNotEmpty)
                    TextButton(
                      onPressed: widget.onNavigateToTransactions,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                ],
              ),
              AppSizes.gapH8,

              if (recentTransactions.isEmpty)
                BorderlessCard(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No transactions yet. Tap (+) to add an expense.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: customColors.subtleText,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTransactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final tx = recentTransactions[index];
                    final isIncome = tx.isIncome;
                    final categoryColor = _getCategoryColor(tx.tag);

                    return BorderlessCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? const Color(0xFF10B981)
                                        .withValues(alpha: 0.12)
                                  : categoryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: isIncome
                                  ? const Color(0xFF10B981)
                                  : categoryColor,
                              size: 16,
                            ),
                          ),
                          AppSizes.gapW10,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        tx.title,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    ItemSyncDot(isSynced: tx.isSynced),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      CurrencyFormatter.formatDate(tx.date),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: customColors.subtleText,
                                      ),
                                    ),
                                    if (tx.tag != null) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '•',
                                        style: TextStyle(
                                          color: customColors.subtleText,
                                          fontSize: 9,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        tx.tag!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: categoryColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isIncome
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 70),
            ],
          ),
        );
      }),
    );
  }
}
