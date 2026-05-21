// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapgoCapacitorAuto",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapgoCapacitorAuto",
            targets: ["AutoPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "AutoPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/AutoPlugin"),
        .testTarget(
            name: "AutoPluginTests",
            dependencies: ["AutoPlugin"],
            path: "ios/Tests/AutoPluginTests")
    ]
)
