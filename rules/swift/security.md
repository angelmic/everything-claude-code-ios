---
paths:
  - "**/*.swift"
  - "**/Package.swift"
---
# Swift Security

> This file extends [common/security.md](../common/security.md) with Swift specific content.

## Secret Management

- Use **Keychain Services** for sensitive data (tokens, passwords, keys) — never `UserDefaults`
- Use environment variables or `.xcconfig` files for build-time secrets
- Never hardcode secrets in source — decompilation tools extract them trivially

```swift
let apiKey = ProcessInfo.processInfo.environment["API_KEY"]
guard let apiKey, !apiKey.isEmpty else {
    fatalError("API_KEY not configured")
}
```

### Keychain Services Example

```swift
// Save to Keychain
let tokenData = token.data(using: .utf8)!
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "auth-token",
    kSecValueData as String: tokenData,
    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
]
SecItemDelete(query as CFDictionary) // Remove existing
let status = SecItemAdd(query as CFDictionary, nil)
guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }

// Read from Keychain
let searchQuery: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "auth-token",
    kSecReturnData as String: true,
    kSecMatchLimit as String: kSecMatchLimitOne
]
var result: AnyObject?
let readStatus = SecItemCopyMatching(searchQuery as CFDictionary, &result)
guard readStatus == errSecSuccess, let data = result as? Data else { return nil }
```

### Secure Enclave for Cryptographic Keys

Use the Secure Enclave for keys that should never leave the device:

```swift
let access = SecAccessControlCreateWithFlags(
    nil,
    kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    .privateKeyUsage,
    nil
)!

let attributes: [String: Any] = [
    kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
    kSecAttrKeySizeInBits as String: 256,
    kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
    kSecPrivateKeyAttrs as String: [
        kSecAttrIsPermanent as String: true,
        kSecAttrAccessControl as String: access
    ]
]
var error: Unmanaged<CFError>?
guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
    throw error!.takeRetainedValue() as Error
}
```

## Biometric Authentication

Use `LAContext` for biometric gates. Never use biometrics as the sole security factor — always combine with Keychain:

```swift
import LocalAuthentication

let context = LAContext()
var error: NSError?
guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
    // Biometrics not available — fall back to passcode
    return
}

do {
    let success = try await context.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics,
        localizedReason: "Authenticate to access your account"
    )
    if success { unlockApp() }
} catch {
    handleAuthError(error)
}
```

## Transport Security

- App Transport Security (ATS) is enforced by default — do not disable it
- Use certificate pinning for critical endpoints
- Validate all server certificates

## Input Validation

- Sanitize all user input before display to prevent injection
- Use `URL(string:)` with validation rather than force-unwrapping
- Validate data from external sources (APIs, deep links, pasteboard) before processing

### Deep Link Validation

Always validate deep link URLs before navigating:

```swift
func handleDeepLink(_ url: URL) -> Bool {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
          let host = components.host,
          allowedHosts.contains(host) else {
        return false // Reject unknown schemes/hosts
    }
    // Validate and sanitize parameters before use
    let params = components.queryItems?.reduce(into: [String: String]()) { dict, item in
        dict[item.name] = item.value?.removingPercentEncoding
    } ?? [:]
    return routeTo(host: host, params: params)
}
```

### Pasteboard Security

```swift
// Set expiration on sensitive pasteboard content
let item = [UIPasteboard.OptionKey.expirationDate: Date().addingTimeInterval(60)]
UIPasteboard.general.setItems([[kUTTypePlainText as String: sensitiveText]], options: item)

// Clear pasteboard when app backgrounds
NotificationCenter.default.addObserver(
    forName: UIApplication.didEnterBackgroundNotification,
    object: nil, queue: .main
) { _ in
    if UIPasteboard.general.hasStrings {
        UIPasteboard.general.string = ""
    }
}
```

## OWASP Mobile Top 10 Checklist

- [ ] M1 — Improper credential storage (use Keychain, never UserDefaults)
- [ ] M2 — Insufficient transport security (enforce ATS, pin certificates)
- [ ] M3 — Insecure authentication (validate tokens server-side)
- [ ] M4 — Insufficient input validation (sanitize all external input)
- [ ] M5 — Insecure communication (no plain HTTP)
- [ ] M6 — Insufficient privacy controls (respect user consent, minimize data collection)
- [ ] M7 — Insufficient binary protections (enable bitcode, strip debug symbols)
- [ ] M8 — Security misconfiguration (review entitlements, disable debug in release)
- [ ] M9 — Insecure data storage (encrypt files, use Data Protection)
- [ ] M10 — Insufficient cryptography (use Apple CryptoKit, no custom crypto)
