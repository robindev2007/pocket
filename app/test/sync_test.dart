import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manage_money/core/theme/theme.dart';
import 'package:manage_money/data/models/debt_model.dart';
import 'package:manage_money/data/models/transaction_model.dart';
import 'package:manage_money/data/services/storage_service.dart';
import 'package:manage_money/data/services/sync_api_service.dart';
import 'package:manage_money/features/auth/controllers/auth_controller.dart';
import 'package:manage_money/features/sync/controllers/sync_controller.dart';
import 'package:manage_money/features/sync/presentation/widgets/sync_status_badge.dart';
import 'package:manage_money/features/tracker/controllers/tracker_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Sync Models Serialization', () {
    test('TransactionModel toJson and fromJson handle isSynced flag properly', () {
      final tx = TransactionModel(
        id: 'tx-1',
        title: 'Coffee',
        amount: 4.5,
        type: TransactionType.expense,
        date: DateTime.parse('2026-10-26T12:00:00Z'),
        isSynced: false,
      );

      final json = tx.toJson();
      expect(json['isSynced'], isFalse);

      final deserialized = TransactionModel.fromJson(json);
      expect(deserialized.isSynced, isFalse);

      final syncedTx = tx.copyWith(isSynced: true);
      expect(syncedTx.isSynced, isTrue);
      expect(syncedTx.toJson()['isSynced'], isTrue);
    });

    test('DebtModel toJson and fromJson handle isSynced flag properly', () {
      final debt = DebtModel(
        id: 'd-1',
        personName: 'Sam',
        title: 'Movie',
        amount: 15.0,
        date: DateTime.parse('2026-10-26T12:00:00Z'),
        direction: DebtDirection.theyOweMe,
        isSynced: false,
      );

      final json = debt.toJson();
      expect(json['isSynced'], isFalse);

      final deserialized = DebtModel.fromJson(json);
      expect(deserialized.isSynced, isFalse);

      final syncedDebt = debt.copyWith(isSynced: true);
      expect(syncedDebt.isSynced, isTrue);
      expect(syncedDebt.toJson()['isSynced'], isTrue);
    });
  });

  group('SyncApiService Tests', () {
    test('uploadTransaction returns true on 201 Created', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/transactions');
        expect(request.headers['Authorization'], 'Bearer mock-token-123');
        return http.Response('{"success": true, "data": {}}', 201);
      });

      final service = SyncApiService(client: mockClient);
      final tx = TransactionModel(
        id: 'tx-123',
        title: 'Lunch',
        amount: 12.0,
        type: TransactionType.expense,
        date: DateTime.now(),
      );

      final success = await service.uploadTransaction(tx, 'mock-token-123');
      expect(success, isTrue);
    });

    test('uploadDebt returns debt ID on 201 Created', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/debts');
        return http.Response('{"success": true, "data": {"id": "server-debt-99"}}', 201);
      });

      final service = SyncApiService(client: mockClient);
      final debt = DebtModel(
        id: 'd-99',
        personName: 'Jordan',
        title: 'Concert',
        amount: 80.0,
        date: DateTime.now(),
        direction: DebtDirection.theyOweMe,
      );

      final id = await service.uploadDebt(debt, 'mock-token-123');
      expect(id, 'server-debt-99');
    });

    test('uploadTransaction returns false on 500 server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Internal Server Error"}', 500);
      });

      final service = SyncApiService(client: mockClient);
      final tx = TransactionModel(
        id: 'tx-err',
        title: 'Snack',
        amount: 2.0,
        type: TransactionType.expense,
        date: DateTime.now(),
      );

      final success = await service.uploadTransaction(tx, 'mock-token-123');
      expect(success, isFalse);
    });

    test('uploadTransaction returns false on network exception', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final service = SyncApiService(client: mockClient);
      final tx = TransactionModel(
        id: 'tx-fail',
        title: 'Coffee',
        amount: 3.5,
        type: TransactionType.expense,
        date: DateTime.now(),
      );

      final success = await service.uploadTransaction(tx, 'mock-token-123');
      expect(success, isFalse);
    });

    test('uploadDebt returns null on 401 Unauthorized or network failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Unauthorized"}', 401);
      });

      final service = SyncApiService(client: mockClient);
      final debt = DebtModel(
        id: 'd-unauth',
        personName: 'Alex',
        title: 'Dinner',
        amount: 40.0,
        date: DateTime.now(),
        direction: DebtDirection.theyOweMe,
      );

      final id = await service.uploadDebt(debt, 'invalid-token');
      expect(id, isNull);
    });

    test('pullRemoteData returns data map with transactions and debts on 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/sync/pull');
        expect(request.headers['Authorization'], 'Bearer mock-token-123');
        return http.Response(
          '{"success": true, "data": {"transactions": [{"id": "t1", "title": "Coffee", "amount": 5.0, "type": "EXPENSE", "date": "2026-10-26T12:00:00.000Z"}], "debts": [{"id": "d1", "personName": "Sarah", "title": "Lunch", "amount": 20.0, "date": "2026-10-26T12:00:00.000Z", "direction": "LENT"}], "serverTime": "2026-10-27T01:00:00.000Z"}}',
          200,
        );
      });

      final service = SyncApiService(client: mockClient);
      final result = await service.pullRemoteData('mock-token-123');
      expect(result, isNotNull);
      expect((result!['transactions'] as List).length, 1);
      expect((result['debts'] as List).length, 1);
      expect(result['serverTime'], isNotNull);
    });
  });

  group('StorageService Account Isolation Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('handleAccountSwitch preserves data for same user', () async {
      final storage = StorageService();
      await storage.saveTransactions([
        TransactionModel(
          id: 't-persist',
          title: 'Books',
          amount: 25.0,
          type: TransactionType.expense,
          date: DateTime.now(),
        ),
      ]);

      await storage.handleAccountSwitch('user-same-1');
      var list = await storage.loadTransactions();
      expect(list.length, 1);

      // Re-login with same user
      await storage.handleAccountSwitch('user-same-1');
      list = await storage.loadTransactions();
      expect(list.length, 1);
      expect(list.first.title, 'Books');
    });

    test('handleAccountSwitch clears data when a different user logs in', () async {
      final storage = StorageService();
      await storage.handleAccountSwitch('user-1');
      await storage.saveTransactions([
        TransactionModel(
          id: 't-user1',
          title: 'Private Expense',
          amount: 100.0,
          type: TransactionType.expense,
          date: DateTime.now(),
        ),
      ]);
      await storage.saveDebts([
        DebtModel(
          id: 'd-user1',
          personName: 'Dave',
          title: 'Private Debt',
          amount: 50.0,
          date: DateTime.now(),
          direction: DebtDirection.theyOweMe,
        ),
      ]);

      expect((await storage.loadTransactions()).length, 1);
      expect((await storage.loadDebts()).length, 1);

      // Different user logs in
      await storage.handleAccountSwitch('user-2');

      // Previous user's records must be cleared
      expect((await storage.loadTransactions()).length, 0);
      expect((await storage.loadDebts()).length, 0);
    });
  });

  group('hydrateFromServer Bidirectional Sync Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      Get.testMode = true;
    });

    test('hydrates remote cloud items and merges with existing local offline items', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/sync/pull') {
          return http.Response(
            '{"success": true, "data": {'
            '"transactions": [{"id": "cloud-tx-1", "title": "Salary", "amount": 2500.0, "type": "INCOME", "date": "2026-10-25T08:00:00.000Z"}],'
            '"debts": [{"id": "cloud-debt-1", "personName": "Emma", "title": "Dinner", "amount": 60.0, "date": "2026-10-25T19:00:00.000Z", "direction": "LENT", "repayments": []}],'
            '"serverTime": "2026-10-27T01:00:00.000Z"'
            '}}',
            200,
          );
        } else if (request.url.path == '/transactions') {
          return http.Response('{"success": true, "data": {"id": "uploaded-tx-id"}}', 201);
        }
        return http.Response('{}', 200);
      });

      final syncApiService = SyncApiService(client: mockClient);
      final auth = Get.put(AuthController());
      auth.isAuthenticated.value = true;

      final tracker = Get.put(TrackerController());
      // Seed local offline transaction (not yet synced)
      tracker.transactions.add(TransactionModel(
        id: 'local-offline-tx',
        title: 'Local Snack',
        amount: 3.5,
        type: TransactionType.expense,
        date: DateTime.parse('2026-10-26T10:00:00.000Z'),
        isSynced: false,
      ));

      final sync = Get.put(SyncController(syncApiService: syncApiService));
      final success = await sync.hydrateFromServer('valid-jwt-token');

      expect(success, isTrue);
      // Both cloud item and local item should be present in merged transactions
      expect(tracker.transactions.any((t) => t.id == 'cloud-tx-1'), isTrue);
      expect(tracker.transactions.any((t) => t.id == 'local-offline-tx'), isTrue);

      // Cloud debt should be present and Emma added to people
      expect(tracker.debts.any((d) => d.id == 'cloud-debt-1'), isTrue);
      expect(tracker.people.contains('Emma'), isTrue);
    });
  });

  group('SyncStatusBadge UI Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      Get.testMode = true;
    });

    testWidgets('shows circular progress without text syncing when isSyncing is true',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final auth = Get.put(AuthController());
      final sync = Get.put(SyncController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.build(brightness: Brightness.light),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: SyncStatusBadge(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      auth.isAuthenticated.value = true;
      await tester.pump();

      sync.state.value = SyncState.syncing;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Circular progress should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // No text "Syncing..." or "syncing" should exist
      expect(find.text('Syncing...'), findsNothing);
      expect(find.text('syncing'), findsNothing);
    });

    testWidgets('shows green tick mark only (no text OK) when synced, then animates out after 2 sec',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final auth = Get.put(AuthController());
      final sync = Get.put(SyncController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.build(brightness: Brightness.light),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: SyncStatusBadge(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      auth.isAuthenticated.value = true;
      sync.state.value = SyncState.syncing;
      await tester.pump();

      // Transition to synced
      sync.state.value = SyncState.synced;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Should show tick mark icon only, NO text "OK"
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('OK'), findsNothing);

      // Fast-forward past 2000ms timer and 300ms crossfade
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump(const Duration(milliseconds: 350));

      // AnimatedCrossFade should show second child (collapsed/faded out)
      final crossFade = tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade));
      expect(crossFade.crossFadeState, CrossFadeState.showSecond);
    });
  });
}
