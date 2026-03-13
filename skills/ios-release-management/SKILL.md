# iOS Release Management

## When to Use

Use this skill during iOS/tvOS release workflows, triggered by `/ios-release` or when the user requests a build and upload to TestFlight or App Store.

## Build Target Matrix

| Target | Platform | Make Command |
|--------|----------|--------------|
| TestFlight | iOS | `make iosbuildtf` |
| TestFlight | tvOS | `make tvosbuildtf` |
| App Store | iOS | `make iosbuildstore` |
| App Store | tvOS | `make tvosbuildstore` |
| Test | All | `make test` |

**These are the ONLY allowed build commands.** Never substitute with `xcodebuild`, `fastlane`, or any other alternative.

## Mandatory Rules

1. **tvOS build prompt**: `"App with name CATCHPLAY-tvOS not found, create one? (y/n)"` → always answer **`n`**
2. **Both mode order**: tvOS first, then iOS
3. **Build failure**: stop immediately, do not continue to next platform

## Environment Requirements

- Run `unset DEVELOPER_DIR` before any build command
- All build commands require **1800000ms timeout** (30 minutes)
- Prefix every make command with `unset DEVELOPER_DIR &&`

## Version Management

Version numbers are stored in Fastlane environment files:

| Platform | File | Field |
|----------|------|-------|
| iOS | `fastlane/.env.ios` | `APP_VERSION` |
| tvOS | `fastlane/.env.tvos` | `APP_VERSION` |

Before building, verify that `APP_VERSION` matches the intended release version.

## 2FA Handling

Fastlane may trigger Apple ID 2FA during upload. When the build output shows a 2FA prompt:
1. Immediately notify the user
2. Wait for the user to provide the verification code
3. Pass the code to the running process

## Dry Run

The `/ios-release --dry-run` flag runs through all validation steps (version check, .env alignment, optional test) but stops before actual build execution. Useful for verifying configuration without uploading.

## Reference

See `/ios-release` command for the full interactive workflow.
