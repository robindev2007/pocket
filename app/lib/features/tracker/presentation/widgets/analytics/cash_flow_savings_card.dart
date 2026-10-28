import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/transaction_model.dart';

class CashFlowSavingsCard extends StatelessWidget {
  const CashFlowSavingsCard({
    super.key,
    required this.transactions,
  });

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final customColors = context.customColors;
    final now = DateTime.now();

    final monthTx = transactions.where(
      (t) => t.date.year == now.year && t.date.month == now.month,
    );

    final income = monthTx
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = monthTx
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final net = income - expense;

    final double savingsRate = income > 0
        ? ((net / income) * 100).clamp(-100.0, 100.0)
        : (expense > 0 ? -100.0 : 0.0);
    final isPositive = net >= 0;

    final spentPct = income > 0
        ? ((expense / income) * 100).clamp(0, 100).round()
        : (expense > 0 ? 100 : 0);
    final savedPct = income > 0 ? max(0, 100 - spentPct) : 0;

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
                      Icons.account_balance_wallet_outlined,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cash Flow & Savings',
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
                  color: isPositive
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : colorScheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPositive
                      ? '${savingsRate.toStringAsFixed(0)}% Saved'
                      : '${(-savingsRate).toStringAsFixed(0)}% Over',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPositive ? colorScheme.primary : colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          AppSizes.gapH12,

          // 3 Column figures
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn(
                label: 'Inflow (Earned)',
                amount: CurrencyFormatter.format(income),
                color: colorScheme.onSurface,
                customColors: customColors,
              ),
              _buildStatColumn(
                label: 'Outflow (Spent)',
                amount: CurrencyFormatter.format(expense),
                color: colorScheme.onSurface,
                customColors: customColors,
              ),
              _buildStatColumn(
                label: isPositive ? 'Kept (Saved)' : 'Deficit',
                amount: CurrencyFormatter.format(net.abs()),
                color: isPositive ? colorScheme.primary : colorScheme.error,
                customColors: customColors,
              ),
            ],
          ),
          AppSizes.gapH12,

          // Segmented proportional cash flow bar
          if (income > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    if (spentPct > 0)
                      Expanded(
                        flex: spentPct,
                        child: Container(
                          color: isPositive
                              ? colorScheme.primary.withValues(alpha: 0.28)
                              : colorScheme.error.withValues(alpha: 0.65),
                        ),
                      ),
                    if (savedPct > 0)
                      Expanded(
                        flex: savedPct,
                        child: Container(
                          color: colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isPositive
                            ? colorScheme.primary.withValues(alpha: 0.28)
                            : colorScheme.error.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Spent $spentPct%',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: customColors.subtleText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Saved $savedPct%',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else if (expense > 0) ...[
            Text(
              'No income recorded this month (Spent ${CurrencyFormatter.format(expense)})',
              style: TextStyle(
                fontSize: 11,
                color: customColors.subtleText,
              ),
            ),
          ] else ...[
            Text(
              'No cash flow recorded this month yet.',
              style: TextStyle(
                fontSize: 11,
                color: customColors.subtleText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String amount,
    required Color color,
    required AppCustomColors customColors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: customColors.subtleText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
