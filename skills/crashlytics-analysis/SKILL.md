# Crashlytics Analysis

## When to Use

Use this skill when analyzing Firebase Crashlytics crash reports, identifying root causes, and prioritizing fixes for iOS/tvOS apps.

## How It Works

### Crash Report Triage

#### Priority Classification
| Priority | Criteria | Action |
|----------|----------|--------|
| P0 | Crash rate > 1%, affects core flow | Fix immediately, hotfix release |
| P1 | Crash rate 0.1-1%, non-core flow | Fix in next release |
| P2 | Crash rate < 0.1%, edge case | Schedule for upcoming sprint |
| P3 | Single occurrence, non-reproducible | Monitor, investigate if recurs |

### Analysis Process

1. **Identify the crash cluster**: Group crashes by stack trace signature
2. **Read the stack trace**: Identify the crashing frame and call chain
3. **Check device/OS distribution**: Is it OS-version specific? Device-specific?
4. **Check user actions**: What was the user doing? (breadcrumbs/logs)
5. **Reproduce locally**: Write a failing test that triggers the same condition
6. **Fix with TDD**: RED (test reproduces crash) → GREEN (fix) → REFACTOR

### Common iOS Crash Patterns

#### Force Unwrap Crash
```
Fatal error: Unexpectedly found nil while unwrapping an Optional value
```
**Fix**: Replace `!` with `guard let` or `if let`

#### Array Index Out of Range
```
Fatal error: Index out of range
```
**Fix**: Add bounds checking, use `safe` subscript extension

#### Unrecognized Selector
```
-[ClassName methodName]: unrecognized selector sent to instance
```
**Fix**: Check for incorrect type casting, stale XIB/Storyboard connections

#### EXC_BAD_ACCESS
```
EXC_BAD_ACCESS (code=1, address=0x...)
```
**Fix**: Check for dangling pointers, zombie objects, use-after-free

#### Concurrent Mutation
```
Simultaneous accesses to ..., but modification requires exclusive access
```
**Fix**: Add proper synchronization (actor, lock, serial queue)

### Crash-Free Rate Monitoring

After deploying a fix:
1. Monitor crash-free rate for 48 hours
2. Compare with baseline from previous version
3. Target: 99.5%+ crash-free users

### Integration Points

- **`crashlytics` toolSpec** — query Crashlytics API for crash data
- **`jira` skill** — create bug tickets for P0/P1 crashes
- **`ios-coder` agent** — implement fixes via TDD

## Examples

### Analyzing a P0 Crash
```
1. Crashlytics shows: "Fatal error: Unexpectedly found nil" in PlayerViewModel.swift:42
2. Stack trace: loadVideo() → configurePlayer() → player.play()
3. Device distribution: All devices, iOS 17.0+ only
4. Root cause: Optional `player` property accessed before initialization on new API path
5. Fix: Guard against nil player, defer initialization
6. Test: test_play_whenPlayerNil_shouldNotCrash()
7. Deploy hotfix, monitor crash-free rate
```
