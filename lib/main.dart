import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/theme.dart';
import 'features/tracker/tracker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());

    return Obx(() {
      return GetMaterialApp(
        title: 'Pocket',
        debugShowCheckedModeBanner: false,
        themeMode: themeController.themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const MainNavigationScreen(),
      );
    });
  }
}
