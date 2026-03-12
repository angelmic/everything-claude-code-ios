# iOS Memory Safety

## When to Use

Use this skill when dealing with memory management, retain cycles, Task+[weak self] patterns, Combine leaks, and memory debugging in iOS/tvOS/macOS apps.

## How It Works

### Task + [weak self] Decision Matrix

| Context | [weak self]? | Why |
|---------|-------------|-----|
| `Task {}` in class method | ✅ Yes | Task captures self strongly, creating potential retain cycle |
| `Task {}` in struct/View | ❌ No | Value types cannot have retain cycles |
| `Task {}` in actor | ❌ No | Actor manages own lifecycle |
| `Task.detached {}` in class | ✅ Yes | Detached tasks have no implicit isolation |
| Combine `sink {}` stored in class | ✅ Yes | AnyCancellable stored in class creates cycle |
| `NotificationCenter.addObserver` closure | ✅ Yes | Closure is escaping and long-lived |

### Retain Cycle Patterns

#### Pattern 1: Closure Capture in Class
```swift
// ❌ Retain cycle
class ViewModel {
    var onUpdate: (() -> Void)?

    func setup() {
        onUpdate = {
            self.refresh()  // strong capture
        }
    }
}

// ✅ Fixed
class ViewModel {
    var onUpdate: (() -> Void)?

    func setup() {
        onUpdate = { [weak self] in
            self?.refresh()
        }
    }
}
```

#### Pattern 2: Combine Pipeline
```swift
// ❌ Retain cycle
class ViewModel {
    var cancellables = Set<AnyCancellable>()

    func observe() {
        publisher
            .sink { value in
                self.handle(value)  // strong capture stored in cancellables
            }
            .store(in: &cancellables)
    }
}

// ✅ Fixed
class ViewModel {
    var cancellables = Set<AnyCancellable>()

    func observe() {
        publisher
            .sink { [weak self] value in
                self?.handle(value)
            }
            .store(in: &cancellables)
    }
}
```

#### Pattern 3: Delegate Cycle
```swift
// ❌ Retain cycle
protocol ServiceDelegate: AnyObject {}

class Service {
    var delegate: ServiceDelegate?  // should be weak
}

// ✅ Fixed
class Service {
    weak var delegate: ServiceDelegate?
}
```

#### Pattern 4: Timer
```swift
// ❌ Retain cycle
class ViewModel {
    var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.tick()  // strong capture
        }
    }
}

// ✅ Fixed
class ViewModel {
    var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    deinit {
        timer?.invalidate()
    }
}
```

### Testing for Memory Leaks
```swift
// Retain cycle detection test
func test_viewModel_shouldNotLeak() {
    var sut: MyViewModel? = MyViewModel(service: mockService)
    weak var weakRef = sut

    sut?.startObserving()
    sut = nil

    XCTAssertNil(weakRef, "ViewModel has a retain cycle")
}
```

### Debugging Tools
- **Xcode Memory Graph Debugger**: Debug → Debug Memory Graph
- **Instruments - Leaks**: Profile → Leaks template
- **Instruments - Allocations**: Track allocation/deallocation patterns
- **`MallocStackLogging`**: Enable for allocation backtraces

### Best Practices
1. Always use `[weak self]` in escaping closures within classes
2. Declare delegate properties as `weak`
3. Cancel Combine subscriptions in `deinit`
4. Invalidate timers in `deinit`
5. Use `addObserver(forName:using:)` with returned token pattern for notifications
6. Test for retain cycles in unit tests using weak reference pattern
