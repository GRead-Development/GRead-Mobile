import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/user.dart';

/// Authentication service matching iOS AuthManager functionality
/// Handles JWT authentication, guest mode, and session management
class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _guestModeKey = 'guest_mode';

  AuthService(this._apiClient, this._secureStorage);

  /// Login with JWT authentication
  /// Mirrors iOS: AuthManager.login()
  Future<User> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      final token = response['token'] as String;
      final userId = response['user_id'] as int;

      // Store token securely (equivalent to iOS Keychain)
      await _secureStorage.write(key: _tokenKey, value: token);
      await _secureStorage.write(key: _userIdKey, value: userId.toString());
      await _secureStorage.delete(key: _guestModeKey);

      // Set token in API client for subsequent requests
      _apiClient.setAuthToken(token);

      // Fetch current user details
      return await getCurrentUser();
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}');
    }
  }

  /// Register new user
  /// Mirrors iOS: AuthManager.signup()
  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.signup,
        data: {
          'user_login': username,
          'user_email': email,
          'password': password,
        },
      );

      // Note: User must verify email before they can login
    } catch (e) {
      throw AuthException('Registration failed: ${e.toString()}');
    }
  }

  /// Enable guest mode (read-only access)
  /// Mirrors iOS: AuthManager.enableGuestMode()
  Future<void> enableGuestMode() async {
    await _secureStorage.write(key: _guestModeKey, value: 'true');
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
    _apiClient.clearAuthToken();
  }

  /// Get current authenticated user
  /// Mirrors iOS: AuthManager.fetchCurrentUser()
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.currentUser);
      return User.fromJson(response);
    } catch (e) {
      throw AuthException('Failed to fetch user: ${e.toString()}');
    }
  }

  /// Check current authentication state
  /// Mirrors iOS: AuthManager's @Published isAuthenticated/isGuestMode
  Future<AuthState> getAuthState() async {
    final token = await _secureStorage.read(key: _tokenKey);
    final guestMode = await _secureStorage.read(key: _guestModeKey);

    if (token != null && token.isNotEmpty) {
      _apiClient.setAuthToken(token);
      return AuthState.authenticated;
    } else if (guestMode == 'true') {
      return AuthState.guest;
    } else {
      return AuthState.unauthenticated;
    }
  }

  /// Logout and clear all stored credentials
  /// Mirrors iOS: AuthManager.logout()
  Future<void> logout() async {
    await _secureStorage.deleteAll();
    _apiClient.clearAuthToken();
  }

  /// Get stored JWT token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Get stored user ID
  Future<int?> getUserId() async {
    final userIdStr = await _secureStorage.read(key: _userIdKey);
    return userIdStr != null ? int.tryParse(userIdStr) : null;
  }
}

/// Authentication states matching iOS implementation
enum AuthState {
  authenticated,  // Full access with valid token
  guest,          // Read-only access
  unauthenticated, // No access, show landing page
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
