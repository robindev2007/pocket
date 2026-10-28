import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/user_profile_model.dart';

class AuthResult {
  AuthResult({
    required this.user,
    required this.accessToken,
  });

  final UserProfileModel user;
  final String accessToken;
}

class AuthApiService {
  final http.Client _client;

  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Default Google Web OAuth Client ID from google-services.json (client_type: 3)
  /// Used as immediate reliable fallback if server environment variable is not configured.
  static const String defaultWebClientId =
      '815403961158-me03lohln0bp1h4f0ugjtgth1thh5s2o.apps.googleusercontent.com';

  /// Retrieves Google OAuth Web Client ID dynamically from backend server
  Future<String?> getGoogleClientId() async {
    try {
      final uri = Uri.parse(ApiConstants.authConfig);
      final response = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        final serverId = data?['googleClientId'] as String?;
        if (serverId != null && serverId.isNotEmpty) {
          return serverId;
        }
      }
    } catch (_) {}
    return defaultWebClientId;
  }

  /// Exchanges a Google ID Token with backend server for an app JWT and user profile
  Future<AuthResult> signInWithGoogle(String idToken) async {
    final uri = Uri.parse(ApiConstants.authGoogle);
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;

      final user = UserProfileModel(
        id: userJson['id'] as String?,
        name: userJson['name'] as String? ?? 'User',
        email: userJson['email'] as String?,
        avatar: userJson['avatar'] as String? ?? '👤',
        currency: userJson['currency'] as String? ?? 'USD',
        hasCompletedOnboarding:
            userJson['hasCompletedOnboarding'] as bool? ?? false,
      );

      return AuthResult(user: user, accessToken: accessToken);
    } else {
      final errorMap = body['error'] as Map<String, dynamic>?;
      final message = errorMap?['message'] as String? ??
          body['message'] as String? ??
          'Failed to authenticate with backend server (HTTP ${response.statusCode})';
      throw Exception(message);
    }
  }

  /// Verifies current session token with the backend
  Future<UserProfileModel?> getMe(String accessToken) async {
    try {
      final uri = Uri.parse(ApiConstants.authMe);
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final userJson = body['data'] as Map<String, dynamic>;
        return UserProfileModel(
          id: userJson['id'] as String?,
          name: userJson['name'] as String? ?? 'User',
          email: userJson['email'] as String?,
          avatar: userJson['avatar'] as String? ?? '👤',
          bio: userJson['bio'] as String?,
          currency: userJson['currency'] as String? ?? 'USD',
          hasCompletedOnboarding:
              userJson['hasCompletedOnboarding'] as bool? ?? false,
        );
      }
    } catch (_) {}
    return null;
  }
}
