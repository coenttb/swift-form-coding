import Foundation
import Parsing
import UrlFormCoding
import URLRouting

public struct MultipartFormField {
    let name: String
    let filename: String?
    let contentType: String?
    let data: Data

    public init(
        name: String,
        filename: String? = nil,
        contentType: String? = nil,
        data: Data
    ) {
        self.name = name
        self.filename = filename
        self.contentType = contentType
        self.data = data
    }
}

public struct MultipartFormCoding<Value: Codable>: Conversion {
    public let decoder: UrlFormDecoder
    private let boundary: String

    public init(
        _ type: Value.Type,
        decoder: UrlFormDecoder = .init()
    ) {
        self.decoder = decoder
        self.boundary = "Boundary-\(UUID().uuidString)"
    }

    public var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    public func apply(_ input: Data) throws -> Value {
        try decoder.decode(Value.self, from: input)
    }

    public func unapply(_ output: Value) -> Data {
        var body = Data()

        let encoder = JSONEncoder()
        guard let fieldData = try? encoder.encode(output),
              var fields = try? JSONSerialization.jsonObject(with: fieldData) as? [String: Any] else {
            return body
        }

        // Remove null values
        fields = fields.filter { $0.value is NSNull == false }

        for (key, value) in fields {
            let field = MultipartFormField(
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

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}

// MARK: - Conversion Extension
extension Conversion {
    @inlinable
    public static func multipart<Value: Codable>(
        _ type: Value.Type,
        decoder: UrlFormDecoder = .init()
    ) -> Self where Self == MultipartFormCoding<Value> {
        .init(type, decoder: decoder)
    }
}

extension Conversion {
    @inlinable
    public func multipart<Value: Codable>(
        _ type: Value.Type,
        decoder: UrlFormDecoder = .init()
    ) -> Conversions.Map<Self, MultipartFormCoding<Value>> {
        self.map(.multipart(type, decoder: decoder))
    }
}
