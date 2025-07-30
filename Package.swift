// swift-tools-version:5.9

import PackageDescription

extension String {
    static let urlFormCoding: Self = "URLFormCoding"
}

extension Target.Dependency {
    static var urlFormCoding: Self { .target(name: .urlFormCoding) }
    static var pointfreeUrlFormCoding: Self { .product(name: "PointFreeURLFormCoding", package: "pointfree-url-form-coding") }
}

let package = Package(
    name: "swift-url-form-coding",
    products: [
        .library(name: .urlFormCoding, targets: [.urlFormCoding])
    ],
    dependencies: [
        .package(url: "https://github.com/coenttb/pointfree-url-form-coding.git", from: "0.0.1")
    ],
    targets: [
        .target(
            name: .urlFormCoding,
            dependencies: [
                .pointfreeUrlFormCoding
            ]
        ),
        .testTarget(
            name: .urlFormCoding.tests,
            dependencies: [
                .urlFormCoding
            ]
        )
    ]
)

extension String { var tests: Self { self + " Tests" } }
