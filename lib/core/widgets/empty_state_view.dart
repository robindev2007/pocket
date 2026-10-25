import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../theme/theme.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final customColors = context.customColors;
    final colorScheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: customColors.surfaceHover,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: customColors.subtleText,
              ),
            ),
            AppSizes.gapH16,
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            if (description != null) ...[
              AppSizes.gapH4,
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: customColors.subtleText,
                ),
              ),
            ],
            if (action != null) ...[
              AppSizes.gapH16,
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
