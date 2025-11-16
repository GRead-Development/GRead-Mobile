# GRead Flutter - Quick Start Guide

Get your GRead Android app up and running in 15 minutes!

---

## Prerequisites

- Flutter SDK 3.16.0 or later
- Android Studio or VS Code with Flutter extensions
- Android device or emulator (API 24+)
- Basic knowledge of Flutter and Dart

---

## Step 1: Project Setup

### Create New Flutter Project

```bash
# Navigate to your workspace
cd ~/workspace

# Create new Flutter project
flutter create gread

cd gread
```

### Copy Code Samples

Copy the code samples from this repository into your project:

```bash
# Copy core files
cp -r flutter_code_samples/core lib/

# Copy features
cp -r flutter_code_samples/features lib/

# Copy shared widgets
cp -r flutter_code_samples/shared lib/

# Copy main.dart
cp flutter_code_samples/lib/main.dart lib/

# Copy pubspec.yaml (backup your original first!)
cp pubspec.yaml pubspec.yaml.backup
cp flutter_code_samples/pubspec.yaml .
```

---

## Step 2: Install Dependencies

```bash
# Get dependencies
flutter pub get

# Generate code for models and mocks
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `*.freezed.dart` files for immutable models
- `*.g.dart` files for JSON serialization
- Mock files for testing

---

## Step 3: Project Structure

Your project should now look like this:

```
lib/
├── main.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   ├── api_endpoints.dart
│   │   └── api_error.dart
│   ├── models/
│   │   ├── user.dart
│   │   ├── activity.dart
│   │   ├── achievement.dart
│   │   ├── book.dart
│   │   └── cosmetics.dart
│   └── services/
│       └── auth_service.dart
├── features/
│   ├── auth/
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── screens/
│   │       ├── landing_screen.dart
│   │       ├── login_screen.dart
│   │       └── register_screen.dart
│   ├── activity/
│   │   ├── providers/
│   │   │   └── activities_provider.dart
│   │   └── screens/
│   │       └── activity_feed_screen.dart
│   ├── library/
│   │   └── providers/
│   │       └── library_provider.dart
│   └── profile/
│       └── providers/
│           └── theme_provider.dart
└── shared/
    └── widgets/
        └── main_tab_view.dart
```

---

## Step 4: Implement Missing Screens

You'll need to create these screens based on the iOS app:

### 1. Landing Screen

**lib/features/auth/screens/landing_screen.dart**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              const FlutterLogo(size: 120),
              const SizedBox(height: 24),

              // App name
              const Text(
                'GRead',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Social Reading Platform',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Sign In button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 16),

              // Register button
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 16),

              // Guest mode button
              TextButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).enableGuestMode();
                },
                child: const Text('Continue as Guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 2. Login Screen

**lib/features/auth/screens/login_screen.dart**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).login(
        _usernameController.text,
        _passwordController.text,
      );

      if (mounted) {
        // Navigate back to root (which will show MainTabView)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Username field
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),

                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Step 5: Run the App

### Start Android Emulator

```bash
# List available devices
flutter devices

# If no device is running, start an emulator
flutter emulators
flutter emulators --launch <emulator_id>
```

### Run the App

```bash
# Run in debug mode
flutter run

# Or run in release mode
flutter run --release
```

---

## Step 6: Verify Everything Works

### Test Checklist

- [ ] App launches without errors
- [ ] Landing screen displays
- [ ] Can navigate to login screen
- [ ] Can enable guest mode
- [ ] API client is configured correctly
- [ ] Models generate without errors

---

## Common Issues & Solutions

### Issue: Build runner fails

```bash
# Clean and regenerate
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Missing dependencies

```bash
# Update dependencies
flutter pub upgrade

# Check for conflicts
flutter pub outdated
```

### Issue: Android build fails

```bash
# Clean Android build
cd android
./gradlew clean
cd ..
flutter clean
flutter build apk
```

---

## Next Steps

1. **Implement Remaining Screens**
   - Activity Feed
   - Library
   - Profile
   - Notifications
   - Achievements

2. **Add Navigation**
   - Set up go_router for declarative routing
   - Implement deep linking

3. **Implement Features**
   - Activity posting
   - Book management
   - Friend system
   - Achievements

4. **Add Tests**
   - Unit tests for services
   - Widget tests for screens
   - Integration tests for flows

5. **Polish UI**
   - Add animations
   - Implement proper error handling
   - Add loading states
   - Improve accessibility

---

## Development Commands

```bash
# Hot reload (while running)
r

# Hot restart
R

# Open DevTools
d

# Run tests
flutter test

# Generate coverage
flutter test --coverage

# Build APK
flutter build apk

# Build App Bundle (for Play Store)
flutter build appbundle
```

---

## Helpful Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Material Design 3](https://m3.material.io/)
- [GRead Implementation Guide](FLUTTER_IMPLEMENTATION_GUIDE.md)
- [Testing Guide](TESTING_GUIDE.md)

---

## Getting Help

If you encounter issues:

1. Check the [Flutter FAQ](https://docs.flutter.dev/resources/faq)
2. Review the iOS implementation for reference
3. Check API endpoint documentation
4. Run `flutter doctor` to verify setup

---

**You're now ready to build GRead for Android! 🚀**
