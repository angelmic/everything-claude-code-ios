---
description: Comprehensive Swift code review for concurrency safety, memory management, SwiftUI patterns, and security. Invokes the swift-reviewer agent.
---

# Swift Code Review

This command invokes the **swift-reviewer** agent for comprehensive Swift-specific code review.

## What This Command Does

1. **Identify Swift Changes**: Find modified `.swift` files via `git diff`
2. **Run Static Analysis**: Execute `swiftlint lint` and `swift build`
3. **Security Scan**: Check for hardcoded secrets, disabled ATS, insecure storage
4. **Concurrency Review**: Analyze data race safety, Sendable conformance, actor isolation
5. **Memory Review**: Check for retain cycles, missing weak references, leaked observers
6. **Generate Report**: Categorize issues by severity

## When to Use

Use `/swift-review` when:
- After writing or modifying Swift code
- Before committing Swift changes
- Reviewing pull requests with Swift code
- Migrating to Swift 6 concurrency
- Onboarding to a new iOS/tvOS/macOS codebase

## Review Categories

### CRITICAL (Must Fix)
- Hardcoded secrets or disabled ATS
- Data races (shared mutable state without actor/lock)
- Strong reference cycles in escaping closures
- Force-unwrapped user input
- UserDefaults storing sensitive data

### HIGH (Should Fix)
- Force unwraps (`!`) on runtime optionals
- Force try (`try!`) on fallible operations
- Empty catch blocks
- Massive view bodies (>50 lines)
- Class used where struct suffices
- `ObservableObject` in new code (use `@Observable`)

### MEDIUM (Consider)
- `print()` instead of `os.Logger`
- Missing access control modifiers
- Expensive computation in SwiftUI `body`
- Missing `LazyVStack`/`LazyHStack` for large lists
- `AnyView` preventing diffing optimization

## Automated Checks Run

```bash
# SwiftLint analysis
swiftlint lint --reporter json

# SPM build check
swift build 2>&1

# Test with coverage
swift test --enable-code-coverage

# Xcode build (if .xcodeproj exists)
xcodebuild build -scheme <scheme> -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1
```

## Example Usage

```text
User: /swift-review

Agent:
# Swift Code Review Report

## Files Reviewed
- Sources/App/UserViewModel.swift (modified)
- Sources/App/LoginView.swift (modified)

## Static Analysis Results
✓ swift build: Success
⚠ swiftlint: 2 warnings

## Issues Found

[CRITICAL] Strong Reference Cycle
File: Sources/App/UserViewModel.swift:34
Issue: Missing [weak self] in escaping closure
```swift
// Before — retain cycle
networkService.fetchUser(id: userId) { result in
    self.user = try? result.get()  // strong capture
}

// After — safe
networkService.fetchUser(id: userId) { [weak self] result in
    self?.user = try? result.get()
}
```

[HIGH] Force Unwrap
File: Sources/App/LoginView.swift:18
Issue: Force unwrap on user input URL
```swift
// Before
let url = URL(string: urlField.text)!

// After
guard let url = URL(string: urlField.text) else {
    showError("Invalid URL")
    return
}
```

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 0

Recommendation: ❌ Block merge until CRITICAL issue is fixed
```

## Approval Criteria

| Status | Condition |
|--------|-----------|
| ✅ Approve | No CRITICAL or HIGH issues |
| ⚠️ Warning | Only MEDIUM issues (merge with caution) |
| ❌ Block | CRITICAL or HIGH issues found |

## Integration with Other Commands

- Use `/swift-test` first to ensure tests pass
- Use `/swift-build` if build errors occur
- Use `/swift-review` before committing
- Use `/code-review` for non-Swift specific concerns

## Related

- Agent: `agents/swift-reviewer.md`
- Skills: `skills/apple-platform-patterns/`, `skills/swiftui-patterns/`, `skills/swift-testing-tdd/`
