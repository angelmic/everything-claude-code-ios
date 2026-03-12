---
paths:
  - "**/*.swift"
  - "**/Package.swift"
---
# Swift Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with Swift specific content.

## Formatting

- **SwiftFormat** for auto-formatting, **SwiftLint** for style enforcement
- `swift-format` is bundled with Xcode 16+ as an alternative

## Immutability

- Prefer `let` over `var` — define everything as `let` and only change to `var` if the compiler requires it
- Use `struct` with value semantics by default; use `class` only when identity or reference semantics are needed

## Naming

Follow [Apple API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/):

- Clarity at the point of use — omit needless words
- Name methods and properties for their roles, not their types
- Use `static let` for constants over global constants

## Error Handling

Use typed throws (Swift 6+) and pattern matching:

```swift
func load(id: String) throws(LoadError) -> Item {
    guard let data = try? read(from: path) else {
        throw .fileNotFound(id)
    }
    return try decode(data)
}
```

## Guard-Let Style

`guard let ... else` 左右括號不同行，即使 body 只有一行 `return`/`throw`/`continue`：
```swift
guard let user = currentUser else {
    return
}
```

Multi-line guard for complex conditions:
```swift
guard
    let user = currentUser,
    user.isActive,
    let token = user.authToken
else {
    throw AuthError.notAuthenticated
}
```

## Control Flow

- Prefer `switch` over multiple `if-else` chains
- Exhaustive `switch` — avoid `default` when possible to get compiler warnings on new cases

## Boolean Naming

Use predicate prefixes: `isEnabled`, `hasValue`, `canSubmit`, `shouldRefresh`

## Safe Casting

- Use `as?` — NEVER `as!` for downcasting
- Forbid implicitly unwrapped optionals (`!`) except for `@IBOutlet`

## Trailing Closures

Use trailing closure syntax for the last closure parameter:
```swift
UIView.animate(withDuration: 0.3) {
    view.alpha = 1.0
}
```

## MARK Comments

Organize files with `// MARK: -` sections:
```swift
// MARK: - Properties
// MARK: - Lifecycle
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Protocol Conformance
```

## Documentation

Use `///` for all `public` and `open` API:
```swift
/// Loads the user profile for the given identifier.
/// - Parameter id: The unique user identifier.
/// - Returns: The user profile.
/// - Throws: `ProfileError.notFound` if no profile exists.
public func loadProfile(id: String) throws(ProfileError) -> Profile
```

## Concurrency

Enable Swift 6 strict concurrency checking. Prefer:

- `Sendable` value types for data crossing isolation boundaries
- Actors for shared mutable state
- Structured concurrency (`async let`, `TaskGroup`) over unstructured `Task {}`
