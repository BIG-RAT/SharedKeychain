# SharedKeychain

A macOS XPC-based keychain service that enables multiple applications to share secure keychain access across app boundaries via a privileged background daemon.

## Overview

SharedKeychain consists of two components:

- **`JSK-keychain-service`** — a LaunchAgent daemon that mediates all keychain operations over XPC
- **`SharedKeychainClient`** — a Swift library that apps link against to communicate with the service

Because the daemon holds the necessary keychain entitlements, client apps can read and write shared keychain items without requiring each app to be individually provisioned with keychain access group entitlements.

## Requirements

- macOS 13 or later
- Xcode 15 / Swift 5.9+

## Architecture

```
Your App
  └── SharedKeychainClient (library)
        └── NSXPCConnection (Mach service: com.jamf.ie.sharedkeychain)
              └── JSK-keychain-service (daemon)
                    └── Security framework / Keychain
```

The client communicates with the daemon over a named Mach service. The daemon exports a `SharedKeychainProtocol` XPC interface and performs all `Security` framework calls on behalf of callers.

## Installation

### Swift Package Manager

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "<repo-url>", from: "<version>")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["SharedKeychainClient"]
    )
]
```

### LaunchAgent

Install the daemon so it runs at login:

```bash
cp Support/LaunchAgent/com.jamf.ie.sharedkeychain.plist ~/Library/LaunchAgents/
cp .build/release/JSK-keychain-service /usr/local/bin/
launchctl load ~/Library/LaunchAgents/com.jamf.ie.sharedkeychain.plist
```

The plist registers the Mach service `com.jamf.ie.sharedkeychain` and keeps the daemon alive.

## Usage

```swift
import SharedKeychainClient

let keychain = SharedKeychainClient.shared

// Store a password
try await keychain.setPassword(
    service: "com.example.myapp",
    account: "user@example.com",
    password: "s3cr3t"
)

// Retrieve a password
if let password = try await keychain.getPassword(
    service: "com.example.myapp",
    account: "user@example.com"
) {
    print("Password: \(password)")
}

// Retrieve a password and its metadata
if let item = try await keychain.getItem(
    service: "com.example.myapp",
    account: "user@example.com"
) {
    print("Password: \(item["password"] ?? "")")
    print("Comment:  \(item["comment"] ?? "")")
}

// Delete a password
try await keychain.deletePassword(
    service: "com.example.myapp",
    account: "user@example.com"
)
```

### Access Groups

Pass an `accessGroup` to target a specific keychain access group:

```swift
try await keychain.setPassword(
    service: "com.example.myapp",
    account: "user@example.com",
    password: "s3cr3t",
    accessGroup: "483DWKW443.jamfie.SharedJSK"
)
```

Supported access groups are defined in `JSK-keychain-service.entitlements`.

## Package Structure

```
Sources/
├── Shared/
│   └── Protocol.swift          # SharedKeychainProtocol (XPC interface)
├── SharedKeychainClient/
│   └── Client.swift            # Client library — link this into your app
└── SharedKeychainService/
    ├── main.swift              # XPC listener entry point
    ├── Service.swift           # Keychain operations implementation
    ├── CallerVerifier.swift    # Connection authorization hook
    └── JSK-keychain-service.entitlements
Support/
└── LaunchAgent/
    └── com.jamf.ie.sharedkeychain.plist
```

## Building

```bash
swift build -c release
```

The built daemon binary will be at `.build/release/JSK-keychain-service`.

## License

Copyright 2026, Jamf
