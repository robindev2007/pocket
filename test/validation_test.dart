import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manage_money/core/theme/theme.dart';
import 'package:manage_money/core/widgets/widgets.dart';
import 'package:manage_money/features/tracker/tracker.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.testMode = true;
    Get.put(ThemeController());
    Get.put(TrackerController());
  });

  testWidgets('AddEditTransactionDialog Luthor validation displays per-input simple red error', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddEditTransactionDialog.show(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify dialog is open
    expect(find.text('Record Transaction'), findsOneWidget);

    // Tap Save without entering amount or title
    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    // Verify individual field error messages from Luthor schema
    expect(find.text('Please enter an amount'), findsOneWidget);
    expect(find.text('Please enter a title'), findsOneWidget);

    // Enter amount and verify amount error disappears on submit
    await tester.enterText(find.byType(AppTextField).first, '150.00');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    // Amount error is gone, title error remains
    expect(find.text('Please enter an amount'), findsNothing);
    expect(find.text('Please enter a title'), findsOneWidget);

    // Enter title and submit successfully
    await tester.enterText(find.byType(AppTextField).at(1), 'Coffee');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Transaction'));
    await tester.pumpAndSettle();

    // Dialog is closed
    expect(find.text('Record Transaction'), findsNothing);
  });
}
