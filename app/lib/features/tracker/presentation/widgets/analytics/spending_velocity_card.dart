import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/transaction_model.dart';

class SpendingVelocityCard extends StatelessWidget {
  const SpendingVelocityCard({
    super.key,
    required this.transactions,
  });

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;
    final now = DateTime.now();

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day;

    final thisMonthExpense = transactions
        .where((t) =>
            t.isExpense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);

    final dailyBurnRate = thisMonthExpense / max(currentDay, 1);
    final projectedMonthEnd = dailyBurnRate * daysInMonth;

    final prevMonthDate = DateTime(now.year, now.month - 1, 1);
    final lastMonthExpense = transactions
        .where((t) =>
            t.isExpense &&
            t.date.year == prevMonthDate.year &&
            t.date.month == prevMonthDate.month)
        .fold(0.0, (sum, t) => sum + t.amount);

    return BorderlessCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Icons.speed_rounded,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Spending Velocity & Forecast',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Day $currentDay of $daysInMonth',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          AppSizes.gapH12,
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Daily Burn Rate',
                  value: '${CurrencyFormatter.format(dailyBurnRate)}/day',
                  subtitle: 'Current pace',
                  colorScheme: colorScheme,
                  customColors: customColors,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: customColors.subtleText.withValues(alpha: 0.15),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: _buildMetricTile(
                    title: 'Projected Month-End',
                    value: CurrencyFormatter.format(projectedMonthEnd),
                    subtitle: lastMonthExpense > 0
                        ? 'Last mo: ${CurrencyFormatter.format(lastMonthExpense)}'
                        : 'Estimated total',
                    colorScheme: colorScheme,
                    customColors: customColors,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required ColorScheme colorScheme,
    required AppCustomColors customColors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: customColors.subtleText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: customColors.subtleText,
          ),
        ),
      ],
    );
  }
}
