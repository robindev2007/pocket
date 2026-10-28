import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../sync/presentation/widgets/item_sync_dot.dart';
import '../../../../data/models/transaction_model.dart';
import '../../controllers/tracker_controller.dart';
import '../dialogs/add_edit_transaction_dialog.dart';
import '../widgets/analytics/cash_flow_savings_card.dart';
import '../widgets/analytics/category_habits_card.dart';
import '../widgets/analytics/spending_velocity_card.dart';
import 'transaction_history_screen.dart';

enum StatsViewPeriod {
  daily,
  weekly,
  monthly;

  String get label {
    switch (this) {
      case StatsViewPeriod.daily:
        return 'Daily';
      case StatsViewPeriod.weekly:
        return 'Weekly';
      case StatsViewPeriod.monthly:
        return 'Monthly';
    }
  }
}

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  StatsViewPeriod _selectedPeriod = StatsViewPeriod.monthly;
  bool _showCategoryBreakdown = false;

  bool _isInStatsPeriod(DateTime date, StatsViewPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case StatsViewPeriod.daily:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case StatsViewPeriod.weekly:
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            date.isBefore(startOfWeek.add(const Duration(days: 7)));
      case StatsViewPeriod.monthly:
        return date.year == now.year && date.month == now.month;
    }
  }

  List<ChartDataPoint> _buildChartPoints(
    List<TransactionModel> periodExpenses,
    DateTime now,
  ) {
    switch (_selectedPeriod) {
      case StatsViewPeriod.daily:
        const labels = ['12 AM', '4 AM', '8 AM', '12 PM', '4 PM', '8 PM'];
        final bucketAmounts = List.filled(6, 0.0);
        for (final tx in periodExpenses) {
          if (tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day) {
            final hour = tx.date.hour;
            final bucketIndex = (hour ~/ 4).clamp(0, 5);
            bucketAmounts[bucketIndex] += tx.amount;
          }
        }
        return List.generate(
          6,
          (i) => ChartDataPoint(label: labels[i], amount: bucketAmounts[i]),
        );

      case StatsViewPeriod.weekly:
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        return List.generate(7, (i) {
          final currentDay = startOfWeek.add(Duration(days: i));
          final dayTotal = periodExpenses
              .where((t) =>
                  t.date.year == currentDay.year &&
                  t.date.month == currentDay.month &&
                  t.date.day == currentDay.day)
              .fold(0.0, (sum, t) => sum + t.amount);
          return ChartDataPoint(label: days[i], amount: dayTotal);
        });

      case StatsViewPeriod.monthly:
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final weekRanges = [
          {'label': 'W1', 'start': 1, 'end': 7},
          {'label': 'W2', 'start': 8, 'end': 14},
          {'label': 'W3', 'start': 15, 'end': 21},
          {'label': 'W4', 'start': 22, 'end': 28},
          if (daysInMonth > 28)
            {'label': 'W5', 'start': 29, 'end': daysInMonth},
        ];
        return weekRanges.map((r) {
          final start = r['start'] as int;
          final end = r['end'] as int;
          final total = periodExpenses
              .where((t) =>
                  t.date.year == now.year &&
                  t.date.month == now.month &&
                  t.date.day >= start &&
                  t.date.day <= end)
              .fold(0.0, (sum, t) => sum + t.amount);
          return ChartDataPoint(
            label: r['label'] as String,
            amount: total,
          );
        }).toList();
    }
  }

  Widget _buildTransactionCard({
    required BuildContext context,
    required TransactionModel tx,
    required ColorScheme colorScheme,
    required AppCustomColors customColors,
  }) {
    final isIncome = tx.isIncome;
    final txColor = AppColors.getTransactionColor(
      tag: tx.tag,
      title: tx.title,
      isIncome: isIncome,
    );

    return BorderlessCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => AddEditTransactionDialog.show(
        context,
        transactionToEdit: tx,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: txColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: txColor,
              size: 18,
            ),
          ),
          AppSizes.gapW12,
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
                          fontSize: 14,
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
                        fontSize: 11.5,
                        color: customColors.subtleText,
                      ),
                    ),
                    if (tx.tag != null && tx.tag!.trim().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(
                          color: customColors.subtleText,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tx.tag!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: txColor,
                        ),
                      ),
                    ],
                  ],
                ),
                if (tx.note != null && tx.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tx.note!,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: customColors.subtleText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isIncome
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        label: const Text(
          'Add Transaction',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Obx(() {
        final now = DateTime.now();

        // 1. Period Expenses and Line Chart Points
        final periodExpenses = controller.transactions
            .where(
              (t) => t.isExpense && _isInStatsPeriod(t.date, _selectedPeriod),
            )
            .toList();

        final periodExpenseTotal = periodExpenses.fold(
          0.0,
          (sum, t) => sum + t.amount,
        );

        final chartPoints = _buildChartPoints(periodExpenses, now);

        final categoryMap = <String, List<TransactionModel>>{};
        for (final t in periodExpenses) {
          final cat = (t.tag != null && t.tag!.trim().isNotEmpty)
              ? t.tag!.trim()
              : 'Other';
          categoryMap.putIfAbsent(cat, () => []).add(t);
        }

        final categorySeries = categoryMap.entries.map((entry) {
          return LineChartSeries(
            name: entry.key,
            color: AppColors.getCategoryColor(entry.key),
            points: _buildChartPoints(entry.value, now),
          );
        }).toList()
          ..sort((a, b) {
            final sumA = a.points.fold(0.0, (s, p) => s + p.amount);
            final sumB = b.points.fold(0.0, (s, p) => s + p.amount);
            return sumB.compareTo(sumA);
          });

        // 2. Recent Transactions (Top 5)
        final recentTransactions =
            controller.sortedTransactions.take(5).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CHARTS SECTION (Daily / Weekly / Monthly Switcher)
              Row(
                children: StatsViewPeriod.values.map((period) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppFilterPill(
                      label: period.label,
                      isSelected: period == _selectedPeriod,
                      onTap: () => setState(() => _selectedPeriod = period),
                    ),
                  );
                }).toList(),
              ),
              AppSizes.gapH12,

              // Top Line Chart Card with spend points
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_selectedPeriod.label} Spending',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(periodExpenseTotal),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: customColors.subtleText,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch.adaptive(
                                value: _showCategoryBreakdown,
                                activeColor: colorScheme.primary,
                                onChanged: (val) => setState(
                                  () => _showCategoryBreakdown = val,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _showCategoryBreakdown
                          ? 'Comparing categories by distinct colored lines'
                          : 'Tap points to inspect spend',
                      style: TextStyle(
                        fontSize: 11,
                        color: customColors.subtleText,
                      ),
                    ),
                    AppSizes.gapH12,

                    LineChartWidget(
                      points: chartPoints,
                      series: _showCategoryBreakdown ? categorySeries : null,
                      lineColor: colorScheme.primary,
                      height: 160,
                    ),

                    if (_showCategoryBreakdown && categorySeries.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: categorySeries.map((s) {
                          final total = s.points.fold(
                            0.0,
                            (sum, p) => sum + p.amount,
                          );
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: s.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                s.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                CurrencyFormatter.format(total),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: customColors.subtleText,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              AppSizes.gapH16,

              // 2. FINANCIAL ANALYTICS & INSIGHTS
              CashFlowSavingsCard(transactions: controller.transactions),
              AppSizes.gapH12,
              SpendingVelocityCard(transactions: controller.transactions),
              AppSizes.gapH12,
              CategoryHabitsCard(transactions: controller.transactions),
              AppSizes.gapH16,

              // 3. HISTORY SECTION WITH VIEW ALL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'History',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${controller.sortedTransactions.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: customColors.subtleText,
                        ),
                      ),
                    ],
                  ),
                  if (controller.sortedTransactions.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          TransactionHistoryScreen.navigate(context),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              AppSizes.gapH8,

              if (recentTransactions.isEmpty)
                const EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions found',
                  description: 'Transactions will appear here once recorded.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTransactions.length,
                  separatorBuilder: (context, index) => AppSizes.gapH8,
                  itemBuilder: (context, index) {
                    final tx = recentTransactions[index];
                    return _buildTransactionCard(
                      context: context,
                      tx: tx,
                      colorScheme: colorScheme,
                      customColors: customColors,
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }
}
