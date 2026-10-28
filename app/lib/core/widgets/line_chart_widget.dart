import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class ChartDataPoint {
  const ChartDataPoint({
    required this.label,
    required this.amount,
  });

  final String label;
  final double amount;
}

class LineChartSeries {
  const LineChartSeries({
    required this.name,
    required this.color,
    required this.points,
  });

  final String name;
  final Color color;
  final List<ChartDataPoint> points;
}

/// A line chart widget modeled after fl_chart LineChartSample12 (Bitcoin Price History).
///
/// Supports both single-overview line and multi-category comparison lines with spend points.
class LineChartWidget extends StatelessWidget {
  const LineChartWidget({
    super.key,
    required this.points,
    this.series,
    this.lineColor = const Color(0xFF3B82F6),
    this.height = 180,
  });

  final List<ChartDataPoint> points;
  final List<LineChartSeries>? series;
  final Color lineColor;
  final double height;

  bool get _isMultiSeries => series != null && series!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectivePoints = _isMultiSeries ? series!.first.points : points;

    if (effectivePoints.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }

    final double maxAmount;
    if (_isMultiSeries) {
      final allAmounts = series!.expand((s) => s.points.map((p) => p.amount));
      maxAmount = allAmounts.isEmpty ? 0.0 : allAmounts.fold(0.0, max);
    } else {
      maxAmount = points.map((p) => p.amount).fold(0.0, max);
    }

    final maxY = maxAmount <= 0 ? 100.0 : maxAmount * 1.25;
    final maxX = (effectivePoints.length - 1).toDouble().clamp(1.0, double.infinity);

    final List<LineChartBarData> linesData;

    if (_isMultiSeries) {
      linesData = series!.map((s) {
        final spots = s.points.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.amount);
        }).toList();

        return LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          barWidth: 2.2,
          color: s.color,
          isStrokeCapRound: true,
          shadow: Shadow(
            color: s.color.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final hasSpend = spot.y > 0;
              return FlDotCirclePainter(
                radius: hasSpend ? 4.0 : 2.0,
                color: hasSpend ? s.color : s.color.withValues(alpha: 0.35),
                strokeWidth: hasSpend ? 1.5 : 0,
                strokeColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        );
      }).toList();
    } else {
      final spots = points.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.amount);
      }).toList();

      linesData = [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          barWidth: 2.5,
          color: lineColor,
          isStrokeCapRound: true,
          shadow: Shadow(
            color: lineColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final hasSpend = spot.y > 0;
              return FlDotCirclePainter(
                radius: hasSpend ? 4.5 : 2.5,
                color: hasSpend ? lineColor : lineColor.withValues(alpha: 0.35),
                strokeWidth: hasSpend ? 2 : 0,
                strokeColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                lineColor.withValues(alpha: 0.25),
                lineColor.withValues(alpha: 0.0),
              ],
              stops: const [0.3, 1.0],
            ),
          ),
        ),
      ];
    }

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(right: 6, top: 4),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: maxX,
            minY: 0,
            maxY: maxY,
            lineTouchData: LineTouchData(
              enabled: true,
              touchSpotThreshold: 12,
              getTouchLineStart: (_, _) => 0,
              getTouchLineEnd: (_, _) => double.infinity,
              getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((index) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: barData.color?.withValues(alpha: 0.6) ??
                          lineColor.withValues(alpha: 0.6),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, data, idx) {
                        return FlDotCirclePainter(
                          radius: 5.5,
                          color: data.color ?? lineColor,
                          strokeWidth: 2,
                          strokeColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                        );
                      },
                    ),
                  );
                }).toList();
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) =>
                    isDark ? const Color(0xFF1E293B) : Colors.white,
                tooltipBorderRadius: BorderRadius.circular(8),
                tooltipPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tooltipBorder: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  final activeSpots = _isMultiSeries
                      ? touchedSpots.where((s) => s.y > 0).toList()
                      : touchedSpots;
                  final spotsToShow = activeSpots.isNotEmpty
                      ? activeSpots
                      : touchedSpots.take(1).toList();

                  return spotsToShow.map((spot) {
                    final idx = spot.x.toInt();
                    if (_isMultiSeries) {
                      final s = series![spot.barIndex];
                      final label = (idx >= 0 && idx < s.points.length)
                          ? s.points[idx].label
                          : '';
                      return LineTooltipItem(
                        '${s.name} ($label)\n',
                        TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: s.color,
                        ),
                        children: [
                          TextSpan(
                            text: CurrencyFormatter.format(spot.y),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: s.color,
                            ),
                          ),
                        ],
                      );
                    } else {
                      final label = (idx >= 0 && idx < points.length)
                          ? points[idx].label
                          : '';
                      return LineTooltipItem(
                        '$label\n',
                        TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        children: [
                          TextSpan(
                            text: CurrencyFormatter.format(spot.y),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: lineColor,
                            ),
                          ),
                        ],
                      );
                    }
                  }).toList();
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 3 > 0 ? maxY / 3 : 25,
              getDrawingHorizontalLine: (value) => FlLine(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.06),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  interval: maxY / 3 > 0 ? maxY / 3 : 25,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max || value == meta.min) {
                      return const SizedBox.shrink();
                    }
                    String formatted;
                    if (value >= 1000000) {
                      formatted = '${(value / 1000000).toStringAsFixed(1)}M';
                    } else if (value >= 1000) {
                      formatted = '${(value / 1000).toStringAsFixed(0)}k';
                    } else {
                      formatted = value.toInt().toString();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 2,
                      child: Text(
                        formatted,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= effectivePoints.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 4,
                      child: Text(
                        effectivePoints[idx].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: linesData,
          ),
        ),
      ),
    );
  }
}
