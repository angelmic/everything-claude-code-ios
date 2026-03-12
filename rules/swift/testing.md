---
paths:
  - "**/*.swift"
  - "**/Package.swift"
---
# Swift Testing

> This file extends [common/testing.md](../common/testing.md) with Swift specific content.

## Framework

Use **Swift Testing** (`import Testing`) for new tests. Use `@Test` and `#expect`:

```swift
@Test("User creation validates email")
func userCreationValidatesEmail() throws {
    #expect(throws: ValidationError.invalidEmail) {
        try User(email: "not-an-email")
    }
}
```

## @Suite for Test Organization

Group related tests with `@Suite`. Setup via `init`, teardown via `deinit`:

```swift
@Suite("Shopping Cart")
struct CartTests {
    let cart: ShoppingCart

    init() {
        cart = ShoppingCart(store: MockStore())
    }

    @Test("Empty cart has zero total")
    func emptyCartTotal() {
        #expect(cart.total == 0)
    }

    @Suite("With Items")
    struct WithItemsTests {
        let cart: ShoppingCart

        init() {
            var c = ShoppingCart(store: MockStore())
            c.add(Item(name: "Widget", price: 9.99))
            cart = c
        }

        @Test("Total reflects items")
        func total() {
            #expect(cart.total == 9.99)
        }
    }
}
```

## #require for Unwrapping

Use `#require` to safely unwrap optionals — test fails immediately with a clear message instead of a crash:

```swift
@Test("User profile contains address")
func profileAddress() throws {
    let user = try #require(userStore.find(id: "123"))
    let address = try #require(user.address)
    #expect(address.city == "San Francisco")
}
```

## Confirmation for Async Callbacks

Use `confirmation` to test callbacks and delegate methods:

```swift
@Test("Delegate notified on save")
func delegateNotified() async {
    await confirmation("save callback") { confirm in
        let store = DataStore()
        store.onSave = { confirm() }
        await store.save(item)
    }
}

// Expect multiple confirmations
@Test("Progress fires 3 times")
func progressFires() async {
    await confirmation("progress", expectedCount: 3) { confirm in
        loader.onProgress = { _ in confirm() }
        await loader.loadAll()
    }
}
```

## Tags for Test Filtering

```swift
extension Tag {
    @Tag static var networking: Self
    @Tag static var slow: Self
}

@Test("API call", .tags(.networking, .slow))
func apiCall() async throws { ... }

// Run only: swift test --filter .tags:networking
```

## Test Isolation

Each test gets a fresh instance — set up in `init`, tear down in `deinit`. No shared mutable state between tests.

## Parameterized Tests

```swift
@Test("Validates formats", arguments: ["json", "xml", "csv"])
func validatesFormat(format: String) throws {
    let parser = try Parser(format: format)
    #expect(parser.isValid)
}
```

## XCUITest (UI Testing)

For end-to-end UI testing, use XCUITest with accessibility identifiers:

```swift
// In your SwiftUI view:
Button("Login") { login() }
    .accessibilityIdentifier("login-button")

// In your UI test:
func testLoginFlow() {
    let app = XCUIApplication()
    app.launch()
    app.textFields["email-field"].tap()
    app.textFields["email-field"].typeText("test@test.com")
    app.buttons["login-button"].tap()
    XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 5))
}
```

## Coverage

```bash
swift test --enable-code-coverage
```

## XCTest + Nimble

For projects using XCTest with the Nimble matcher framework:

### SUT Naming Convention
- `sut` — primary system under test
- `sut2`, `sut3` — for comparison or multi-instance tests

### AAA Pattern
```swift
func test_loadItems_whenSuccess_shouldPopulateList() {
    // Arrange
    let sut = ItemListViewModel(repository: MockItemRepository(result: .success(.sample)))

    // Act
    sut.loadItems()

    // Assert
    expect(sut.items).to(haveCount(3))
    expect(sut.state).to(equal(.loaded))
}
```

### Test Naming: `test_<method>_<condition>_<expected>()`
```swift
func test_login_whenPasswordEmpty_shouldShowError()
func test_fetchUser_whenNetworkFails_shouldReturnCachedData()
func test_addToCart_whenItemExists_shouldIncrementQuantity()
```

### Mock Naming
| Pattern | Usage |
|---------|-------|
| `Mock<Protocol>` | Controllable test double |
| `Happy<Name>` | Always returns success |
| `Dummy<Name>` | Unused dependency placeholder |
| `Spy<Name>` | Records calls for verification |

### Nimble Async
```swift
// waitUntil for callback-based async
waitUntil(timeout: .seconds(5)) { done in
    sut.fetch { result in
        expect(result).toNot(beNil())
        done()
    }
}

// toEventually for polling-based async
sut.startLoading()
expect(sut.state).toEventually(equal(.ready), timeout: .seconds(3))
```

### Retain Cycle Testing
```swift
func test_viewModel_shouldNotLeak() {
    var sut: MyViewModel? = MyViewModel(service: mockService)
    weak var weakRef = sut
    sut?.startObserving()
    sut = nil
    expect(weakRef).to(beNil())
}
```

### Anti-Patterns
- **Testing implementation, not behavior** — test what it does, not how
- **Shared mutable state between tests** — use fresh `setUp` for each test
- **Force unwrapping in tests** — use `try XCTUnwrap()` or Nimble's `unwrap()`
- **Testing private methods** — test through public API instead
- **Giant test methods** — one assertion focus per test

## Reference

- See skill: `swift-protocol-di-testing` for protocol-based dependency injection and mock patterns with Swift Testing.
- See skill: `swift-testing-tdd` for comprehensive testing patterns and TDD workflow.
- See skill: `xctest-nimble-patterns` for comprehensive XCTest + Nimble matcher patterns.
- See skill: `ios-memory-safety` for retain cycle testing patterns.
