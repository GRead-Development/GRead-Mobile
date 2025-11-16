# iOS to Flutter Feature Mapping

This document provides a side-by-side comparison of iOS and Flutter implementations for the GRead app, helping developers translate iOS concepts to Flutter equivalents.

---

## Architecture Patterns

| Concept | iOS (SwiftUI) | Flutter |
|---------|--------------|---------|
| View | `View` protocol | `Widget` class |
| State | `@State`, `@Published` | `State`, `StateNotifier` |
| Dependency Injection | `@EnvironmentObject` | `Provider`, `Riverpod` |
| Navigation | `NavigationView`, `NavigationLink` | `Navigator`, `go_router` |
| List | `List`, `ForEach` | `ListView`, `ListView.builder` |
| Async Operations | `async/await`, `Task` | `Future`, `async/await` |
| Reactive Updates | `ObservableObject` | `ChangeNotifier`, `StateNotifier` |

---

## State Management

### iOS: ObservableObject Pattern

```swift
// iOS
class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?

    func login(username: String, password: String) async throws {
        // Login logic
        self.isAuthenticated = true
    }
}

// Usage
struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        if authManager.isAuthenticated {
            MainView()
        } else {
            LoginView()
        }
    }
}
```

### Flutter: Riverpod StateNotifier

```dart
// Flutter
class AuthNotifier extends StateNotifier<AsyncValue<AuthStateData>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading());

  Future<void> login(String username, String password) async {
    final user = await _authService.login(username, password);
    state = AsyncValue.data(AuthStateData(
      isAuthenticated: true,
      user: user,
    ));
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthStateData>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

// Usage
class ContentView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (data) => data.isAuthenticated ? MainView() : LoginView(),
      loading: () => LoadingView(),
      error: (e, _) => ErrorView(),
    );
  }
}
```

---

## Data Models

### iOS: Codable Structs

```swift
// iOS
struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let userLogin: String?
    let avatarUrls: AvatarUrls?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case userLogin = "user_login"
        case avatarUrls = "avatar_urls"
    }
}
```

### Flutter: Freezed Classes

```dart
// Flutter
@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    @JsonKey(name: 'user_login') String? userLogin,
    @JsonKey(name: 'avatar_urls') AvatarUrls? avatarUrls,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

---

## API Networking

### iOS: URLSession + Codable

```swift
// iOS
class APIManager {
    func request<T: Decodable>(
        _ endpoint: String,
        method: String = "GET"
    ) async throws -> T {
        var request = URLRequest(url: URL(string: baseURL + endpoint)!)
        request.httpMethod = method

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(T.self, from: data)
    }
}
```

### Flutter: Dio + json_serializable

```dart
// Flutter
class ApiClient {
  final Dio _dio;

