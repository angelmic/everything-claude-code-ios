# XCTest + Nimble Testing Patterns

## When to Use

Use this skill when writing tests with XCTest and Nimble matcher framework. Applies to projects that use Nimble for expressive assertions alongside XCTest.

## How It Works

### SUT Naming Convention
- `sut` — primary system under test
- `sut2`, `sut3` — for comparison or multi-instance tests

### AAA Pattern (Arrange-Act-Assert)
```swift
func test_loadItems_whenNetworkSucceeds_shouldPopulateList() {
    // Arrange
    let mockRepo = MockItemRepository(result: .success(.sample))
    let sut = ItemListViewModel(repository: mockRepo)

    // Act
    sut.loadItems()

    // Assert
    expect(sut.items).to(haveCount(3))
    expect(sut.state).to(equal(.loaded))
}
```

### Test Naming Convention
```
test_<methodUnderTest>_<condition>_<expectedBehavior>()
```

Examples:
- `test_login_whenPasswordEmpty_shouldShowError()`
- `test_fetchUser_whenNetworkFails_shouldReturnCachedData()`
- `test_addToCart_whenItemExists_shouldIncrementQuantity()`

### Mock Naming Convention
| Pattern | Usage |
|---------|-------|
| `Mock<Protocol>` | Controllable test double with configurable responses |
| `Happy<Name>` | Always returns success/valid data |
| `Dummy<Name>` | Unused dependency placeholder (satisfies compiler) |
| `Spy<Name>` | Records method calls for verification |
| `Stub<Name>` | Returns predetermined responses |

### Nimble Matchers
```swift
// Equality
expect(value).to(equal(expected))
expect(value).toNot(equal(other))

// Collection
expect(array).to(haveCount(3))
expect(array).to(contain(element))
expect(array).to(beEmpty())

// Boolean
expect(flag).to(beTrue())
expect(flag).to(beFalse())

// Nil
expect(optional).to(beNil())
expect(optional).toNot(beNil())

// Type
expect(object).to(beAnInstanceOf(MyClass.self))
expect(object).to(beAKindOf(MyProtocol.self))

// Comparison
expect(value).to(beGreaterThan(0))
expect(value).to(beLessThanOrEqualTo(100))

// String
expect(string).to(contain("substring"))
expect(string).to(beginWith("prefix"))
expect(string).to(match("regex"))

// Error
expect { try sut.validate() }.to(throwError(ValidationError.invalid))
```

### Nimble Async Patterns
```swift
// waitUntil — for callback-based async
func test_fetch_whenCalled_shouldComplete() {
    waitUntil(timeout: .seconds(5)) { done in
        sut.fetch { result in
            expect(result).toNot(beNil())
            done()
        }
    }
}

// toEventually — for polling-based async
func test_state_afterLoad_shouldBecomeReady() {
    sut.startLoading()
    expect(sut.state).toEventually(equal(.ready), timeout: .seconds(3))
}

// toEventuallyNot
func test_spinner_afterLoad_shouldDisappear() {
    sut.startLoading()
    expect(sut.isLoading).toEventuallyNot(beTrue())
}
```

### Retain Cycle Testing
```swift
func test_viewModel_afterDealloc_shouldNotRetain() {
    var sut: MyViewModel? = MyViewModel(service: mockService)
    weak var weakSut = sut

    sut?.startObserving()
    sut = nil

    expect(weakSut).to(beNil())  // fails if retain cycle exists
}
```

### Anti-Patterns to Avoid
1. **Testing implementation, not behavior** — test what it does, not how
2. **Shared mutable state between tests** — use fresh `setUp` for each test
3. **Flaky async tests** — use proper timeout and deterministic triggers
4. **Force unwrapping in tests** — use `try XCTUnwrap()` or Nimble's `unwrap()`
5. **Testing private methods** — test through public API instead
6. **Giant test methods** — one assertion focus per test
