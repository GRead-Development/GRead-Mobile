# GRead Flutter Testing Guide

## Overview

This guide covers comprehensive testing strategies for the GRead Flutter app, including unit tests, widget tests, integration tests, and best practices.

---

## Table of Contents

1. [Testing Philosophy](#testing-philosophy)
2. [Test Structure](#test-structure)
3. [Unit Tests](#unit-tests)
4. [Widget Tests](#widget-tests)
5. [Integration Tests](#integration-tests)
6. [Mocking](#mocking)
7. [Test Coverage](#test-coverage)
8. [CI/CD Integration](#cicd-integration)
9. [Best Practices](#best-practices)

---

## Testing Philosophy

### Testing Pyramid

```
        /\
       /  \      E2E Tests (10%)
      /----\
     /      \    Integration Tests (20%)
    /--------\
   /          \  Unit Tests (70%)
  /____________\
```

- **70% Unit Tests**: Fast, isolated, test business logic
- **20% Widget Tests**: Test UI components and interactions
- **10% Integration Tests**: Test complete user flows

### What to Test

✅ **DO Test**:
- Business logic in services and providers
- API client request/response handling
- State management logic
- Widget rendering and interactions
- Navigation flows
- Error handling

❌ **DON'T Test**:
- Third-party packages (assume they work)
- Flutter framework code
- Generated code (freezed, json_serializable)

---

## Test Structure

### Directory Organization

```
test/
├── unit/
│   ├── services/
│   │   ├── auth_service_test.dart
│   │   └── theme_service_test.dart
│   ├── api/
│   │   └── api_client_test.dart
│   └── models/
│       └── user_test.dart
├── widget/
│   ├── auth/
│   │   └── login_screen_test.dart
│   ├── activity/
│   │   └── activity_card_test.dart
│   └── shared/
│       └── main_tab_view_test.dart
├── integration/
│   ├── login_flow_test.dart
│   └── activity_flow_test.dart
├── helpers/
│   ├── mock_data.dart
│   ├── test_helpers.dart
│   └── pump_app.dart
└── mocks/
    └── mocks.dart (generated)
```

---

## Unit Tests

### Testing Services

#### Example: AuthService Tests

**test/unit/services/auth_service_test.dart**:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:gread/core/services/auth_service.dart';
import 'package:gread/core/api/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gread/core/models/user.dart';

// Generate mocks
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
    group('login', () {
      test('should store token and return user on successful login', () async {
        // Arrange
        const username = 'testuser';
        const password = 'password123';
        const token = 'test_jwt_token';
        const userId = 1;

        when(mockApiClient.post(
          '/jwt-auth/v1/token',
          data: anyNamed('data'),
        )).thenAnswer((_) async => {
          'token': token,
          'user_id': userId,
        });

        when(mockApiClient.get('/buddypress/v1/members/me'))
            .thenAnswer((_) async => {
          'id': userId,
          'name': 'Test User',
          'user_login': username,
        });

        when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        final user = await authService.login(username, password);

        // Assert
        expect(user.id, userId);
        expect(user.name, 'Test User');
        expect(user.userLogin, username);

        verify(mockStorage.write(key: 'jwt_token', value: token)).called(1);
        verify(mockStorage.write(key: 'user_id', value: userId.toString())).called(1);
        verify(mockApiClient.setAuthToken(token)).called(1);
      });

      test('should throw AuthException on login failure', () async {
        // Arrange
        when(mockApiClient.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(Exception('Invalid credentials'));

        // Act & Assert
        expect(
          () => authService.login('baduser', 'badpass'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('logout', () {
      test('should clear storage and token on logout', () async {
        // Arrange
        when(mockStorage.deleteAll()).thenAnswer((_) async {});

        // Act
        await authService.logout();

        // Assert
        verify(mockStorage.deleteAll()).called(1);
        verify(mockApiClient.clearAuthToken()).called(1);
      });
    });

    group('getAuthState', () {
      test('should return authenticated when token exists', () async {
        // Arrange
        when(mockStorage.read(key: 'jwt_token'))
            .thenAnswer((_) async => 'valid_token');
        when(mockStorage.read(key: 'guest_mode'))
            .thenAnswer((_) async => null);

        // Act
        final authState = await authService.getAuthState();

        // Assert
        expect(authState, AuthState.authenticated);
        verify(mockApiClient.setAuthToken('valid_token')).called(1);
      });

      test('should return guest when guest mode is enabled', () async {
        // Arrange
        when(mockStorage.read(key: 'jwt_token'))
            .thenAnswer((_) async => null);
        when(mockStorage.read(key: 'guest_mode'))
            .thenAnswer((_) async => 'true');

        // Act
        final authState = await authService.getAuthState();

        // Assert
        expect(authState, AuthState.guest);
      });

      test('should return unauthenticated when no token or guest mode', () async {
        // Arrange
        when(mockStorage.read(key: any))
            .thenAnswer((_) async => null);

        // Act
        final authState = await authService.getAuthState();

        // Assert
        expect(authState, AuthState.unauthenticated);
      });
    });
  });
}
```

#### Generate Mocks

Run this command to generate mock classes:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Testing Providers

#### Example: AuthProvider Tests

**test/unit/providers/auth_provider_test.dart**:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gread/features/auth/providers/auth_provider.dart';
import 'package:gread/core/services/auth_service.dart';
import 'package:gread/core/models/user.dart';

@GenerateMocks([AuthService])
import 'auth_provider_test.mocks.dart';

void main() {
  late MockAuthService mockAuthService;
  late ProviderContainer container;

  setUp(() {
    mockAuthService = MockAuthService();

    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier', () {
    test('should initialize with loading state', () {
      // Arrange
      when(mockAuthService.getAuthState())
          .thenAnswer((_) async => AuthState.unauthenticated);

      // Act
      final state = container.read(authProvider);

      // Assert
      expect(state.isLoading, true);
    });

    test('should set authenticated state after successful login', () async {
      // Arrange
      const user = User(
        id: 1,
        name: 'Test User',
        userLogin: 'testuser',
      );

      when(mockAuthService.login(any, any))
          .thenAnswer((_) async => user);

      // Act
      await container.read(authProvider.notifier).login('testuser', 'password');

      // Assert
      final state = container.read(authProvider).value!;
      expect(state.isAuthenticated, true);
      expect(state.user, user);
      expect(state.isGuest, false);
    });

    test('should set guest state when enabling guest mode', () async {
      // Arrange
      when(mockAuthService.enableGuestMode()).thenAnswer((_) async {});

      // Act
      await container.read(authProvider.notifier).enableGuestMode();

      // Assert
      final state = container.read(authProvider).value!;
      expect(state.isGuest, true);
      expect(state.isAuthenticated, false);
      expect(state.user, null);
    });

    test('should clear state on logout', () async {
      // Arrange
      when(mockAuthService.logout()).thenAnswer((_) async {});

      // Act
      await container.read(authProvider.notifier).logout();

      // Assert
      final state = container.read(authProvider).value!;
      expect(state.isAuthenticated, false);
      expect(state.isGuest, false);
      expect(state.user, null);
    });
  });
}
```

---

## Widget Tests

### Testing Widgets with Riverpod

#### Helper: Pump App

**test/helpers/pump_app.dart**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper to pump a widget with Riverpod provider scope
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
  }) {
    return pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: widget,
        ),
      ),
    );
  }
}
```

#### Example: Activity Card Test

**test/widget/activity/activity_card_test.dart**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gread/core/models/activity.dart';
import 'package:gread/features/activity/widgets/activity_card.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('ActivityCard', () {
    testWidgets('should display activity content and user info', (tester) async {
      // Arrange
      const activity = Activity(
        id: 1,
        displayName: 'John Doe',
        userAvatar: 'https://example.com/avatar.jpg',
        content: 'This is a test activity',
        dateRecorded: '2024-01-15T10:30:00',
        replyCount: 5,
      );

      // Act
      await tester.pumpApp(const ActivityCard(activity: activity));

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('This is a test activity'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);  // Reply count
    });

    testWidgets('should display "Unknown User" when displayName is null', (tester) async {
      // Arrange
      const activity = Activity(
        id: 1,
        content: 'Anonymous activity',
      );

      // Act
      await tester.pumpApp(const ActivityCard(activity: activity));

      // Assert
      expect(find.text('Unknown User'), findsOneWidget);
    });

    testWidgets('should show comment icon button', (tester) async {
      // Arrange
      const activity = Activity(id: 1, content: 'Test');

      // Act
      await tester.pumpApp(const ActivityCard(activity: activity));

      // Assert
      expect(find.byIcon(Icons.comment), findsOneWidget);
    });

    testWidgets('should render nested comments', (tester) async {
      // Arrange
      const activity = Activity(
        id: 1,
        content: 'Parent activity',
        children: [
          Activity(id: 2, content: 'Child comment 1'),
          Activity(id: 3, content: 'Child comment 2'),
        ],
      );

      // Act
      await tester.pumpApp(const ActivityCard(activity: activity));

      // Assert
      expect(find.text('Parent activity'), findsOneWidget);
      expect(find.text('Child comment 1'), findsOneWidget);
      expect(find.text('Child comment 2'), findsOneWidget);
    });
  });
}
```

#### Example: Login Screen Test

**test/widget/auth/login_screen_test.dart**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gread/features/auth/screens/login_screen.dart';
import 'package:gread/features/auth/providers/auth_provider.dart';
import '../../helpers/pump_app.dart';
import '../../unit/providers/auth_provider_test.mocks.dart';

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  group('LoginScreen', () {
    testWidgets('should display username and password fields', (tester) async {
      // Act
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );

      // Assert
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('should show error when login fails', (tester) async {
      // Arrange
      when(mockAuthService.login(any, any))
          .thenThrow(Exception('Invalid credentials'));

      // Act
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );

      await tester.enterText(
        find.byType(TextField).first,
        'wronguser',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'wrongpass',
      );

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('should disable login button when fields are empty', (tester) async {
      // Act
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );

      final loginButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      // Assert
      expect(loginButton.enabled, false);
    });
  });
}
```

---

## Integration Tests

### Full Flow Testing

#### Example: Login Flow Test

**integration_test/login_flow_test.dart**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gread/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow Integration Tests', () {
    testWidgets('Complete login flow with valid credentials', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Should show landing page
      expect(find.text('Welcome to GRead'), findsOneWidget);

      // Tap sign in button
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(
        find.byKey(const Key('username_field')),
        'testuser',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'TestPassword123!',
      );

      // Tap login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should navigate to main screen
      expect(find.text('Activity Feed'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Guest mode flow', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Tap continue as guest
      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      // Should show main screen with limited access
      expect(find.text('Activity Feed'), findsOneWidget);

      // Try to post (should show sign-in prompt)
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to post'), findsOneWidget);
    });
  });
}
```

#### Running Integration Tests

```bash
# Run on connected device or emulator
flutter test integration_test/login_flow_test.dart

# Run all integration tests
flutter test integration_test/
```

---

## Test Coverage

### Generate Coverage Report

```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report (requires genhtml from lcov package)
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html
```

### Coverage Goals

- **Overall**: > 80%
- **Services**: > 90%
- **Providers**: > 85%
- **Widgets**: > 70%

---

## Best Practices

### 1. Use Descriptive Test Names

```dart
// ❌ Bad
test('test login', () { ... });

// ✅ Good
test('should return user and store token when login is successful', () { ... });
```

### 2. Follow AAA Pattern

```dart
test('description', () {
  // Arrange - Set up test data and mocks
  final user = User(id: 1, name: 'Test');
  when(mockService.getUser()).thenReturn(user);

  // Act - Perform the action being tested
  final result = await service.fetchUser();

  // Assert - Verify the outcome
  expect(result, user);
  verify(mockService.getUser()).called(1);
});
```

### 3. Test Edge Cases

```dart
group('updateProgress', () {
  test('should handle valid page number', () { ... });

  test('should throw error when page exceeds total pages', () { ... });

  test('should handle zero page number', () { ... });

  test('should handle negative page number', () { ... });
});
```

### 4. Use Test Helpers

```dart
// test/helpers/mock_data.dart
class MockData {
  static const testUser = User(
    id: 1,
    name: 'Test User',
    userLogin: 'testuser',
  );

  static const testActivity = Activity(
    id: 1,
    content: 'Test activity',
    displayName: 'Test User',
  );
}
```

### 5. Clean Up Resources

```dart
group('MyTest', () {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();  // Important!
  });

  test('...', () { ... });
});
```

### 6. Mock External Dependencies

```dart
// Always mock:
// - API clients
// - Storage services
// - Platform-specific code
// - Time-dependent operations

@GenerateMocks([
  ApiClient,
  FlutterSecureStorage,
  SharedPreferences,
])
```

### 7. Test Error Scenarios

```dart
test('should handle network errors gracefully', () async {
  // Arrange
  when(mockClient.get(any))
      .thenThrow(DioException(type: DioExceptionType.connectionTimeout));

  // Act & Assert
  expect(
    () => service.fetchData(),
    throwsA(isA<ApiError>()),
  );
});
```

---

## Running Tests

### Run All Tests

```bash
flutter test
```

### Run Specific Test File

```bash
flutter test test/unit/services/auth_service_test.dart
```

### Run Tests by Name Pattern

```bash
flutter test --name "login"
```

### Run with Verbose Output

```bash
flutter test --verbose
```

### Watch Mode (run tests on file changes)

```bash
flutter test --watch
```

---

## CI/CD Integration

### GitHub Actions Example

**.github/workflows/test.yml**:

```yaml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run code generation
        run: flutter pub run build_runner build --delete-conflicting-outputs

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info

      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info | grep lines | awk '{print $2}' | sed 's/%//')
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage is below 80%"
            exit 1
          fi
```

---

## Useful Testing Commands

```bash
# Generate mocks
flutter pub run build_runner build --delete-conflicting-outputs

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/

# Run tests in a specific directory
flutter test test/unit/

# Run tests with platform specification
flutter test --platform chrome

# Clear test cache
flutter test --clear-cache
```

---

## Additional Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Riverpod Testing Guide](https://riverpod.dev/docs/cookbooks/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

---

*Keep tests fast, focused, and maintainable!*
