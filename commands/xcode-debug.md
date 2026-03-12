---
description: Xcode debugging — scheme exploration, simulator management, DerivedData cleanup, and build diagnostics.
---

# Xcode Debug

## Scheme Exploration

List available schemes and destinations:

```bash
# List schemes
xcodebuild -list

# List available simulators
xcrun simctl list devices available

# List booted simulators
xcrun simctl list devices booted
```

## Simulator Management

```bash
# Boot a simulator
xcrun simctl boot "iPhone 16"

# Shutdown all simulators
xcrun simctl shutdown all

# Erase a simulator (factory reset)
xcrun simctl erase <device-id>

# Install app on simulator
xcrun simctl install booted path/to/app.app

# Open URL in simulator
xcrun simctl openurl booted "myapp://deeplink"

# Take screenshot
xcrun simctl io booted screenshot output.png

# Record video
xcrun simctl io booted recordVideo output.mp4
```

## DerivedData Cleanup

```bash
# Remove DerivedData (safe — will be rebuilt)
rm -rf ~/Library/Developer/Xcode/DerivedData

# Remove specific project's DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/<ProjectName>-*

# Clear module cache
rm -rf "$(getconf DARWIN_USER_CACHE_DIR)/org.llvm.clang/ModuleCache"

# Clear SPM cache
rm -rf ~/Library/Caches/org.swift.swiftpm
```

## Build Diagnostics

```bash
# Build with verbose output
xcodebuild build -scheme <scheme> -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1

# Show build settings
xcodebuild -scheme <scheme> -showBuildSettings

# Build timing summary
xcodebuild build -scheme <scheme> -destination 'platform=iOS Simulator,name=iPhone 16' OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-function-bodies" 2>&1 | grep -E '^\d+\.\d+ms'

# Check for SPM dependency issues
swift package resolve
swift package show-dependencies
```

## Common Issues

| Issue | Solution |
|-------|----------|
| "No such module" | Clean DerivedData, `swift package resolve` |
| Simulator won't boot | `xcrun simctl shutdown all`, then boot again |
| Code signing error | Check signing certificate and provisioning profile |
| Swift version mismatch | Check `SWIFT_VERSION` build setting |
| "Command PhaseScriptExecution failed" | Check Build Phases run scripts |
