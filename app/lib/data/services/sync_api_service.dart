import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/debt_model.dart';
import '../models/transaction_model.dart';

class SyncApiService {
  final http.Client _client;

  SyncApiService({http.Client? client}) : _client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 8);

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Uploads a single transaction to the cloud server
  Future<bool> uploadTransaction(TransactionModel tx, String token) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/transactions');
      final response = await _client
          .post(
            uri,
            headers: _headers(token),
            body: jsonEncode({
              'title': tx.title,
              'amount': tx.amount,
              'type': tx.isIncome ? 'INCOME' : 'EXPENSE',
              'date': tx.date.toIso8601String(),
              if (tx.tag != null) 'tag': tx.tag,
              if (tx.note != null) 'note': tx.note,
            }),
          )
          .timeout(_timeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Uploads a single debt record to the cloud server
  Future<String?> uploadDebt(DebtModel debt, String token) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/debts');
      final response = await _client
          .post(
            uri,
            headers: _headers(token),
            body: jsonEncode({
              'personName': debt.personName,
              'title': debt.title,
              'amount': debt.amount,
              'date': debt.date.toIso8601String(),
              'direction': debt.isTheyOweMe ? 'LENT' : 'BORROWED',
              if (debt.note != null) 'note': debt.note,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        return data?['id'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Uploads a repayment for a debt
  Future<bool> uploadRepayment(
    String debtId,
    DebtRepaymentModel rep,
    String token,
  ) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/debts/$debtId/repayments');
      final response = await _client
          .post(
            uri,
            headers: _headers(token),
            body: jsonEncode({
              'amount': rep.amount,
              'date': rep.date.toIso8601String(),
              if (rep.note != null) 'note': rep.note,
              'affectsCashBalance': rep.affectsCashBalance,
            }),
          )
          .timeout(_timeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
