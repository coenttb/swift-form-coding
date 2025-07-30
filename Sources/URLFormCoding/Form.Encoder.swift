// https://github.com/pointfreeco/swift-web/tree/main/Sources/UrlFormEncoding

import Foundation
import PointFreeURLFormCoding

/// An encoder that converts Swift Codable types to URL-encoded form data.
///
/// `Form.Encoder` implements the `Encoder` protocol to provide seamless
/// conversion from Swift types to `application/x-www-form-urlencoded` format,
/// the standard format used by HTML forms and many web APIs.
///
/// ## Basic Usage
///
/// ```swift
/// struct User: Codable {
///     let name: String
///     let age: Int
///     let isActive: Bool
/// }
///
/// let encoder = Form.Encoder()
/// let user = User(name: "John Doe", age: 30, isActive: true)
/// let formData = try encoder.encode(user)
/// // Result: "name=John%20Doe&age=30&isActive=true"
/// ```
///
/// ## Configuration Options
///
/// The encoder supports various encoding strategies:
/// - **Date encoding**: ISO8601, seconds since 1970, milliseconds, custom formats
/// - **Data encoding**: Base64 or custom strategies
/// - **Array encoding**: Multiple strategies for handling arrays
///
/// ```swift
/// let encoder = Form.Encoder()
/// encoder.dateEncodingStrategy = .iso8601
/// encoder.dataEncodingStrategy = .base64
/// ```
///
/// ## Advanced Features
///
/// - Supports nested objects and arrays
/// - Configurable encoding strategies for different data types
/// - Thread-safe encoding operations
/// - Comprehensive error reporting
///
/// - Note: This encoder is designed to work with ``Form.Decoder`` for round-trip compatibility.
/// - Important: Ensure encoding strategies match your server's expected format.
extension Form {
    public typealias Encoder = PointFreeURLFormCoding.PointFreeFormEncoder
}
