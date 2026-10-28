class ApiConstants {
  ApiConstants._();

  /// Production API base URL: https://pocket-api.robinmia.com
  static const String defaultBaseUrl = 'http://localhost:3000';

  /// Default API base URL.
  /// Can be overridden at build/runtime with:
  /// `--dart-define=API_BASE_URL=https://your-api.com`
  static String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine.replaceAll(RegExp(r'/+$'), '');
    }
    return defaultBaseUrl;
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
