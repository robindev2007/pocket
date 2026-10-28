import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manage_money/core/theme/theme.dart';
import 'package:manage_money/core/widgets/widgets.dart';
import 'package:manage_money/features/tracker/tracker.dart';
import 'package:manage_money/data/models/debt_model.dart';
import 'package:manage_money/data/models/transaction_model.dart';
import 'package:manage_money/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.testMode = true;
    Get.put(ThemeController());
    Get.put(TrackerController());
  });

  testWidgets('Personal Money Tracker full UI test matching reference screenshot', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Onboarding Welcome dialog appears on fresh launch
    expect(find.text('Welcome to Pocket'), findsOneWidget);
    expect(find.text('What should we call you?'), findsOneWidget);

    // Enter name "Robin"
    await tester.enterText(find.byType(AppTextField).first, 'Robin');
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Header on Dashboard
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Hello, Robin 👋'), findsOneWidget);
    expect(find.byTooltip('Toggle Theme Mode'), findsOneWidget);

    // Verify Hero Card elements
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('INCOME'), findsOneWidget);
    expect(find.text('EXPENSES'), findsOneWidget);

    // Verify Period Filter Pills
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Year'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);

    // Verify Monthly Spending Card
    expect(find.text('Monthly Spending'), findsOneWidget);
    expect(find.byType(DonutChartWidget), findsOneWidget);

    // Verify Bottom Navigation items (HOME, STATS, DEBTS, PROFILE)
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('STATS'), findsOneWidget);
    expect(find.text('DEBTS'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);

    // Verify Floating Action Button (+)
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Tap Floating Action Button to add fast expense
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Record Transaction dialog opened in Expense mode
    expect(find.text('Record Transaction'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);

    // Close the dialog
    Navigator.of(tester.element(find.text('Record Transaction'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Add Income transaction
    final controller = TrackerController.to;
    await controller.addTransaction(
      title: 'Salary',
      amount: 8500.0,
      type: TransactionType.income,
      date: DateTime.now(),
      tag: 'Salary',
    );
    await tester.pump();

    // Add Expense transaction
    await controller.addTransaction(
      title: 'Groceries',
      amount: 3245.50,
      type: TransactionType.expense,
      date: DateTime.now(),
      tag: 'Food',
    );
    await tester.pump();

    // Add Debt
    await controller.addDebt(
      personName: 'Rahim',
      title: 'Lunch share',
      amount: 500.0,
      date: DateTime.now(),
      direction: DebtDirection.theyOweMe,
    );
    await tester.pump();

    expect(controller.cashBalance, 5254.50);
    expect(controller.totalIncome, 8500.0);
    expect(controller.totalExpenses, 3245.50);
    expect(controller.totalOwedToMe, 500.0);

    // Navigate to STATS (Transactions) tab
    await tester.tap(find.text('STATS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Salary'), findsWidgets);

    // Navigate to PROFILE tab
    await tester.tap(find.text('PROFILE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Robin'), findsWidgets);
    expect(find.text('Edit Profile & Avatar'), findsOneWidget);
  });
}
