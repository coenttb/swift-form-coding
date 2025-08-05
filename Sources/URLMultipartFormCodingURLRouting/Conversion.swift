//
//  File.swift
//  swift-url-form-coding-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 26/07/2025.
//

import Foundation
import Shared
import URLMultipartFormCoding
import URLRouting

extension Conversion {
    /// Maps this conversion through a multipart form data conversion.
    ///
    /// This method allows you to chain conversions, applying multipart form data
    /// conversion after another conversion has been applied.
    ///
    /// - Parameters:
    ///   - type: The Codable type to convert to/from multipart form data
    ///   - decoder: Optional custom URL form decoder (uses default if not provided)
    /// - Returns: A mapped conversion that applies both conversions in sequence
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct APIResponse: Codable {
    ///     let data: UserProfile
    /// }
    ///
    /// // Chain conversions: first parse bytes, then apply multipart conversion
    /// let chainedConversion = Conversion<Data, Data>.identity
    ///     .multipart(UserProfile.self)
    /// ```
    public func multipart<Value: Codable>(
        _ type: Value.Type,
        decoder: Form.Decoder = .init()
    ) -> Conversions.Map<Self, Multipart.Conversion<Value>> {
        self.map(.multipart(type, decoder: decoder))
    }

    /// Creates a multipart form data conversion for the specified Codable type.
    ///
    /// This static method provides a convenient way to create ``Multipart.Conversion``
    /// instances for use in URLRouting route definitions.
    ///
    /// - Parameters:
    ///   - type: The Codable type to convert to/from multipart form data
    ///   - decoder: Optional custom URL form decoder (uses default if not provided)
    /// - Returns: A ``Multipart.Conversion`` conversion instance
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct UserProfile: Codable {
    ///     let name: String
    ///     let bio: String
    /// }
    ///
    /// // Create conversion with default decoder
    /// let conversion = Conversion.multipart(UserProfile.self)
    ///
    /// // Create conversion with custom decoder
    /// let decoder = Form.Decoder()
    /// decoder.parsingStrategy = .brackets
    /// let customConversion = Conversion.multipart(UserProfile.self, decoder: decoder)
    /// ```
    public static func multipart<Value: Codable>(
        _ type: Value.Type,
        decoder: Form.Decoder = .init()
    ) -> Self where Self == Multipart.Conversion<Value> {
        .init(type, decoder: decoder)
    }
}

extension Conversion {
    public static func fileUpload(
        fieldName: String,
        filename: String,
        fileType: Multipart.FileUpload.FileType,
        maxSize: Int
    ) -> Self where Self == Multipart.FileUpload.Conversion {
        .init(
            fieldName: fieldName,
            filename: filename,
            fileType: fileType,
            maxSize: maxSize
        )
    }
}
