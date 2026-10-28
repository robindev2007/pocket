class ApiConstants {
  ApiConstants._();

  /// Production API base URL: https://pocket-api.robinmia.com
  static const String defaultBaseUrl = 'https://pocket-api.robinmia.com';

  /// Default API base URL.
  /// Can be overridden at build/runtime with:
  /// `--dart-define=API_BASE_URL=https://your-api.com`
  static String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine.replaceAll(RegExp(r'/+$'), '');
    }
    return defaultBaseUrl.replaceAll(RegExp(r'/+$'), '');
  }

  // Endpoints
  static String get authConfig => '$baseUrl/auth/config';
  static String get authGoogle => '$baseUrl/auth/google';
  static String get authMe => '$baseUrl/auth/me';
  static String get userProfile => '$baseUrl/users/profile';
}
