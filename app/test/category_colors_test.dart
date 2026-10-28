import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage_money/core/constants/app_constants.dart';
import 'package:manage_money/core/theme/app_colors.dart';
import 'package:manage_money/core/widgets/donut_chart_widget.dart';

void main() {
  group('Category and Transaction Color Tests', () {
    test('Every default expense category has a unique distinct color', () {
      final colors = <Color>{};
      for (final tag in AppConstants.defaultExpenseTags) {
        final color = AppColors.getCategoryColor(tag);
        expect(
          colors.contains(color),
          isFalse,
          reason: 'Duplicate color found for expense tag: $tag',
        );
        colors.add(color);
      }
    });

    test('Every default income category has a unique distinct color', () {
      final colors = <Color>{};
      for (final tag in AppConstants.defaultIncomeTags) {
        final color = AppColors.getCategoryColor(tag, isIncome: true);
        expect(
          colors.contains(color),
          isFalse,
          reason: 'Duplicate color found for income tag: $tag',
        );
        colors.add(color);
      }
    });

    test('Custom categories and uncategorized titles receive consistent deterministic colors', () {
      final customColor1 = AppColors.getCategoryColor('Coffee');
      final customColor2 = AppColors.getCategoryColor('coffee');
      expect(customColor1, equals(customColor2));

      final txColor = AppColors.getTransactionColor(title: 'Gym membership');
      expect(txColor, isNotNull);

      final taggedColor = AppColors.getTransactionColor(
        tag: 'Transport',
        title: 'Train ticket',
      );
      expect(taggedColor, equals(AppColors.getCategoryColor('Transport')));
    });

    test('DonutChartWidget correctly handles single item and multiple items', () {
      final singleItem = [
        CategorySpendingItem(
          category: 'Food',
          amount: 500,
          color: AppColors.getCategoryColor('Food'),
        ),
      ];

      final widget1 = DonutChartWidget(items: singleItem, totalAmount: 500);
      expect(widget1.items.length, 1);

      final multiItems = [
        CategorySpendingItem(
          category: 'Food',
          amount: 500,
          color: AppColors.getCategoryColor('Food'),
        ),
        CategorySpendingItem(
          category: 'Transport',
          amount: 300,
          color: AppColors.getCategoryColor('Transport'),
        ),
      ];
      final widget2 = DonutChartWidget(items: multiItems, totalAmount: 800);
      expect(widget2.items.length, 2);
      expect(widget2.items[0].color, isNot(equals(widget2.items[1].color)));
    });
  });
}
