import 'package:flutter/material.dart';

/// Custom theme extension for application-specific design tokens.
///
/// Follows Flutter's official [ThemeExtension] architecture, enabling
/// smooth animations and type-safe access through `Theme.of(context)`.
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  const AppCustomColors({
    required this.heroCardBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.inputFill,
    required this.inputBorder,
    required this.subtleText,
    required this.surfaceHover,
    required this.pillBackground,
    required this.pillText,
    required this.pillActiveBackground,
    required this.pillActiveText,
    required this.bottomSheetHandle,
  });

  final Color heroCardBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color inputFill;
  final Color inputBorder;
  final Color subtleText;
  final Color surfaceHover;
  final Color pillBackground;
  final Color pillText;
  final Color pillActiveBackground;
  final Color pillActiveText;
  final Color bottomSheetHandle;

  @override
  AppCustomColors copyWith({
    Color? heroCardBackground,
    Color? cardBackground,
    Color? cardBorder,
    Color? inputFill,
    Color? inputBorder,
    Color? subtleText,
    Color? surfaceHover,
    Color? pillBackground,
    Color? pillText,
    Color? pillActiveBackground,
    Color? pillActiveText,
    Color? bottomSheetHandle,
  }) {
    return AppCustomColors(
      heroCardBackground: heroCardBackground ?? this.heroCardBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      inputFill: inputFill ?? this.inputFill,
      inputBorder: inputBorder ?? this.inputBorder,
      subtleText: subtleText ?? this.subtleText,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      pillBackground: pillBackground ?? this.pillBackground,
      pillText: pillText ?? this.pillText,
      pillActiveBackground: pillActiveBackground ?? this.pillActiveBackground,
      pillActiveText: pillActiveText ?? this.pillActiveText,
      bottomSheetHandle: bottomSheetHandle ?? this.bottomSheetHandle,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      heroCardBackground: Color.lerp(heroCardBackground, other.heroCardBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      subtleText: Color.lerp(subtleText, other.subtleText, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      pillBackground: Color.lerp(pillBackground, other.pillBackground, t)!,
      pillText: Color.lerp(pillText, other.pillText, t)!,
      pillActiveBackground: Color.lerp(pillActiveBackground, other.pillActiveBackground, t)!,
      pillActiveText: Color.lerp(pillActiveText, other.pillActiveText, t)!,
      bottomSheetHandle: Color.lerp(bottomSheetHandle, other.bottomSheetHandle, t)!,
    );
  }
}
