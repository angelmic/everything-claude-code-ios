---
paths:
  - "**/*.swift"
---
# Swift Code Review Rules

> This file extends [common/coding-style.md](../common/coding-style.md) with Swift code review specifics.

## Task + [weak self] — Four Scenarios

This is the most critical review rule for Swift concurrency and memory safety.

### Scenario 1: Task Inside a Class Method — MUST Use [weak self]
```swift
// ✅ CORRECT
class MyViewModel {
    func fetch() {
        Task { [weak self] in
            guard let self else { return }
            let data = await service.load()
            self.items = data
        }
    }
}

// ❌ WRONG — strong capture keeps self alive
class MyViewModel {
    func fetch() {
        Task {
            let data = await service.load()
            self.items = data  // implicit strong self
        }
    }
}
```

### Scenario 2: Task Inside SwiftUI View — No [weak self] Needed
```swift
// ✅ CORRECT — structs have no retain cycles
struct ContentView: View {
    var body: some View {
        Button("Load") {
            Task {
                await viewModel.load()  // no [weak self] needed
            }
        }
    }
}
```

### Scenario 3: Task Inside Actor — No [weak self] Needed
```swift
// ✅ CORRECT — actors manage their own isolation
actor DataStore {
    func refresh() {
        Task {
            let data = await api.fetch()
            self.cache = data  // safe, actor-isolated
        }
    }
}
```

### Scenario 4: Task.detached — MUST Use [weak self] for Classes
```swift
// ✅ CORRECT
class Coordinator {
    func process() {
        Task.detached { [weak self] in
            guard let self else { return }
            await self.handleResult()
        }
    }
}
```

### Summary Table
| Context | [weak self] | Reason |
|---------|-------------|--------|
| Task in class method | ✅ Required | Prevents retain cycle |
| Task in struct/SwiftUI View | ❌ Not needed | Value type, no cycle |
| Task in actor | ❌ Not needed | Actor-isolated |
| Task.detached in class | ✅ Required | No implicit isolation |
| Combine sink in class | ✅ Required | Escaping closure |

## Build Verification

Every code review MUST include:
1. `swift build` or `xcodebuild build` — project compiles without errors
2. `swift test` or `xcodebuild test` — all tests pass
3. No new warnings introduced

## Team Leader Review Perspective

When reviewing, think like a tech lead:
- Will this code be maintainable by junior developers?
- Are the naming conventions clear and consistent?
- Is the complexity justified?
- Are there simpler alternatives?
- Does it follow the project's established patterns?

## Definition of Done
- [ ] All tests pass
- [ ] No CRITICAL or HIGH review issues
- [ ] Build succeeds without new warnings
- [ ] Public API has `///` documentation
- [ ] No force unwraps on external data
- [ ] Proper `[weak self]` usage (see scenarios above)
- [ ] No hardcoded strings (localization ready)
