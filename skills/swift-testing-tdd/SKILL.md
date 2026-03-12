---
name: swift-testing-tdd
description: Comprehensive Swift testing patterns using Swift Testing framework (@Test, #expect, #require, @Suite), TDD methodology, mocking, async testing, UI testing, and coverage.
origin: ECC
---

# Swift Testing & TDD

Comprehensive testing patterns for Swift using the Swift Testing framework and TDD methodology.

## When to Activate

- Writing new Swift functions, types, or features
- Adding test coverage to existing Swift code
- Following TDD workflow (RED-GREEN-REFACTOR)
- Writing async tests, mock objects, or UI tests
- Setting up CI/CD test pipelines for Swift projects

## Swift Testing Framework

### Basic Structure

```swift
import Testing

@Suite("Calculator Operations")
struct CalculatorTests {
    let calculator = Calculator()

    @Test("Addition returns correct sum")
    func addition() {
        #expect(calculator.add(2, 3) == 5)
    }

    @Test("Division by zero throws error")
    func divisionByZero() {
        #expect(throws: CalculatorError.divisionByZero) {
            try calculator.divide(10, by: 0)
        }
    }
}
```

### @Test — Declaring Tests

```swift
// Simple test
@Test("User name is formatted correctly")
func nameFormatting() {
    let user = User(firstName: "John", lastName: "Doe")
    #expect(user.displayName == "John Doe")
}

// Test with traits
@Test("Slow network test", .timeLimit(.minutes(1)))
func networkTest() async throws {
    let result = try await api.fetchData()
    #expect(!result.isEmpty)
}

// Disabled test with reason
@Test("Feature not yet implemented", .disabled("Waiting for backend API"))
func futureFeature() { }

// Conditional test
@Test("Only runs on iOS", .enabled(if: ProcessInfo.processInfo.environment["CI"] != nil))
func ciOnlyTest() { }
```

### #expect — Assertions

```swift
// Boolean expectation
#expect(user.isActive)
#expect(!list.isEmpty)

// Equality
#expect(result == expected)
#expect(result != forbidden)

// Comparison
#expect(count > 0)
#expect(latency < 100)

// Optional check
#expect(optionalValue != nil)

// Throws
#expect(throws: ValidationError.empty) {
    try validator.validate("")
}

// Throws any error
#expect(throws: (any Error).self) {
    try riskyOperation()
}

// No throw
#expect(throws: Never.self) {
    try safeOperation()
}
```

### #require — Unwrapping and Preconditions

Use `#require` when a test cannot meaningfully continue without a value:

```swift
@Test("User profile loads correctly")
func profileLoads() throws {
    let user = try #require(userStore.find(id: "123"))
    #expect(user.name == "Alice")
    #expect(user.isActive)

    let address = try #require(user.address)
    #expect(address.city == "San Francisco")
}

// Require condition
@Test("Database has data")
func databaseHasData() throws {
    try #require(database.count > 0, "Database must be seeded before testing")
    let first = try #require(database.first)
    #expect(first.isValid)
}
```

### @Suite — Test Organization

```swift
@Suite("User Authentication")
struct AuthenticationTests {
    let auth: AuthService

    // Suite-level setup via init
    init() {
        auth = AuthService(store: MockTokenStore())
    }

    @Suite("Login")
    struct LoginTests {
        let auth: AuthService

        init() {
            auth = AuthService(store: MockTokenStore())
        }

        @Test("Succeeds with valid credentials")
        func validLogin() async throws {
            let token = try await auth.login(email: "test@test.com", password: "pass123")
            #expect(!token.isEmpty)
        }

        @Test("Fails with wrong password")
        func wrongPassword() async {
            await #expect(throws: AuthError.invalidCredentials) {
                try await auth.login(email: "test@test.com", password: "wrong")
            }
        }
    }

    @Suite("Logout")
    struct LogoutTests {
        @Test("Clears stored token")
        func clearsToken() async throws {
            let store = MockTokenStore()
            store.token = "existing-token"
            let auth = AuthService(store: store)

            await auth.logout()
            #expect(store.token == nil)
        }
    }
}
```

### Parameterized Tests

```swift
// Arguments from inline collection
@Test("Email validation", arguments: [
    ("user@example.com", true),
    ("user@mail.co.uk", true),
    ("invalid", false),
    ("", false),
    ("@no-local.com", false),
])
func emailValidation(email: String, isValid: Bool) {
    #expect(EmailValidator.isValid(email) == isValid)
}

// Arguments from enum
enum Currency: String, CaseIterable {
    case usd, eur, gbp, jpy
}

@Test("Currency formatting", arguments: Currency.allCases)
func currencyFormatting(currency: Currency) {
    let formatted = CurrencyFormatter.format(100, currency: currency)
    #expect(!formatted.isEmpty)
}

// Two argument collections (cartesian product)
@Test("Matrix operations", arguments: [1, 2, 3], [10, 20, 30])
func matrixOps(row: Int, col: Int) {
    let result = Matrix.multiply(row, col)
    #expect(result == row * col)
}
```

### Tags for Test Filtering

```swift
extension Tag {
    @Tag static var networking: Self
    @Tag static var database: Self
    @Tag static var slow: Self
    @Tag static var smoke: Self
    @Tag static var ui: Self
}

@Test("API fetch", .tags(.networking))
func apiFetch() async throws { }

@Test("DB query", .tags(.database, .slow))
func dbQuery() async throws { }

@Test("Login flow", .tags(.smoke, .ui))
func loginFlow() async throws { }

// Run only networking tests:
// swift test --filter .tags:networking
```

## TDD Workflow

### The RED-GREEN-REFACTOR Cycle

```
RED     → Write a failing @Test with #expect
GREEN   → Write minimal code to make it pass
REFACTOR → Improve code while tests stay green
REPEAT  → Next requirement
```

### Step-by-Step TDD Example

```swift
// ── Step 1: Define the interface ──
// Sources/Cart/ShoppingCart.swift
struct ShoppingCart {
    func addItem(_ item: CartItem) -> ShoppingCart {
        fatalError("not implemented")
    }

    func total() -> Decimal {
        fatalError("not implemented")
    }

    var itemCount: Int {
        fatalError("not implemented")
    }
}

struct CartItem: Equatable {
    let name: String
    let price: Decimal
    let quantity: Int
}

// ── Step 2: Write failing tests (RED) ──
// Tests/CartTests/ShoppingCartTests.swift
import Testing
@testable import Cart

@Suite("Shopping Cart")
struct ShoppingCartTests {
    @Test("Starts empty")
    func startsEmpty() {
        let cart = ShoppingCart()
        #expect(cart.itemCount == 0)
        #expect(cart.total() == 0)
    }

    @Test("Adding item increases count")
    func addItemIncreasesCount() {
        let cart = ShoppingCart()
            .addItem(CartItem(name: "Widget", price: 9.99, quantity: 1))
        #expect(cart.itemCount == 1)
    }

    @Test("Total reflects added items")
    func totalReflectsItems() {
        let cart = ShoppingCart()
            .addItem(CartItem(name: "Widget", price: 9.99, quantity: 2))
            .addItem(CartItem(name: "Gadget", price: 14.99, quantity: 1))
        #expect(cart.total() == 34.97)
    }
}

// ── Step 3: Run tests — verify FAIL ──
// $ swift test --filter ShoppingCartTests
// ✘ 3 tests failed (fatalError)

// ── Step 4: Implement minimal code (GREEN) ──
struct ShoppingCart {
    private let items: [CartItem]

    init(items: [CartItem] = []) {
        self.items = items
    }

    func addItem(_ item: CartItem) -> ShoppingCart {
        ShoppingCart(items: items + [item])
    }

    func total() -> Decimal {
        items.reduce(0) { $0 + ($1.price * Decimal($1.quantity)) }
    }

    var itemCount: Int { items.count }
}

// ── Step 5: Run tests — verify PASS ──
// $ swift test --filter ShoppingCartTests
// ✔ 3 tests passed

// ── Step 6: Refactor if needed, re-run tests ──
```

## Mock Patterns

### Protocol-Based Mocks

```swift
// Protocol
protocol UserRepository: Sendable {
    func find(id: String) async throws -> User?
    func save(_ user: User) async throws
}

// Mock
final class MockUserRepository: UserRepository, @unchecked Sendable {
    var users: [String: User] = [:]
    var saveCallCount = 0
    var shouldThrow = false

    func find(id: String) async throws -> User? {
        if shouldThrow { throw TestError.forced }
        return users[id]
    }

    func save(_ user: User) async throws {
        if shouldThrow { throw TestError.forced }
        saveCallCount += 1
        users[user.id] = user
    }
}

// Usage in test
@Test("ViewModel loads user")
func viewModelLoadsUser() async {
    let repo = MockUserRepository()
    repo.users["1"] = User(id: "1", name: "Alice")

    let vm = UserViewModel(repository: repo)
    await vm.load(userId: "1")

    #expect(vm.user?.name == "Alice")
}
```

### Throwing Mocks

```swift
@Test("ViewModel shows error on failure")
func viewModelShowsError() async {
    let repo = MockUserRepository()
    repo.shouldThrow = true

    let vm = UserViewModel(repository: repo)
    await vm.load(userId: "1")

    #expect(vm.user == nil)
    #expect(vm.error != nil)
}
```

### Confirmation for Async Callbacks

```swift
@Test("Delegate is called on completion")
func delegateCalled() async {
    await confirmation("delegate notified") { confirm in
        let service = DataService()
        service.onComplete = { confirm() }
        await service.process()
    }
}

// Multiple confirmations
@Test("Progress updates fire three times")
func progressUpdates() async {
    await confirmation("progress", expectedCount: 3) { confirm in
        let loader = DataLoader()
        loader.onProgress = { _ in confirm() }
        await loader.loadAll()
    }
}
```

## Async Testing

### Testing Async Functions

```swift
@Test("Fetches data successfully")
func fetchData() async throws {
    let service = DataService(client: MockAPIClient())
    let items = try await service.fetchItems()
    #expect(items.count == 3)
}
```

### Testing Actors

```swift
@Test("Actor maintains consistency")
func actorConsistency() async {
    let counter = Counter()

    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<100 {
            group.addTask { await counter.increment() }
        }
    }

    let value = await counter.value
    #expect(value == 100)
}
```

### Testing Task Cancellation

```swift
@Test("Task cancellation stops work")
func taskCancellation() async throws {
    let service = LongRunningService()
    let task = Task {
        try await service.process()
    }

    try await Task.sleep(for: .milliseconds(50))
    task.cancel()

    do {
        _ = try await task.value
        Issue.record("Expected cancellation error")
    } catch is CancellationError {
        // Expected
    }
}
```

## UI Testing (XCUITest)

### Page Object Pattern

```swift
// Page object
struct LoginPage {
    let app: XCUIApplication

    var emailField: XCUIElement {
        app.textFields["login-email-field"]
    }

    var passwordField: XCUIElement {
        app.secureTextFields["login-password-field"]
    }

    var loginButton: XCUIElement {
        app.buttons["login-submit-button"]
    }

    var errorLabel: XCUIElement {
        app.staticTexts["login-error-label"]
    }

    func login(email: String, password: String) {
        emailField.tap()
        emailField.typeText(email)
        passwordField.tap()
        passwordField.typeText(password)
        loginButton.tap()
    }
}

// Test
final class LoginUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testSuccessfulLogin() {
        let loginPage = LoginPage(app: app)
        loginPage.login(email: "test@test.com", password: "password123")

        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 5))
    }
}
```

### Accessibility Identifiers

```swift
// In SwiftUI views — set identifiers for UI tests
TextField("Email", text: $email)
    .accessibilityIdentifier("login-email-field")

Button("Log In") { login() }
    .accessibilityIdentifier("login-submit-button")
```

## Snapshot Testing

```swift
// Using swift-snapshot-testing library
import SnapshotTesting

@Test("Profile view matches snapshot")
func profileSnapshot() {
    let view = ProfileView(user: .mock)
    assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
}

@Test("Dark mode snapshot")
func darkModeSnapshot() {
    let view = ProfileView(user: .mock)
        .environment(\.colorScheme, .dark)
    assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
}
```

## Performance Testing

```swift
// With Swift Testing — measure duration manually
@Test("Sorting performance", .timeLimit(.seconds(5)))
func sortingPerformance() {
    let largeArray = (0..<10_000).map { _ in Int.random(in: 0...1_000_000) }
    let start = ContinuousClock.now
    _ = largeArray.sorted()
    let elapsed = ContinuousClock.now - start
    #expect(elapsed < .seconds(1))
}

// With XCTest — built-in measure
func testSortingPerformance() {
    let array = (0..<10_000).map { _ in Int.random(in: 0...1_000_000) }
    measure {
        _ = array.sorted()
    }
}
```

## Coverage

### Generating Coverage Reports

```bash
# SPM: run with coverage
swift test --enable-code-coverage

# Report summary
xcrun llvm-cov report \
    .build/debug/<Package>PackageTests.xctest/Contents/MacOS/<Package>PackageTests \
    -instr-profile .build/debug/codecov/default.profdata

# Export to lcov
xcrun llvm-cov export \
    .build/debug/<Package>PackageTests.xctest/Contents/MacOS/<Package>PackageTests \
    -instr-profile .build/debug/codecov/default.profdata \
    -format lcov > coverage.lcov

# Xcode: test with coverage
xcodebuild test \
    -scheme <scheme> \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -enableCodeCoverage YES \
    -resultBundlePath TestResults.xcresult

# Extract from xcresult
xcrun xccov view --report TestResults.xcresult
```

### Coverage Targets

| Code Type | Target |
|-----------|--------|
| Critical business logic | 100% |
| Public APIs | 90%+ |
| General application code | 80%+ |
| Generated code / UI glue | Exclude |

## Continuous Integration

### GitHub Actions

```yaml
name: Swift Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: swift build
      - name: Test with coverage
        run: swift test --enable-code-coverage
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage.lcov
```

### Xcode Cloud / xcodebuild CLI

```bash
# Build and test all schemes
xcodebuild test \
    -scheme MyApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -parallel-testing-enabled YES \
    -enableCodeCoverage YES \
    -resultBundlePath TestResults.xcresult

# Run specific test suite
xcodebuild test \
    -scheme MyApp \
    -only-testing:MyAppTests/AuthenticationTests \
    -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Best Practices

**DO:**
- Write tests FIRST (TDD)
- Use `@Test` and `#expect` (Swift Testing) for new tests
- Use `#require` to unwrap, never force-unwrap in tests
- Use parameterized tests for multiple inputs
- Use `@Suite` to organize related tests
- Use `confirmation` for async callback expectations
- Set `.timeLimit` on potentially slow tests
- Use `.tags` for categorization and selective running

**DON'T:**
- Write implementation before tests
- Use `XCTAssert*` in new test files
- Force-unwrap in tests (`value!`)
- Use `Thread.sleep` — use `confirmation` or `Task.sleep`
- Ignore flaky tests — fix or quarantine them
- Test private implementation details
- Mock types you don't own

## Related

- Skill: `skills/swift-protocol-di-testing/` — Protocol-based DI and mock patterns
- Skill: `skills/tdd-workflow/` — Language-agnostic TDD principles
- Skill: `skills/apple-platform-patterns/` — Architecture patterns
- Command: `/swift-test` — TDD command for Swift
