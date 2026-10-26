import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  /// Default API base URL.
  /// - Android emulator connects to host machine via 10.0.2.2:3000
  /// - iOS simulator, desktop, and web connect via localhost:3000
  /// Can be overridden at build/runtime with:
  /// `--dart-define=API_BASE_URL=https://your-api.vercel.app`
  static String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;

    if (kIsWeb) return 'http://localhost:3000';
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {
      // Platform check may fail on unsupported environments
    }
    return 'http://localhost:3000';
  }

  /// Google OAuth Web Client ID (from Google Cloud Console).
  /// Required for obtaining an idToken that the backend can verify.
  /// Can be provided at build/runtime with:
  /// `--dart-define=GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com`
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '815403961158-me03lohln0bp1h4f0ugjtgth1thh5s2o.apps.googleusercontent.com',
  );

  // Endpoints
  static String get authGoogle => '$baseUrl/auth/google';
  static String get authMe => '$baseUrl/auth/me';
  static String get userProfile => '$baseUrl/users/profile';
}