  Future<T> get<T>(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}

// With automatic JSON parsing
Future<User> getCurrentUser() async {
  final response = await apiClient.get('/buddypress/v1/members/me');
  return User.fromJson(response);
}
```

---

## Storage

### iOS: UserDefaults & Keychain

```swift
// iOS - Simple storage
UserDefaults.standard.set(value, forKey: "theme_id")
let themeId = UserDefaults.standard.string(forKey: "theme_id")

// iOS - Secure storage (Keychain)
let token = KeychainHelper.load(key: "jwt_token")
KeychainHelper.save(key: "jwt_token", data: token)
```

### Flutter: SharedPreferences & FlutterSecureStorage

```dart
// Flutter - Simple storage
final prefs = await SharedPreferences.getInstance();
await prefs.setString('theme_id', value);
final themeId = prefs.getString('theme_id');

// Flutter - Secure storage
final storage = FlutterSecureStorage();
await storage.write(key: 'jwt_token', value: token);
final token = await storage.read(key: 'jwt_token');
```

---

## UI Components

### List with Items

**iOS:**
```swift
List {
    ForEach(activities) { activity in
        ActivityCard(activity: activity)
    }
}
.refreshable {
    await loadActivities()
}
```

**Flutter:**
```dart
RefreshIndicator(
  onRefresh: loadActivities,
  child: ListView.builder(
    itemCount: activities.length,
    itemBuilder: (context, index) {
      return ActivityCard(activity: activities[index]);
    },
  ),
)
```

### Navigation

**iOS:**
```swift
NavigationLink(destination: DetailView(user: user)) {
    Text(user.name)
}
```

**Flutter:**
```dart
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailView(user: user),
      ),
    );
  },
  child: Text(user.name),
)
```

### Async Image Loading

**iOS:**
```swift
AsyncImage(url: URL(string: avatarUrl)) { image in
    image.resizable().scaledToFit()
} placeholder: {
    ProgressView()
}
.frame(width: 50, height: 50)
.clipShape(Circle())
```

**Flutter:**
```dart
CachedNetworkImage(
  imageUrl: avatarUrl,
  imageBuilder: (context, imageProvider) => CircleAvatar(
    backgroundImage: imageProvider,
    radius: 25,
  ),
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### Modal Sheets

**iOS:**
```swift
.sheet(isPresented: $showingSheet) {
    PostActivitySheet()
}
```

**Flutter:**
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => PostActivitySheet(),
)
```

---

## Common UI Patterns

### Loading States

**iOS:**
```swift
if isLoading {
    ProgressView()
} else {
    ContentView()
}
```

**Flutter:**
```dart
isLoading
  ? CircularProgressIndicator()
  : ContentView()
```

### Error Handling

**iOS:**
```swift
.alert("Error", isPresented: $showError) {
    Button("OK") { }
} message: {
    Text(errorMessage)
}
```

**Flutter:**
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Error'),
    content: Text(errorMessage),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('OK'),
      ),
    ],
  ),
)
```

### Tab Bar Navigation

**iOS:**
```swift
TabView {
    ActivityFeedView()
        .tabItem {
            Label("Feed", systemImage: "house")
        }

    LibraryView()
        .tabItem {
            Label("Library", systemImage: "book")
        }
}
```

**Flutter:**
```dart
Scaffold(
  body: IndexedStack(
    index: currentIndex,
    children: [
      ActivityFeedScreen(),
      LibraryScreen(),
    ],
  ),
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: currentIndex,
    onTap: (index) => setState(() => currentIndex = index),
    items: [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Feed',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.library_books),
        label: 'Library',
      ),
    ],
  ),
)
```

---

## Feature Mapping

### Activity Feed

| Feature | iOS Implementation | Flutter Implementation |
|---------|-------------------|----------------------|
| Load activities | `Task { await loadActivities() }` | `Future<void> loadActivities()` |
| Pagination | Manual page tracking | StateNotifier with page state |
| Pull to refresh | `.refreshable` modifier | `RefreshIndicator` widget |
| Infinite scroll | `onAppear` detection | ScrollController listener |
| Post activity | Sheet with TextField | BottomSheet with TextField |

### Authentication

| Feature | iOS Implementation | Flutter Implementation |
|---------|-------------------|----------------------|
| JWT storage | Keychain | FlutterSecureStorage |
| Auth state | `@Published var isAuthenticated` | StateNotifier provider |
| Token injection | URLRequest interceptor | Dio interceptor |
| Session check | Init with keychain read | FutureProvider initialization |
| Logout | Clear keychain + reset state | Clear storage + reset provider |

### Theming

| Feature | iOS Implementation | Flutter Implementation |
|---------|-------------------|----------------------|
| Theme colors | Custom Color extension | ThemeData with ColorScheme |
| Dark mode | `.preferredColorScheme` | Brightness in ThemeData |
| Dynamic themes | `@EnvironmentObject ThemeManager` | StateNotifierProvider |
| Persistence | UserDefaults | SharedPreferences |
| Apply theme | Environment injection | MaterialApp theme property |

---

## Testing Comparison

### Unit Tests

