// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "ExactAssociationKit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "ExactAssociationKit", targets: ["ExactAssociationKit"]),
        .executable(name: "ExactAssociationDemo", targets: ["ExactAssociationDemo"])
    ],
    dependencies: [
        .package(url: "https://github.com/rajatslakhina/association-transport-kit.git", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "ExactAssociationKit",
            dependencies: [
                .product(name: "AssociationTransportKit", package: "association-transport-kit")
            ],
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
        .executableTarget(
            name: "ExactAssociationDemo",
            dependencies: ["ExactAssociationKit"],
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
        .testTarget(
            name: "ExactAssociationKitTests",
            dependencies: ["ExactAssociationKit"]
        )
    ]
)
