# iOS Release Management

## When to Use

Use this skill when managing an iOS/tvOS app release: version bumping, changelog, submission checklist, and post-release monitoring.

## How It Works

### Release Pipeline

```
Feature Freeze → RC Branch → QA → Version Bump → Changelog → Submit → Monitor
```

### Step 1: Feature Freeze
- Create release branch: `release/X.Y.Z`
- Only bug fixes allowed after this point
- Cherry-pick critical fixes from main

### Step 2: Version Bump
Update version in:
- Xcode project settings (MARKETING_VERSION, CURRENT_PROJECT_VERSION)
- Package.swift (if SPM library)
- Info.plist (if manual management)

### Step 3: Changelog
Generate from git history:
```bash
git log $(git describe --tags --abbrev=0)..HEAD --pretty=format:"- %s" --no-merges
```

Organize by category: Added, Changed, Fixed, Removed.

### Step 4: Release Checklist
See `/ios-release` command for full checklist.

### Step 5: Post-Release Monitoring
- **Crash rate**: Monitor via Crashlytics or Xcode Organizer
- **User reviews**: Check App Store Connect
- **Performance metrics**: MetricKit data

## Integration Points

- **`jira` skill** — GISS release tracking, close release issues
- **`confluence` toolSpec** — publish Release Notes
- **`crashlytics` toolSpec** — monitor crash-free rate
- **`/ios-release` command** — execute release steps

## Examples

### Standard Release
```
1. Create release/2.1.0 branch
2. Run QA regression suite
3. Bump MARKETING_VERSION to 2.1.0
4. Generate changelog from git log
5. Archive and submit to App Store Connect
6. Tag: git tag -a v2.1.0 -m "Release 2.1.0"
7. Monitor crash-free rate for 48 hours
```

### Hotfix Release
```
1. Branch from release tag: hotfix/2.1.1
2. Fix critical bug with TDD
3. Cherry-pick to main
4. Bump to 2.1.1, submit expedited review
5. Monitor crash-free rate
```
