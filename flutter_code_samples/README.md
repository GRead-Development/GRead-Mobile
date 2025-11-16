# GRead Flutter Code Samples

This directory contains complete, working Flutter code samples for building the GRead Android app to match the iOS version.

## 📁 Contents

### Documentation

- **[FLUTTER_IMPLEMENTATION_GUIDE.md](../FLUTTER_IMPLEMENTATION_GUIDE.md)** - Comprehensive implementation guide covering architecture, features, and best practices
- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Complete testing strategy with examples for unit, widget, and integration tests
- **[QUICKSTART.md](QUICKSTART.md)** - Get up and running in 15 minutes

### Code Samples

```
flutter_code_samples/
├── core/
│   ├── api/
│   │   ├── api_client.dart          # HTTP client with Dio
│   │   ├── api_endpoints.dart       # Centralized endpoint definitions
│   │   └── api_error.dart          # Error handling
│   ├── models/
│   │   ├── user.dart               # User models with Freezed
│   │   ├── activity.dart           # Activity feed models
│   │   ├── achievement.dart        # Achievement system models
│   │   ├── book.dart               # Book and library models
│   │   └── cosmetics.dart          # Theme and customization models
│   └── services/
│       └── auth_service.dart       # Authentication service
├── features/
│   ├── auth/
│   │   └── providers/
│   │       └── auth_provider.dart  # Auth state management
│   ├── activity/
│   │   └── providers/
│   │       └── activities_provider.dart  # Activity feed state
│   ├── library/
│   │   └── providers/
│   │       └── library_provider.dart     # Library state
│   └── profile/
│       └── providers/
│           └── theme_provider.dart       # Theme state
├── lib/
│   └── main.dart                   # App entry point
├── pubspec.yaml                    # Dependencies
├── TESTING_GUIDE.md               # Testing documentation
├── QUICKSTART.md                  # Quick start guide
└── README.md                      # This file
```

## 🚀 Quick Start

### 1. Install Flutter

Make sure you have Flutter 3.16.0 or later installed:

```bash
flutter --version
```

