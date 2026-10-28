import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manage_money/core/theme/theme.dart';
import 'package:manage_money/core/widgets/widgets.dart';
import 'package:manage_money/data/models/transaction_model.dart';
import 'package:manage_money/features/tracker/tracker.dart';
import 'package:manage_money/features/tracker/presentation/screens/transactions_tab.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.testMode = true;
    Get.put(ThemeController());
    Get.put(TrackerController());
  });

  testWidgets('Stats page features: Line Charts, Category Lines Switch, and History View All', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final controller = TrackerController.to;

    // Add multiple transactions across different categories
    await controller.addTransaction(
      title: 'Lunch with team',
      amount: 450.0,
      type: TransactionType.expense,
      date: DateTime.now(),
      tag: 'Food',
    );

    await controller.addTransaction(
      title: 'Groceries supermarket',
      amount: 1200.0,
      type: TransactionType.expense,
      date: DateTime.now(),
      tag: 'Groceries',
    );

    await controller.addTransaction(
      title: 'Freelance payment',
      amount: 5000.0,
      type: TransactionType.income,
      date: DateTime.now(),
      tag: 'Freelance',
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: TransactionsTab(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Line Chart section and period options (Daily, Weekly, Monthly)
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.byType(LineChartWidget), findsOneWidget);
    expect(find.text('Monthly Spending'), findsOneWidget);

    // Switch to Daily view
    await tester.tap(find.text('Daily'));
    await tester.pumpAndSettle();
    expect(find.text('Daily Spending'), findsOneWidget);
    expect(find.byType(LineChartWidget), findsOneWidget);

    // Switch to Weekly view
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    expect(find.text('Weekly Spending'), findsOneWidget);
    expect(find.byType(LineChartWidget), findsOneWidget);

    // 2. Verify Category Breakdown Switch on chart
    expect(find.text('Categories'), findsOneWidget);
    final categorySwitchFinder = find.byType(Switch);
    expect(categorySwitchFinder, findsOneWidget);

    // Toggle Categories ON
    await tester.tap(categorySwitchFinder);
    await tester.pumpAndSettle();

    // Category legend should now be visible below chart
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('Comparing categories by distinct colored lines'), findsOneWidget);

    // Toggle Categories OFF
    await tester.tap(categorySwitchFinder);
    await tester.pumpAndSettle();
    expect(find.text('Tap points to inspect spend'), findsOneWidget);

    // 3. Verify Financial Analytics Cards
    expect(find.text('Cash Flow & Savings'), findsOneWidget);
    expect(find.text('Spending Velocity & Forecast'), findsOneWidget);
    expect(find.text('Top Spending & Habits'), findsOneWidget);

    // 4. Verify History section and View All
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Lunch with team'), findsWidgets);

    // Add additional transactions to exceed 5 items
    for (int i = 1; i <= 6; i++) {
      await controller.addTransaction(
        title: 'Extra Expense $i',
        amount: 50.0 + i,
        type: TransactionType.expense,
        date: DateTime.now(),
        tag: 'Shopping',
      );
    }
    await tester.pumpAndSettle();

    // View All button should be visible
    final viewAllFinder = find.text('View All');
    await tester.ensureVisible(viewAllFinder);
    await tester.pumpAndSettle();
    expect(viewAllFinder, findsOneWidget);

    // Tap View All
    await tester.tap(viewAllFinder);
    await tester.pumpAndSettle();

    // Now it should navigate to TransactionHistoryScreen
    expect(find.text('Transaction History'), findsOneWidget);
    expect(find.byType(AppTextField), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);

    // Pop back to stats
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('TransactionHistoryScreen paginates on scroll', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final controller = TrackerController.to;

    // Add 35 transactions
    for (int i = 1; i <= 35; i++) {
      await controller.addTransaction(
        title: 'Batch Item $i',
        amount: 10.0 * i,
        type: TransactionType.expense,
        date: DateTime.now().subtract(Duration(minutes: i)),
        tag: 'Test',
      );
    }

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: TransactionsTab(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap View All
    final viewAllBtn = find.text('View All');
    await tester.ensureVisible(viewAllBtn);
    await tester.pumpAndSettle();
    await tester.tap(viewAllBtn);
    await tester.pumpAndSettle();

    expect(find.text('Transaction History'), findsOneWidget);

    // Page size is 20, so Batch Item 1 is visible, Batch Item 25 is not in the list view initially
    expect(find.text('Batch Item 1'), findsOneWidget);
    expect(find.text('Batch Item 25'), findsNothing);

    // Scroll down to trigger pagination until Batch Item 25 comes into view
    await tester.scrollUntilVisible(
      find.text('Batch Item 25'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    // After scrolling, Batch Item 25 is loaded and visible
    expect(find.text('Batch Item 25'), findsOneWidget);
  });
}
