---
name: apple-platform-patterns
description: Comprehensive iOS/tvOS/macOS development patterns covering architecture, networking, persistence, memory management, app lifecycle, and multi-platform adaptation.
origin: ECC
---

# Apple Platform Patterns

Comprehensive patterns for building robust, performant applications across iOS, tvOS, and macOS using modern Swift and SwiftUI.

## When to Activate

- Designing app architecture for Apple platforms
- Building networking layers with async/await
- Implementing data persistence (SwiftData, Keychain, FileManager)
- Managing memory and avoiding retain cycles
- Handling app lifecycle events, background tasks, push notifications
- Writing cross-platform code for iOS, tvOS, and macOS

## Architecture

### MVVM with @Observable

The standard architecture for SwiftUI apps: Views observe ViewModels, ViewModels coordinate with Services.

```swift
// ── Model ──
struct User: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var email: String
    var avatarURL: URL?
}

// ── ViewModel ──
@Observable
final class UserListViewModel {
    private(set) var users: [User] = []
    private(set) var isLoading = false
    private(set) var error: UserError?
    var searchText = ""

    var filteredUsers: [User] {
        guard !searchText.isEmpty else { return users }
        return users.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private let service: any UserService

    init(service: any UserService = DefaultUserService()) {
        self.service = service
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            users = try await service.fetchUsers()
        } catch {
            self.error = .fetchFailed(error)
        }
        isLoading = false
    }

    func delete(_ user: User) async {
        do {
            try await service.delete(user.id)
            users.removeAll { $0.id == user.id }
        } catch {
            self.error = .deleteFailed(error)
        }
    }
}

// ── View ──
struct UserListView: View {
    @State private var viewModel = UserListViewModel()

    var body: some View {
        List(viewModel.filteredUsers) { user in
            UserRow(user: user)
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task { await viewModel.delete(user) }
                    }
                }
        }
        .searchable(text: $viewModel.searchText)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.filteredUsers.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
        .task { await viewModel.load() }
    }
}
```

### Coordinator Pattern

For complex navigation flows that span multiple screens:

```swift
@Observable
final class AppCoordinator {
    var path = NavigationPath()
    var sheet: Sheet?
    var fullScreenCover: FullScreenCover?

    enum Route: Hashable {
        case userDetail(User.ID)
        case settings
        case editProfile
    }

    enum Sheet: Identifiable {
        case newUser
        case shareUser(User)
        var id: String { String(describing: self) }
    }

    enum FullScreenCover: Identifiable {
        case onboarding
        case login
        var id: String { String(describing: self) }
    }

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func present(_ sheet: Sheet) {
        self.sheet = sheet
    }

    func presentFullScreen(_ cover: FullScreenCover) {
        self.fullScreenCover = cover
    }
}
```

### Feature Modules

Organize code by feature, not by type:

```
App/
├── Features/
│   ├── Authentication/
│   │   ├── LoginView.swift
│   │   ├── LoginViewModel.swift
│   │   ├── AuthService.swift
│   │   └── AuthModels.swift
│   ├── UserProfile/
│   │   ├── ProfileView.swift
│   │   ├── ProfileViewModel.swift
│   │   └── ProfileService.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── SettingsViewModel.swift
├── Shared/
│   ├── Networking/
│   ├── Persistence/
│   └── Extensions/
└── App.swift
```

## Networking

### Async/Await URLSession

```swift
protocol APIClient: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

actor DefaultAPIClient: APIClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let baseURL: URL

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let urlRequest = try endpoint.urlRequest(baseURL: baseURL)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        return try decoder.decode(T.self, from: data)
    }
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let body: Data?
    let headers: [String: String]

    func urlRequest(baseURL: URL) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: true)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }
}
```

### Retry with Exponential Backoff

```swift
func requestWithRetry<T: Decodable>(
    _ endpoint: Endpoint,
    maxRetries: Int = 3,
    initialDelay: Duration = .seconds(1)
) async throws -> T {
    var lastError: Error?
    for attempt in 0..<maxRetries {
        do {
            return try await request(endpoint)
        } catch let error as APIError where error.isRetryable {
            lastError = error
            let delay = initialDelay * pow(2, Double(attempt))
            try await Task.sleep(for: delay)
        }
    }
    throw lastError ?? APIError.unknown
}
```

