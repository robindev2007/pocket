import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manage_money/data/models/user_profile_model.dart';
import 'package:manage_money/data/services/auth_api_service.dart';
import 'package:manage_money/data/services/storage_service.dart';

void main() {
  group('AuthApiService Tests', () {
    test('signInWithGoogle parses successful response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/auth/google');
        expect(request.headers['Content-Type'], 'application/json');
        return http.Response(
          '''
          {
            "success": true,
            "data": {
              "user": {
                "id": "user-uuid-123",
                "name": "Robin Dev",
                "email": "robin@example.com",
                "avatar": "https://avatar.url/img.png",
                "currency": "USD",
                "hasCompletedOnboarding": true
              },
              "accessToken": "mock-jwt-token-xyz"
            }
          }
          ''',
          200,
        );
      });

      final service = AuthApiService(client: mockClient);
      final result = await service.signInWithGoogle('mock-google-id-token');

      expect(result.accessToken, 'mock-jwt-token-xyz');
      expect(result.user.id, 'user-uuid-123');
      expect(result.user.name, 'Robin Dev');
      expect(result.user.email, 'robin@example.com');
      expect(result.user.currency, 'USD');
    });

    test('signInWithGoogle throws Exception on server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '''
          {
            "success": false,
            "error": {
              "message": "Invalid Google token payload"
            }
          }
          ''',
          401,
        );
      });

      final service = AuthApiService(client: mockClient);
      expect(
        () => service.signInWithGoogle('invalid-id-token'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('StorageService Auth Token Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveAuthToken, loadAuthToken, and clearAuthToken work properly',
        () async {
      final storage = StorageService();

      expect(await storage.hasAuthToken(), isFalse);
      expect(await storage.loadAuthToken(), isNull);

      await storage.saveAuthToken('test-token-123');
      expect(await storage.hasAuthToken(), isTrue);
      expect(await storage.loadAuthToken(), 'test-token-123');

      await storage.clearAuthToken();
      expect(await storage.hasAuthToken(), isFalse);
      expect(await storage.loadAuthToken(), isNull);
    });
  });

  group('UserProfileModel Serialization', () {
    test('toJson and fromJson handle id and currency properly', () {
      final model = UserProfileModel(
        id: 'u-123',
        name: 'Alex',
        email: 'alex@test.com',
        avatar: '💼',
        currency: 'EUR',
        hasCompletedOnboarding: true,
      );

      final json = model.toJson();
      expect(json['id'], 'u-123');
      expect(json['currency'], 'EUR');

      final deserialized = UserProfileModel.fromJson(json);
      expect(deserialized.id, 'u-123');
      expect(deserialized.currency, 'EUR');
      expect(deserialized.name, 'Alex');
    });
  });
}
