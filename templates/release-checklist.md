# Release Checklist

## Release: v[X.Y.Z]
**Date**: [YYYY-MM-DD]
**Release Manager**: [Name]

---

## Pre-Release

### Code Quality
- [ ] All feature branches merged to release branch
- [ ] No open CRITICAL or HIGH code review issues
- [ ] Test coverage ≥ 80%
- [ ] All CI checks pass

### Version
- [ ] MARKETING_VERSION bumped to [X.Y.Z]
- [ ] CURRENT_PROJECT_VERSION incremented
- [ ] Changelog updated

### Testing
- [ ] Full regression test suite passed
- [ ] Smoke test on physical device (iPhone)
- [ ] Smoke test on physical device (iPad) — if applicable
- [ ] Smoke test on Apple TV — if tvOS app
- [ ] Smoke test on Mac — if macOS app
- [ ] Test on oldest supported OS version
- [ ] Test on latest OS version
- [ ] Performance test: launch time within budget
- [ ] Performance test: memory usage within budget
- [ ] Accessibility audit passed (`/accessibility-check`)

### Localization
- [ ] All user-facing strings localized
- [ ] String translations reviewed
- [ ] RTL layout verified (if applicable)

---

## Build & Submit

### Archive
- [ ] Archive build succeeds
- [ ] No compiler warnings in release configuration
- [ ] dSYM files generated and archived

### Signing & Entitlements
- [ ] Code signing identity valid
- [ ] Provisioning profile valid and not expiring soon
- [ ] Entitlements match expected capabilities

### App Store Connect
- [ ] App metadata updated
- [ ] What's New text updated
- [ ] Screenshots updated (if UI changed)
- [ ] Privacy manifest (PrivacyInfo.xcprivacy) current
- [ ] App Review notes updated (if needed)
- [ ] Submit for review

---

## Post-Release

### Monitoring (First 48 Hours)
- [ ] Crash-free rate ≥ 99.5%
- [ ] No P0 crashes reported
- [ ] App Store reviews monitored
- [ ] Performance metrics normal (MetricKit)

### Documentation
- [ ] Release tagged in git: `git tag -a vX.Y.Z -m "Release X.Y.Z"`
- [ ] Release notes published
- [ ] Internal documentation updated
- [ ] Related JIRA issues closed

### Communication
- [ ] Team notified of release
- [ ] Stakeholders notified
- [ ] Release branch merged back to main (if applicable)
