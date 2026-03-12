---
description: Audit accessibility — VoiceOver labels, Dynamic Type support, tvOS Focus Engine, and contrast compliance.
---

# Accessibility Check

Run an accessibility audit on the current project.

## Automated Checks

Search the codebase for accessibility issues:

```bash
# Find images without accessibility labels
grep -rn "Image(" --include="*.swift" | grep -v "accessibilityLabel\|accessibilityHidden"

# Find buttons without accessibility labels
grep -rn "Button(" --include="*.swift" | grep -v "accessibilityLabel"

# Find fixed font sizes (should use Dynamic Type)
grep -rn "\.font(.system(size:" --include="*.swift"
grep -rn "UIFont.systemFont(ofSize:" --include="*.swift"

# Find hardcoded colors without dark mode support
grep -rn "Color(.sRGB\|UIColor(red:" --include="*.swift" | grep -v "Color(\"\|Color.accentColor\|Color.primary"
```

## VoiceOver Audit

### Required Labels
- All `Button` elements need `.accessibilityLabel()`
- All `Image` elements need `.accessibilityLabel()` or `.accessibilityHidden(true)`
- Navigation elements need descriptive labels
- Custom controls need `.accessibilityAddTraits()`

### Navigation Order
- Verify logical reading order with VoiceOver
- Group related elements with `.accessibilityElement(children: .combine)`
- Use `.accessibilitySortPriority()` for custom ordering

## Dynamic Type Audit

### Text Styles
- Use `.font(.headline)`, `.font(.body)` etc. — NOT fixed sizes
- Test at all Dynamic Type sizes including Accessibility sizes
- Ensure layouts don't break at largest text sizes

### Layout Resilience
- Verify `ScrollView` wraps content that might overflow
- Check `fixedSize()` usage — may break at large text
- Test horizontal layout switches to vertical at large sizes

## tvOS Focus Engine Audit

### Focus Navigation
- All interactive elements are focusable
- No focus traps (can navigate away in all directions)
- Focus movement follows visual layout
- Custom focus effects provide clear feedback

### tvOS Specifics
- Minimum 66×66 point touch targets
- Overscan safe area respected
- Text readable from 10 feet (minimum 29pt body)
- Sufficient contrast in focused/unfocused states

## Contrast Audit

### WCAG Guidelines
- Normal text: 4.5:1 contrast ratio minimum
- Large text (18pt+): 3:1 contrast ratio minimum
- Interactive elements: 3:1 contrast ratio minimum

## Report Format

After running checks, produce:

```markdown
## Accessibility Audit Results

### Critical Issues
- [items that block accessibility]

### Warnings
- [items that degrade accessibility]

### Passed
- [confirmed accessible patterns]

### Recommendations
- [suggested improvements]
```
