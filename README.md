# Swift URL Form Coding

[![CI](https://github.com/coenttb/swift-url-form-coding/workflows/CI/badge.svg)](https://github.com/coenttb/swift-url-form-coding/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

A Swift package for type-safe web form encoding and decoding.

## Overview

Type-safe web form encoding and decoding with support for `application/x-www-form-urlencoded` and `multipart/form-data` formats, with URLRouting integration.

## Features

- URL form encoding/decoding with `application/x-www-form-urlencoded` support
- Multipart form data processing (RFC 7578 compliant)
- Custom parsing strategies for nested objects, arrays, and complex data structures
- File upload support with validation, magic number checking, and size limits
- URLRouting integration via `Conversion` protocol
- Type-safe routes with compile-time guarantees
- Conversion chaining for complex data transformations
- Swift 6.0 compatibility with strict concurrency

## Quick Start

### Installation

Add `swift-url-form-coding` to your Swift package:

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-url-form-coding.git", from: "0.0.1")
]
```

### Basic Form Handling

```swift
import URLFormCoding

// Define your data model
struct LoginRequest: Codable {
    let username: String
    let password: String
    let rememberMe: Bool
}

// Create encoder and decoder
let encoder = Form.Encoder()
let decoder = Form.Decoder()

// Encode to form data
let request = LoginRequest(username: "john", password: "secret", rememberMe: true)
let formData = try encoder.encode(request)

// Decode from form data
let formString = "username=john&password=secret&rememberMe=true"
let decoded = try decoder.decode(LoginRequest.self, from: Data(formString.utf8))
print(decoded.username) // "john"
```

### URLRouting Integration

```swift
import URLFormCodingURLRouting

// Define your data model
struct LoginRequest: Codable {
    let username: String
    let password: String
    let rememberMe: Bool
}

// Create a form conversion
let loginForm = Form.Conversion(LoginRequest.self)

// Handle form data
let formData = "username=john&password=secret&rememberMe=true"
let request = try loginForm.apply(Data(formData.utf8))
print(request.username) // "john"
```

### Multipart Form Handling

```swift
import URLMultipartFormCoding

// Define file upload for user avatars
let avatarUpload = Multipart.FileUpload(
    fieldName: "avatar",
    filename: "profile.jpg",
    fileType: .image(.jpeg),
    maxSize: 2 * 1024 * 1024  // 2MB limit
)

// The file upload automatically validates:
// - File size limits
// - JPEG magic number signature
// - Content type matching
```

## Advanced Usage

### Custom Form Decoding Strategies

```swift
// Configure decoder for nested objects
let decoder = Form.Decoder()
decoder.arrayParsingStrategy = .brackets  // Supports user[profile][name]=value
decoder.dateDecodingStrategy = .iso8601

let encoder = Form.Encoder()
encoder.arrayEncodingStrategy = .brackets

// Create form with custom configuration
let advancedForm = Form.Conversion(
    ComplexUser.self,
    decoder: decoder,
    encoder: encoder
)
```

### Supported Parsing Strategies

| Strategy | Example | Use Case |
|----------|---------|----------|
| **Default** | `name=value&age=30` | Simple key-value pairs |
| **Brackets** | `user[name]=John&user[age]=30` | Nested objects |
| **Accumulate** | `tags=swift&tags=ios&tags=web` | Multiple values per key |

### Custom File Types

```swift
import URLMultipartFormCoding

// Define custom file type with validation
let customFileType = Multipart.FileUpload.FileType(
    contentType: "application/json",
    fileExtension: "json"
) { data in
    // Custom validation logic
    _ = try JSONSerialization.jsonObject(with: data)
}

let jsonUpload = Multipart.FileUpload(
    fieldName: "config",
    filename: "settings.json", 
    fileType: customFileType,
    maxSize: 1024 * 1024  // 1MB limit
)
```

### Supported File Types

| Type | Content Type | Validation |
|------|-------------|------------|
| **JPEG** | `image/jpeg` | Magic number validation |
| **PNG** | `image/png` | PNG signature check |
| **PDF** | `application/pdf` | %PDF header validation |
| **Custom** | User-defined | Custom validation function |

### Chaining Conversions

```swift
// Chain multiple conversions together
let stringToUser = Conversion<String, Data>.utf8
    .form(User.self)

// Use in route definition
let chainedRoute = Route {
    Method.post
    Path { "users" }
    Body(stringToUser)
}
```

## Core Components

### Form.Encoder & Form.Decoder

The foundation for URL-encoded form data handling:

```swift
// Basic encoding/decoding
let encoder = Form.Encoder()
let decoder = Form.Decoder()

struct User: Codable {
    let name: String
    let preferences: [String: String]
    let createdAt: Date
}

// Encode to form data
let user = User(name: "John", preferences: ["theme": "dark"], createdAt: Date())
let formData = try encoder.encode(user)

// Decode from form data
let decoded = try decoder.decode(User.self, from: formData)
```

### Form.Conversion

The main conversion type for URLRouting integration:

```swift
// Basic form conversion
let userForm = Form.Conversion(User.self)

// Custom configuration
let encoder = Form.Encoder()
let decoder = Form.Decoder()

let customForm = Form.Conversion(
    User.self,
    decoder: decoder,
    encoder: encoder
)
```

### Multipart Components

Multipart form data handling components:

```swift
import URLMultipartFormCoding

// Basic form field
let field = Multipart.FormField(
    name: "username",
    value: "john_doe"
)

// File upload with validation
let upload = Multipart.FileUpload(
    fieldName: "document",
    filename: "report.pdf", 
    fileType: .pdf,
    maxSize: 5 * 1024 * 1024  // 5MB
)
```

## Security Features

### Form Data Security
- Input Validation: Automatic validation of form field types and formats
- URL Decoding: Proper handling of URL-encoded data with security considerations
- Memory Safety: Efficient parsing that prevents buffer overflows
- Type Safety: Compile-time guarantees for form data structure

### File Upload Security
- Magic Number Validation: Prevents malicious files disguised as safe formats
- Size Limits: Configurable limits prevent DoS attacks via large files
- Content Type Validation: Ensures uploaded content matches declared type
- Safe Boundary Generation: Cryptographically secure multipart boundaries

## Error Handling

### Form Data Errors

```swift
do {
    let user = try formDecoder.decode(User.self, from: formData)
} catch let error as Form.Decoder.Error {
    switch error {
    case .invalidFormat:
        print("Invalid form data format")
    case .missingRequiredField(let field):
        print("Missing required field: \(field)")
    case .typeMismatch(let field, let expectedType):
        print("Type mismatch for \(field), expected \(expectedType)")
    }
}

// Form conversions integrate seamlessly with URLRouting error handling
do {
    let user = try Conversion.form(User.self).apply(formData)
    // Handle successful conversion
} catch {
    // Handle any conversion errors
    print("Form conversion failed: \(error)")
}
```

### Multipart Form Errors

```swift
import URLMultipartFormCoding

do {
    let fileData = try fileUpload.conversion.apply(uploadData)
} catch let error as Multipart.FileUpload.ValidationError {
    switch error {
    case .fileTooLarge(let size, let limit):
        print("File too large: \(size) bytes, limit: \(limit)")
    case .invalidFileType(let expected, let actual):
        print("Invalid file type: expected \(expected), got \(actual)")
    case .emptyFile:
        print("Uploaded file is empty")
    case .invalidMagicNumber:
        print("File signature validation failed")
    }
}
```

## Testing

```bash
swift test
```

## Requirements

- Swift 6.0+
- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+

## Dependencies

- [swift-url-routing](https://github.com/pointfreeco/swift-url-routing) (0.6.0+)
- [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) (1.1.5+)
- [pointfree-url-form-coding](https://github.com/coenttb/pointfree-url-form-coding) (0.2.0+)

## Related Packages

### Dependencies

- [pointfree-url-form-coding](https://github.com/coenttb/pointfree-url-form-coding): A fork of Point-Free's swift-web/UrlFormEncoding.

### Used By

- [swift-mailgun-live](https://github.com/coenttb/swift-mailgun-live): A Swift package with live implementations for Mailgun.
- [swift-types-foundation](https://github.com/coenttb/swift-types-foundation): A Swift package bundling essential type-safe packages for domain modeling.
- [swift-web-foundation](https://github.com/coenttb/swift-web-foundation): A Swift package with tools to simplify web development.

### Third-Party Dependencies

- [pointfreeco/swift-dependencies](https://github.com/pointfreeco/swift-dependencies): A dependency management library for controlling dependencies in Swift.
- [pointfreeco/swift-url-routing](https://github.com/pointfreeco/swift-url-routing): A bidirectional URL router with more type safety and less fuss.

## Acknowledgements

This package's Form.Encoder and Form.Decoder are forked from Point-Free's [swift-web](https://github.com/pointfreeco/swift-web).

## License

This package is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
