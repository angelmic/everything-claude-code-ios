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

## Reference

- See skill: `swift-protocol-di-testing` for protocol-based dependency injection and mock patterns with Swift Testing.
- See skill: `swift-testing-tdd` for comprehensive testing patterns and TDD workflow.
