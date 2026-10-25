import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_custom_colors.dart';
import 'theme_controller.dart';

/// Ergonomic syntax extensions on [BuildContext] for theme access.
extension ThemeContextExtensions on BuildContext {
  /// The active [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// The active [AppCustomColors] theme extension tokens.
  AppCustomColors get customColors =>
      Theme.of(this).extension<AppCustomColors>()!;

  /// The active [ThemeController] provided by GetX.
  ThemeController get themeController => Get.find<ThemeController>();
}
