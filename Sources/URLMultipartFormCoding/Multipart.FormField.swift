//
//  File.swift
//  swift-url-form-coding-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 26/07/2025.
//

import Foundation

/// A multipart form field that represents a single field in a multipart/form-data request.
///
/// Use this structure to represent individual fields when constructing multipart form data manually.
/// Each field contains a name, optional filename, content type, and the field's data.
///
/// ## Example
///
/// ```swift
/// let field = Multipart.FormField(
///     name: "username",
///     contentType: "text/plain",
///     data: "john_doe".data(using: .utf8)!
/// )
/// ```
extension Multipart {
    public struct FormField {
        /// The name of the form field.
        public let name: String

        /// The filename of the field, if it represents a file upload.
        public let filename: String?

        /// The MIME content type of the field data.
        public let contentType: String?

        /// The raw data content of the field.
        public let data: Data

        /// Creates a new multipart form field.
        ///
        /// - Parameters:
        ///   - name: The name of the form field
        ///   - filename: Optional filename if this field represents a file upload
        ///   - contentType: Optional MIME content type for the field data
        ///   - data: The raw data content of the field
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
}
