import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_custom_colors.dart';

/// Button visual style variants.
enum ButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
}

/// Button size options.
enum ButtonSize {
  sm,
  md,
  lg,
  icon,
}

/// A highly reusable, modern Flutter button widget.
///
/// Supports multiple [variant]s, [size]s, loading indicators, and custom icons.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
  }) : assert(
          text != null || child != null || prefixIcon != null,
          'Must provide either text, child, or prefixIcon',
        );

  /// Convenient factory for primary / default variant
  const AppButton.primary({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.size = ButtonSize.md,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
  }) : variant = ButtonVariant.primary;

  /// Convenient factory for secondary variant
  const AppButton.secondary({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.size = ButtonSize.md,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
  }) : variant = ButtonVariant.secondary;

  /// Convenient factory for outline variant
  const AppButton.outline({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.size = ButtonSize.md,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
  }) : variant = ButtonVariant.outline;

  /// Convenient factory for ghost variant
  const AppButton.ghost({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.size = ButtonSize.md,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
  }) : variant = ButtonVariant.ghost;

  /// Convenient factory for destructive variant
  const AppButton.destructive({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.size = ButtonSize.md,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
  }) : variant = ButtonVariant.destructive;

  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isLoading;
  final bool isFullWidth;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final customColors = theme.extension<AppCustomColors>();

    // Resolve Colors according to variant
    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case ButtonVariant.primary:
        bg = backgroundColor ?? colorScheme.primary;
        fg = foregroundColor ?? colorScheme.onPrimary;
        break;
      case ButtonVariant.secondary:
        bg = backgroundColor ??
            (customColors?.surfaceHover ??
                (isDark ? AppColors.slate800 : AppColors.slate200));
        fg = foregroundColor ?? colorScheme.onSurface;
        break;
      case ButtonVariant.outline:
        bg = backgroundColor ?? Colors.transparent;
        fg = foregroundColor ?? colorScheme.onSurface;
        border = BorderSide(
          color: customColors?.cardBorder ??
              (isDark ? AppColors.slate700 : AppColors.slate300),
          width: 1,
        );
        break;
      case ButtonVariant.ghost:
        bg = backgroundColor ?? Colors.transparent;
        fg = foregroundColor ?? colorScheme.onSurface;
        break;
      case ButtonVariant.destructive:
        bg = backgroundColor ??
            (isDark
                ? colorScheme.errorContainer
                : colorScheme.error.withValues(alpha: 0.12));
        fg = foregroundColor ?? colorScheme.error;
        break;
    }

    // Resolve Dimensions & Typography by size
    double height;
    double? width;
    EdgeInsets padding;
    double fontSize;
    double iconSize;

    switch (size) {
      case ButtonSize.sm:
        height = 34;
        padding = const EdgeInsets.symmetric(horizontal: 12);
        fontSize = 12.5;
        iconSize = 15;
        break;
      case ButtonSize.md:
        height = 42;
        padding = const EdgeInsets.symmetric(horizontal: 16);
        fontSize = 14;
        iconSize = 18;
        break;
      case ButtonSize.lg:
        height = 50;
        padding = const EdgeInsets.symmetric(horizontal: 22);
        fontSize = 15.5;
        iconSize = 20;
        break;
      case ButtonSize.icon:
        height = 40;
        width = 40;
        padding = EdgeInsets.zero;
        fontSize = 14;
        iconSize = 18;
        break;
    }

    final effectiveRadius = borderRadius ?? AppSizes.borderRadiusMd;

    Widget content = child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              ),
              if (text != null) AppSizes.gapW8,
            ] else if (prefixIcon != null) ...[
              IconTheme(
                data: IconThemeData(color: fg, size: iconSize),
                child: prefixIcon!,
              ),
              if (text != null) AppSizes.gapW8,
            ],
            if (text != null)
              Text(
                text!,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  letterSpacing: -0.2,
                ),
              ),
            if (!isLoading && suffixIcon != null) ...[
              if (text != null) AppSizes.gapW8,
              IconTheme(
                data: IconThemeData(color: fg, size: iconSize),
                child: suffixIcon!,
              ),
            ],
          ],
        );

    final buttonWidget = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: _isDisabled ? 0.55 : 1.0,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: effectiveRadius,
          side: border ?? BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isDisabled ? null : onPressed,
          borderRadius: effectiveRadius,
          splashColor: fg.withValues(alpha: 0.08),
          highlightColor: fg.withValues(alpha: 0.05),
          child: Container(
            height: height,
            width: isFullWidth ? double.infinity : width,
            padding: padding,
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );

    return buttonWidget;
  }
}

/// Convenience alias matching web/Next.js nomenclature
typedef Button = AppButton;

