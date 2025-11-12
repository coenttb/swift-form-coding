import Foundation
import RFC_2045
import RFC_2046
import RFC_7578
import Shared
import URLMultipartFormCoding
import URLRouting

// Helper extension for efficient string appending to Data
extension Data {
    fileprivate mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8, allowLossyConversion: false) {
            self.append(data)
        }
    }
}

// Error types for multipart encoding failures
private struct InvalidUTF8Error: Error, LocalizedError {
    var errorDescription: String? {
        "Failed to convert encoded form data to UTF-8 string"
    }
}

private struct InvalidFieldDataError: Error, LocalizedError {
    let fieldName: String
    var errorDescription: String? {
        "Failed to encode field '\(fieldName)' as UTF-8 data"
    }
}

/// A conversion that handles multipart/form-data encoding and decoding for URLRouting.
///
/// `MultipartFormCoding` provides a way to convert Codable Swift types to and from
/// multipart/form-data format, commonly used in web forms and file uploads.
/// It integrates seamlessly with URLRouting's conversion system.
///
/// ## Overview
///
/// This conversion uses a `Form.Decoder` for parsing incoming multipart data and
/// automatically generates proper multipart/form-data format when encoding Swift types.
/// Each instance generates a unique boundary string to separate multipart fields.
///
/// ## Usage with URLRouting
///
/// ```swift
/// struct User: Codable {
///     let name: String
///     let email: String
///     let isActive: Bool
/// }
///
/// // Create conversion for routing
/// let userConversion = Conversion.multipart(User.self)
///
/// // Use in route definition
/// Route {
///   Method.post
///   Path { "users" }
///   Body(userConversion)
/// }
/// ```
///
/// ## Custom Decoder Configuration
///
/// ```swift
/// let decoder = Form.Decoder()
/// decoder.parsingStrategy = .brackets
/// decoder.dateDecodingStrategy = .iso8601
///
/// let conversion = MultipartFormCoding(User.self, decoder: decoder)
/// ```
///
/// ## Content Type
///
/// The conversion automatically provides the correct `Content-Type` header value
/// including the boundary parameter required for multipart parsing.
///
/// - Note: Each instance generates a unique boundary to prevent conflicts.
/// - Important: The `apply` method expects URL-encoded form data, not actual multipart data.
///   For true multipart parsing, use ``Multipart.FileUpload.Conversion``.
extension Multipart {
    public struct Conversion<Value: Codable> {
        /// The URL form decoder used for parsing input data.
        public let decoder: Form.Decoder
        public let encoder: Form.Encoder

        /// The unique boundary string used to separate multipart fields.
        public let boundary: String

        /// Creates a new multipart form coding conversion.
        ///
        /// - Parameters:
        ///   - type: The Codable type to convert to/from
        ///   - decoder: Custom URL form decoder (optional, uses default if not provided)
        ///   - encoder: Custom URL form encoder (optional, uses default if not provided)
        public init(
            _ type: Value.Type,
            decoder: Form.Decoder = .init(),
            encoder: Form.Encoder = .init()
        ) {
            self.decoder = decoder
            self.encoder = encoder
            // Use RFC 2046's boundary generation for RFC compliance
            self.boundary = RFC_2046.Multipart.generateBoundary()
        }

        /// The Content-Type header value for multipart/form-data requests.
        ///
        /// Returns a string in the format: `multipart/form-data; boundary=<unique-boundary>`
        ///
        /// Use this value when setting HTTP headers for multipart requests.
        public var contentType: String {
            "multipart/form-data; boundary=\(boundary)"
        }
    }
}

extension Multipart.Conversion: URLRouting.Conversion {
    /// Converts multipart form data to a Swift value.
    ///
    /// - Parameter input: The form data to decode (URL-encoded format)
    /// - Returns: The decoded Swift value
    /// - Throws: `Form.Decoder.Error` if the data cannot be decoded
    ///
    /// - Note: This method expects URL-encoded data, not raw multipart data.
    ///   For parsing actual multipart data, use ``Multipart.FileUpload.Conversion``.
    public func apply(_ input: Data) throws -> Value {
        try decoder.decode(Value.self, from: input)
    }

    /// Converts a Swift value to multipart form data.
    ///
    /// This method serializes the Swift value to URL-encoded format, then converts each field
    /// to an RFC 2046 body part using RFC 7578 form-data conventions.
    ///
    /// - Parameter output: The Swift value to encode
    /// - Returns: The multipart form data as `Data`
    /// - Throws: An error if encoding fails
    ///
    /// ## RFC Compliance
    ///
    /// Uses RFC 2046 for multipart structure and RFC 7578 for form-data specifics:
    /// - Boundary generation via RFC 2046
    /// - Content-Disposition escaping via RFC 7578
    /// - Proper multipart rendering via RFC 2046
    public func unapply(_ output: Value) throws -> Foundation.Data {
        // Encode the value to URL-encoded form data
        let fieldData = try encoder.encode(output)

        // Convert URL-encoded data to string
        guard let urlEncodedString = String(data: fieldData, encoding: .utf8) else {
            throw InvalidUTF8Error()
        }

        // Parse URL-encoded string into key-value pairs
        let pairs = urlEncodedString.split(separator: "&")

        // Create RFC 2046 body parts for each field
        var bodyParts: [RFC_2046.BodyPart] = []

        for pair in pairs {
            let components = pair.split(separator: "=", maxSplits: 1)
            guard components.count == 2 else { continue }

            let encodedKey = String(components[0])
            let encodedValue = String(components[1])

            // URL decode both key and value (handle + to space first, then percent decoding)
            // Order matters: + represents space in URL encoding, %2B represents literal +
            let decodedKey =
                encodedKey
                .replacingOccurrences(of: "+", with: " ")
                .removingPercentEncoding ?? encodedKey

            let decodedValue =
                encodedValue
                .replacingOccurrences(of: "+", with: " ")
                .removingPercentEncoding ?? encodedValue

            // Create form field value data
            guard let valueData = decodedValue.data(using: .utf8) else {
                throw InvalidFieldDataError(fieldName: decodedKey)
            }

            // Sanitize field name to prevent header injection (CR/LF removal)
            let sanitizedName = decodedKey
                .replacingOccurrences(of: "\r", with: "")
                .replacingOccurrences(of: "\n", with: "")

            // Use RFC 7578 Content-Disposition escaping
            let contentDisposition = RFC_7578.FormData.escapeContentDisposition(name: sanitizedName)

            // Create RFC 2046 body part with proper headers
            let part = RFC_2046.BodyPart(
                headers: [
                    "Content-Disposition": contentDisposition,
                    "Content-Type": "text/plain"
                ],
                content: valueData
            )

            bodyParts.append(part)
        }

        // Use RFC 2046 to construct the multipart message
        guard !bodyParts.isEmpty else {
            // Empty body case
            return Data()
        }

        let multipart = try RFC_2046.Multipart(
            subtype: .formData,
            parts: bodyParts,
            boundary: boundary
        )

        // Render using RFC 2046's render method
        let rendered = multipart.render()
        return Data(rendered.utf8)
    }
}
