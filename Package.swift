// swift-tools-version:6.0

import PackageDescription

extension String {
    static let shared: Self = "Shared"
    static let urlFormCoding: Self = "URLFormCoding"
    static let urlFormCodingURLRouting: Self = "URLFormCodingURLRouting"
    static let multipartURLFormCoding: Self = "URLMultipartFormCoding"
    static let multipartURLFormCodingURLRouting: Self = "URLMultipartFormCodingURLRouting"
}

extension Target.Dependency {
    static var shared: Self { .target(name: .shared) }
    static var urlFormCoding: Self { .target(name: .urlFormCoding) }
    static var urlFormCodingURLRouting: Self { .target(name: .urlFormCodingURLRouting) }
    static var multipartURLFormCoding: Self { .target(name: .multipartURLFormCoding) }
    static var multipartURLFormCodingURLRouting: Self { .target(name: .multipartURLFormCodingURLRouting) }
    static var rfc2045: Self { .product(name: "RFC 2045", package: "swift-rfc-2045") }
    static var rfc2046: Self { .product(name: "RFC 2046", package: "swift-rfc-2046") }
    static var rfc7578: Self { .product(name: "RFC 7578", package: "swift-rfc-7578") }
    static var pointfreeUrlFormCoding: Self { .product(name: "PointFreeURLFormCoding", package: "pointfree-url-form-coding") }
    static var dependencies: Self { .product(name: "Dependencies", package: "swift-dependencies") }
    static var dependenciesTestSupport: Self { .product(name: "DependenciesTestSupport", package: "swift-dependencies") }
    static var urlRouting: Self { .product(name: "URLRouting", package: "swift-url-routing") }
}

let package = Package(
    name: "swift-url-form-coding",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: .urlFormCoding, targets: [.urlFormCoding]),
        .library(name: .urlFormCodingURLRouting, targets: [.urlFormCodingURLRouting]),
        .library(name: .multipartURLFormCoding, targets: [.multipartURLFormCoding]),
        .library(name: .multipartURLFormCodingURLRouting, targets: [.multipartURLFormCodingURLRouting])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-rfc-2045", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2046", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-7578", from: "0.2.0"),
        .package(url: "https://github.com/coenttb/pointfree-url-form-coding.git", from: "0.5.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.1.5"),
        .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.6.0")
    ],
    targets: [
        .target(
            name: .shared,
            dependencies: [
                .pointfreeUrlFormCoding
            ]
        ),
        .target(
            name: .urlFormCoding,
            dependencies: [
                .shared,
                .urlFormCodingURLRouting,
                .multipartURLFormCoding,
                .multipartURLFormCodingURLRouting
            ]
        ),
        .testTarget(
            name: .urlFormCoding.tests,
            dependencies: [
                .urlFormCoding,
                .multipartURLFormCoding,
                .multipartURLFormCodingURLRouting
            ]
        ),
        .target(
            name: .urlFormCodingURLRouting,
            dependencies: [
                .urlRouting,
                .shared
            ]
        ),
        .testTarget(
            name: .urlFormCodingURLRouting.tests,
            dependencies: [
                .urlFormCoding,
                .urlFormCodingURLRouting,
                .dependenciesTestSupport
            ]
        ),
        .target(
            name: .multipartURLFormCoding,
            dependencies: [
                .rfc2045,
                .rfc2046,
                .rfc7578,
                .urlRouting,
                .shared
            ]
        ),
        .testTarget(
            name: .multipartURLFormCoding.tests,
            dependencies: [
                .urlFormCoding,
                .multipartURLFormCoding,
                .dependenciesTestSupport
            ]
        ),
        .target(
            name: .multipartURLFormCodingURLRouting,
            dependencies: [
                .multipartURLFormCoding,
                .urlRouting,
                .shared
            ]
        ),
        .testTarget(
            name: .multipartURLFormCodingURLRouting.tests,
            dependencies: [
                .urlFormCoding,
                .multipartURLFormCodingURLRouting,
                .dependenciesTestSupport
            ]
        )
    ]
)

extension String { var tests: Self { self + " Tests" } }
