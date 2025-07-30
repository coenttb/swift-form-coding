// https://github.com/pointfreeco/swift-web/tree/main/Sources/UrlFormEncoding
//
// MIT License
//
// Copyright (c) 2017 Point-Free, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import PointFreeURLFormCoding

/// A decoder that converts URL-encoded form data to Swift Codable types.
///
/// `Form.Decoder` implements the `Decoder` protocol to provide seamless
/// conversion from `application/x-www-form-urlencoded` format to Swift types.
/// It supports various parsing strategies for handling different form data formats.
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
/// let decoder = Form.Decoder()
/// let formData = "name=John%20Doe&age=30&isActive=true".data(using: .utf8)!
/// let user = try decoder.decode(User.self, from: formData)
/// ```
///
/// ## Parsing Strategies
///
/// The decoder supports multiple parsing strategies for different form data formats:
///
/// ### Accumulate Values (Default)
/// ```
/// tags=swift&tags=ios&tags=server
/// // Parsed as: tags = ["swift", "ios", "server"]
/// ```
///
/// ### Brackets
/// ```
/// user[name]=John&user[email]=john@example.com
/// // Parsed as: user = {name: "John", email: "john@example.com"}
/// ```
///
/// ### Brackets with Indices
/// ```
/// items[0]=apple&items[1]=banana
/// // Parsed as: items = ["apple", "banana"]
/// ```
///
/// ## Configuration
///
/// ```swift
/// let decoder = Form.Decoder()
/// decoder.parsingStrategy = .brackets
/// decoder.dateDecodingStrategy = .iso8601
/// decoder.dataDecodingStrategy = .base64
/// ```
///
/// ## Advanced Features
///
/// - Multiple parsing strategies for different form formats
/// - Configurable date and data decoding strategies
/// - Support for nested objects and arrays
/// - Custom parsing strategy support
/// - Comprehensive error reporting with coding paths
///
/// - Note: This decoder is designed to work with ``Form.Encoder`` for round-trip compatibility.
/// - Important: Choose parsing strategies that match your form data format.
extension Form {
    public typealias Decoder = PointFreeURLFormCoding.Form.Decoder
}
