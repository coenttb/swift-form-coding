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

extension Foundation.Data {
    package mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
