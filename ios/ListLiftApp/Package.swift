// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ListLiftApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "ListLiftApp", targets: ["ListLiftApp"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "ListLiftApp",
            resources: [
                .process("../Resources")
            ]
        )
    ]
)
