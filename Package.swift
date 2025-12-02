// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SubscriptionKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "SubscriptionKit",
            targets: ["SubscriptionKit"]
        ),
    ],
    targets: [
        .target(
            name: "SubscriptionKit",
            dependencies: [],
            path: "Sources/SubscriptionKit"
        ),
        .testTarget(
            name: "SubscriptionKitTests",
            dependencies: ["SubscriptionKit"],
            path: "Tests/SubscriptionKitTests"
        ),
    ]
)