### Certificate Pinning

```swift
final class PinningDelegate: NSObject, URLSessionDelegate, Sendable {
    private let pinnedHashes: Set<String>

    init(pinnedHashes: Set<String>) {
        self.pinnedHashes = pinnedHashes
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard let trust = challenge.protectionSpace.serverTrust,
              let certificate = SecTrustCopyCertificateChain(trust)?.first else {
            return (.cancelAuthenticationChallenge, nil)
        }

        let publicKey = SecCertificateCopyKey(certificate)
        let publicKeyData = SecKeyCopyExternalRepresentation(publicKey!, nil)! as Data
        let hash = SHA256.hash(data: publicKeyData).compactMap { String(format: "%02x", $0) }.joined()

        if pinnedHashes.contains(hash) {
            return (.useCredential, URLCredential(trust: trust))
        }
        return (.cancelAuthenticationChallenge, nil)
    }
}
```

## Persistence

### SwiftData

```swift
@Model
final class Item {
    var title: String
    var timestamp: Date
    var isCompleted: Bool

    @Relationship(deleteRule: .cascade)
    var tags: [Tag]

    init(title: String, timestamp: Date = .now, isCompleted: Bool = false) {
        self.title = title
        self.timestamp = timestamp
        self.isCompleted = isCompleted
        self.tags = []
    }
}

@Model
final class Tag {
    var name: String

    @Relationship(inverse: \Item.tags)
    var items: [Item]

    init(name: String) {
        self.name = name
        self.items = []
    }
}

// Usage in App
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Item.self, Tag.self])
    }
}

// Usage in View
struct ItemListView: View {
    @Query(sort: \Item.timestamp, order: .reverse)
    private var items: [Item]

    @Environment(\.modelContext) private var context

    var body: some View {
        List(items) { item in
            Text(item.title)
        }
    }

    func addItem(title: String) {
        let item = Item(title: title)
        context.insert(item)
    }
}
```

### Keychain Services (Sensitive Data Only)

```swift
enum KeychainHelper {
    static func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    static func load(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound { return nil }
            throw KeychainError.loadFailed(status)
        }
        return result as? Data
    }

    static func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
```

### FileManager

```swift
enum FileStore {
    private static let documentsDirectory = FileManager.default.urls(
        for: .documentDirectory, in: .userDomainMask
    ).first!

    static func save<T: Encodable>(_ value: T, filename: String) throws {
        let url = documentsDirectory.appending(path: filename)
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    static func load<T: Decodable>(_ type: T.Type, filename: String) throws -> T? {
        let url = documentsDirectory.appending(path: filename)
        guard FileManager.default.fileExists(atPath: url.path()) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

## Memory Management

### ARC Rules

```swift
// ✅ Weak reference for delegates
protocol UserServiceDelegate: AnyObject {
    func didFetchUser(_ user: User)
}

class UserService {
    weak var delegate: UserServiceDelegate?
}

// ✅ Weak self in escaping closures
class ViewModel {
    func load() {
        networkService.fetch { [weak self] result in
            guard let self else { return }
            self.handleResult(result)
        }
    }
}

// ✅ Unowned when lifetime is guaranteed
class Parent {
    let child: Child

    init() {
        child = Child(parent: self)
    }
}

class Child {
    unowned let parent: Parent
    init(parent: Parent) { self.parent = parent }
}

// ❌ Anti-pattern: strong reference cycle
class BadViewModel {
    var onComplete: (() -> Void)?

    func setup() {
        onComplete = {
            self.doSomething() // Strong capture — retain cycle!
        }
    }
}
```

### Combine Pipeline Safety

```swift
class ViewModel {
    private var cancellables = Set<AnyCancellable>()

    func subscribe() {
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in  // ✅ weak self
                self?.update(value)
            }
            .store(in: &cancellables)
    }
}
```

### Detecting Leaks with Instruments

1. Product > Profile > Leaks
2. Run the app and exercise suspect flows
3. Look for purple leak indicators
4. Inspect the backtrace to find the retain cycle

## App Lifecycle

### Scene-Based Lifecycle

```swift
@main
struct MyApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // App is in foreground and interactive
                break
            case .inactive:
                // App is visible but not interactive (e.g., incoming call)
                break
            case .background:
                // App is in background — save state, stop timers
                break
            @unknown default:
                break
            }
        }
    }
}
```

### Background Tasks (BGTaskScheduler)

```swift
import BackgroundTasks

