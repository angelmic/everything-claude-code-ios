---
description: Fix Swift build errors, xcodebuild failures, and SPM dependency issues incrementally. Invokes the xcode-build-resolver agent for minimal, surgical fixes.
---

# Swift Build and Fix

This command invokes the **xcode-build-resolver** agent to incrementally fix Swift build errors with minimal changes.

## What This Command Does

1. **Run Diagnostics**: Execute `swift build`, `xcodebuild`, `swiftlint`
2. **Parse Errors**: Group by file and sort by severity
3. **Fix Incrementally**: One error at a time
4. **Verify Each Fix**: Re-run build after each change
5. **Report Summary**: Show what was fixed and what remains

## When to Use

Use `/swift-build` when:
- `swift build` fails with errors
- `xcodebuild` reports compilation failures
- SPM dependency resolution fails
- After pulling changes that break the build
- Swift 6 concurrency migration errors appear
- Protocol conformance mismatches occur

## Diagnostic Commands Run

```bash
# SPM build
swift build 2>&1

# Xcode build (if .xcodeproj exists)
xcodebuild build -scheme <scheme> -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1

# SwiftLint (if available)
swiftlint lint --reporter json

# Dependency check
swift package resolve
swift package show-dependencies
```

## Example Session

```text
User: /swift-build

Agent:
# Swift Build Resolution

## Initial Diagnostics

```bash
$ swift build 2>&1
Sources/App/UserViewModel.swift:25:15: error: cannot find type 'UserService' in scope
Sources/App/LoginView.swift:42:9: error: value of type 'String' has no member 'isValidEmail'
Sources/App/ProfileView.swift:18:2: error: missing return in a function expected to return 'some View'
```

Errors found: 3

## Fix 1: Missing Import

File: Sources/App/UserViewModel.swift:25
Error: cannot find type 'UserService' in scope
Cause: Missing import

```swift
// Added import
import Services
```

```bash
$ swift build 2>&1
# 2 errors remaining
```

## Fix 2: Missing Extension Method

File: Sources/App/LoginView.swift:42
Error: value of type 'String' has no member 'isValidEmail'

```swift
// Added String extension
extension String {
    var isValidEmail: Bool {
        let regex = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/
        return wholeMatch(of: regex.ignoresCase()) != nil
    }
}
```

```bash
$ swift build 2>&1
# 1 error remaining
```

## Fix 3: Missing Return

File: Sources/App/ProfileView.swift:18
Error: missing return in a function expected to return 'some View'

```swift
var body: some View {
    if let user {
        ProfileContent(user: user)
    } else {
        ContentUnavailableView("No Profile", systemImage: "person.slash")
    }
}
```

```bash
$ swift build 2>&1
# Build successful!
```

## Final Verification

```bash
$ swift test 2>&1
Test Suite 'All tests' passed.
    Executed 24 tests, with 0 failures in 1.234 seconds
```

## Summary

| Metric | Count |
|--------|-------|
| Build errors fixed | 3 |
| Lint warnings fixed | 0 |
| Files modified | 3 |
| Remaining issues | 0 |

Build Status: ✅ SUCCESS
```

## Common Errors Fixed

| Error | Typical Fix |
|-------|-------------|
| `cannot find type 'X' in scope` | Add import or fix spelling |
| `does not conform to protocol` | Add missing method/property |
| `sending 'X' risks data races` | Add Sendable, use actor |
| `expression too complex` | Break into intermediate variables |
| `circular dependency` | Extract shared types to module |
| `missing return` | Add return statement |
| `package resolution failed` | `swift package resolve` |
| `ambiguous use of 'X'` | Add module prefix |

## Fix Strategy

1. **Build errors first** — Code must compile
2. **Type errors second** — Fix conformance and type mismatches
3. **Concurrency errors third** — Sendable and actor isolation
4. **Lint warnings last** — Style and best practices
5. **One fix at a time** — Verify each change
6. **Minimal changes** — Don't refactor, just fix

## Stop Conditions

The agent will stop and report if:
- Same error persists after 3 attempts
- Fix introduces more errors
- Requires architectural changes
- Missing external SDK or framework

## Related Commands

- `/swift-test` — Run tests after build succeeds
- `/swift-review` — Review code quality
- `/verify` — Full verification loop

## Related

- Agent: `agents/xcode-build-resolver.md`
- Skills: `skills/apple-platform-patterns/`, `skills/swiftui-patterns/`
