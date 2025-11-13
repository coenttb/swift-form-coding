// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "swift-form-coding",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "FormCoding", targets: ["FormCoding"])
    ],
    traits: [
        .trait(
            name: "URLRouting",
            description: "URLRouting integration for FormCoding"
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/coenttb/swift-url-form-coding",
            from: "0.1.0",
            traits: [.trait(name: "URLRouting", condition: .when(traits: ["URLRouting"]))]
        ),
        .package(
            url: "https://github.com/coenttb/swift-multipart-form-coding",
            from: "0.1.0",
            traits: [.trait(name: "URLRouting", condition: .when(traits: ["URLRouting"]))]
        )
    ],
    targets: [
        .target(
            name: "FormCoding",
            dependencies: [
                .product(
                    name: "URLFormCoding",
                    package: "swift-url-form-coding"
                ),
                .product(name: "MultipartFormCoding", package: "swift-multipart-form-coding"),
            ]
        ),
        .testTarget(
            name: "FormCoding Tests",
            dependencies: ["FormCoding"]
        )
    ]
)