// Register in App init
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.app.refresh",
    using: nil
) { task in
    handleAppRefresh(task: task as! BGAppRefreshTask)
}

func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.app.refresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    try? BGTaskScheduler.shared.submit(request)
}

func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleAppRefresh() // Reschedule

    let refreshTask = Task {
        do {
            try await dataStore.refresh()
            task.setTaskCompleted(success: true)
        } catch {
            task.setTaskCompleted(success: false)
        }
    }

    task.expirationHandler = {
        refreshTask.cancel()
    }
}
```

### Push Notifications (APNs)

```swift
import UserNotifications

func requestNotificationPermission() async throws -> Bool {
    let center = UNUserNotificationCenter.current()
    let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
    if granted {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    return granted
}

// In AppDelegate or via notification delegate
func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    // Send token to your server
}
```

### Deep Links and Universal Links

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        switch components.host {
        case "user":
            if let id = components.queryItems?.first(where: { $0.name == "id" })?.value {
                coordinator.push(.userDetail(id))
            }
        case "settings":
            coordinator.push(.settings)
        default:
            break
        }
    }
}
```

## Platform Adaptation

### Conditional Compilation

```swift
#if os(iOS)
import UIKit
typealias PlatformColor = UIColor
#elseif os(macOS)
import AppKit
typealias PlatformColor = NSColor
#elseif os(tvOS)
import UIKit
typealias PlatformColor = UIColor
#endif

struct AdaptiveView: View {
    var body: some View {
        #if os(iOS)
        iOSLayout()
        #elseif os(tvOS)
        tvOSLayout()
        #elseif os(macOS)
        macOSLayout()
        #endif
    }
}
```

### Multi-Platform SwiftUI

```swift
// Shared view with platform-specific modifiers
struct ContentCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline)
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding()
        .platformCardStyle()
    }
}

extension View {
    func platformCardStyle() -> some View {
        #if os(tvOS)
        self
            .focusable()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        #elseif os(macOS)
        self
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 2)
        #else
        self
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
        #endif
    }
}
```

### Platform-Specific ViewModifier

```swift
struct PlatformNavigationModifier: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Preferences") { }
                }
            }
        #elseif os(tvOS)
        content
            .navigationTitle(title)
        #else
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
        #endif
    }
}
```

## Anti-Patterns

### God Controllers

```swift
// ❌ Massive view controller / view model doing everything
class GodViewModel {
    // 1000+ lines, 20+ properties, networking + caching + validation + formatting
}

// ✅ Split into focused services
@Observable
final class UserListViewModel {
    private let userService: any UserService
    private let formatter: UserFormatter
    // Focused on list presentation only
}
```

### Synchronous Networking on Main Thread

```swift
// ❌ Blocks UI
let data = try Data(contentsOf: remoteURL)

// ✅ Async
let (data, _) = try await URLSession.shared.data(from: remoteURL)
```

### Force Unwraps on External Data

```swift
// ❌ Crash on unexpected API response
let name = json["user"]["name"].string!

// ✅ Safe unwrapping
guard let name = json["user"]["name"].string else {
    throw ParseError.missingField("name")
}
```

### Massive AppDelegate

```swift
// ❌ Everything in AppDelegate
class AppDelegate: UIResponder, UIApplicationDelegate {
    // Push notifications, deep links, analytics, crash reporting,
    // database setup, theme configuration, feature flags...
}

// ✅ Compose with dedicated handlers
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let services: [AppService] = [
        PushNotificationService(),
        AnalyticsService(),
        CrashReportingService(),
    ]

    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions opts: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        services.forEach { $0.configure(app) }
        return true
    }
}
```

## Related

- Skill: `skills/swiftui-patterns/` — SwiftUI view patterns and state management
- Skill: `skills/swift-concurrency-6-2/` — Swift 6.2 concurrency model
- Skill: `skills/swift-protocol-di-testing/` — Protocol-based dependency injection
- Skill: `skills/tvos-patterns/` — tvOS-specific patterns
- Skill: `skills/macos-patterns/` — macOS-specific patterns
- Rule: `rules/swift/security.md` — Swift security guidelines
