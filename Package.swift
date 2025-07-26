// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let urlRoutingMultipart: Self = "URLRouting+Multipart"
    static let urlRoutingForm: Self = "URLRouting+Form"
    static let urlFormCoding: Self = "UrlFormCoding"
}

extension Target.Dependency {
    static var urlRoutingMultipart: Self { .target(name: .urlRoutingMultipart) }
    static var urlRoutingForm: Self { .target(name: .urlRoutingForm) }
    static var urlFormCoding: Self { .target(name: .urlFormCoding) }
}

extension Target.Dependency {
    static var dependencies: Self { .product(name: "Dependencies", package: "swift-dependencies") }
    static var dependenciesTestSupport: Self { .product(name: "DependenciesTestSupport", package: "swift-dependencies") }
    static var parsing: Self { .product(name: "Parsing", package: "swift-parsing") }
    static var urlRouting: Self { .product(name: "URLRouting", package: "swift-url-routing") }
}

let package = Package(
    name: "swift-urlrouting-multipart",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: .urlRoutingMultipart, targets: [.urlRoutingMultipart]),
        .library(name: .urlRoutingForm, targets: [.urlRoutingForm]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.1.5"),
        .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.6.0"),
    ],
    targets: [
        .target(
            name: .urlFormCoding,
            dependencies: []
        ),
        .testTarget(
            name: .urlFormCoding.tests,
            dependencies: [
                .urlFormCoding,
                .dependenciesTestSupport
            ]
        ),
        .target(
            name: .urlRoutingMultipart,
            dependencies: [
                .dependencies,
                .urlRouting,
                .urlFormCoding,
            ]
        ),
        .testTarget(
            name: .urlRoutingMultipart.tests,
            dependencies: [
                .urlRoutingMultipart,
                .dependenciesTestSupport
            ]
        ),
        .target(
            name: .urlRoutingForm,
            dependencies: [
                .dependencies,
                .urlRouting,
                .urlFormCoding,
            ]
        ),
        .testTarget(
            name: .urlRoutingForm.tests,
            dependencies: [
                .urlRoutingMultipart,
                .dependenciesTestSupport
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String { var tests: Self { self + " Tests" } }
