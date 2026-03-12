# iOS Task Template

## Task

### Title
[Short, descriptive title]

### Type
- [ ] Feature implementation
- [ ] Bug fix
- [ ] Refactoring
- [ ] Technical debt
- [ ] Spike / Investigation
- [ ] Infrastructure

### Description
[What needs to be done and why]

### Parent Story
[Link to parent user story if applicable]

### Architecture Layer
- [ ] UI (SwiftUI / UIKit)
- [ ] ViewModel (@Observable / ObservableObject)
- [ ] UseCase (Business Logic)
- [ ] Repository (Data Abstraction)
- [ ] Service (Network / Storage)
- [ ] Infrastructure (DI, Navigation, Analytics)

### Subtasks
- [ ] Create/update protocol definition
- [ ] Implement concrete type
- [ ] Write unit tests (Swift Testing or XCTest)
- [ ] Write integration tests (if applicable)
- [ ] Update UI layer
- [ ] Verify build (`swift build` / `xcodebuild`)
- [ ] Code review passed

### Test Plan
- **Unit Tests**: [what to test]
- **Integration Tests**: [what to test]
- **Manual Tests**: [what to verify]

### Estimate
- [ ] 1h
- [ ] 2h
- [ ] 4h
- [ ] 8h (1 day)
- [ ] 16h+ (consider splitting)

### Risks
- [Potential blockers or unknowns]

### Definition of Done
- [ ] All tests pass
- [ ] Build succeeds without new warnings
- [ ] Code review approved (no CRITICAL/HIGH issues)
- [ ] Public API documented
- [ ] Accessibility verified
