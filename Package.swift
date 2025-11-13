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

#if swift(>=6.1) && swift(<6.3)
// workaround for error:
// error: exhausted attempts to resolve the dependencies graph, with the following dependencies unresolved:
// * 'swift-rfc-7578' from https://github.com/swift-standards/swift-rfc-7578.git
// * 'swift-url-routing' from https://github.com/pointfreeco/swift-url-routing
package.dependencies.append(contentsOf: [
    .package(url: "https://github.com/swift-standards/swift-rfc-7578", from: "0.1.0"),
    .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.1.0")
])
#endif



for target in package.targets {
    target.swiftSettings?.append(
        contentsOf: [
            .enableUpcomingFeature("MemberImportVisibility")
        ]
    )
}

//package.traits.insert(
//    .default(
//        enabledTraits: ["URLRouting"]
//    )
//)