If not installed, follow the [official Flutter installation guide](https://docs.flutter.dev/get-started/install).

### 2. Create New Project

```bash
flutter create gread
cd gread
```

### 3. Copy Code Samples

Copy the code samples into your project:

```bash
# From the GRead-Mobile repository root
cp -r flutter_code_samples/core lib/
cp -r flutter_code_samples/features lib/
cp -r flutter_code_samples/shared lib/
cp flutter_code_samples/lib/main.dart lib/
cp flutter_code_samples/pubspec.yaml .
```

### 4. Install Dependencies

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Run the App

```bash
flutter run
```

📖 For detailed setup instructions, see [QUICKSTART.md](QUICKSTART.md)

## 📚 What's Included

### ✅ Complete API Client

- **Dio-based HTTP client** with automatic JWT token injection
- **Centralized endpoint management** matching WordPress/BuddyPress API
- **Comprehensive error handling** with user-friendly messages
- **Request/response logging** for debugging

### ✅ Authentication System

- **JWT token authentication** with secure storage
- **Guest mode** support
- **Session management** matching iOS implementation
- **User registration** with BuddyPress integration

### ✅ State Management

- **Riverpod providers** for reactive state management
- **Auth state** with automatic persistence
- **Activity feed** with infinite scroll
- **Library management** with optimistic updates
- **Theme system** with dynamic theme switching

### ✅ Data Models

All models implemented with **Freezed** for immutability:

- User and UserStats
- Activity and ActivityComment
- Achievement with progress tracking
- Book and LibraryItem
- Theme, Font, and Icon cosmetics
- Unlock requirements

### ✅ Testing Infrastructure

- **Unit test examples** for services and providers
- **Widget test examples** for UI components
- **Integration test examples** for user flows
- **Mock generation** with Mockito
- **Coverage reporting** setup

## 🎯 Features Implemented

### Core Features

- [x] JWT Authentication
- [x] Guest Mode
- [x] API Client with token injection
- [x] Secure token storage
- [x] User session management

### State Management

- [x] Auth state provider
- [x] Activities provider with pagination
- [x] Library provider with CRUD operations
- [x] Theme provider with persistence

### API Integration

- [x] All major endpoints defined
- [x] Error handling
- [x] Request/response logging
- [x] Automatic token refresh (ready)

## 📖 Architecture

### Clean Architecture + MVVM

```
Presentation Layer (Widgets)
    ↓
Providers (State Management)
    ↓
Services (Business Logic)
    ↓
API Client (Data Access)
    ↓
Backend API (WordPress/BuddyPress)
```

### Key Patterns

- **Provider Pattern** - Dependency injection with Riverpod
- **Repository Pattern** - Data access abstraction (ready for implementation)
- **Singleton Pattern** - API client and services
- **Observer Pattern** - State notifications with StateNotifier

## 🔧 Technology Stack

| Category | iOS | Flutter |
|----------|-----|---------|
| Language | Swift | Dart |
| UI Framework | SwiftUI | Flutter Widgets |
| State Management | ObservableObject | Riverpod |
| Networking | URLSession | Dio |
| Data Models | Codable | Freezed + json_serializable |
| Storage | UserDefaults + Keychain | SharedPreferences + FlutterSecureStorage |
| Navigation | NavigationView | Navigator 2.0 / go_router |

## 📝 Implementation Roadmap

### Phase 1: Foundation ✅
- [x] Project setup
- [x] API client
- [x] Data models
- [x] Authentication service
- [x] State management structure

### Phase 2: Core Features (Your Next Steps)
- [ ] Implement all screens (Activity, Library, Profile, etc.)
- [ ] Add navigation with go_router
- [ ] Implement activity posting
- [ ] Add book library features
- [ ] Build user profiles

### Phase 3: Social Features
- [ ] Friend system
- [ ] Mentions
- [ ] Notifications
- [ ] User search
- [ ] Moderation (block/mute/report)

### Phase 4: Advanced Features
- [ ] Achievement system
- [ ] Theme/cosmetics customization
- [ ] Leaderboards
- [ ] Analytics

### Phase 5: Polish
- [ ] Animations
- [ ] Loading states
- [ ] Error handling
- [ ] Accessibility
- [ ] Performance optimization

## 🧪 Testing

### Run Tests

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Integration tests
flutter test integration_test/
```

### Coverage Goals

- Overall: >80%
- Services: >90%
- Providers: >85%
- Widgets: >70%

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for comprehensive testing documentation.

## 📚 Additional Documentation

### Main Guide

- [**FLUTTER_IMPLEMENTATION_GUIDE.md**](../FLUTTER_IMPLEMENTATION_GUIDE.md)
  - Comprehensive feature implementation guide
  - iOS to Flutter architecture mapping
  - Code samples for all major features
  - Best practices and common pitfalls

### Testing

- [**TESTING_GUIDE.md**](TESTING_GUIDE.md)
  - Unit, widget, and integration testing
  - Mocking strategies
  - Coverage reporting
  - CI/CD setup

### Quick Reference

- [**QUICKSTART.md**](QUICKSTART.md)
  - Get started in 15 minutes
  - Step-by-step setup
  - Common issues and solutions
  - Development commands

## 🔗 iOS Reference

All Flutter implementations are designed to match the iOS app functionality:

- **iOS App Location**: `/GRead/` directory
- **API Backend**: Same WordPress/BuddyPress backend
- **Feature Parity**: 1:1 mapping with iOS features
- **Data Models**: Identical to iOS structs

## 💡 Usage Tips

### 1. Start with Authentication

The auth system is the foundation. Make sure it works before building other features:

```dart
// In your widget
final authState = ref.watch(authProvider);
```

### 2. Use Providers for All State

Don't use StatefulWidget unless necessary. Prefer Riverpod:

```dart
final activitiesProvider = StateNotifierProvider<ActivitiesNotifier, ActivitiesState>((ref) {
  return ActivitiesNotifier(ref.watch(apiClientProvider));
});
```

### 3. Always Handle Errors

Use AsyncValue for automatic error handling:

```dart
authState.when(
  data: (data) => SuccessWidget(data),
  loading: () => LoadingWidget(),
  error: (e, stack) => ErrorWidget(e),
);
```

### 4. Generate Code After Model Changes

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Test Early and Often

Write tests as you implement features, not after!

## 🐛 Common Issues

### Build Runner Issues

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Android Build Issues

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter build apk
```

### Dependency Conflicts

```bash
flutter pub upgrade
flutter pub outdated
```

## 🤝 Contributing

This is a reference implementation. Feel free to:

- Adapt code to your specific needs
- Add missing features
- Improve error handling
- Enhance UI/UX
- Add more tests

## 📞 Getting Help

1. Check the iOS implementation for reference
2. Review [Flutter Documentation](https://docs.flutter.dev/)
3. See [Riverpod Documentation](https://riverpod.dev/)
4. Check API endpoint responses
5. Run `flutter doctor -v` for environment issues

## 📄 License

This code is provided as a reference implementation for the GRead project.

---

## 📋 Checklist for New Developers

Before you start:

- [ ] Read [FLUTTER_IMPLEMENTATION_GUIDE.md](../FLUTTER_IMPLEMENTATION_GUIDE.md)
- [ ] Review iOS app functionality
- [ ] Understand the API backend structure
- [ ] Set up Flutter development environment
- [ ] Read [QUICKSTART.md](QUICKSTART.md)

First steps:

- [ ] Create new Flutter project
- [ ] Copy code samples
- [ ] Install dependencies
- [ ] Generate models
- [ ] Run the app
- [ ] Verify authentication works

---

**Ready to build GRead for Android? Start with [QUICKSTART.md](QUICKSTART.md)!** 🚀
