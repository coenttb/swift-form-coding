import Foundation
import URLRouting


extension DateFormatter {
    @MainActor public static let form: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

extension URLRouting.Field {
    public static func contentType(_ type: () -> Value) -> Self {
        Field("Content-Type") {
            type()
        }
    }
}

extension URLRouting.Field<String> {
    // Convenience properties for common Content-Type values
    @inlinable public static var applicationJSON: Self {
        Field.contentType { "application/json" }
    }

    @inlinable public static var json: Self {
        .applicationJSON
    }

    @inlinable public static var applicationFormURLEncoded: Self {
        Field.contentType { "application/x-www-form-urlencoded" }
    }

    @inlinable public static var formURLEncoded: Self {
        .applicationFormURLEncoded
    }

    @inlinable public static var multipartFormData: Self {
        Field.contentType { "multipart/form-data" }
    }

    @inlinable public static var textPlain: Self {
        Field.contentType { "text/plain" }
    }

    @inlinable public static var textHTML: Self {
        Field.contentType { "text/html" }
    }

    @inlinable public static var html: Self {
        .textHTML
    }

    @inlinable public static var applicationXML: Self {
        Field.contentType { "application/xml" }
    }

    @inlinable public static var xml: Self {
        .applicationXML
    }

    @inlinable public static var applicationOctetStream: Self {
        Field.contentType { "application/octet-stream" }
    }

    @inlinable public static var octetStream: Self {
        .applicationOctetStream
    }
}

extension URLRouting.Field<String> {
    public enum form {
        @inlinable public static var multipart: URLRouting.Field<String> {
            Field.contentType { "multipart/form-data" }
        }

        @inlinable public static var urlEncoded: URLRouting.Field<String> {
            Field.contentType { "application/x-www-form-urlencoded" }
        }
    }
}
