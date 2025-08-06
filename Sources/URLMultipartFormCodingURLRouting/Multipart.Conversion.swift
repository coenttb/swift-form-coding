import Foundation
import Shared
import URLMultipartFormCoding
import URLRouting

// Helper extension for efficient string appending to Data
private extension Data {
    mutating func appendString(_ string: String) {
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
            // Use UUID for boundary generation - provides 36 characters of uniqueness
            // Format: "Boundary-UUID" where UUID is 36 chars (including hyphens)
            // This gives us a boundary that's highly unlikely to appear in content
            self.boundary = "Boundary-\(UUID().uuidString)"
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
    /// to a multipart form field with appropriate headers and boundaries.
    ///
    /// - Parameter output: The Swift value to encode
    /// - Returns: The multipart form data as `Data`
    /// - Throws: An error if encoding fails
    ///
    /// ## Multipart Format
    ///
    /// The generated data follows RFC 7578 multipart/form-data format:
    /// ```
    /// --Boundary-<UUID>
    /// Content-Disposition: form-data; name="fieldName"
    /// Content-Type: text/plain
    ///
    /// fieldValue
    /// --Boundary-<UUID>--
    /// ```
    public func unapply(_ output: Value) throws -> Foundation.Data {
        var body = Data()
        
        // Encode the value to URL-encoded form data
        let fieldData = try encoder.encode(output)
        
        // Convert URL-encoded data to string
        guard let urlEncodedString = String(data: fieldData, encoding: .utf8) else {
            throw InvalidUTF8Error()
        }
        
        // Parse URL-encoded string into key-value pairs
        let pairs = urlEncodedString.split(separator: "&")
        
        for pair in pairs {
            let components = pair.split(separator: "=", maxSplits: 1)
            guard components.count == 2 else { continue }
            
            let encodedKey = String(components[0])
            let encodedValue = String(components[1])
            
            // URL decode both key and value (handle percent encoding first, then + to space)
            let decodedKey = encodedKey
                .removingPercentEncoding?
                .replacingOccurrences(of: "+", with: " ") ?? encodedKey
            
            let decodedValue = encodedValue
                .removingPercentEncoding?
                .replacingOccurrences(of: "+", with: " ") ?? encodedValue
            
            // Create form field
            guard let valueData = decodedValue.data(using: .utf8) else {
                throw InvalidFieldDataError(fieldName: decodedKey)
            }
            
            let field = Multipart.FormField(
                name: decodedKey,
                contentType: "text/plain",
                data: valueData
            )
            
            // Sanitize field name to prevent header injection
            let sanitizedName = field.name
                .replacingOccurrences(of: "\r", with: "")
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\"", with: "'")
            
            // Append boundary
            body.appendString("--\(boundary)\r\n")
            
            // Add Content-Disposition header
            var disposition = "Content-Disposition: form-data; name=\"\(sanitizedName)\""
            if let filename = field.filename {
                // Sanitize filename as well
                let sanitizedFilename = filename
                    .replacingOccurrences(of: "\r", with: "")
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "\"", with: "'")
                disposition += "; filename=\"\(sanitizedFilename)\""
            }
            body.appendString("\(disposition)\r\n")
            
            // Add Content-Type if specified
            if let contentType = field.contentType {
                body.appendString("Content-Type: \(contentType)\r\n")
            }
            
            // Add empty line before content
            body.appendString("\r\n")
            
            // Add field data
            body.append(field.data)
            body.appendString("\r\n")
        }
        
        // Final boundary
        if !pairs.isEmpty {
            body.appendString("--\(boundary)--\r\n")
        }
        return body
    }
}
