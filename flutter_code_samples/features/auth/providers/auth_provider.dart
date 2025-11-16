import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user.dart';
import '../../../core/api/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Authentication state data
/// Matches iOS AuthManager @Published properties
class AuthStateData {
  final bool isAuthenticated;
  final bool isGuest;
  final User? user;

  const AuthStateData({
    required this.isAuthenticated,
    required this.isGuest,
    required this.user,
  });

  bool get isLoggedIn => isAuthenticated && user != null;
}

/// Auth state notifier
/// Mirrors iOS AuthManager ObservableObject pattern
class AuthNotifier extends StateNotifier<AsyncValue<AuthStateData>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _checkAuthState();
  }

  /// Check authentication state on app launch
  /// Mirrors iOS: AuthManager init with token check
  Future<void> _checkAuthState() async {
    state = const AsyncValue.loading();
    try {
      final authState = await _authService.getAuthState();

      if (authState == AuthState.authenticated) {
        final user = await _authService.getCurrentUser();
        state = AsyncValue.data(
          AuthStateData(
            isAuthenticated: true,
            isGuest: false,
            user: user,
          ),
        );
      } else if (authState == AuthState.guest) {
        state = const AsyncValue.data(
          AuthStateData(
            isAuthenticated: false,
            isGuest: true,
            user: null,
          ),
        );
      } else {
        state = const AsyncValue.data(
          AuthStateData(
            isAuthenticated: false,
            isGuest: false,
            user: null,
          ),
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Login with credentials
  /// Mirrors iOS: AuthManager.login()
  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.login(username, password);
      state = AsyncValue.data(
        AuthStateData(
          isAuthenticated: true,
          isGuest: false,
          user: user,
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;  // Allow UI to handle error
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
      await _authService.register(
        email: email,
        username: username,
        password: password,
      );
      // After registration, user needs to verify email
    } catch (e) {
      rethrow;
    }
  }

  /// Enable guest mode
  /// Mirrors iOS: AuthManager.enableGuestMode()
  Future<void> enableGuestMode() async {
    await _authService.enableGuestMode();
    state = const AsyncValue.data(
      AuthStateData(
        isAuthenticated: false,
        isGuest: true,
        user: null,
      ),
    );
  }

  /// Logout
  /// Mirrors iOS: AuthManager.logout()
  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(
      AuthStateData(
        isAuthenticated: false,
        isGuest: false,
        user: null,
      ),
    );
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(
        AuthStateData(
          isAuthenticated: true,
          isGuest: false,
          user: user,
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider definitions

/// API client provider (singleton)
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Secure storage provider (singleton)
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Auth service provider (singleton)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

/// Main auth provider
/// Usage in UI:
///   final authState = ref.watch(authProvider);
///   authState.when(
///     data: (data) => data.isAuthenticated ? MainScreen() : LoginScreen(),
///     loading: () => LoadingScreen(),
///     error: (e, _) => ErrorScreen(),
///   );
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthStateData>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

/// Convenience provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    data: (data) => data.isAuthenticated,
    orElse: () => false,
  );
});

/// Convenience provider to check if in guest mode
final isGuestModeProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    data: (data) => data.isGuest,
    orElse: () => false,
  );
});

/// Convenience provider to get current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    data: (data) => data.user,
    orElse: () => null,
  );
});
