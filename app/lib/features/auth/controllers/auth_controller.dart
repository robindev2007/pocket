import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/services/auth_api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../tracker/controllers/tracker_controller.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final StorageService _storageService = StorageService();
  final AuthApiService _apiService = AuthApiService();

  final RxBool isAuthenticated = false.obs;
  final RxBool isLoading = false.obs;
  final Rx<UserProfileModel?> authUser = Rx<UserProfileModel?>(null);
  final RxString errorMessage = ''.obs;
  bool _isGoogleSignInInitialized = false;

  @override
  void onInit() {
    super.onInit();
    _initGoogleSignIn();
    _checkInitialAuthState();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      final serverClientId = ApiConstants.googleServerClientId;
      await GoogleSignIn.instance.initialize(
        serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
      );
      _isGoogleSignInInitialized = true;
    } catch (_) {
      // Handled if already initialized or on unsupported environments
    }
  }

  Future<void> _checkInitialAuthState() async {
    final hasToken = await _storageService.hasAuthToken();
    if (!hasToken) {
      isAuthenticated.value = false;
      return;
    }

    final token = await _storageService.loadAuthToken();
    if (token == null) return;

    // Verify token with backend in background
    try {
      final user = await _apiService.getMe(token);
      if (user != null) {
        authUser.value = user;
        isAuthenticated.value = true;
      } else {
        // Token expired or invalid
        await _storageService.clearAuthToken();
        isAuthenticated.value = false;
      }
    } catch (_) {
      // In offline mode, retain local authenticated state if token was saved
      isAuthenticated.value = true;
    }
  }

  /// Initiates Google Sign-In, retrieves ID token, exchanges with backend for app JWT
  Future<bool> signInWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      if (!_isGoogleSignInInitialized) {
        await _initGoogleSignIn();
      }

      // 1. Trigger Google Sign-In prompt
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();

      // 2. Obtain Google Authentication tokens (synchronous in google_sign_in 7.x)
      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google did not return an ID token. Make sure a Web OAuth Client ID '
          'is configured in ApiConstants.googleServerClientId or via '
          '--dart-define=GOOGLE_CLIENT_ID=<YOUR_WEB_CLIENT_ID>',
        );
      }

      // 3. Authenticate with backend server
      final AuthResult result = await _apiService.signInWithGoogle(idToken);

      // 4. Save session token
      await _storageService.saveAuthToken(result.accessToken);

      // 5. Update local state
      authUser.value = result.user;
      isAuthenticated.value = true;

      // 6. Update TrackerController user profile so profile tab reflects user details
      if (Get.isRegistered<TrackerController>()) {
        final tracker = TrackerController.to;
        await tracker.updateProfile(
          id: result.user.id,
          name: result.user.name,
          email: result.user.email,
          avatar: result.user.avatar.isNotEmpty ? result.user.avatar : '👤',
          currency: result.user.currency,
          hasCompletedOnboarding: true,
        );
      }

      Get.snackbar(
        'Welcome, ${result.user.name}!',
        'You are now signed in with Google.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.85),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorMessage.value = msg;

      Get.snackbar(
        'Sign In',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Signs the user out from Google and clears stored JWT
  Future<void> signOut() async {
    isLoading.value = true;
    try {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}

      await _storageService.clearAuthToken();
      isAuthenticated.value = false;
      authUser.value = null;

      Get.snackbar(
        'Signed Out',
        'You have successfully signed out.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
