---
description: Enforce TDD workflow for Swift. Write tests first using Swift Testing framework (@Test, #expect), then implement. Verify 80%+ coverage.
---

# Swift TDD Command

This command enforces test-driven development methodology for Swift code using the Swift Testing framework.

## What This Command Does

1. **Define Types/Protocols**: Scaffold function signatures first
2. **Write Tests**: Create `@Test` functions with `#expect` assertions (RED)
3. **Run Tests**: Verify tests fail for the right reason
4. **Implement Code**: Write minimal code to pass (GREEN)
5. **Refactor**: Improve while keeping tests green
6. **Check Coverage**: Ensure 80%+ coverage

## When to Use

Use `/swift-test` when:
- Implementing new Swift functions or types
- Adding test coverage to existing code
- Fixing bugs (write failing test first)
- Building critical business logic
- Learning TDD workflow with Swift Testing

## TDD Cycle

```
RED     → Write failing @Test with #expect
GREEN   → Implement minimal code to pass
REFACTOR → Improve code, tests stay green
REPEAT  → Next test case
```

## Example Session

````
User: /swift-test I need a function to validate email addresses

Agent:
# TDD Session: Email Validator

## Step 1: Define Interface

```swift
// Sources/Validation/EmailValidator.swift

struct EmailValidator {
    func validate(_ email: String) throws -> String {
        fatalError("not implemented")
    }
}

enum EmailValidationError: Error, Equatable {
    case empty
    case invalidFormat
    case missingDomain
}
```

## Step 2: Write Tests (RED)

```swift
// Tests/ValidationTests/EmailValidatorTests.swift
import Testing
@testable import Validation

@Suite("Email Validation")
struct EmailValidatorTests {
    let validator = EmailValidator()

    // Valid emails
    @Test("Accepts simple email")
    func acceptsSimpleEmail() throws {
        let result = try validator.validate("user@example.com")
        #expect(result == "user@example.com")
    }

    @Test("Accepts email with subdomain")
    func acceptsSubdomain() throws {
        let result = try validator.validate("user@mail.example.com")
        #expect(result == "user@mail.example.com")
    }

    @Test("Accepts email with plus tag")
    func acceptsPlusTag() throws {
        let result = try validator.validate("user+tag@example.com")
        #expect(result == "user+tag@example.com")
    }

    // Invalid emails — parameterized
    @Test("Rejects invalid emails", arguments: [
        ("", EmailValidationError.empty),
        ("userexample.com", EmailValidationError.invalidFormat),
        ("user@", EmailValidationError.missingDomain),
        ("@example.com", EmailValidationError.invalidFormat),
        ("user@@example.com", EmailValidationError.invalidFormat),
    ])
    func rejectsInvalid(email: String, expectedError: EmailValidationError) {
        #expect(throws: expectedError) {
            try validator.validate(email)
        }
    }
}
```

## Step 3: Run Tests — Verify FAIL

```bash
$ swift test --filter EmailValidatorTests
◇ Test run started.
✘ Email Validation — Accepts simple email
  ↳ Fatal error: not implemented

◇ 6 tests failed.
```

✓ Tests fail as expected (fatalError).

## Step 4: Implement Minimal Code (GREEN)

```swift
// Sources/Validation/EmailValidator.swift
import Foundation

struct EmailValidator {
    private let pattern = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/

    func validate(_ email: String) throws -> String {
        guard !email.isEmpty else {
            throw EmailValidationError.empty
        }
        guard email.contains("@"),
              let atIndex = email.firstIndex(of: "@"),
              atIndex != email.startIndex else {
            throw EmailValidationError.invalidFormat
        }
        let domain = email[email.index(after: atIndex)...]
        guard !domain.isEmpty, domain.contains(".") else {
            throw EmailValidationError.missingDomain
        }
        guard email.wholeMatch(of: pattern) != nil else {
            throw EmailValidationError.invalidFormat
        }
        return email
    }
}
```

## Step 5: Run Tests — Verify PASS

```bash
$ swift test --filter EmailValidatorTests
◇ Test run started.
✔ Email Validation — Accepts simple email
✔ Email Validation — Accepts email with subdomain
✔ Email Validation — Accepts email with plus tag
✔ Email Validation — Rejects invalid emails (5 parameterized)

◇ 8 tests passed.
```

✓ All tests passing!

## Step 6: Check Coverage

```bash
$ swift test --enable-code-coverage
$ xcrun llvm-cov report .build/debug/<Package>PackageTests.xctest \
    -instr-profile .build/debug/codecov/default.profdata

Filename          Regions  Missed  Cover
EmailValidator.swift   12       0  100.0%
```

✓ Coverage: 100%

## TDD Complete!
````

## Test Patterns

### Basic @Test with #expect

```swift
@Test("Addition works correctly")
func addition() {
    #expect(2 + 2 == 4)
}
```

### @Test with throws

```swift
@Test("Parsing invalid JSON throws")
func invalidJSON() {
    #expect(throws: ParsingError.invalidJSON) {
        try parser.parse("not json")
    }
}
```

### #require for Unwrapping

```swift
@Test("User has valid profile")
func userProfile() throws {
    let user = try #require(fetchUser(id: "123"))
    #expect(user.name == "Alice")
    #expect(user.isActive)
}
```

### Parameterized Tests

```swift
@Test("Validates formats", arguments: ["json", "xml", "csv"])
func validatesFormat(format: String) throws {
    let parser = try Parser(format: format)
    #expect(parser.isValid)
}
```

### @Suite for Organization

```swift
@Suite("User Authentication")
struct AuthTests {
    let auth = AuthService()

    @Test("Login succeeds with valid credentials")
    func loginSuccess() async throws { ... }

    @Test("Login fails with wrong password")
    func loginFailure() { ... }
}
```

### Confirmation for Async Callbacks

```swift
@Test("Notification fires on save")
func notificationOnSave() async {
    await confirmation("save notification") { confirm in
        NotificationCenter.default.addObserver(
            forName: .didSave, object: nil, queue: nil
        ) { _ in confirm() }

        store.save(item)
    }
}
```

### Tags for Filtering

```swift
extension Tag {
    @Tag static var networking: Self
    @Tag static var slow: Self
}

@Test("API call succeeds", .tags(.networking, .slow))
func apiCall() async throws { ... }
```

## Coverage Commands

```bash
# Run tests with coverage
swift test --enable-code-coverage

# Generate coverage report
xcrun llvm-cov report .build/debug/<Target>PackageTests.xctest \
    -instr-profile .build/debug/codecov/default.profdata

# Export to lcov format
xcrun llvm-cov export .build/debug/<Target>PackageTests.xctest \
    -instr-profile .build/debug/codecov/default.profdata \
    -format lcov > coverage.lcov

# Xcode: test with coverage
xcodebuild test -scheme <scheme> \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -enableCodeCoverage YES
```

## Coverage Targets

| Code Type | Target |
|-----------|--------|
| Critical business logic | 100% |
| Public APIs | 90%+ |
| General code | 80%+ |
| Generated code / UI glue | Exclude |

## TDD Best Practices

**DO:**
- Write test FIRST, before any implementation
- Use `@Test` and `#expect` (Swift Testing), not `XCTestCase`
- Use parameterized tests for multiple inputs
- Use `#require` to unwrap optionals instead of force unwrap
- Use `@Suite` to group related tests
- Test behavior, not implementation details
- Include edge cases (empty, nil, boundary values)

**DON'T:**
- Write implementation before tests
- Skip the RED phase
- Use `XCTAssert` in new test files (use `#expect`)
- Use `time.sleep` in async tests (use `confirmation`)
- Ignore flaky tests

## Related Commands

- `/swift-build` — Fix build errors
- `/swift-review` — Review code after implementation
- `/verify` — Run full verification loop

## Related

- Skill: `skills/swift-testing-tdd/`
- Skill: `skills/swift-protocol-di-testing/`
- Skill: `skills/tdd-workflow/`
