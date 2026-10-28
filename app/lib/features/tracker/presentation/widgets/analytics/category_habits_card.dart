import 'package:flutter/material.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/transaction_model.dart';

class CategoryHabitsCard extends StatelessWidget {
  const CategoryHabitsCard({
    super.key,
    required this.transactions,
  });

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;
    final now = DateTime.now();

    final monthExpenses = transactions
        .where((t) =>
            t.isExpense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .toList();

    final totalExpense =
        monthExpenses.fold(0.0, (sum, t) => sum + t.amount);

    final catMap = <String, double>{};
    double weekdaySpend = 0.0;

    for (final t in monthExpenses) {
      final cat = (t.tag != null && t.tag!.trim().isNotEmpty)
          ? t.tag!.trim()
          : 'Other';
      catMap[cat] = (catMap[cat] ?? 0.0) + t.amount;

      if (t.date.weekday <= 5) {
        weekdaySpend += t.amount;
      }
    }

    final sortedCats = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sortedCats.take(3).toList();

    final weekdayPct = totalExpense > 0
        ? ((weekdaySpend / totalExpense) * 100).round()
        : 50;
    final weekendPct = 100 - weekdayPct;

    return BorderlessCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pie_chart_outline_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Top Spending & Habits',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          AppSizes.gapH12,

          if (top3.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No expenses recorded this month.',
                style: TextStyle(fontSize: 12, color: customColors.subtleText),
              ),
            )
          else ...[
            ...top3.map((entry) {
              final pct = totalExpense > 0
                  ? (entry.value / totalExpense * 100).round()
                  : 0;
              final color = AppColors.getCategoryColor(entry.key);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
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
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${entry.key} ($pct%)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyFormatter.format(entry.value),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: customColors.subtleText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: totalExpense > 0
                            ? (entry.value / totalExpense).clamp(0.0, 1.0)
                            : 0.0,
                        minHeight: 4,
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            AppSizes.gapH8,

            // Weekday vs Weekend split
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekdays: $weekdayPct%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: customColors.subtleText,
                    ),
                  ),
                  Text(
                    'Weekends: $weekendPct%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: customColors.subtleText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
