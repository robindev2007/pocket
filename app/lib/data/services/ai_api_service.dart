import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class AiApiService {
  final http.Client _client;

  AiApiService({http.Client? client}) : _client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 25);

  Map<String, String> _headers(String? token) {
    final map = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }

  Future<Map<String, dynamic>?> sendChat({
    String? message,
    List<Map<String, dynamic>>? history,
    Map<String, dynamic>? toolResult,
    String? provider,
    String? token,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/ai/chat');
      final body = <String, dynamic>{};
      if (message != null) body['message'] = message;
      if (history != null) body['history'] = history;
      if (toolResult != null) body['toolResult'] = toolResult;
      if (provider != null) body['provider'] = provider;
      if (userContext != null) body['userContext'] = userContext;

      final response = await _client
          .post(
            uri,
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Stream<Map<String, dynamic>> sendChatStream({
    String? message,
    List<Map<String, dynamic>>? history,
    Map<String, dynamic>? toolResult,
    String? provider,
    String? token,
    Map<String, dynamic>? userContext,
  }) async* {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/ai/chat/stream');
      final request = http.Request('POST', uri);
      request.headers.addAll(_headers(token));

      final body = <String, dynamic>{};
      if (message != null) body['message'] = message;
      if (history != null) body['history'] = history;
      if (toolResult != null) body['toolResult'] = toolResult;
      if (provider != null) body['provider'] = provider;
      if (userContext != null) body['userContext'] = userContext;

      request.body = jsonEncode(body);

      final streamedResponse = await _client.send(request).timeout(_timeout);

      if (streamedResponse.statusCode >= 200 &&
          streamedResponse.statusCode < 300) {
        final lineStream = streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in lineStream) {
          final trimmed = line.trim();
          if (trimmed.startsWith('data: ')) {
            final jsonStr = trimmed.substring(6);
            try {
              final Map<String, dynamic> data =
                  jsonDecode(jsonStr) as Map<String, dynamic>;
              yield data;
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getProviders([String? token]) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/ai/providers');
      final response = await _client
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

