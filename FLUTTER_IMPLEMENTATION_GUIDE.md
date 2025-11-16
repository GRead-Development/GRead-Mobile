# GRead Flutter Implementation Guide

## Overview

This guide provides a comprehensive roadmap for implementing the GRead Android app using Flutter, maintaining 1:1 feature parity with the iOS version while preserving the existing iOS codebase.

### Key Principles
- **Feature Parity**: All iOS features must be replicated in Flutter
- **Code Independence**: Flutter and iOS codebases remain separate
- **Shared Backend**: Both apps use the same WordPress/BuddyPress API
- **Native Feel**: Flutter app should feel native to Android while matching iOS functionality

---

## Table of Contents

1. [Project Setup](#1-project-setup)
2. [Architecture Overview](#2-architecture-overview)
3. [Dependencies](#3-dependencies)
4. [Authentication System](#4-authentication-system)
5. [API Client Implementation](#5-api-client-implementation)
6. [State Management](#6-state-management)
7. [Data Models](#7-data-models)
8. [Core Features](#8-core-features)
9. [UI Components](#9-ui-components)
10. [Theme System](#10-theme-system)
11. [Testing Strategy](#11-testing-strategy)

---

## 1. Project Setup

### Initial Flutter Project Structure

```
gread_flutter/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart
│   │   │   ├── api_endpoints.dart
│   │   │   └── api_error.dart
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── activity.dart
│   │   │   ├── achievement.dart
│   │   │   ├── book.dart
│   │   │   └── cosmetics.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   ├── storage_service.dart
│   │   │   └── theme_service.dart
│   │   ├── utils/
│   │   │   ├── constants.dart
│   │   │   ├── extensions.dart
│   │   │   └── validators.dart
│   │   └── theme/
│   │       ├── app_theme.dart
│   │       ├── theme_colors.dart
│   │       └── custom_themes.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── activity/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── library/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── profile/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   ├── notifications/
│   │   ├── achievements/
│   │   ├── friends/
│   │   └── moderation/
│   └── shared/
│       └── widgets/
├── test/
├── android/
├── ios/
└── pubspec.yaml
```

### Android-Specific Configuration

**android/app/build.gradle**:
```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.gread.app"
        minSdkVersion 24
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

**android/app/src/main/AndroidManifest.xml**:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <application
        android:label="GRead"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
        </activity>
    </application>
</manifest>
```

---

## 2. Architecture Overview

### iOS to Flutter Architecture Mapping

| iOS Pattern | Flutter Equivalent |
|-------------|-------------------|
| SwiftUI Views | Flutter Widgets |
| ObservableObject | ChangeNotifier/StateNotifier |
| @Published | notifyListeners() |
| @State | setState() |
| @EnvironmentObject | Provider/Riverpod |
| Singleton (.shared) | GetIt/Provider singleton |
| Combine | Streams/RxDart |
| UserDefaults | SharedPreferences/FlutterSecureStorage |
| URLSession | Dio/Http |

### Recommended Architecture: Clean Architecture + MVVM

```
Presentation Layer (UI)
    ↓ (uses)
Provider/State Management
    ↓ (uses)
Service Layer (Business Logic)
    ↓ (uses)
Repository Layer (Data Access)
    ↓ (uses)
Data Sources (API, Local Storage)
```

---

## 3. Dependencies

### pubspec.yaml

```yaml
name: gread
description: GRead - Social Reading Platform
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.9

  # Networking
  dio: ^5.4.0

  # Data Models
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

  # Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # UI Components
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  pull_to_refresh: ^2.0.0

  # Navigation
  go_router: ^13.0.0

  # Utilities
  intl: ^0.18.1
  html: ^0.15.4
  url_launcher: ^6.2.3

  # Logging
  logger: ^2.0.2+1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1

  # Testing
  mockito: ^5.4.4
  integration_test:
    sdk: flutter

  flutter_lints: ^3.0.1
```

### Package Purpose Breakdown

- **flutter_riverpod**: State management (replaces ObservableObject pattern)
- **dio**: HTTP client with interceptors for JWT tokens
- **freezed**: Immutable data classes (replaces Swift structs)
- **json_serializable**: Auto JSON serialization
- **shared_preferences**: Simple key-value storage (UserDefaults equivalent)
- **flutter_secure_storage**: Encrypted storage for JWT tokens
- **cached_network_image**: Image caching (AsyncImage equivalent)
- **go_router**: Declarative routing
- **intl**: Date formatting

---

## 4. Authentication System

### iOS Implementation Analysis

The iOS app uses:
- JWT token stored in UserDefaults
- AuthManager singleton with @Published properties
- Guest mode support
- Token injection in API requests

### Flutter Implementation

#### 4.1 Auth Service

**lib/core/services/auth_service.dart**:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _guestModeKey = 'guest_mode';

  AuthService(this._apiClient, this._secureStorage);

  // Login with JWT
  Future<User> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        '/jwt-auth/v1/token',
        data: {
          'username': username,
          'password': password,
        },
      );

      final token = response['token'] as String;
      final userId = response['user_id'] as int;

      // Store token securely
      await _secureStorage.write(key: _tokenKey, value: token);
      await _secureStorage.write(key: _userIdKey, value: userId.toString());
      await _secureStorage.delete(key: _guestModeKey);

      // Set token in API client
      _apiClient.setAuthToken(token);

      // Fetch current user details
      return await getCurrentUser();
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}');
    }
  }

  // Register new user
  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      await _apiClient.post(
        '/buddypress/v1/signup',
        data: {
          'user_login': username,
          'user_email': email,
          'password': password,
        },
      );
    } catch (e) {
      throw AuthException('Registration failed: ${e.toString()}');
    }
  }

  // Enable guest mode
  Future<void> enableGuestMode() async {
    await _secureStorage.write(key: _guestModeKey, value: 'true');
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
  }

  // Get current user
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/buddypress/v1/members/me');
      return User.fromJson(response);
    } catch (e) {
      throw AuthException('Failed to fetch user: ${e.toString()}');
    }
  }

  // Check authentication status
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

  // Logout
  Future<void> logout() async {
    await _secureStorage.deleteAll();
    _apiClient.clearAuthToken();
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
}

enum AuthState {
  authenticated,
  guest,
  unauthenticated,
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
```

#### 4.2 Auth State Provider

**lib/features/auth/providers/auth_provider.dart**:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user.dart';

class AuthNotifier extends StateNotifier<AsyncValue<AuthStateData>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _checkAuthState();
  }

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
    }
  }

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
    } catch (e) {
      rethrow;
    }
  }

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
}

class AuthStateData {
  final bool isAuthenticated;
  final bool isGuest;
  final User? user;

  const AuthStateData({
    required this.isAuthenticated,
    required this.isGuest,
    required this.user,
  });
}

// Provider definition
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthStateData>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
```

---

## 5. API Client Implementation

### iOS Implementation Analysis

The iOS APIManager uses:
- Generic async/await request method
- Snake_case to camelCase conversion
- Multiple date format handling
- JWT token injection
- Custom error handling

### Flutter Implementation

#### 5.1 API Client with Dio

**lib/core/api/api_client.dart**:
```dart
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'api_error.dart';

class ApiClient {
  static const String baseUrl = 'https://gread.fun/wp-json';

  final Dio _dio;
  final Logger _logger;
  String? _authToken;

  ApiClient({Dio? dio, Logger? logger})
      : _dio = dio ?? Dio(),
        _logger = logger ?? Logger() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Request interceptor - Add auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }

          _logger.d('REQUEST[${options.method}] => ${options.uri}');
          _logger.d('Headers: ${options.headers}');
          _logger.d('Data: ${options.data}');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}');
          _logger.d('Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e(
            'ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}',
            error: error.error,
            stackTrace: error.stackTrace,
          );
          return handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  // Generic GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic POST request
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic PUT request
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _handleResponse(Response response) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response.data;
    } else {
      throw ApiError(
        message: 'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  ApiError _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError(
          message: 'Connection timeout. Please check your internet connection.',
          type: ApiErrorType.timeout,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] as String? ??
            error.response?.data?['error'] as String? ??
            'Request failed';

        return ApiError(
          message: message,
          statusCode: statusCode,
          type: _getErrorType(statusCode),
        );

      case DioExceptionType.cancel:
        return ApiError(
          message: 'Request cancelled',
          type: ApiErrorType.cancelled,
        );

      default:
        return ApiError(
          message: error.message ?? 'Unknown error occurred',
          type: ApiErrorType.unknown,
        );
    }
  }

  ApiErrorType _getErrorType(int? statusCode) {
    if (statusCode == null) return ApiErrorType.unknown;

    if (statusCode == 401) return ApiErrorType.unauthorized;
    if (statusCode == 403) return ApiErrorType.forbidden;
    if (statusCode == 404) return ApiErrorType.notFound;
    if (statusCode >= 500) return ApiErrorType.serverError;

    return ApiErrorType.unknown;
  }
}
```

#### 5.2 API Endpoints

**lib/core/api/api_endpoints.dart**:
```dart
class ApiEndpoints {
  // Base paths
  static const String buddyPress = '/buddypress/v1';
  static const String gread = '/gread/v1';
  static const String jwtAuth = '/jwt-auth/v1';

  // Authentication
  static const String login = '$jwtAuth/token';
  static const String signup = '$buddyPress/signup';
  static const String currentUser = '$buddyPress/members/me';

  // User
  static String userStats(int userId) => '$gread/user/$userId/stats';
  static const String userCosmetics = '$gread/user/cosmetics';
  static const String setTheme = '$gread/user/cosmetics/theme';
  static const String checkUnlocks = '$gread/user/check-unlocks';

  // Activities
  static const String activities = '$gread/activity';
  static String activityComments(int activityId) => '$gread/activity/$activityId/comments';
  static const String createActivity = '$gread/activity';

  // Friends
  static const String friendRequest = '$gread/friends/request';
  static String friends(int userId) => '$gread/friends/$userId';
  static const String friendRequests = '$gread/friends/requests';

  // Achievements
  static const String achievements = '$gread/achievements';
  static String userAchievements(int userId) => '$gread/user/$userId/achievements';
  static const String achievementsLeaderboard = '$gread/achievements/leaderboard';
  static const String checkAchievements = '$gread/me/achievements/check';

  // Moderation
  static const String blockUser = '$gread/user/block';
  static const String muteUser = '$gread/user/mute';
  static const String reportUser = '$gread/user/report';
  static const String blockedList = '$gread/user/blocked_list';
  static const String mutedList = '$gread/user/muted_list';

  // Mentions
  static const String mentionsSearch = '$gread/mentions/search';
  static String userMentions(int userId) => '$gread/user/$userId/mentions';
  static const String markMentionsRead = '$gread/me/mentions/read';

  // Notifications
  static const String notifications = '$buddyPress/notifications';

  // Search
  static const String searchMembers = '$gread/members/search';

  // Cosmetics
  static const String cosmetics = '$gread/cosmetics';
}
```

#### 5.3 API Error Handling

**lib/core/api/api_error.dart**:
```dart
enum ApiErrorType {
  timeout,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  cancelled,
  unknown,
}

class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorType type;

  ApiError({
    required this.message,
    this.statusCode,
    this.type = ApiErrorType.unknown,
  });

  @override
  String toString() => message;

  String get userFriendlyMessage {
    switch (type) {
      case ApiErrorType.timeout:
        return 'Connection timeout. Please check your internet connection.';
      case ApiErrorType.unauthorized:
        return 'Session expired. Please login again.';
      case ApiErrorType.forbidden:
        return 'You don\'t have permission to perform this action.';
      case ApiErrorType.notFound:
        return 'The requested resource was not found.';
      case ApiErrorType.serverError:
        return 'Server error. Please try again later.';
      case ApiErrorType.cancelled:
        return 'Request was cancelled.';
      default:
        return message;
    }
  }
}
```

---

## 6. State Management

### State Management Strategy

We'll use **Riverpod** for state management, which provides:
- Compile-time safety
- Better testability
- No BuildContext dependency
- Automatic disposal

### Provider Architecture

```dart
// Service Providers (Singletons)
final apiClientProvider = Provider((ref) => ApiClient());
final authServiceProvider = Provider((ref) => AuthService(
  ref.watch(apiClientProvider),
  const FlutterSecureStorage(),
));

// State Providers
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthStateData>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier(ref.watch(themeServiceProvider));
});

// Data Providers (with auto-refresh)
final userStatsProvider = FutureProvider.family<UserStats, int>((ref, userId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.userStats(userId));
  return UserStats.fromJson(response);
});

final activitiesProvider = StateNotifierProvider<ActivitiesNotifier, AsyncValue<List<Activity>>>((ref) {
  return ActivitiesNotifier(ref.watch(apiClientProvider));
});
```

---

## 7. Data Models

### Using Freezed for Immutable Data Classes

#### 7.1 User Model

**lib/core/models/user.dart**:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    @JsonKey(name: 'user_login') String? userLogin,
    @JsonKey(name: 'avatar_urls') AvatarUrls? avatarUrls,
    @JsonKey(name: 'member_types') List<String>? memberTypes,
    @JsonKey(name: 'registered_date') String? registeredDate,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class AvatarUrls with _$AvatarUrls {
  const factory AvatarUrls({
    String? thumb,
    String? full,
  }) = _AvatarUrls;

  factory AvatarUrls.fromJson(Map<String, dynamic> json) => _$AvatarUrlsFromJson(json);
}
```

#### 7.2 Activity Model

**lib/core/models/activity.dart**:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity.freezed.dart';
part 'activity.g.dart';

@freezed
class Activity with _$Activity {
  const factory Activity({
    required int id,
    @JsonKey(name: 'user_id') int? userId,
    String? content,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'user_login') String? userLogin,
    @JsonKey(name: 'user_avatar') String? userAvatar,
    @JsonKey(name: 'date_recorded') String? dateRecorded,
    List<Activity>? children,
    @JsonKey(name: 'reply_count') int? replyCount,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);
}
```

#### 7.3 Achievement Model

**lib/core/models/achievement.dart**:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';
part 'achievement.g.dart';

@freezed
class Achievement with _$Achievement {
  const factory Achievement({
    required int id,
    required String slug,
    required String name,
    required String description,
    required AchievementIcon icon,
    @JsonKey(name: 'unlock_requirements') required UnlockRequirements unlockRequirements,
    required int reward,
    AchievementProgress? progress,
    @JsonKey(name: 'is_unlocked') bool? isUnlocked,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
}

@freezed
class AchievementIcon with _$AchievementIcon {
  const factory AchievementIcon({
    required String symbol,
    required String color,
  }) = _AchievementIcon;

  factory AchievementIcon.fromJson(Map<String, dynamic> json) => _$AchievementIconFromJson(json);
}

@freezed
class UnlockRequirements with _$UnlockRequirements {
  const factory UnlockRequirements({
    required String metric,
    required int value,
  }) = _UnlockRequirements;

  factory UnlockRequirements.fromJson(Map<String, dynamic> json) => _$UnlockRequirementsFromJson(json);
}

@freezed
class AchievementProgress with _$AchievementProgress {
  const factory AchievementProgress({
    required int current,
    required int required,
    required double percentage,
  }) = _AchievementProgress;

  factory AchievementProgress.fromJson(Map<String, dynamic> json) => _$AchievementProgressFromJson(json);
}
```

### Generate Code

After creating models, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 8. Core Features

### 8.1 Activity Feed

**lib/features/activity/providers/activities_provider.dart**:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/activity.dart';

class ActivitiesNotifier extends StateNotifier<AsyncValue<List<Activity>>> {
  final ApiClient _apiClient;
  int _currentPage = 1;
  bool _hasMore = true;

  ActivitiesNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    loadActivities();
  }

  Future<void> loadActivities({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.activities,
        queryParameters: {
          'per_page': 20,
          'page': _currentPage,
        },
      );

      final activities = (response as List)
          .map((json) => Activity.fromJson(json))
          .toList();

      if (refresh) {
        state = AsyncValue.data(activities);
      } else {
        state = state.whenData((current) => [...current, ...activities]);
      }

      _hasMore = activities.length == 20;
      _currentPage++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (_hasMore && !state.isLoading) {
      await loadActivities();
    }
  }

  Future<void> postActivity(String content) async {
    try {
      await _apiClient.post(
        ApiEndpoints.createActivity,
        data: {'content': content},
      );

      // Refresh after posting
      await loadActivities(refresh: true);
    } catch (e) {
      rethrow;
    }
  }
}

final activitiesProvider = StateNotifierProvider<ActivitiesNotifier, AsyncValue<List<Activity>>>((ref) {
  return ActivitiesNotifier(ref.watch(apiClientProvider));
});
```

**lib/features/activity/screens/activity_feed_screen.dart**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/activities_provider.dart';
import '../widgets/activity_card.dart';
import '../widgets/post_activity_sheet.dart';

class ActivityFeedScreen extends ConsumerStatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  ConsumerState<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends ConsumerState<ActivityFeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(activitiesProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activitiesState = ref.watch(activitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Feed'),
      ),
      body: activitiesState.when(
        data: (activities) => RefreshIndicator(
          onRefresh: () => ref.read(activitiesProvider.notifier).loadActivities(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: activities.length + 1,
            itemBuilder: (context, index) {
              if (index == activities.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return ActivityCard(activity: activities[index]);
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${error.toString()}'),
              ElevatedButton(
                onPressed: () => ref.refresh(activitiesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const PostActivitySheet(),
    );
  }
}
```

### 8.2 Book Library

**lib/features/library/providers/library_provider.dart**:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/book.dart';

class LibraryNotifier extends StateNotifier<AsyncValue<List<LibraryItem>>> {
  final ApiClient _apiClient;

  LibraryNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    loadLibrary();
  }

  Future<void> loadLibrary() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.get('/gread/v1/library');
      final items = (response as List)
          .map((json) => LibraryItem.fromJson(json))
          .toList();

      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProgress(int itemId, int currentPage) async {
    try {
      await _apiClient.put(
        '/gread/v1/library/$itemId',
        data: {'current_page': currentPage},
      );

      await loadLibrary();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStatus(int itemId, String status) async {
    try {
      await _apiClient.put(
        '/gread/v1/library/$itemId',
        data: {'status': status},
      );

      await loadLibrary();
    } catch (e) {
      rethrow;
    }
  }
}
```

### 8.3 Achievements

**lib/features/achievements/providers/achievements_provider.dart**:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/achievement.dart';

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.achievements);
  return (response as List)
      .map((json) => Achievement.fromJson(json))
      .toList();
});

final userAchievementsProvider = FutureProvider.family<List<Achievement>, int>((ref, userId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.userAchievements(userId));
  return (response as List)
      .map((json) => Achievement.fromJson(json))
      .toList();
});

final achievementLeaderboardProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.get(ApiEndpoints.achievementsLeaderboard);
});
```

---

## 9. UI Components

### 9.1 Main Navigation (Tab Bar)

**lib/shared/widgets/main_tab_view.dart**:
```dart
import 'package:flutter/material.dart';
import '../../features/activity/screens/activity_feed_screen.dart';
import '../../features/library/screens/library_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ActivityFeedScreen(),
    LibraryScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
```

### 9.2 Activity Card Component

**lib/features/activity/widgets/activity_card.dart**:
```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/activity.dart';
import '../../../core/utils/date_formatter.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;

  const ActivityCard({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: activity.userAvatar != null
                      ? CachedNetworkImageProvider(activity.userAvatar!)
                      : null,
                  child: activity.userAvatar == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.displayName ?? 'Unknown User',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (activity.dateRecorded != null)
                        Text(
                          DateFormatter.timeAgo(activity.dateRecorded!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            if (activity.content != null)
              Text(
                _stripHtml(activity.content!),
                style: Theme.of(context).textTheme.bodyMedium,
              ),

            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.comment),
                  label: Text('${activity.replyCount ?? 0}'),
                ),
              ],
            ),

            // Comments/Replies
            if (activity.children != null && activity.children!.isNotEmpty)
              Column(
                children: activity.children!.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 24, top: 8),
                    child: ActivityCard(activity: reply),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
```

### 9.3 Theme Selector

**lib/features/profile/widgets/theme_selector.dart**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/cosmetics.dart';
import '../providers/theme_provider.dart';

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesState = ref.watch(availableThemesProvider);
    final currentTheme = ref.watch(currentThemeProvider);

    return themesState.when(
      data: (themes) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final theme = themes[index];
          final isSelected = theme.id == currentTheme?.id;
          final isLocked = theme.unlockRequirement != null;

          return GestureDetector(
            onTap: isLocked ? null : () {
              ref.read(themeProvider.notifier).setTheme(theme);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(int.parse('0xFF${theme.primaryColor}')),
                    Color(int.parse('0xFF${theme.secondaryColor}')),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          theme.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (theme.description.isNotEmpty)
                          Text(
                            theme.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (isLocked)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                  if (isSelected)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
```

---

## 10. Theme System

### 10.1 Theme Service

**lib/core/services/theme_service.dart**:
```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/cosmetics.dart';

class ThemeService {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  static const String _themeKey = 'active_theme';
  static const String _fontKey = 'active_font';

  ThemeService(this._apiClient, this._prefs);

  // Fetch available themes
  Future<List<AppTheme>> getAvailableThemes() async {
    final response = await _apiClient.get(ApiEndpoints.cosmetics);
    final themes = response['themes'] as List;
    return themes.map((json) => AppTheme.fromJson(json)).toList();
  }

  // Get current theme
  Future<AppTheme?> getCurrentTheme() async {
    final themeId = _prefs.getString(_themeKey);
    if (themeId == null) return null;

    final themes = await getAvailableThemes();
    return themes.firstWhere((t) => t.id == themeId);
  }

  // Set active theme
  Future<void> setTheme(AppTheme theme) async {
    await _apiClient.post(
      ApiEndpoints.setTheme,
      data: {'theme_id': theme.id},
    );

    await _prefs.setString(_themeKey, theme.id);
  }

  // Convert AppTheme to Flutter ThemeData
  ThemeData toThemeData(AppTheme appTheme) {
    final primaryColor = Color(int.parse('0xFF${appTheme.primaryColor}'));
    final secondaryColor = Color(int.parse('0xFF${appTheme.secondaryColor}'));
    final backgroundColor = Color(int.parse('0xFF${appTheme.backgroundColor}'));

    return ThemeData(
      useMaterial3: true,
      brightness: appTheme.isDarkTheme ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: appTheme.isDarkTheme ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: backgroundColor,
        onSurface: appTheme.isDarkTheme ? Colors.white : Colors.black,
      ),
      scaffoldBackgroundColor: backgroundColor,
    );
  }
}
```

### 10.2 Theme Provider

**lib/features/profile/providers/theme_provider.dart**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/models/cosmetics.dart';

class ThemeNotifier extends StateNotifier<ThemeData> {
  final ThemeService _themeService;
  AppTheme? _currentAppTheme;

  ThemeNotifier(this._themeService) : super(ThemeData.light()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final appTheme = await _themeService.getCurrentTheme();
    if (appTheme != null) {
      _currentAppTheme = appTheme;
      state = _themeService.toThemeData(appTheme);
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    await _themeService.setTheme(theme);
    _currentAppTheme = theme;
    state = _themeService.toThemeData(theme);
  }

  AppTheme? get currentAppTheme => _currentAppTheme;
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  return ThemeNotifier(ref.watch(themeServiceProvider));
});

final currentThemeProvider = Provider<AppTheme?>((ref) {
  return ref.watch(themeProvider.notifier).currentAppTheme;
});
```

---

## 11. Testing Strategy

### 11.1 Unit Tests

**test/services/auth_service_test.dart**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:gread/core/services/auth_service.dart';
import 'package:gread/core/api/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@GenerateMocks([ApiClient, FlutterSecureStorage])
import 'auth_service_test.mocks.dart';

void main() {
  late AuthService authService;
  late MockApiClient mockApiClient;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockApiClient = MockApiClient();
    mockStorage = MockFlutterSecureStorage();
    authService = AuthService(mockApiClient, mockStorage);
  });

  group('AuthService', () {
    test('login should store token and return user', () async {
      // Arrange
      when(mockApiClient.post(
        '/jwt-auth/v1/token',
        data: anyNamed('data'),
      )).thenAnswer((_) async => {
        'token': 'test_token',
        'user_id': 1,
      });

      when(mockApiClient.get('/buddypress/v1/members/me'))
          .thenAnswer((_) async => {
        'id': 1,
        'name': 'Test User',
      });

      // Act
      final user = await authService.login('testuser', 'password');

      // Assert
      expect(user.id, 1);
      expect(user.name, 'Test User');
      verify(mockStorage.write(key: 'jwt_token', value: 'test_token')).called(1);
    });

    test('logout should clear storage and token', () async {
      // Act
      await authService.logout();

      // Assert
      verify(mockStorage.deleteAll()).called(1);
      verify(mockApiClient.clearAuthToken()).called(1);
    });
  });
}
```

### 11.2 Widget Tests

**test/widgets/activity_card_test.dart**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gread/core/models/activity.dart';
import 'package:gread/features/activity/widgets/activity_card.dart';

void main() {
  testWidgets('ActivityCard displays activity content', (tester) async {
    // Arrange
    const activity = Activity(
      id: 1,
      displayName: 'Test User',
      content: 'Test content',
      dateRecorded: '2024-01-01T00:00:00',
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityCard(activity: activity),
        ),
      ),
    );

    // Assert
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('Test content'), findsOneWidget);
  });
}
```

### 11.3 Integration Tests

**integration_test/app_test.dart**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gread/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('Complete login flow', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Find and tap login button
      final loginButton = find.text('Sign In');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextField).first, 'testuser');
      await tester.enterText(find.byType(TextField).last, 'password');

      // Submit
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Verify navigation to main screen
      expect(find.text('Activity Feed'), findsOneWidget);
    });
  });
}
```

### 11.4 Test Commands

```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test

# Run specific test file
flutter test test/services/auth_service_test.dart
```

---

## Implementation Checklist

### Phase 1: Foundation (Week 1-2)
- [ ] Set up Flutter project structure
- [ ] Configure Android build settings
- [ ] Implement API client with Dio
- [ ] Create data models with Freezed
- [ ] Set up Riverpod state management
- [ ] Implement authentication service
- [ ] Create storage service
- [ ] Write unit tests for services

### Phase 2: Core Features (Week 3-4)
- [ ] Implement activity feed
- [ ] Create book library management
- [ ] Build user profile screens
- [ ] Implement notifications
- [ ] Create friend system
- [ ] Write widget tests

### Phase 3: Advanced Features (Week 5-6)
- [ ] Implement achievement system
- [ ] Create theme/cosmetics system
- [ ] Build moderation features
- [ ] Implement search functionality
- [ ] Add mentions support
- [ ] Write integration tests

### Phase 4: Polish & Testing (Week 7-8)
- [ ] UI/UX refinements
- [ ] Performance optimization
- [ ] Comprehensive testing
- [ ] Bug fixes
- [ ] Documentation
- [ ] Beta testing

---

## Key Differences from iOS

### 1. Navigation
- **iOS**: NavigationView with stack-based navigation
- **Flutter**: Navigator 2.0 with go_router for declarative routing

### 2. State Management
- **iOS**: @Published properties with ObservableObject
- **Flutter**: Riverpod providers with StateNotifier

### 3. Async Operations
- **iOS**: async/await with Task
- **Flutter**: Future/async-await with FutureProvider

### 4. Image Loading
- **iOS**: AsyncImage
- **Flutter**: CachedNetworkImage with shimmer placeholders

### 5. Storage
- **iOS**: UserDefaults for simple data, Keychain for tokens
- **Flutter**: SharedPreferences for simple data, FlutterSecureStorage for tokens

---

## Common Pitfalls to Avoid

1. **Not handling auth token refresh**: Implement token refresh interceptor
2. **Memory leaks**: Properly dispose controllers and subscriptions
3. **Not handling offline state**: Implement proper error handling
4. **Ignoring platform differences**: Test on various Android devices
5. **Poor list performance**: Use ListView.builder, not Column with many children
6. **Not caching images**: Always use CachedNetworkImage for remote images
7. **Blocking UI thread**: Use async/await properly, isolates for heavy computation

---

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Dio Documentation](https://pub.dev/packages/dio)
- [Freezed Documentation](https://pub.dev/packages/freezed)
- [Material Design 3](https://m3.material.io/)

---

## Next Steps

1. Review this guide with the development team
2. Set up development environment
3. Create Flutter project from template
4. Begin Phase 1 implementation
5. Set up CI/CD pipeline
6. Start weekly progress reviews

---

*This guide is a living document. Update it as you discover new patterns or encounter challenges during implementation.*
