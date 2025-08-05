import Foundation
import Shared
import URLMultipartFormCoding
import URLRouting

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
        
        /// The unique boundary string used to separate multipart fields.
        public let boundary: String
        
        /// Creates a new multipart form coding conversion.
        ///
        /// - Parameters:
        ///   - type: The Codable type to convert to/from
        ///   - decoder: Custom URL form decoder (optional, uses default if not provided)
        public init(
            _ type: Value.Type,
            decoder: Form.Decoder = .init()
        ) {
            self.decoder = decoder
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
    /// This method serializes the Swift value to JSON, then converts each field
    /// to a multipart form field with appropriate headers and boundaries.
    ///
    /// - Parameter output: The Swift value to encode
    /// - Returns: The multipart form data as `Data`
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
    public func unapply(_ output: Value) -> Foundation.Data {
        var body = Data()
        
        let encoder = JSONEncoder()
        guard let fieldData = try? encoder.encode(output),
              var fields = try? JSONSerialization.jsonObject(with: fieldData) as? [String: Any] else {
            return body
        }
        
        // Remove null values
        fields = fields.filter { $0.value is NSNull == false }
        
        for (key, value) in fields {
            let field = Multipart.FormField(
                name: key,
                contentType: "text/plain",
                data: String(describing: value).data(using: .utf8) ?? Data()
            )
            
            // Append boundary
            body.append("--\(boundary)\r\n")
            
            // Add Content-Disposition header
            var disposition = "Content-Disposition: form-data; name=\"\(field.name)\""
            if let filename = field.filename {
                disposition += "; filename=\"\(filename)\""
            }
            body.append("\(disposition)\r\n")
            
            // Add Content-Type if specified
            if let contentType = field.contentType {
                body.append("Content-Type: \(contentType)\r\n")
            }
            
            // Add empty line before content
            body.append("\r\n")
            
            // Add field data
            body.append(field.data)
            body.append("\r\n")
        }
        
        // Final boundary
        body.append("--\(boundary)--\r\n")
        return body
    }
}
