// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "MyClient",
    products: [
        .library(name: "MyClient", targets: ["MyClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SamBallantyne/EventIdProvider.git",
                 from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "MyClient",
            dependencies: [
                .byName(name: "EventIdProvider")
            ]),
    ]
)
