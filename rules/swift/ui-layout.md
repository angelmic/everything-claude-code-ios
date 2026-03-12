---
paths:
  - "**/*.swift"
  - "**/*.xib"
  - "**/*.storyboard"
---
# Swift UI Layout Rules

> Guidelines for SwiftUI, UIKit Auto Layout, tvOS Focus Engine, and Accessibility.

## SwiftUI Layout

### View Composition
- Extract subviews when `body` exceeds 30 lines
- Use `@ViewBuilder` for conditional content
- Prefer computed properties for simple subviews, separate `struct` for complex ones

### Layout Priorities
```swift
// ✅ Use layout priorities and fixed frames intentionally
Text(title)
    .layoutPriority(1)  // gets space first
Text(subtitle)
    .layoutPriority(0)
```

### Safe Area
```swift
// ✅ Respect safe areas
.ignoresSafeArea(.container, edges: .bottom)  // only when intentional

// ❌ Don't blindly ignore all safe areas
.ignoresSafeArea()
```

### GeometryReader
- Use sparingly — prefer built-in layout containers
- Never use `GeometryReader` in scrollable content without careful sizing
- Prefer `containerRelativeFrame` (iOS 17+) when possible

## UIKit Auto Layout

### Constraint Best Practices
- Activate constraints in batches with `NSLayoutConstraint.activate([])`
- Set `translatesAutoresizingMaskIntoConstraints = false` on programmatic views
- Use `UILayoutGuide` instead of spacer views
- Prefer `directionalLayoutMargins` over fixed leading/trailing for RTL support

### Intrinsic Content Size
- Override `intrinsicContentSize` for custom views that have natural dimensions
- Set `contentHuggingPriority` and `contentCompressionResistancePriority` appropriately

## tvOS Focus Engine

### Focus Management
```swift
// ✅ Use focusable modifier
Button(action: play) {
    Label("Play", systemImage: "play.fill")
}
.focusable()

// ✅ Custom focus effects
.focusEffectDisabled()
.onFocusChange { focused in
    withAnimation { isFocused = focused }
}
```

### Focus Guide
- Use `UIFocusGuide` to redirect focus for non-rectangular layouts
- Test focus movement in all four directions (up/down/left/right)
- Ensure no focus traps (user can always navigate away)

### tvOS-Specific Layout
- Minimum tap target: 66×66 points
- Account for overscan safe area
- Use large, readable text (minimum 29pt for body text)
- High contrast between focused and unfocused states

## Accessibility

### VoiceOver
```swift
// ✅ Meaningful labels
Image(systemName: "heart.fill")
    .accessibilityLabel("Favorite")
    .accessibilityHint("Double tap to remove from favorites")

// ✅ Group related elements
VStack {
    Text(title)
    Text(subtitle)
}
.accessibilityElement(children: .combine)
```

### Dynamic Type
```swift
// ✅ Use built-in text styles
Text(title)
    .font(.headline)  // scales with Dynamic Type

// ❌ Don't use fixed font sizes for user-facing text
Text(title)
    .font(.system(size: 16))  // won't scale
```

### Accessibility Checklist
- [ ] All interactive elements have accessibility labels
- [ ] Images have meaningful descriptions or are decorative (`.accessibilityHidden(true)`)
- [ ] Dynamic Type supported — no fixed font sizes for user text
- [ ] Color is not the sole indicator of state
- [ ] Touch targets are at least 44×44 points (iOS) or 66×66 points (tvOS)
- [ ] VoiceOver navigation order is logical
- [ ] Custom actions available for complex gestures
