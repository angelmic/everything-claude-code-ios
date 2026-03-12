---
description: iOS release workflow — version bump, changelog generation, and release checklist.
---

# iOS Release

Manage the iOS/tvOS release process.

## Version Bump

### Semantic Versioning
```bash
# Read current version
grep -r "MARKETING_VERSION" *.xcodeproj/project.pbxproj | head -1

# For SPM packages
grep '"version"' Package.swift
```

### Bump Types
- **Major** (X.0.0): Breaking changes, major features
- **Minor** (x.Y.0): New features, backward compatible
- **Patch** (x.y.Z): Bug fixes, performance improvements

## Changelog Generation

Generate changelog from git history since last release:

```bash
# Find last release tag
git describe --tags --abbrev=0

# Generate changelog
git log $(git describe --tags --abbrev=0)..HEAD --pretty=format:"- %s (%h)" --no-merges
```

### Changelog Format
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New feature description

### Changed
- Modified behavior description

### Fixed
- Bug fix description

### Removed
- Removed feature description
```

## Release Checklist

### Pre-Release
- [ ] All tests pass (`xcodebuild test` or `swift test`)
- [ ] No CRITICAL or HIGH code review issues
- [ ] Version number bumped
- [ ] Changelog updated
- [ ] Release branch created (if applicable)
- [ ] Accessibility audit passed (`/accessibility-check`)

### Build & Sign
- [ ] Archive build succeeds
- [ ] Code signing valid
- [ ] Entitlements correct
- [ ] App thinning report reviewed

### Testing
- [ ] Smoke test on physical device
- [ ] Regression test on oldest supported OS version
- [ ] Performance test (launch time, memory)
- [ ] Localization verified for all supported languages

### Submission
- [ ] App Store metadata updated
- [ ] Screenshots updated (if UI changed)
- [ ] Privacy manifest (PrivacyInfo.xcprivacy) updated
- [ ] Submit for review

### Post-Release
- [ ] Tag release in git
- [ ] Update release notes (use `confluence` toolSpec if available)
- [ ] Monitor crash reports (use `crashlytics` toolSpec if available)
- [ ] Close related issues (use `jira` skill if available)

## Integration Points
- **`jira` skill** — close release issues, update GISS status
- **`confluence` toolSpec** — update Release Note page
- **`crashlytics` toolSpec** — monitor post-release crashes
