import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../theme/app_custom_colors.dart';

/// Size variants for [AppTextField] / [AppInput].
enum InputSize {
  sm,
  md,
  lg,
}

/// A modern, borderless text input widget with a clean, soft surface fill.
///
/// Features an optional top label, prefix/suffix icons, helper and error text,
/// smooth rounded corners, and completely borderless styling.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.size = InputSize.md,
    this.borderRadius,
    this.fillColor,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final int? maxLines;
  final int? minLines;
  final InputSize size;
  final BorderRadius? borderRadius;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customColors = theme.extension<AppCustomColors>();

    final effectiveRadius = borderRadius ?? BorderRadius.circular(14);

    // Padding & font size by input size
    EdgeInsets contentPadding;
    double fontSize;
    switch (size) {
      case InputSize.sm:
        contentPadding =
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        fontSize = 13;
        break;
      case InputSize.md:
        contentPadding =
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12);
        fontSize = 14;
        break;
      case InputSize.lg:
        contentPadding =
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15);
        fontSize = 15;
        break;
    }

    final focusedBorderColor = theme.colorScheme.primary;
    final errorBorderColor = theme.colorScheme.error;

    // Clean, modern soft fill color
    final effectiveFillColor = fillColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : const Color(0xFFF1F5F9));

    final inputField = TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      cursorColor: focusedBorderColor,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.35)
              : const Color(0xFF94A3B8),
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
        ),
        helperText: helperText,
        helperStyle: TextStyle(
          color: customColors?.subtleText ??
              (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          fontSize: 11.5,
        ),
        errorText: errorText,
        errorStyle: TextStyle(
          color: errorBorderColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: prefixIcon != null
            ? IconTheme(
                data: IconThemeData(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  size: 20,
                ),
                child: prefixIcon!,
              )
            : null,
        suffixIcon: suffixIcon != null
            ? IconTheme(
                data: IconThemeData(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  size: 20,
                ),
                child: suffixIcon!,
              )
            : null,
        prefix: prefix,
        suffix: suffix,
        filled: true,
        fillColor: enabled
            ? effectiveFillColor
            : effectiveFillColor.withValues(alpha: 0.4),
        contentPadding: contentPadding,
        // Completely borderless styling
        border: OutlineInputBorder(
          borderRadius: effectiveRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: effectiveRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: effectiveRadius,
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: effectiveRadius,
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: effectiveRadius,
          borderSide: BorderSide(
            color: errorBorderColor.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: effectiveRadius,
          borderSide: BorderSide(
            color: errorBorderColor,
            width: 1.2,
          ),
        ),
      ),
    );

    if (label == null) {
      return inputField;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label!,
          style: TextStyle(
            fontSize: fontSize - 1.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            letterSpacing: -0.1,
          ),
        ),
        AppSizes.gapH6,
        inputField,
      ],
    );
  }
}

/// Compatibility aliases for developers preferring Input / AppInput
typedef AppInput = AppTextField;
typedef Input = AppTextField;
