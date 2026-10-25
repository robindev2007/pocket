import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/theme.dart';

/// A clean, flat borderless card without shadows.
class BorderlessCard extends StatelessWidget {
  const BorderlessCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.p16),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customColors = context.customColors;
    final radius = borderRadius ?? AppSizes.borderRadiusLg;

    // Ultra-light soft tone (lighter than #F1F5F9, #F8FAFC)
    // ensuring borderless cards have gentle, minimal contrast in light mode
    final defaultBg = isDark
        ? customColors.cardBackground
        : const Color(0xFFF8FAFC);
    final cardBg = backgroundColor ?? defaultBg;

    return Container(
      margin: margin,
      decoration: BoxDecoration(color: cardBg, borderRadius: radius),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
