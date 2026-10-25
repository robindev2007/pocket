import 'package:flutter/material.dart';
import '../theme/app_custom_colors.dart';

/// Reusable filter pill widget styled identically to the Week / Month / Year period tabs.
///
/// Features smooth animated selection transitions, rounded corners, and uses
/// reusable design tokens from [AppCustomColors] and [ThemeData.colorScheme.primary].
class AppFilterPill extends StatelessWidget {
  const AppFilterPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.accentColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? icon;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customColors = theme.extension<AppCustomColors>();

    final activeBg = accentColor ?? customColors?.pillActiveBackground ?? theme.colorScheme.primary;
    final inactiveBg = customColors?.pillBackground ??
        (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));

    final activeTextColor = customColors?.pillActiveText ?? Colors.white;
    final inactiveTextColor = customColors?.pillText ??
        (isDark ? Colors.white70 : const Color(0xFF64748B));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: padding,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeTextColor : inactiveTextColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

