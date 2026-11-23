// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SpelunkrCore",
    platforms: [.macOS(.v15), .tvOS(.v18)],
    products: [.library(name: "SpelunkrCore", targets: ["SpelunkrCore"])],
    targets: [
        .target(name: "SpelunkrCore"),
        .testTarget(name: "SpelunkrCoreTests", dependencies: ["SpelunkrCore"], resources: [.copy("Fixtures")])
    ]
)
