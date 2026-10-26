import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class CategorySpendingItem {
  CategorySpendingItem({
    required this.category,
    required this.amount,
    required this.color,
  });

  final String category;
  final double amount;
  final Color color;
}

class DonutChartWidget extends StatelessWidget {
  const DonutChartWidget({
    super.key,
    required this.items,
    required this.totalAmount,
    this.size = 180,
    this.strokeWidth = 22,
  });

  final List<CategorySpendingItem> items;
  final double totalAmount;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String centerAmountText;
    if (totalAmount >= 1000000) {
      centerAmountText = '৳${(totalAmount / 1000000).toStringAsFixed(1)}M';
    } else if (totalAmount >= 1000) {
      centerAmountText = '৳${(totalAmount / 1000).toStringAsFixed(1)}k';
    } else {
      centerAmountText = CurrencyFormatter.format(totalAmount);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              items: items,
              totalAmount: totalAmount,
              strokeWidth: strokeWidth,
              emptyTrackColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerAmountText,
                style: TextStyle(
                  fontSize: size * 0.14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SPENT',
                style: TextStyle(
                  fontSize: size * 0.07,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.items,
    required this.totalAmount,
    required this.strokeWidth,
    required this.emptyTrackColor,
  });

  final List<CategorySpendingItem> items;
  final double totalAmount;
  final double strokeWidth;
  final Color emptyTrackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paintBase = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (totalAmount <= 0 || items.isEmpty) {
      canvas.drawCircle(center, radius, paintBase..color = emptyTrackColor);
      return;
    }

    double startAngle = -pi / 2;
    const gapAngle = 0.04; // subtle gap between segments for modern clean look

    final validItems = items.where((e) => e.amount > 0).toList();
    final totalValidAmount =
        validItems.fold(0.0, (sum, item) => sum + item.amount);

    for (final item in validItems) {
      final sweepAngle = (item.amount / totalValidAmount) * 2 * pi;
      final effectiveSweep = max(0.0, sweepAngle - gapAngle);

      final paintItem = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = item.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gapAngle / 2),
        effectiveSweep,
        false,
        paintItem,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.totalAmount != totalAmount ||
        oldDelegate.items != items;
  }
}

