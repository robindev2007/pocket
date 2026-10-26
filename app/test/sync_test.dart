import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manage_money/data/models/debt_model.dart';
import 'package:manage_money/data/models/transaction_model.dart';
import 'package:manage_money/data/services/sync_api_service.dart';

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
  });
}
