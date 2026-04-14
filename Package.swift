// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SharedKeychain",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "JSK-keychain-service",
            targets: ["SharedKeychainService"]
        ),
        .library(
            name: "SharedKeychainClient",
            targets: ["SharedKeychainClient"]
        )
    ],
    targets: [
        .target(name: "Shared"),
        .executableTarget(
            name: "SharedKeychainService",
            dependencies: ["Shared"]
        ),
        .target(
            name: "SharedKeychainClient",
            dependencies: ["Shared"]
        )
    ]
)