**iOS:**
```swift
import XCTest
@testable import GRead

class AuthManagerTests: XCTestCase {
    var authManager: AuthManager!

    override func setUp() {
        authManager = AuthManager()
    }

    func testLogin() async throws {
        try await authManager.login(username: "test", password: "pass")
        XCTAssertTrue(authManager.isAuthenticated)
    }
}
```

**Flutter:**
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuthService authService;

  setUp(() {
    authService = AuthService(mockApiClient, mockStorage);
  });

  test('should authenticate user on successful login', () async {
    final user = await authService.login('test', 'pass');
    expect(user, isNotNull);
  });
}
```

### Widget/View Tests

**iOS:**
```swift
import ViewInspector
import XCTest

class ActivityCardTests: XCTestCase {
    func testActivityCardDisplaysContent() throws {
        let activity = Activity(id: 1, content: "Test")
        let view = ActivityCard(activity: activity)

        let text = try view.inspect().find(text: "Test")
        XCTAssertNotNil(text)
    }
}
```

**Flutter:**
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ActivityCard displays content', (tester) async {
    const activity = Activity(id: 1, content: 'Test');

    await tester.pumpWidget(
      MaterialApp(home: ActivityCard(activity: activity)),
    );

    expect(find.text('Test'), findsOneWidget);
  });
}
```

---

## Lifecycle Methods

| iOS SwiftUI | Flutter StatefulWidget |
|-------------|----------------------|
| `onAppear` | `initState()` |
| `onDisappear` | `dispose()` |
| - | `didUpdateWidget()` |
| - | `didChangeDependencies()` |
| `onChange` | `didUpdateWidget()` with comparison |

---

## Performance Optimization

### iOS Optimizations

```swift
// Lazy loading
LazyVStack {
    ForEach(items) { item in
        ItemView(item: item)
    }
}

// Equatable for efficient updates
struct User: Equatable {
    let id: Int
    let name: String
}
```

### Flutter Optimizations

```dart
// Use ListView.builder for large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemView(item: items[index]),
)

// Use const constructors
const Text('Static content')

// Implement == and hashCode for efficient rebuilds
@override
bool operator ==(Object other) =>
  identical(this, other) ||
  other is User && id == other.id && name == other.name;
```

---

## Key Differences to Remember

### 1. Everything is a Widget
- iOS: Mix of Views, Modifiers, and Controls
- Flutter: Everything (including padding, alignment) is a Widget

### 2. State Management
- iOS: Built-in with `@State`, `@Published`
- Flutter: Requires external solution (Provider, Riverpod, Bloc)

### 3. Navigation
- iOS: Declarative with NavigationView
- Flutter: Imperative Navigator or declarative go_router

### 4. Asynchronous Operations
- iOS: Built-in async/await, Task
- Flutter: Future/Stream + async/await

### 5. Platform Conventions
- iOS: iOS design patterns (tab bar, navigation bar)
- Flutter: Material Design by default (can use Cupertino)

---

## Migration Checklist

When converting an iOS feature to Flutter:

- [ ] Identify the core functionality
- [ ] Map iOS state management to Riverpod
- [ ] Convert Codable models to Freezed
- [ ] Translate SwiftUI Views to Widgets
- [ ] Replace URLSession with Dio
- [ ] Update UserDefaults to SharedPreferences
- [ ] Convert Keychain to FlutterSecureStorage
- [ ] Adapt navigation pattern
- [ ] Port unit tests
- [ ] Port UI tests to widget tests
- [ ] Test on Android devices

---

## Resources

- [SwiftUI to Flutter Migration Guide](https://docs.flutter.dev/get-started/flutter-for/swiftui-devs)
- [iOS Developers - Flutter Basics](https://docs.flutter.dev/get-started/flutter-for/ios-devs)
- [Riverpod vs Combine](https://riverpod.dev/)
- [Freezed Documentation](https://pub.dev/packages/freezed)

---

**This mapping guide should help you translate any iOS feature to Flutter efficiently!**
