---
paths:
  - "**/*.swift"
---
# Swift Code Analysis Rules

> Guidelines for analyzing Swift code in reviews and debugging sessions.

## Chain-of-Thought Analysis

When analyzing Swift code:
1. **Think in English** for reasoning (CoT) — structured, precise analysis
2. **Explain in 繁體中文** for user communication — clear, accessible summaries

## Analysis Checklist

### Context Gathering
- Read adjacent files in the same module to understand relationships
- Check protocol conformances and their requirements
- Trace data flow from source to destination
- Verify API usage against Apple documentation (use Apple Doc MCP when available)

### Memory Safety — Zero Tolerance
- **Retain cycles**: Check all closures captured by escaping references
- **Delegate patterns**: Ensure `weak` on all delegate properties
- **Combine pipelines**: Verify `[weak self]` in `sink`, `map`, `flatMap` closures stored in `cancellables`
- **NotificationCenter**: Confirm observers are removed or use `Task`-based APIs
- **Timer**: Check `Timer.publish` subscribers for proper cancellation

### Concurrency Safety
- **Actor isolation**: Verify non-isolated access patterns
- **Sendable conformance**: Check types crossing isolation boundaries
- **MainActor usage**: Confirm UI updates happen on `@MainActor`
- **Task cancellation**: Check for cancellation handling in long-running tasks

### Performance Analysis
- **SwiftUI body complexity**: Flag `body` properties exceeding 30 lines
- **Unnecessary re-renders**: Check for missing `Equatable` or excessive `@State`
- **Collection operations**: Verify lazy evaluation for large collections
- **Image loading**: Check for synchronous image loading on main thread

### Error Handling
- **Typed throws**: Prefer typed throws (Swift 6+) over untyped
- **Error propagation**: Verify errors are properly propagated, not swallowed
- **User-facing errors**: Check that error messages are localized and helpful
